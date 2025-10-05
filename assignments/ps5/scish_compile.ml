(* TODO:  your job is to map ScishAst expressions to CishAst functions. 
   The file sample_input.scish shows a sample Scish expression and the
   file sample_output.cish shows the output I get from my compiler.
   You will want to do your own test cases...
 *)

open Cish_ast

exception Unimplemented

(* how many nested environments away the variable was declared *)
type value = {
  name: string;
  depth: int;
}

(* environment is just list of values*)
type environment = value list

(*how many parent links do we have to traverse, returns an int*)
let find_var_depth (target_var: string) (env:environment) : int =
  let rec search = function
  | [] -> failwith("variable not found")
  | entry :: remaining_entries -> 
      if entry.name = target_var then entry.depth
      else search remaining_entries
  in
  search env 

(* traverse N parent links from environment pointer *)
let rec traverse_parent_chain (env_ptr: rexp) (depth: int) : rexp =
  if depth = 0 then
    Load (Binop((env_ptr, 0), Plus, (Int 4, 0)), 0)
  else
    let parent_ptr = Load (Binop((env_ptr, 0), Plus, (Int 0, 0)), 0) in
    traverse_parent_chain parent_ptr (depth - 1)

(* generate code to access a variable via an environment register *)
let generate_env_access (env_reg: string) (depth: int) : rexp =
  if depth = 0 then
    Load (Binop((Var env_reg, 0), Plus, (Int 4, 0)), 0)
  else
    let parent_ptr = Load (Binop((Var env_reg, 0), Plus, (Int 0, 0)), 0) in
    traverse_parent_chain parent_ptr (depth - 1)


(*generate new function name*)
let counter= ref 0
let generate_new_fname (name_prefix: string) : string =
  let current_count = !counter in 
  counter := current_count +1;
  name_prefix ^ string_of_int current_count


let rec compile_with_env (e: Scish_ast.exp) (result: string) (env: environment): (stmt*program ) =
  match e with
  | Scish_ast.Int i -> 
    let stmt = (Exp (Assign (result, (Int i, 0)), 0),0) in
    (stmt, [])
  | Scish_ast.Var v -> 
    (*find how deep in the environment x is *)
    let var_depth = find_var_depth v env in 
    let stmt = (Exp(Assign(result,(generate_env_access "dynenv" var_depth,0)),0),0) in 
    (stmt,[])
  | Scish_ast.Lambda (x, e) ->
    (*generate function name*)
    let fname =  generate_new_fname "t" in 

    (*update the environment*)
    let updated_env = 
      (* increment depth of all vars by 1, and add new lambda x at depth 0*)
      let updated_part= List.map (fun e -> {e with depth = e.depth+1}) env in 
      {name=x; depth =0}::updated_part
    in 
    let body_stmt, functions = compile_with_env e "result" updated_env in 
    let body_complete : stmt = Seq(body_stmt, (Return( (Var "result",0)),0)), 0
    in 
    let func = Cish_ast.Fn {
        name = fname;
        args = ["dynenv"];
        body = (Let ("result", (Int 0, 0), body_complete), 0);
        pos = 0
      } in
    (*create closure*)
      let malloc_stmt = (Exp (Assign (result, (Malloc (Int 8, 0), 0)), 0), 0) in
      let store_fn_stmt = (Exp (Store ((Var result, 0), (Var fname, 0)), 0),0)in
      let store_env_stmt = (Exp (Store ((Binop ((Var result, 0), Plus, (Int 4, 0)), 0), (Var "dynenv", 0)),0),0)
    in

    let body_stmt = (Cish_ast.Seq(
      malloc_stmt,
      (Cish_ast.Seq(store_fn_stmt, store_env_stmt), 0)
    ), 0)
  in 
  (body_stmt, func :: functions)


  | Scish_ast.App (e1, e2) ->

    let closure_ptr = generate_new_fname "t" in
    let (stmt_e1, funcs_e1) = compile_with_env e1 closure_ptr env in
    
    let func_ptr = generate_new_fname "t" in
    let captured_env = generate_new_fname "t" in
    let extended_env = generate_new_fname "t" in
    let e2_result = generate_new_fname "t" in  
    
    let (stmt_e2, funcs_e2) = compile_with_env e2 e2_result env in
    
    let stmts = [
      (Let (closure_ptr, (Int 0, 0), stmt_e1), 0);

      (Let (func_ptr, (Int 0, 0), 
        (Exp (Assign (func_ptr, (Load (Var closure_ptr, 0), 0)), 0), 0)),0);

      (Let (captured_env, (Int 0, 0), 
        (Exp (Assign (captured_env, (Load (Binop ((Var closure_ptr, 0), Plus, (Int 4, 0)), 0), 0)), 0),0)),0);

      (Let (e2_result, (Int 0, 0), stmt_e2),0);

      (Let (extended_env, (Int 0, 0),
        (Seq (
          (Exp (Assign (extended_env, (Malloc (Int 8, 0), 0)),0),0),
          (Seq (
            (Exp (Store ((Var extended_env, 0), (Var captured_env, 0)), 0),0),
            (Exp (Store ((Binop ((Var extended_env, 0), Plus, (Int 4, 0)),0), (Var e2_result, 0)), 0) ,0)
          ),0)
        ), 0)),0);
      (Exp (Assign (result, (Call ((Var func_ptr, 0), [(Var extended_env, 0)]), 0)),0) ,0);
    ] in
    
    let rec nest_let_sequence stmts =
      List.fold_right (fun stmt acc ->
        match stmt with
        | (Let (var, init, body), pos) -> 
            (Let (var, init, (Seq (body, acc), pos)), pos)
        | other_stmt -> 
            (Seq (other_stmt, acc), 0))
      stmts
      (Exp (Int 0, 0), 0)
    in
    let compiled_app_stmts = nest_let_sequence stmts in
    (compiled_app_stmts, funcs_e1 @ funcs_e2)

  | Scish_ast.If (cond_exp, then_exp, else_exp) ->
    let cond_tmp = generate_new_fname "cond" in
    let (cond_stmt, funcs_cond) = compile_with_env cond_exp cond_tmp env in
    let (then_stmt, funcs_then) = compile_with_env then_exp result env in
    let (else_stmt, funcs_else) = compile_with_env else_exp result env in
    let if_stmt = (If ((Var cond_tmp, 0), then_stmt, else_stmt), 0) in
    let full_stmt = (Let (cond_tmp, (Int 0, 0), (Seq (cond_stmt, if_stmt), 0)), 0) in
    (full_stmt, funcs_cond @ funcs_then @ funcs_else)
  | Scish_ast.PrimApp (op, args) ->
    (match op with
    | Scish_ast.Plus | Scish_ast.Minus | Scish_ast.Times | Scish_ast.Div | Scish_ast.Eq | Scish_ast.Lt ->
        compile_binary_op op args result env
    | Scish_ast.Cons ->
        compile_cons args result env
    | Scish_ast.Fst ->
        compile_fst args result env
    | Scish_ast.Snd ->
        compile_snd args result env)
    

    and compile_binary_op (op : Scish_ast.primop) (args : Scish_ast.exp list) (result_var : string) (env : environment) : (stmt * program) =
      match args with
      | [left_exp; right_exp] ->
          let map_scish_to_cish_op = function
            | Scish_ast.Plus  -> Plus
            | Scish_ast.Minus -> Minus
            | Scish_ast.Times -> Times
            | Scish_ast.Div   -> Div
            | Scish_ast.Eq    -> Eq
            | Scish_ast.Lt    -> Lt
            | _ -> failwith "unsupported binary operator"
          in
          let binary_operator = map_scish_to_cish_op op in
    
          let (compiled_left_stmt, funcs_left) = compile_with_env left_exp "result" env in
          let left_val_tmp = generate_new_fname "lhs_val" in
          let (compiled_right_stmt, funcs_right) = compile_with_env right_exp "result" env in
    
          let binary_operation_expr =
            (Binop ((Var left_val_tmp, 0), binary_operator, (Var "result", 0)), 0)
          in
    
          let assign_result_stmt =
            (Exp (Assign (result_var, binary_operation_expr), 0), 0)
          in
    
          let save_left_val_stmt =
            (Exp (Assign (left_val_tmp, (Var "result", 0)), 0), 0)
          in
    
          let body_seq =
            let seq1 = (Seq (compiled_left_stmt, save_left_val_stmt), 0) in
            let seq2 = (Seq (seq1, compiled_right_stmt), 0) in
            let seq3 = (Seq (seq2, assign_result_stmt), 0) in
            seq3
          in
    
          let full_stmt =
            (Let (left_val_tmp, (Int 0, 0), body_seq), 0)
          in
    
          (full_stmt, funcs_left @ funcs_right)
    
      | _ ->
          failwith "binary op expects two arguments"

and compile_cons (args : Scish_ast.exp list) (result_var : string) (env : environment) : (stmt * program) =
  match args with
  | [head_exp; tail_exp] ->
    let (compiled_head_stmt, funcs_head) = compile_with_env head_exp "result" env in
    let head_tmp = generate_new_fname "head_val" in

    let (compiled_tail_stmt, funcs_tail) = compile_with_env tail_exp "result" env in
    let tail_tmp = generate_new_fname "tail_val" in

    let pair_ptr = generate_new_fname "pair_ptr" in

    let assign_head_tmp =
      (Exp (Assign (head_tmp, (Var "result", 0)), 0), 0)
    in

    let assign_tail_tmp =
      (Exp (Assign (tail_tmp, (Var "result", 0)), 0), 0)
    in

    let allocate_pair_ptr =
      (Exp (Assign (pair_ptr, (Malloc (Int 8, 0), 0)), 0), 0)
    in

    let store_head_to_pair =
      (Exp (Store ((Var pair_ptr, 0), (Var head_tmp, 0)), 0), 0)
    in

    let store_tail_to_pair =
      (Exp (
        Store (
          (Binop ((Var pair_ptr, 0), Plus, (Int 4, 0)), 0),
          (Var tail_tmp, 0)
        ), 0), 0)
    in

    let assign_result_to_pair =
      (Exp (Assign (result_var, (Var pair_ptr, 0)), 0), 0)
    in

    let pair_block =
      let inner = (Seq (allocate_pair_ptr,
                    (Seq (store_head_to_pair,
                      (Seq (store_tail_to_pair,
                        assign_result_to_pair), 0)
                    ), 0)
                  ), 0)
      in
      (Let (pair_ptr, (Int 0, 0), inner), 0)
    in

    let tail_block =
      let inner = (Seq (compiled_tail_stmt,
                    (Seq (assign_tail_tmp, pair_block), 0)
                  ), 0)
      in
      (Let (tail_tmp, (Int 0, 0), inner), 0)
    in

    let head_block =
      let inner = (Seq (compiled_head_stmt,
                    (Seq (assign_head_tmp, tail_block), 0)
                  ), 0)
      in
      (Let (head_tmp, (Int 0, 0), inner), 0)
    in

    (head_block, funcs_head @ funcs_tail)

  | _ ->
    failwith "cons expects 2 arguments"
          

and compile_fst (args : Scish_ast.exp list) (target_var : string) (env : environment) : (stmt * program) =
  match args with
  | [pair_exp] ->
    let (compiled_pair_stmt, compiled_funcs) = compile_with_env pair_exp "result" env in
    let extract_first_element =
      (Load (Var "result", 0), 0)
    in
    let assign_first_to_target =
      (Exp (Assign (target_var, extract_first_element), 0), 0)
    in
    let combined_stmt =
      (Seq (compiled_pair_stmt, assign_first_to_target), 0)
    in
    (combined_stmt, compiled_funcs)
  | _ -> failwith "fst expects 1 argument"
    

  and compile_snd (args : Scish_ast.exp list) (target_var : string) (env : environment) : (stmt * program) =
    match args with
    | [pair_expr] ->
      let (compiled_pair_stmt, compiled_funcs) = compile_with_env pair_expr "result" env in
      let extract_second_element =
        (Load (
          (Binop ((Var "result", 0), Plus, (Int 4, 0)), 0)
        ), 0)
      in
      let assign_second_to_target =
        (Exp (Assign (target_var, extract_second_element), 0), 0)
      in
      let combined_stmt =
        (Seq (compiled_pair_stmt, assign_second_to_target), 0)
      in
      (combined_stmt, compiled_funcs)
    | _ -> failwith "snd expects  1 argument"
  


let rec compile_exp (e:Scish_ast.exp) : Cish_ast.program =
  (* expression e, empty environment and a counter starting at 0  *)
  let (code, functions) = compile_with_env e "result" [] in 
  let main_execution : stmt =
    Seq(code, (Return((Var "result",0)),0)),0
  in

  (* intialize dynenv and result*)
  let main_environment_setup : Cish_ast.stmt =
   Let("dynenv", (Int 0,0), (Let("result", (Int 0,0),main_execution),0)),0
  in
  let main_func = Cish_ast.Fn {
      name = "main";
      args = [];
      body = main_environment_setup;
      pos = 0
    } in
  (* // construct final Cish program as list of functions, main function first, and then additional functions *)
  main_func :: functions 

