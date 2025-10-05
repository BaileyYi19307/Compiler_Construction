(* Compile Fish AST to RISC-V AST *)
open Riscv
open Ast

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

let zero = Word32.fromInt 0

let rec collect_exp_vars ((e,_): Ast.exp) : unit = 
    match e with
    | Int _ -> ()  
    | Var v ->
        variables := VarSet.add v (!variables)
    | Binop (e1, _, e2) ->
        collect_exp_vars e1;   
        collect_exp_vars e2    
    | Not e1 ->
        collect_exp_vars e1     
    | And (e1, e2)
    | Or (e1, e2) ->
        collect_exp_vars e1;
        collect_exp_vars e2
    | Assign (v, e1) ->
        variables := VarSet.add v (!variables);  
        collect_exp_vars e1                    


let rec collect_stmt_vars ((s,_): Ast.stmt) : unit = 
    match s with 
    | Exp e -> 
        collect_exp_vars e
    | Seq (s1, s2) ->
        collect_stmt_vars s1;
        collect_stmt_vars s2
    | If (e, s1, s2) -> 
        collect_exp_vars e; 
        collect_stmt_vars s1;
        collect_stmt_vars s2
    | While (e, s1) -> 
        collect_exp_vars e;
        collect_stmt_vars s1
    | For (e1, e2, e3, s1) ->
        collect_exp_vars e1;
        collect_exp_vars e2;
        collect_exp_vars e3;
        collect_stmt_vars s1
    | Return (e) -> 
        collect_exp_vars e

(* find all of the variables in a program and add them to
 * the set variables *)
let collect_vars (p : Ast.program) : unit = 
    (*************************************************************)
    collect_stmt_vars p 
    (*************************************************************)



let rec compile_expr ((e, _): Ast.exp) : inst list = 
    match e with 
    | Int n -> [Li(R5, Word32.fromInt n)] 
    | Var v -> [La(R5, v); Lw(R5, R5, zero)]
    | Binop (e1, b, e2) -> 
        (let t = new_temp()in
            (compile_expr e1) @ [La (R7, t); Sw (R7, R5, zero)]
           @(compile_expr e2) @ [La (R7, t); Lw (R6, R7, zero)] 
           @(match b with 
              Plus -> [Add (R5, R5, Reg R6)]
            | Minus -> [Sub (R5, R6, R5)]
            | Times -> [Mul (R5, R5, R6)]
            | Div -> [Div (R5, R6, R5)]
            | Eq    -> [Sub (R5, R5, R6); Seqz (R5, R5)]
            | Neq   -> [Sub (R5, R5, R6); Snez (R5, R5)]
            | Lt    -> [Slt (R5, R6, R5)]
            | Lte   -> 
                [Slt (R10, R5, R6); Seqz (R10, R10); Add (R5, R10, Reg R0)]
            | Gt    -> [Slt (R5, R5, R6)]
            | Gte   -> [Slt (R10, R6, R5); Seqz (R10, R10); Add (R5, R10, Reg R0)]))
    | Not e -> (compile_expr e) @ [Seqz (R5, R5)]
    | And (e1, e2) ->
        (compile_expr e1) @
        (let t = new_temp() in [La(R7, t); Sw(R7, R5, zero)] @
        (compile_expr e2) @
        [La(R7, t); Lw(R6, R7, zero); And (R5, R5, Reg R6)])
    | Or (e1, e2) -> 
        (compile_expr e1) @
        (let t = new_temp() in [La(R7, t); Sw(R7, R5, zero)] @
        (compile_expr e2) @
        [La(R7, t); Lw(R6, R7, zero); Or (R5, R5, Reg R6); Snez (R5, R5)];)
    | Assign(v,e) -> (compile_expr e) @
    [La(R7,v); Sw(R7,R5,zero)]

(* compiles a Fish statement down to a list of RISC-V instructions.
 * Note that a "Return" is accomplished by placing the resulting
 * value in x10 and then doing a jr x1.
 *)
let rec compile_stmt ((s,_):Ast.stmt) : inst list = 
    (*************************************************************)
    match s with
    | Exp e ->
        (compile_expr e)
    | Seq(s1,s2) ->
        (compile_stmt s1) @ (compile_stmt s2)
    | If(e,s1,s2) ->
        (let else_l = new_label() in
        let end_l = new_label() in
        (compile_expr e) @ [Beq(R5,R0,else_l)] @
        (compile_stmt s1) @ [J end_l;Label else_l] @
        (compile_stmt s2) @ [Label end_l])
    | While(e,s) ->
        (let test_l = new_label() in
        let top_l = new_label() in
        [J test_l; Label top_l] @
        (compile_stmt s) @
        [Label test_l] @
        (compile_expr e) @
        [Bne(R5,R0,top_l)])
    | For(e1,e2,e3,s) ->
        compile_stmt(Seq((Exp e1, 0),(While(e2,(Seq(s,(Exp e3,0)),0)),0)),0)
    | Return(e) -> (compile_expr e) @ [Add (R10, R5, Reg R0); jr R1]
    (*************************************************************)

(* compiles Fish AST down to RISC-V instructions and a list of global vars *)
let compile (p : Ast.program) : result = 
    let _ = reset() in
    let _ = collect_vars(p) in
    let insts = (Label "main") :: (compile_stmt p) in
    { code = insts; data = VarSet.elements (!variables) }

(* converts the output of the compiler to a big string which can be 
 * dumped into a file, assembled, and run in qemu *)
let result2string ({code;data}:result) : string = 
    let strs = List.map (fun x -> (Riscv.inst2string x) ^ "\n") code in
    let var2decl x = x ^ ":\t.word 0\n" in
    "\t.text\n" ^
    "\t.align\t2\n" ^
    "\t.globl main\n\n" ^
    (String.concat "" strs) ^
    "\n\n" ^
    "\t.data\n" ^
    "\t.align 0\n"^
    (String.concat "" (List.map var2decl data)) ^
    "\n"
