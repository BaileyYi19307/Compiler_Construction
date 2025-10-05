(* Compile Fish AST to RISC-V AST *)
open Riscv

exception IMPLEMENT_ME

type result = { code : Riscv.inst list;
                data : Riscv.label list }

(* generate fresh labels *)
let label_counter = ref 0
let new_int() = (label_counter := (!label_counter) + 1; !label_counter)
let new_label() = "L" ^ (string_of_int (new_int()))

(* sets of variables -- Ocaml Set and Set.S *)
module VarSet = Set.Make(struct
                           type t = Ast.var
                           let compare = String.compare
                         end)

(* a table of variables that we need for the code segment *)
let variables : VarSet.t ref = ref (VarSet.empty)

(* generate a fresh temporary variable and store it in the variables set. *)
let rec new_temp() = 
    let t = "T" ^ (string_of_int (new_int())) in
    (* make sure we don't already have a variable with the same name! *)
    if VarSet.mem t (!variables) then new_temp()
    else (variables := VarSet.add t (!variables); t)

(* reset internal state *)
let reset() = (label_counter := 0; variables := VarSet.empty)


(* find all variables in an expression and add to set of variables *)
let rec collect_vars_exp (e: Ast.exp) : unit = 
    match fst e with 
    | Int _ -> ()
    | Var x -> variables := VarSet.add x (!variables)
    | Binop (e1, _, e2) -> collect_vars_exp e1 ; collect_vars_exp e2
    | Assign (x, e) -> variables := VarSet.add x (!variables); collect_vars_exp e
    | Not e -> collect_vars_exp e
    | And (e1, e2) -> collect_vars_exp e1; collect_vars_exp e2
    | Or (e1, e2) -> collect_vars_exp e1; collect_vars_exp e2


(* find all of the variables in a program and add them to
 * the set variables *)
let rec collect_vars (p : Ast.program) : unit = 
    match fst p with
    | Exp e -> collect_vars_exp e
    | Seq (s1,s2) -> collect_vars s1; collect_vars s2;
    | If (e1, s1, s2) -> collect_vars_exp e1; collect_vars s1; collect_vars s2
    | While (e1,s1) -> collect_vars_exp e1; collect_vars s1
    | For (e1, e2, e3, s1) -> collect_vars_exp e1; collect_vars_exp e2; collect_vars_exp e3; collect_vars s1
    | Return e1 -> collect_vars_exp e1

let rec compile_exp ((e, _): Ast.exp) : inst list =
  match e with 
  | Int n ->
      [Li (R10, Word32.fromInt n)]
  | Var v ->
      [La (R10, v); Lw (R10, R10, Int32.of_int 0 )]
  | Binop (e1, b, e2) ->
      let temp = new_temp () in
      (compile_exp e1)
      @ [La (R7, temp); Sw (R7, R10, Int32.of_int 0 )]
      @ (compile_exp e2)
      @ [La (R7, temp); Lw (R6, R7, Int32.of_int 0 )]
      @ (match b with 
           | Plus  -> [Add (R10, R10, Reg R6)]
           | Minus -> [Sub (R10, R6, R10)]
           | Times -> [Mul (R10, R10, R6)]
           | Div   -> [Div (R10, R6, R10)]
           | Eq    -> [Sub (R10, R10, R6); Seqz (R10, R10)]
           | Neq   -> [Sub (R10, R10, R6); Snez (R10, R10)]
           | Lt    -> [Slt (R10, R6, R10)]
           | Lte   -> [Slt (R10, R10, R6); Seqz (R10, R10)]
           | Gt    -> [Slt (R10, R10, R6)]
           | Gte   -> [Slt (R10, R6, R10); Seqz (R10, R10)])
  | Not e ->
      (compile_exp e) @ [Seqz (R10, R10)]
  | And (e1, e2) ->
      (compile_exp e1)
      @ (let temp = new_temp () in
         [La (R7, temp); Sw (R7, R10, Int32.of_int 0 )]
         @ (compile_exp e2)
         @ [La (R7, temp); Lw (R6, R7, Int32.of_int 0 ); And (R10, R10, Reg R6)])
  | Or (e1, e2) ->
      (compile_exp e1)
      @ (let temp = new_temp () in
         [La (R7, temp); Sw (R7, R10, Int32.of_int 0 )]
         @ (compile_exp e2)
         @ [La (R7, temp); Lw (R6, R7, Int32.of_int 0 ); Or (R10, R10, Reg R6); Snez (R10, R10)])
  | Assign (v, e) ->
      (compile_exp e)
      @ [La (R7, v); Sw (R7, R10, Int32.of_int 0 )]

(* Compile statements to RISC-V instructions.
   Note: the result of each expression is now in R10. *)
let rec compile_stmt ((s, _): Ast.stmt) : inst list =
  match s with
  | Exp e ->
      compile_exp e
  | Seq (s1, s2) ->
      (compile_stmt s1) @ (compile_stmt s2)
  | If (e, s1, s2) ->
      let else_label = new_label () in
      let end_label  = new_label () in
      (compile_exp e)
      @ [Beq (R10, R0, else_label)]
      @ (compile_stmt s1)
      @ [J end_label; Label else_label]
      @ (compile_stmt s2)
      @ [Label end_label]
  | While (e, s) ->
      let test_label = new_label () in
      let top_label  = new_label () in
      [J test_label; Label top_label]
      @ (compile_stmt s)
      @ [Label test_label]
      @ (compile_exp e)
      @ [Bne (R10, R0, top_label)]
| For(e1,e2,e3,s) ->
        compile_stmt(Seq((Exp e1, 0),(While(e2,(Seq(s,(Exp e3,0)),0)),0)),0)
  | Return e ->
      (compile_exp e) @ [Add (R10, R10, Reg R0); jr R1]

(* compiles Fish AST down to RISC-V instructions and a list of global vars *)
let compile (p : Ast.program) : result =
  let _ = reset () in
  let _ = collect_vars p in
  let insts = (Label "main") :: (compile_stmt p) in
  { code = insts; data = VarSet.elements (!variables) }

(* converts the output of the compiler to a big string which can be 
   dumped into a file, assembled, and run in qemu *)
let result2string ({ code; data } : result) : string =
  let inst_strs = List.map (fun i -> (Riscv.inst2string i) ^ "\n") code in
  let var_decl v = v ^ ":\t.word 0\n" in
  "\t.text\n" ^
  "\t.align\t2\n" ^
  "\t.globl main\n\n" ^
  (String.concat "" inst_strs) ^
  "\n\n" ^
  "\t.data\n" ^
  "\t.align 0\n" ^
  (String.concat "" (List.map var_decl data)) ^
  "\n"
