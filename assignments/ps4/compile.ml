
 open Riscv
open Ast
open Word32
open List

exception IMPLEMENT_ME

type result = { code : Riscv.inst list;
                data : Riscv.label list }

(* generate fresh labels *)
let label_counter = ref 0
let new_int() = (label_counter := (!label_counter) + 1; !label_counter)
let new_label() = "L" ^ (string_of_int (new_int()))

module VarSet = Set.Make (String)
module VarMap = Map.Make (String)

let vars : VarSet.t ref = ref VarSet.empty
let fnames : VarSet.t ref = ref VarSet.empty

let reset () = (label_counter := 0; vars := VarSet.empty)
let zero = fromInt 0

(* push to stack *)
let push (r : reg) : inst list =[
    Add (R2, R2, Immed(fromInt (-4)));
    Sw (R2, r, fromInt 0)
]

(*pop from stack*)
let pop (r:reg) : inst list = [
    Lw (r, R2, fromInt 0);
    Add (R2, R2, Immed (fromInt 4))
]

(*collect vars, use to determine stack size*)
let rec collect_exp_vars ((e, _): Ast.exp) : unit =
  match e with
  | Int _ -> ()
  | Var v -> vars := VarSet.add v !vars
  | Binop (e1, _, e2) -> collect_exp_vars e1; collect_exp_vars e2
  | Not e | Assign (_, e) -> collect_exp_vars e
  | And (e1, e2) | Or (e1, e2) | Call (_, (e1 :: e2 :: _)) ->
      collect_exp_vars e1; collect_exp_vars e2
  | Call (_, args) -> List.iter collect_exp_vars args

let rec collect_stmt_vars ((s, _) : Ast.stmt) : unit =
  match s with
  | Exp e -> collect_exp_vars e
  | Seq (s1, s2) -> collect_stmt_vars s1; collect_stmt_vars s2
  | If (e, s1, s2) -> collect_exp_vars e; collect_stmt_vars s1; collect_stmt_vars s2
  | While (e, s) -> collect_exp_vars e; collect_stmt_vars s
  | For (e1, e2, e3, s) ->
      collect_exp_vars e1; collect_exp_vars e2; collect_exp_vars e3; collect_stmt_vars s
  | Return e -> collect_exp_vars e
  | Let (v, e, s) ->
      vars := VarSet.add v !vars;
      collect_exp_vars e; collect_stmt_vars s

let collect_vars (p : Ast.program) =
  List.iter (function
    | Fn { name; body; _ } ->
        fnames := VarSet.add name !fnames;
        collect_stmt_vars body
  ) p

(* compile expressions *)
let rec compile_exp (env : int VarMap.t) ((e, _) : Ast.exp) : inst list =
  match e with
  | Int n -> [ Li (R5, fromInt n) ]
  | Var v ->
      if VarMap.mem v env then
        [ Lw (R5, R8, fromInt (VarMap.find v env)) ]
      else
        [ La (R5, v); Lw (R5, R5, zero) ]
  | Binop (e1, b, e2) ->
      compile_exp env e1 @
      push R5 @
      compile_exp env e2 @
      pop R6 @
      (match b with
       | Plus -> [ Add (R5, R5, Reg R6) ]
       | Minus -> [ Sub (R5, R6, R5) ]
       | Times -> [ Mul (R5, R5, R6) ]
       | Div -> [ Div (R5, R6, R5) ]
       | Eq -> [ Sub (R5, R5, R6); Seqz (R5, R5) ]
       | Neq -> [ Sub (R5, R5, R6); Snez (R5, R5) ]
       | Lt -> [ Slt (R5, R6, R5) ]
       | Lte -> [ Slt (R10, R5, R6); Seqz (R10, R10); Add (R5, R10, Reg R0) ]
       | Gt -> [ Slt (R5, R5, R6) ]
       | Gte -> [ Slt (R10, R6, R5); Seqz (R10, R10); Add (R5, R10, Reg R0) ])
  | Not e -> compile_exp env e @ [ Seqz (R5, R5) ]
  | And (e1, e2) ->
      compile_exp env e1 @
      push R5 @
      compile_exp env e2 @
      pop R6 @ [ And (R5, R6, Reg R5) ]
  | Or (e1, e2) ->
        compile_exp env e1 @
        push R5 @
        compile_exp env e2 @
        pop R6 @[Or (R5, R5, Reg R6); Snez (R5, R5)]

    | Assign (v, e) ->
        let offset = VarMap.find v env in
        let rhs_code = compile_exp env e in
        if VarMap.mem v env then
    rhs_code @ [ Sw (R8, R5, fromInt offset) ]
    else
        (*global*)
    rhs_code @ [ La (R7, v); Sw (R7, R5, zero) ]
    
    | Call(fname, args_list) ->
        (* save caller saved registers *)
        let save_caller_registers = [
          Add(R2, R2, Immed (fromInt (-20)));
          Sw(R2, R1, fromInt 16);
          Sw(R2, R5, fromInt 12);
          Sw(R2, R6, fromInt 8);
          Sw(R2, R7, fromInt 4)
        ] in
      
        let total_args = List.length args_list in
        let num_reg_args = if total_args < 8 then total_args else 8 in
        let num_stack_args = if total_args > 8 then total_args - 8 else 0 in
      
        (* push all arguments onto stack reverse order *)
        let reversed_args = List.rev args_list in
        let push_all_args = 
          List.concat (
            List.map (fun arg ->
              compile_exp env arg @ push R5
            ) reversed_args
          )
        in
      
        (* pop  top 8 arguments into regs R10 to R17 *)
        let rec pop_register_args i acc =
          if i >= num_reg_args then acc
          else
            let target_reg =
              match i with
              | 0 -> R10 | 1 -> R11 | 2 -> R12 | 3 -> R13
              | 4 -> R14 | 5 -> R15 | 6 -> R16 | 7 -> R17
              | _ -> failwith "error"
            in
            pop_register_args (i + 1) (
              acc @ [ Lw(target_reg, R2, fromInt 0);
                      Add(R2, R2, Immed (fromInt 4)) ]
            )
        in
        let pop_into_arg_registers = pop_register_args 0 [] in
      
        let call_function = [ Jal(R1, fname) ] in
      
        (* remove  extra arguments passed on the stack *)
        let clean_stack =
          if num_stack_args > 0 then
            [ Add(R2, R2, Immed (fromInt (num_stack_args * 4))) ]
          else []
        in
      
        let restore_caller_registers = [
          Lw(R7, R2, fromInt 4);
          Lw(R6, R2, fromInt 8);
          Lw(R5, R2, fromInt 12);
          Lw(R1, R2, fromInt 16);
          Add(R2, R2, Immed(fromInt 20))
        ] in
      
        (* move result from R10 -> R5 *)
        let move_return_value = [ Add(R5, R10, Reg R0) ] in
      
        save_caller_registers
        @ push_all_args
        @ pop_into_arg_registers
        @ call_function
        @ clean_stack
        @ restore_caller_registers
        @ move_return_value
      
(* compile statements *)
let rec compile_stmt (env: int VarMap.t) (epilogue_label: label) ((s, _): Ast.stmt) : inst list =
  match s with
  | Exp e -> compile_exp env e
  | Seq (s1, s2) -> compile_stmt env epilogue_label s1 @ compile_stmt env epilogue_label s2
  | If (e, s1, s2) ->
    let else_label = new_label () in
    let end_label = new_label () in
      compile_exp env e @ [ Beq (R5, R0, else_label) ] @
      compile_stmt env epilogue_label s1 @ [ J end_label; Label else_label ] @
      compile_stmt env epilogue_label s2 @ [ Label end_label ]
  |Let (v, e, s) ->
    let offset = -4 * (VarMap.cardinal env + 3) in
    let env' = VarMap.add v offset env in
    compile_exp env e @ 
    [ Sw (R8, R5, fromInt offset) ] 
    @ compile_stmt env' epilogue_label s
  |While (e, s) ->
    let test_label = new_label () in
    let top_label = new_label () in
    [ J test_label; Label top_label ] 
    @ compile_stmt env epilogue_label s @[ Label test_label ] 
    @ compile_exp env e @ [ Bne (R5, R0, top_label) ]
  | For (e1, e2, e3, s) ->
      compile_stmt env epilogue_label (Seq ((Exp e1, 0), (While (e2, (Seq (s, (Exp e3, 0)), 0)), 0)), 0)
  | Return e -> compile_exp env e @ [ Add (R10, R5, Reg R0); Jal (R0, epilogue_label) ]

(* compile function *)
let compile_function (fn: func) : inst list =
match fn with
| Fn { name; args; body; _ } ->
    let epilogue_label = new_label () in   
    let frame_size = (List.length args)*4 + 128 in
    let prologue = [
        Label name;
        Add (R2, R2, Immed (fromInt (-frame_size)));
        Sw (R2, R8, fromInt (frame_size - 4));
        Sw (R2, R1, fromInt (frame_size - 8));
        Add (R8, R2, Immed (fromInt frame_size))
    ] in

    let store_params, env_params =
        let rec loop i (insts, env) = function
        | [] -> (insts, env)
        | param :: rest ->
            let offset = -4 * (i + 3) in
            let store_inst =
                if i < 8 then
                let reg = match i with
                    | 0 -> R10 | 1 -> R11 | 2 -> R12 | 3 -> R13
                    | 4 -> R14 | 5 -> R15 | 6 -> R16 | 7 -> R17
                    | _ -> failwith "error"
                in [ Sw (R8, reg, fromInt offset) ]
                else
                let stack_offset = frame_size + (i - 8) * 4 in
                [ Lw (R6, R2, fromInt stack_offset); Sw (R8, R6, fromInt offset) ]
            in
            let env' = VarMap.add param offset env in
            loop (i + 1) (insts @ store_inst, env') rest
        in
        loop 0 ([], VarMap.empty) args
    in

    let code_body = store_params @ compile_stmt env_params epilogue_label body in
    let epilogue = [
        Label epilogue_label;
        Lw (R1, R2, fromInt (frame_size - 8));
        Lw (R8, R2, fromInt (frame_size - 4));
        Add (R2, R2, Immed (Word32.fromInt frame_size));
        jr R1
    ] in
    prologue @ code_body @ epilogue

let compile (p: program) : result =
    collect_vars p;
    let function_codes = List.map compile_function p in
    let data = VarSet.diff !vars !fnames in
    { code = List.flatten function_codes; data = VarSet.elements data  }


let result2string (res: result) : string =
let code_strs = List.map (fun i -> inst2string i ^ "\n") res.code in
let data_strs = List.map (fun x -> x ^ ":\t.word 0\n") res.data in
"\t.text\n\t.align\t2\n\t.globl main\n" ^
String.concat "" code_strs ^
"\n\n\t.data\n\t.align 0\n" ^
String.concat "" data_strs ^
"\n"
