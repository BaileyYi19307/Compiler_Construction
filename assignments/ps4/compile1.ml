
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

type varmap = string -> int

type env = {
  varmap : varmap;
  epilogue : string;
  next_offset:int;
}

let empty_varmap () : varmap = fun _ -> raise Not_found
let insert_var (vm : varmap) (x : string) (offset : int) : varmap =
  fun y -> if y = x then offset else vm y
let lookup_var (vm : varmap) (x : string) : int = vm x

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

(* compile expressions *)
let rec compile_exp (env : env) ((e, _) : Ast.exp) : inst list =
  match e with
  | Int n -> [ Li (R10, fromInt n) ]
  | Var v ->
      let offset = lookup_var env.varmap v in
      [ Lw (R10, R8, fromInt offset) ]
  | Binop (e1, b, e2) ->
      let code1 = compile_exp env e1 in
      let save_e1 = push R10 in
      let code2 = compile_exp env e2 in
      let restore_e1 = pop R11 in
      let compute =
        match b with
        | Plus  -> [ Add (R10, R11, Reg R10) ]
        | Minus -> [ Sub (R10, R11, R10) ]
        | Times -> [ Mul (R10, R10, R11) ]
        | Div   -> [ Div (R10, R11, R10) ]
        | Eq    -> seq (R10, R10, R11)
        | Neq   -> sne (R10, R10, R11)
        | Lt    -> [ Slt (R10, R11, R10) ]
        | Lte   -> [ Slt (R10, R10, R11); Seqz (R10, R10) ]
        | Gt    -> [ Slt (R10, R10, R11) ]
        | Gte   -> [ Slt (R10, R11, R10); Seqz (R10, R10) ]
      in
      code1 @ save_e1 @ code2 @ restore_e1 @ compute
  | Not e -> compile_exp env e @ [ Seqz (R10, R10) ]
  | And (e1, e2) ->
      let code1 = compile_exp env e1 in
      let save_e1 = push R10 in
      let code2 = compile_exp env e2 in
      let restore_e1 = pop R11 in
      code1 @ save_e1 @ code2 @ restore_e1 @ [ And (R10, R11, Reg R10) ]
  | Or (e1, e2) ->
      let code1 = compile_exp env e1 in
      let save_e1 = push R10 in
      let code2 = compile_exp env e2 in
      let restore_e1 = pop R11 in
      code1 @ save_e1 @ code2 @ restore_e1 @ [ Or (R10, R10, Reg R11); Snez (R10, R10) ]
  | Assign (v, e) ->
      let offset = lookup_var env.varmap v in
      let rhs_code = compile_exp env e in
      rhs_code @ [ Sw (R8, R10, fromInt offset) ]
               @ [ Lw (R10, R8, fromInt offset) ]
 
               | Call (fname, args) ->
                let rec split_at n lst =
                  if n <= 0 then ([], lst)
                  else match lst with
                    | [] -> ([], [])
                    | x :: xs ->
                        let (l1, l2) = split_at (n - 1) xs in
                        (x :: l1, l2)
                in
                let (reg_args, stack_args) = split_at 8 args in
                let stack_setup =
                  List.map (fun arg -> compile_exp env arg @ push R10) stack_args
                  |> List.flatten
                in
                let reg_setup =
                  List.mapi (fun i arg ->
                    let arg_code = compile_exp env arg in
                    let target_reg =
                      match i with
                      | 0 -> R10 | 1 -> R11 | 2 -> R12 | 3 -> R13
                      | 4 -> R14 | 5 -> R15 | 6 -> R16 | 7 -> R17
                      | _ -> failwith "failed"
                    in
                    arg_code @ [ Add (target_reg, R10, Reg R0) ]
                  ) reg_args
                  |> List.flatten
                in
                let cleanup =
                  match List.length stack_args with
                  | 0 -> []
                  | n -> [ Add (R2, R2, Immed (fromInt (4 * n))) ]
                in
                stack_setup @ reg_setup @ [ Jal (R1, fname) ] @ cleanup


(* compile statements *)
let rec compile_stmt (env : env) ((s, _) : Ast.stmt) : inst list =
  match s with
  | Exp e -> compile_exp env e
  | Seq (s1, s2) -> compile_stmt env s1 @ compile_stmt env s2
  | If (e, s1, s2) ->
      let else_label = new_label () in
      let end_label = new_label () in
      compile_exp env e @ [ Beq (R10, R0, else_label) ]
      @ compile_stmt env s1 @ [ J end_label; Label else_label ]
      @ compile_stmt env s2 @ [ Label end_label ]
  | Let (v, e, s1) ->
      let compiled_exp = compile_exp env e in
      let offset = env.next_offset in
      let store_in_varmap = [ Sw (R8, R10, fromInt offset) ] in
      let varmap' = insert_var env.varmap v offset in
      let env' = { varmap = varmap'; epilogue = env.epilogue; next_offset = offset - 4 } in
      compiled_exp @ store_in_varmap @ compile_stmt env' s1
  | While (e, s) ->
      let test_label = new_label () in
      let top_label = new_label () in
      [ J test_label; Label top_label ]
      @ compile_stmt env s @ [ Label test_label ]
      @ compile_exp env e @ [ Bne (R10, R0, top_label) ]
  | For (e1, e2, e3, s) ->
      compile_stmt env (Seq ((Exp e1, 0), (While (e2, (Seq (s, (Exp e3, 0)), 0)), 0)), 0)
  | Return e ->
      compile_exp env e @ [ J env.epilogue ]

(* compile function *)
let compile_function (fn : func) : inst list =
  match fn with
  | Fn { name; args; body; _ } ->
      let epilogue_label = new_label () in
      let frame_size = 128 in
      let prologue =
        [ Label name;
          Add (R2, R2, Immed (fromInt (-frame_size)));
          Sw (R2, R1, fromInt (frame_size - 4));
          Sw (R2, R8, fromInt (frame_size - 8));
          Add (R8, R2, Immed (fromInt frame_size))
        ]
      in
      let env = { varmap = empty_varmap (); epilogue = epilogue_label; next_offset = -20 } in
      let rec save_args env i args =
        match args with
        | [] -> (env, [])
        | arg_name :: rest ->
            if i < 8 then
              let offset = env.next_offset in
              let reg =
                match i with
                | 0 -> R10 | 1 -> R11 | 2 -> R12 | 3 -> R13
                | 4 -> R14 | 5 -> R15 | 6 -> R16 | 7 -> R17
                | _ -> failwith "failed"
              in
              let store_inst = Sw (R8, reg, fromInt offset) in
              let env' = { env with
                           varmap = insert_var env.varmap arg_name offset;
                           next_offset = offset - 4 } in
              let (env_final, rest_insts) = save_args env' (i + 1) rest in
              (env_final, store_inst :: rest_insts)
            else
              let extra_offset = (i - 8) * 4 in
              let env' = { env with varmap = insert_var env.varmap arg_name extra_offset } in
              save_args env' (i + 1) rest
      in
      let (env_with_args, arg_saves) = save_args env 0 args in
      let code_body = arg_saves @ compile_stmt env_with_args body in
      let epilogue =
        [ Label epilogue_label;
          Lw (R1, R2, fromInt (frame_size - 4));
          Lw (R8, R2, fromInt (frame_size - 8));
          Add (R2, R2, Immed (fromInt frame_size));
          Jalr (R0, R1, Int32.zero)
        ]
      in
      prologue @ code_body @ epilogue

let compile (p : program) : result =
  let function_codes = List.map compile_function p in
  { code = List.flatten function_codes; data = [] }

let result2string (res : result) : string =
  let code = res.code in
  let data = res.data in
  let strs = List.map (fun x -> Riscv.inst2string x ^ "\n") code in
  let var_decl x = x ^ ":\t.word 0\n" in
  "\t.text\n\t.align\t2\n\t.globl main\n"
  ^ String.concat "" strs
  ^ "\n\n\t.data\n\t.align 0\n"
  ^ String.concat "" (List.map var_decl data)
  ^ "\n"
;; 
 *)