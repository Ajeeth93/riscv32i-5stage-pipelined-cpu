# 5-Stage Pipelined RISC-V Processor (RV32I subset) — SystemVerilog

![SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-blue)
![Vivado](https://img.shields.io/badge/Tools-Vivado%20xsim-orange)
![UVM](https://img.shields.io/badge/Verification-UVM%201.2-green)
![Status](https://img.shields.io/badge/Processor%20test-PASSING-brightgreen)

A 32-bit, five-stage pipelined RISC-V processor (**Fetch → Decode → Execute → Memory → Writeback**) with full data forwarding, load-use stall detection and branch/jump flushing, written in synthesizable SystemVerilog. Based on the microarchitecture in *Digital Design and Computer Architecture: RISC-V Edition* (Harris & Harris), implemented, debugged and verified independently.

## Highlights

- **5-stage pipeline** with 4 pipeline registers and a dedicated hazard unit
- **Data forwarding** from the Memory and Writeback stages to both ALU operands, with Memory-stage priority
- **Load-use hazard detection** – 1-cycle stall plus bubble insertion
- **Control hazards** – static not-taken prediction; taken `beq`/`jal` flush 2 slots
- **Self-checking processor testbench** – verified program exercises every hazard type, prints register writes, stores and performance counters (cycles, CPI, stalls, flushes)
- **UVM testbench for the hazard unit** – 1,170 transactions, 0 mismatches, **99.21 % functional coverage**
- **Synthesized** for a Xilinx Zynq-7000 (xc7z010): **~80 MHz** post-synthesis estimate, **636 LUTs**, 0 DSP / 0 BRAM (see [Results](#results))
- **Two pipeline bugs found and fixed** through system-level testing (see [Debugging highlights](#debugging-highlights))

## Architecture

![Pipelined processor schematic](RTL%20Modules%20and%20Schematics/RISC-V%20Processor%20Schematics.jpg)

| Stage | Main blocks |
|---|---|
| Fetch | Program counter, PC+4 adder, instruction memory, next-PC mux |
| Decode | Controller (main + ALU decoder), register file (write on falling edge), immediate extension |
| Execute | Forwarding muxes, ALU, branch-target adder, branch decision (`PCSrcE`) |
| Memory | Data memory (64 × 32-bit) |
| Writeback | Result mux (ALU / load data / PC+4) |
| Hazard unit | Forwarding control, load-use stall, flush on taken branch / jump |

### Supported instructions

| Type | Instructions |
|---|---|
| R-type | `add`, `sub`, `and`, `or`, `slt` |
| I-type ALU | `addi`, `andi`, `ori`, `slti` |
| Load / Store | `lw`, `sw` |
| Branch / Jump | `beq`, `jal` |

### Hazard handling

| Hazard | Mechanism | Penalty |
|---|---|---|
| RAW, ALU result needed next instruction | Forward from Memory stage (`ForwardXE = 10`) | 0 cycles |
| RAW, result needed two instructions later | Forward from Writeback stage (`ForwardXE = 01`) | 0 cycles |
| RAW, result needed three instructions later | Register file writes on the falling edge, Decode reads the new value in the same cycle | 0 cycles |
| Load-use | Stall Fetch/Decode, flush Execute | 1 cycle |
| Taken `beq` / `jal` | Flush Decode and Execute | 2 cycles |

## Verification

### 1. Processor-level test (directed, self-checking)

The processor runs [`Test Bench/riscvtest.s`](Test%20Bench/riscvtest.s), a 21-instruction program that deliberately exercises every hazard path: Memory- and Writeback-stage forwarding, a load-use stall, a not-taken and a taken branch, and a `jal`. It passes when the program stores **25 to address 100**. Console output (condensed):

```
REGISTER WRITE: x2 <= 5        REGISTER WRITE: x7 <= 12
REGISTER WRITE: x3 <= 12       REGISTER WRITE: x7 <= 7
REGISTER WRITE: x7 <= 3        STORE: Address=96,  Data=7
REGISTER WRITE: x4 <= 7        REGISTER WRITE: x2 <= 7
REGISTER WRITE: x5 <= 4        REGISTER WRITE: x9 <= 18
REGISTER WRITE: x5 <= 11       REGISTER WRITE: x3 <= 68
REGISTER WRITE: x4 <= 0        REGISTER WRITE: x2 <= 25
REGISTER WRITE: x4 <= 1        STORE: Address=100, Data=25

              SIMULATION PASSED
Cycles 25 · Load-use stalls 1 · Taken branches/jumps 2 (4 flushed slots)
```

The testbench also fails immediately if the program file is not loaded, so a silent "all-`nop`" run cannot be mistaken for a pass.

![Processor waveform](Simulation%20%26%20Testing/RISC-V%20Processor%20Simulation.PNG)

*Waveform (90–230 ns): the taken `beq` raises `PCSrcE`, `FlushD` and `FlushE` (~115 ns); the `sw` to address 96 coincides with the load-use stall (`lwstall`, `StallF`, `StallD`, ~185 ns); the `jal` causes the second flush (~215 ns). Forwarding selects (`ForwardAE`/`ForwardBE`) and the architectural registers (`sp`, `gp`, `tp`, `t0`, `t2`, `s1`) are shown underneath. The `instruction`/`opcode`/`rd`/`rs1`/`rs2` fields are those of the instruction in **Decode**, one stage behind `PC`/`Instr` in Fetch.*

### 2. UVM verification of the hazard unit

A full UVM 1.2 environment (sequencer, driver, monitor, agent, scoreboard with an independent reference model, coverage collector) runs 17 directed scenarios and 1,000+ constrained-random transactions.

| Metric | Result |
|---|---|
| Transactions checked | 1,170 |
| Scoreboard mismatches | **0** |
| Functional coverage | **99.21 %** |
| UVM errors / fatals | 0 / 0 |

Details, test plan and coverage model: [UVM Verification/README.md](UVM%20Verification/README.md)

### 3. Unit tests

Directed testbenches and waveforms for the PC, PC+4 adder, ALU, decoders, control unit and hazard unit are in [`Simulation & Testing/`](Simulation%20%26%20Testing/).

## Results

**Synthesis** – Vivado 2023.2, Zynq-7000 `xc7z010clg400-1`, out-of-context, 100 MHz constraint:

| Metric | Value |
|---|---|
| Estimated Fmax | **~80 MHz** (WNS −2.48 ns at 10 ns, post-synthesis estimate) |
| LUTs | 636 (556 logic + 80 distributed RAM for data memory) |
| Flip-flops | 492 |
| BRAM / DSP | 0 / 0 |

> Resource numbers include the test program held in on-chip instruction ROM. Because that program only uses registers x2–x9, Vivado trims unused register-file entries, so these figures are a lower bound for the full core. Program-independent core-only numbers are on the roadmap.

**Critical path** (22 logic levels, 12.5 ns): `Rs2E` → forwarding mux → ALU subtraction (carry chain) → `Zero` → `PCSrcE` → next-PC mux → PC register. Branches are resolved in Execute using the ALU, so the branch decision and the PC update share one cycle. That is the main target for frequency improvement.

## Debugging highlights

System-level testing exposed two bugs that unit and UVM tests of individual blocks could not catch, because both come from how the blocks interact:

1. **Writeback-to-Decode hazard.** With a rising-edge register-file write, an instruction three positions after its producer read a stale value (`or x4, x7, x2` produced 3 instead of 7). The hazard unit only forwards into Execute, so this case is resolved by writing the register file on the falling edge.
2. **First instruction executed twice after reset.** Instructions fetched while reset was held flowed through the un-reset pipeline registers. Fixed by clearing the Fetch/Decode and Decode/Execute registers during reset (`clr = Flush | rst`).

## Repository structure

```
RTL Code/                     SystemVerilog source, one module per file
  RISC_V_Pipeline_Top.sv        top level (ports: clk, rst, PC, Instr, DataAdr, WriteData, MemWrite)
Test Bench/
  RISC-V_Processor_tb.sv        self-checking processor testbench with performance counters
  RISC-Vmem.txt                 program (hex) loaded into instruction memory
  riscvtest.s                   annotated assembly listing of the program
  wave.tcl                      grouped waveform view for Vivado
  HazardUnit_tb.sv              directed hazard-unit testbench
UVM Verification/             UVM environment for the hazard unit
Constraints/clock.xdc         100 MHz clock constraint
RTL Modules and Schematics/   block diagrams
Simulation & Testing/         waveforms
```

## Running it

### Processor simulation (Vivado)

1. Create an RTL project (part `xc7z010clg400-1`) outside this folder.
2. Add all files in `RTL Code/` as **design sources** and set `RISC_V_Pipeline_Top` as top.
3. Add `Test Bench/RISC-V_Processor_tb.sv` as a **simulation source** and set `testbench` as top.
4. Add the program as a design source and mark it as memory data (Tcl console; double braces because of the space in the path):
   ```tcl
   add_files -fileset sources_1 -norecurse {{<repo>/Test Bench/RISC-Vmem.txt}}
   set_property file_type {Memory Initialization Files} [get_files RISC-Vmem.txt]
   ```
5. Run Behavioral Simulation, then load the grouped waveform:
   ```tcl
   source {<repo>/Test Bench/wave.tcl}
   ```

### UVM testbench

```bash
cd "UVM Verification"
./run_xsim.sh          # 170 directed + 1000 random transactions
```

### Synthesis

1. Add `Constraints/clock.xdc` as a constraint.
2. Settings → Synthesis → More Options: `-mode out_of_context`
3. Run Synthesis → Open Synthesized Design → `report_utilization`, `report_timing_summary`.

## Roadmap

- [ ] Program-independent, post-route resource and timing numbers (core with external instruction port)
- [ ] Dedicated branch comparator to shorten the critical path
- [ ] Remaining RV32I instructions (`bne`, `blt`, `jalr`, `lui`, `auipc`, shifts, byte/half loads and stores)
- [ ] Longer benchmarks (sorting, loops) and `riscv-tests` for compliance and steady-state CPI
- [ ] ASIC implementation: RTL-to-GDSII with Cadence Genus, Innovus and Tempus

## Acknowledgments

Microarchitecture based on *Digital Design and Computer Architecture: RISC-V Edition* by Sarah L. Harris and David Money Harris.
