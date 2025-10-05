exception Implement_Me
exception FatalError
open Cfg

open Cfg_ast
open Spill

open Riscv

(************************************)

let reg_alloc blocks =
  (*initialize caller/callee saved *)
  let available_regs =  [R5;  R6;R7; R10;  R11; R12; R13; R14; R15; R16; R17;  R28; R29; R30; R31;R18; R19;R20; R21;   R22; R23;R24; R25; R26; R27] 
in  let available_count = List.length available_regs
   in

   (* simplify*)
   (* look for a node first that has degree less than the num of registers*)
   let simplify graph k =
     (*   nodes that can be colored *)
     let colorable_nodes = ref [] in
     (* mutable copy *)
     let working_graph = ref graph in
     
     (* do until can't find any more removable nodes *)
     let rec process_graph () =
       (*  degree < max_colors *)
       let candidate = 
         try 
           Some (List.find (fun (node_id, adjacent_nodes) -> 
             List.length adjacent_nodes < k
           ) !working_graph)
         with Not_found -> None
       in
       
       match candidate with
       | None -> 
           (* no more nodes to remove - return remaining graph and stack *)
           (!working_graph, !colorable_nodes)
           
       | Some (node_to_remove, _) ->
           (* add this node to our colorable stack *)
           colorable_nodes := node_to_remove :: !colorable_nodes;
           
           (* remove the node from the graph *)
           working_graph := List.filter 
             (fun (n, _) -> n <> node_to_remove) 
             !working_graph;
             
           (* remove this node from all adjacency lists *)
           working_graph := List.map 
             (fun (node, neighbors) -> 
               (node, List.filter 
                 (fun adj -> adj <> node_to_remove) 
                 neighbors)
             ) 
             !working_graph;
           process_graph ()
     in
          process_graph ()
   in
   
(* choose node to spill *)
(* prefer to spill nodes with high degree *)
let select_nodes_spill graph =
  if graph = [] then raise FatalError 
  else
    (* find the node with the highest degree *)
    let (spill_node, _) = List.fold_left (fun (max_node, max_degree) (node, neighbors) ->
        let degree = List.length neighbors in
if degree > max_degree then (node, degree) else (max_node, max_degree)) 
      (fst (List.hd graph), 0)  
      (* initialize with the first node and degree 0 *)
      graph in
    spill_node
  in

(*paint nodes in the graph *)
let assign_colors g s k available_colors =
  let cmap = ref [] in
  
  (*get neighbors or return an empty list *)
  let grab_neighbors n = 
    try List.assoc n g with Not_found -> []
  in
  
  (* get color of a node or return-1 *)
  let fetch_color n =
    try List.assoc n !cmap with Not_found -> -1
  in

  (* find unused color that isn't taken by neighbors *)
  let rec find_color nbs i =
    if i >= k then -1
    else if List.mem i (List.fold_left (fun acc nb -> 
      let c = fetch_color nb in
      if c >= 0 && not (List.mem c acc) then c :: acc else acc
    ) [] nbs) then find_color nbs (i + 1)
    else i
  in

  (* try to color each node from the stack *)
  List.iter (fun n ->
    let nbs = grab_neighbors n in
    let col = find_color nbs 0 in
    if col >= 0 then cmap := (n, col) :: !cmap
    else raise (Failure ("Could not color node " ^ n))
  ) s;

  !cmap
  in
  
(* map colors to registers *)
let map_colors_to_registers cmap =
  List.map (fun (v, c) ->
    if c < 0 || c >= List.length available_regs then
      failwith ("color index out of bounds for var: " ^ v)
    else
      let r = List.nth available_regs c in
      (v, r)
  ) cmap
    in
  (* step 9: map registers to blocks *)
let apply_register_allocation blks rmap =
  (* replace variable with register in instruction *)
  let swap_var_with_reg instr =
    let get_reg v = 
      try List.assoc v rmap with Not_found -> R0 
    in
    match instr with
    | Move(Var d, Var s) -> 
        let dr = get_reg d and sr = get_reg s in
        if dr = sr then Move(Reg R0, Reg R0) else Move(Reg dr, Reg sr)

    | Move(Var d, s) -> Move(Reg (get_reg d), s)
    | Move(d, Var s) -> Move(d, Reg (get_reg s))

    | Arith(Var d, Var s1, op, Var s2) -> 
        Arith(Reg (get_reg d), Reg (get_reg s1), op, Reg (get_reg s2))
    | Arith(Var d, Var s1, op, s2) -> 
        Arith(Reg (get_reg d), Reg (get_reg s1), op, s2)
    | Arith(Var d, s1, op, Var s2) -> 
        Arith(Reg (get_reg d), s1, op, Reg (get_reg s2))
    | Arith(Var d, s1, op, s2) -> 
        Arith(Reg (get_reg d), s1, op, s2)

    | Load(Var d, Var s, off) -> 
        Load(Reg (get_reg d), Reg (get_reg s), off)
    | Load(Var d, s, off) -> 
        Load(Reg (get_reg d), s, off)

    | Store(Var d, off, Var s) -> 
        Store(Reg (get_reg d), off, Reg (get_reg s))
    | Store(Var d, off, s) -> 
        Store(Reg (get_reg d), off, s)
    | Store(d, off, Var s) -> 
        Store(d, off, Reg (get_reg s))

    | Call(Var f, n) -> 
        Call(Reg (get_reg f), n)

    | If(Var s1, op, Var s2, l1, l2) -> 
        If(Reg (get_reg s1), op, Reg (get_reg s2), l1, l2)
    | If(Var s1, op, s2, l1, l2) -> 
        If(Reg (get_reg s1), op, s2, l1, l2)
    | If(s1, op, Var s2, l1, l2) -> 
        If(s1, op, Reg (get_reg s2), l1, l2)
    | _ -> instr
  in

  (* filter and map instructions *)
  List.map (fun blk ->
    blk 
    |> List.map swap_var_with_reg
      (* remove  instructions where a register moves to itself *)
    |> List.filter (function Move(Reg R0, Reg R0) -> false | _ -> true)
  ) blks
  in
  
(* main reg allocation algorithm *)
let rec allocate_registers blks =
  (* build interference graph from blocks *)
  let igraph = Cfg.build_interfere_graph blks in
  
  (* convert the graph to a list of (node, neighbors) *)
  let convert_graph g =
    let nodes = IUGraph.nodes g in
    (* fold over nodes to build a list of neighbors *)
    NodeSet.fold (fun n acc ->
      match n with
      | VarNode v ->
          let adj = IUGraph.adj n g in
          let var_nbs = 
            NodeSet.fold (fun x acc ->
              match x with
              | VarNode v -> v :: acc
              | _ -> acc
            ) adj []
          in
          (v, var_nbs) :: acc
      | _ -> acc
    ) nodes []
  in

  let graph = convert_graph igraph in
  (* simplify + get stack of nodes *)
  let (rem_graph, stack) = simplify graph available_count in
  
  (* handle remaining nodes after simplification *)
  if List.length rem_graph > 0 then begin
    let spill_var = select_nodes_spill rem_graph in
    let spilled_blks = 
      if spill_var = "" then blks
      else spill blks [spill_var]
    in
    allocate_registers spilled_blks
  end else begin
    let color_map = assign_colors graph stack available_count available_regs in
    let reg_map = map_colors_to_registers color_map in
    apply_register_allocation blks reg_map
  end
in

  
  allocate_registers blocks

(*

let reg_alloc blocks =
  exception FatalError

let process_fn fn =
  let curfblocks = (Cfg_ast.fn2blocks fn) in
  reg_alloc curfblocks

let compile prog =
  let blocks = List.flatten (List.map (fun fn -> process_fn fn) prog) in
  Cfg_compile.cfg_to_riscv blocks

*)


let process_fn fn =
  let curfblocks = (Cfg_ast.fn2blocks fn) in
  reg_alloc curfblocks

  (************************************)

(** This is the hook for your compiler. Please keep your
    implementation contained to this file, plus, optionally the file
    cfg.ml *)
let compile prog =
  let blocks = List.flatten (List.map (fun fn -> process_fn fn) prog) in
  Cfg_compile.cfg_to_riscv blocks

  (***********************************)

(**
   Here is a template for one strategy to get a basic implementation
   working, which would just require implementing reg_alloc to map
   temporaries to registers.

   For each function, it calls Cfg_ast.fn2blocks to convert it into a
   Cfg representation of basic blocks, then calls a register allocator
   to map temporaries to registers, and finally uses Cfg_compile to
   convert the Cfg blocks to RISC-V.

   But you don't have to use this approach!
*)


