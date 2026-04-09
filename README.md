# RV32I CPU

A single-cycle 32-bit RV32I CPU written in SystemVerilog. The design implements the base RV32I instruction set and is verified using self-checking testbenches for both individual modules and full-program execution.

## Features
- Single-cycle RV32I processor
- SystemVerilog RTL implementation
- Self-checking testbenches for core modules and top-level integration
- Simulation workflow using Icarus Verilog and Make

## Repository Structure
- `src/` — CPU RTL modules
- `tb/` — self-checking testbenches
- `isa/` — RV32I instruction set references
- `Makefile` — build and simulation commands
- `docs/` - some theory on comp arch from scratch (in progress)
