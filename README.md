# RISC-V Processor Project

This project is a RISC-V RV32I processor from the book *Digital Design and Computer Architecture RISC-V Edition* by Sarah L. Harris and David Money Harris, designed and implemented in SystemVerilog. It was built to gain practical experience with computer architecture, pipelining, and processor performance.

## Overview

The processor uses a **five-stage pipeline** and includes features such as **hazard detection, data forwarding, and branch prediction**. The project focuses on understanding how a processor works at the RTL level while keeping the design modular and easy to understand.

It serves as both a learning platform and a demonstration of practical digital design.

## Repository Structure

- **`RTL Code/`** – SystemVerilog source files for the processor.
- **`RTL Modules and Schematics/`** – Schematics for individual components and the complete pipelined processor.
- **`Test Bench/`** – Directed SystemVerilog testbenches for the hazard unit and the full processor.
- **`UVM Verification/`** – UVM testbench for the hazard unit (constrained-random stimulus, scoreboard, functional coverage).
- **`Simulation & Testing/`** – Simulation waveforms for key components and the complete CPU.
- **`README.md`** – Repository overview.

## Verification

The design is verified at two levels:

- **Directed testbenches** (`Test Bench/`) for the hazard unit and the full pipelined processor, checked through waveform analysis (`Simulation & Testing/`).
- **UVM testbench for the hazard unit** (`UVM Verification/`): a full UVM environment (sequencer, driver, monitor, agent, scoreboard, coverage collector) that runs 17 directed scenarios and 1000+ constrained-random transactions. A self-checking scoreboard compares every output against an independent reference model, and a covergroup measures forwarding paths, MEM-over-WB priority, x0 handling, load-use stalls and branch flushes. Result: **PASSED with 0 mismatches over 1,170 transactions and 99.21 % functional coverage**. See the [UVM Verification README](UVM%20Verification/README.md) for the architecture, test plan and how to run it.

## Goals

- Build a **modular and easy-to-understand RISC-V processor**.
- Focus on **correct and reliable RTL design**.
- Use **simulation and waveform analysis** to test and debug the processor.
- Verify critical blocks with **UVM** (constrained-random stimulus, scoreboarding and functional coverage).
- Gain hands-on experience with **pipelining, hazards, forwarding, and branch prediction**.
- Continuously improve the processor's **design and performance**.
