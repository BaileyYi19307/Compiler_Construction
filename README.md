````markdown
# Compiler Construction Assignments (PS3–PS7 and Mini-Project)

A collection of compiler construction projects developed for CSCI 2130.  
Each stage builds upon the previous one, extending from simple code generation to type inference, dataflow analysis, and performance optimization targeting RISC-V.

## Overview

| Project | Description |
|----------|--------------|
| **PS3** | Compiles **Fish → RISC-V** (basic code generation; result in `a0`, ends with `jr ra`) |
| **PS4** | Compiles **Cish → RISC-V** (adds functions, calls, and local variables with stack frames) |
| **PS5** | Compiles **Scish → Cish** (introduces closures and first-class functions) |
| **PS6** | Compiles **MLish → Scish** (adds type inference and functional language features) |
| **PS7** | **Liveness and Interference Analysis** (dataflow analysis over a control-flow graph) |
| **Mini-Project** | Optimizing **Cish → RISC-V** compiler with a focus on runtime performance using gem5 |

**Target ISA:** RISC-V (RV32)  
**Language:** OCaml  

---

## Setup

Requirements:
- OCaml and opam  
- Docker (for the RISC-V toolchain and emulators)  

Install dependencies once:
```bash
opam install ppx_deriving ppx_sexp_conv sexp
````

Each subproject builds independently with `make`.

---

## Running the Compilers

### PS3 — Fish → RISC-V

```bash
make
./ps3 sexp tests/01cexpr_01add.sexp > tmp.s       # or: ./ps3 src file.fish
sh ./docker-gcc.sh tmp.s
sh ./docker-qemu.sh a.out     # or: sh ./docker-temu.sh a.out
echo $?                       # prints return value
```

### PS4 — Cish → RISC-V

```bash
make
./ps4 tests/01cexpr_01add.cish > tmp.s
sh ./docker-gcc.sh tmp.s
sh ./docker-temu.sh a.out
```

### PS5 — Scish → Cish

```bash
make
./ps5_scish samples/example_input.scish | ./ps5_cish
```

### PS6 — MLish → Scish

```bash
make
./ps6_mlish typecheck tests/test5.ml
./ps6_mlish compile tests/test5.ml
```

### PS7 — Liveness and Interference Graph

```bash
make
./ps7_cfg tests/01cexpr_01add.cish
./ps7_cfg tests/01cexpr_01add.cish true   # omit callee-saved handling
```

### Mini-Project — Optimizing Cish → RISC-V

```bash
make
./proj bench/01cexpr_01add.cish tmp.s
sh ./docker-gcc.sh tmp.s -o a.out
sh ./docker-gem5.sh a.out      # prints gem5 ticks; see stats.txt
```

---

## Implementation Highlights

| Project          | Core Work                                                                                                       |
| ---------------- | --------------------------------------------------------------------------------------------------------------- |
| **PS3**          | Implemented `compile.ml` to translate AST to RISC-V assembly                                                    |
| **PS4**          | Extended `compile.ml` to support stack frames, function calls, and local variables                              |
| **PS5**          | Implemented closure-based translation (`scish_compile.ml`) for higher-order functions                           |
| **PS6**          | Built a type inference engine (`mlish_type_check.ml`) and compiler to Scish (`mlish_compile.ml`)                |
| **PS7**          | Implemented `cfg.ml` for liveness analysis and interference graph generation                                    |
| **Mini-Project** | Developed an optimized Cish → RISC-V compiler focusing on register allocation and reduced memory access latency |

---

## Notes

* The compilers target 32-bit RISC-V assembly (`RV32`).
* QEMU or TEMU (via Docker) emulates RISC-V programs locally.
* The gem5 simulator measures execution performance for optimization experiments.
* Each compiler produces working assembly that can be assembled and executed end-to-end.

---

## Example Workflow

Compile and run a simple program (Cish example):

```bash
./ps4 tests/10fun_01call.cish > tmp.s
sh ./docker-gcc.sh tmp.s
sh ./docker-temu.sh a.out
echo $?
```

Benchmark the optimized compiler (mini-project):

```bash
./proj bench/10fun_01call.cish tmp.s
sh ./docker-gcc.sh tmp.s -o a.out
sh ./docker-gem5.sh a.out
```

---

## Project Context

Developed as part of **CSCI 2130 — Compiler Construction**.
Implements a full multi-stage compiler pipeline in OCaml, including lexical analysis, parsing, code generation, type inference, and dataflow analysis for register allocation and optimization.

```
```
