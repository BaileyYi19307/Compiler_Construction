open Cfg_ast
exception Implement_Me
exception FatalError


type igraph_node = RegNode of Riscv.reg | VarNode of var

let string_of_node (n: igraph_node) : string =
  match n with
  | RegNode r -> "$" ^ Riscv.reg2string r
  | VarNode v -> v
;;

module IGraphNode =
  struct
    type t = igraph_node
    let compare = compare
  end

module NodeSet = Set.Make(IGraphNode)                                                   

(* These are the registers that must be generated / killed as part of
   liveness analysis for call instructions to reflect RISC-V calling
   conventions *)

(* Note that for call_gen_list, if the number of arguments n in the
   call is less than 8, then only the first n of these are actually
   used *)
let call_gen_list = ["x10";"x11";"x12";"x13";"x14";"x15";"x16";"x17";]
let call_kill_list = ["x1";"x5";"x6";"x7";"x10";"x11";"x12";"x13";"x14";"x15";"x16";"x17";"x28";"x29";"x30";"x31"]

(* Undirected graphs where nodes are identified by igraph_node type above. Look at
   graph.ml for the interface description.  *)

module IUGraph = Graph.UndirectedGraph(IGraphNode)

(* this is a wrapper to addEdge that prevents adding self edges.
   to do all sorts of other complicated stuff for eg coloring *)
let specialAddEdge u v g =
  if (u = v) then
    g
  else
    IUGraph.addEdge u v g

(* An interference graph is an SUGraph where a node is temp variable
   or a register (to be able to handle pre-colored nodes)

   The adjacency set of variable x should be the set of variables
   y such that x and y are live at the same point in time. *)
type interfere_graph = IUGraph.graph

(* To help you printing an igraph for debugging *)
let string_of_igraph (g: interfere_graph) : string =
  let rec string_of_row (n: IUGraph.node) =
    let ns = IUGraph.adj n g in
    Printf.sprintf "  %s\t: {%s}"
      (string_of_node n)
      (String.concat "," (List.map string_of_node (NodeSet.elements ns)))
  in
  let rows = String.concat "\n" (List.map string_of_row (NodeSet.elements (IUGraph.nodes g))) in
  Printf.sprintf "{\n%s\n}\n" rows


(*******************************************************************)
(* PS7 TODO:  interference graph construction *)

(* given a function (i.e., list of basic blocks), construct the
 * interference graph for that function.  This will require that
 * you build a dataflow analysis for calculating what set of variables
 * are live-in and live-out for each program point. *)

 let build_interfere_graph (f : func) : interfere_graph = 
  (* flatten blocks into instruction list *)
  let instructions =
    f |> List.concat |> List.mapi (fun i instr -> (i, instr))
  in

  (* create map from labels-->instruction index *)
  let label_indices =
    Hashtbl.create 16
  in
  List.iter (fun (i, instr) ->
    match instr with
    | Label name -> Hashtbl.add label_indices name i
    | _ -> ()
  ) instructions;


  (* get list of successors *)
  let get_successors (idx : int) (instr : inst) : int list =
    match instr with
    | Jump l -> (
        match Hashtbl.find_opt label_indices l with
        | Some target -> [target]
        | None -> []
      )
    | If (_, _, _, l1, l2) ->
        [Hashtbl.find_opt label_indices l1; Hashtbl.find_opt label_indices l2]
        |> List.filter_map Fun.id
    | Return -> []
    | _ ->
        if idx + 1 < List.length instructions then [idx + 1] else []
    in  

  (*convert operand to graph node*)
  let to_graph_node operand =
    match operand with
    | Var v -> VarNode v
    | Reg r -> RegNode r
    | _ -> raise FatalError
  in

  let used_defs_sets instr =
    let node_set_of = function
      | Var v -> NodeSet.singleton (VarNode v)
      | Reg r -> NodeSet.singleton (RegNode r)
      | _ -> NodeSet.empty
    in
  
    try
      match instr with
      | Move (dst, src) ->
          node_set_of src, NodeSet.singleton (to_graph_node dst)
  
      | Arith (dst, lhs, _, rhs) ->
          let uses = NodeSet.union (node_set_of lhs) (node_set_of rhs) in
          uses, NodeSet.singleton (to_graph_node dst)
  
      | Load (dst, addr, _) ->
          node_set_of addr, NodeSet.singleton (to_graph_node dst)
  
      | Store (addr, _, value) ->
          NodeSet.union (node_set_of addr) (node_set_of value), NodeSet.empty
  
      | Call (dst, n_args) ->
          let arg_regs =
            if n_args <= List.length call_gen_list then
              List.filteri (fun i _ -> i < n_args) call_gen_list
            else
              call_gen_list
          in
          let uses =
            arg_regs
            |> List.map (fun r -> RegNode (Riscv.string2reg r))
            |> NodeSet.of_list
          in
          let defs =
            let killed =
              call_kill_list
              |> List.map (fun r -> RegNode (Riscv.string2reg r))
              |> NodeSet.of_list
            in
            match dst with
            | Var v -> NodeSet.add (VarNode v) killed
            | Reg r -> NodeSet.add (RegNode r) killed
            | _ -> killed
          in
          uses, defs
  
      | If (a, _, b, _, _) ->
          NodeSet.union (node_set_of a) (node_set_of b), NodeSet.empty
  
      | Jump _ | Label _ | Return ->
          NodeSet.empty, NodeSet.empty
  
    with _ ->
      NodeSet.empty, NodeSet.empty
    in
  
  let compute_liveness_maps
      (instructions : (int * inst) list)
      ~(successors_of : int -> inst -> int list)
      ~(defs_and_uses : inst -> NodeSet.t * NodeSet.t)
    : (int, NodeSet.t) Hashtbl.t * (int, NodeSet.t) Hashtbl.t =

    let in_map = Hashtbl.create 32 in
    let out_map = Hashtbl.create 32 in

    List.iter (fun (idx, _) ->
      Hashtbl.add in_map idx NodeSet.empty;
      Hashtbl.add out_map idx NodeSet.empty
    ) instructions;

    let has_changed = ref true in
    while !has_changed do
      has_changed := false;

      List.iter (fun (idx, instr) ->
        let uses, defs = defs_and_uses instr in
        let succs = successors_of idx instr in

        let out_new =
          List.fold_left (fun acc s ->
            match Hashtbl.find_opt in_map s with
            | Some s_in -> NodeSet.union acc s_in
            | None -> acc
          ) NodeSet.empty succs
        in

        let in_new = NodeSet.union uses (NodeSet.diff out_new defs) in
        let in_old = Hashtbl.find in_map idx in
        let out_old = Hashtbl.find out_map idx in

        if not (NodeSet.equal in_new in_old && NodeSet.equal out_new out_old) then begin
          has_changed := true;
          Hashtbl.replace in_map idx in_new;
          Hashtbl.replace out_map idx out_new;
        end
      ) instructions
    done;

    in_map, out_map
  in

  let in_map, out_map =
    compute_liveness_maps
      instructions
      ~successors_of:get_successors
      ~defs_and_uses:used_defs_sets
  in

  let g =
    List.fold_left (fun graph (idx, instr) ->
      let _, defs = used_defs_sets instr in
      let live_out = Hashtbl.find out_map idx in

      NodeSet.fold (fun d acc ->
        NodeSet.fold (fun l acc2 -> specialAddEdge d l acc2) live_out acc
      ) defs graph
    ) IUGraph.empty instructions
  in

  g