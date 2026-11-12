# 5-Stage Pipelined RISC-V Processor (RV32I subset) — SystemVerilog

![SystemVerilog](https://img.shields.io/badge/HDL-SystemVerilog-blue)
![Vivado](https://img.shields.io/badge/Tools-Vivado%20xsim-orange)
![UVM](https://img.shields.io/badge/Verification-UVM%201.2-green)
![Status](https://img.shields.io/badge/Processor%20test-PASSING-brightgreen)
![ASIC](https://img.shields.io/badge/ASIC-sky130%20signed%20off%20%4055.6%20MHz-blueviolet)
![Flow](https://img.shields.io/badge/Flow-LibreLane%20(Yosys%20%2B%20OpenROAD)-informational)

A 32-bit, five-stage pipelined RISC-V processor (**Fetch → Decode → Execute → Memory → Writeback**) with full data forwarding, load-use stall detection and branch/jump flushing, written in synthesizable SystemVerilog. Based on the microarchitecture in *Digital Design and Computer Architecture: RISC-V Edition* (Harris & Harris), implemented, debugged and verified independently, then taken from RTL to a **signed-off SkyWater 130 nm layout** with an open-source ASIC flow. A second round (v2) traced the critical path with static timing and SDF gate-level simulation, added a dedicated branch comparator and shrank the die: **55.6 MHz, 0.123 mm², verified down to gate level with real delays**.

## Highlights

- **5-stage pipeline** with 4 pipeline registers and a dedicated hazard unit
- **Data forwarding** from the Memory and Writeback stages to both ALU operands, with Memory-stage priority
- **Load-use hazard detection** – 1-cycle stall plus bubble insertion
- **Control hazards** – static not-taken prediction; taken `beq`/`jal` flush 2 slots
- **Self-checking processor testbench** – verified program exercises every hazard type, prints register writes, stores and performance counters (cycles, CPI, stalls, flushes)
- **UVM testbench for the hazard unit** – 1,170 transactions, 0 mismatches, **99.21 % functional coverage**
- **Synthesized** for a Xilinx Zynq-7000 (xc7z010): **~80 MHz** post-synthesis estimate, **636 LUTs**, 0 DSP / 0 BRAM, for the original (pre-comparator) RTL (see [Results](#results))
- **Two pipeline bugs found and fixed** through system-level testing (see [Debugging highlights](#debugging-highlights))
- **ASIC implementation in SkyWater 130 nm**: signed off at **55.6 MHz** with **0 setup / hold / slew / cap violations at 9 PVT corners**, DRC / LVS / antenna clean, **0.123 mm²**, 8,555 cells (see [ASIC implementation](#asic-implementation-skywater-130-nm), [interactive layout viewer](https://ajeeth93.github.io/riscv32i-5stage-pipelined-cpu/layout/))
- **Timing optimisation (v2)**: critical path traced with STA and SDF gate-level simulation; a dedicated branch comparator raised Fmax **+22 %** (45.7 → 55.6 MHz), and a utilization sweep cut die area **−42 %** while improving setup slack and power
- **Gate-level verification**: functional simulation of the routed netlist and **SDF-annotated timing simulation at the slowest and fastest corners** pass; static IR drop 1.4 mV (0.08 % of 1.8 V)

## ASIC implementation: SkyWater 130 nm

<table>
  <tr>
    <td align="center">
      <a href="https://ajeeth93.github.io/riscv32i-5stage-pipelined-cpu/layout/"><img src="docs/img/chip_innovus.png" width="400" alt="Metal routing view"></a><br>
      <b>Metal routing</b><br><sub>met1 blue · met2 red · met3 green · met4 yellow · met5 purple</sub>
    </td>
    <td align="center">
      <a href="https://ajeeth93.github.io/riscv32i-5stage-pipelined-cpu/layout/"><img src="docs/img/chip_all_layers.png" width="400" alt="All layers view"></a><br>
      <b>All layers</b><br><sub>diffusion, poly, contacts, li1, metals and vias</sub>
    </td>
  </tr>
</table>

**[Open the interactive layout viewer](https://ajeeth93.github.io/riscv32i-5stage-pipelined-cpu/layout/)**: zoom from the whole die down to single transistors, in a **Metal routing** view (met1 blue, met2 red, met3 green, met4 yellow, met5 purple) and an **All layers** view (diffusion, poly, contacts, li1, metals and vias).

The core was hardened with memory ports (instruction and data memories outside the block) and taken to a signed-off GDSII with the open-source **LibreLane 3.0** flow on the **sky130A** PDK, in two rounds:

| | v1 (Oct 2026) | v2 (Nov 2026) |
|---|---|---|
| Signed-off clock | 40 MHz | **55.6 MHz** |
| Die area | 0.211 mm² | **0.123 mm² (−42 %)** |
| Final utilization | 47 % | 80.6 % |
| Gate-level simulation | – | functional + SDF (ss, ff) PASS |

Full report, including constraints, configuration, per-corner timing, gate-level simulation, IR drop, the v2 optimisation and the v1 timing-closure story: **[asic/README.md](asic/README.md)**. Engineering log with predictions versus results: **[asic/V2_LOG.md](asic/V2_LOG.md)**.

```mermaid
flowchart TD
    RTL["RTL<br/>18 SystemVerilog files"] --> LINT["Lint<br/>Verilator: 5 expected warnings"]
    LINT --> SYN["Synthesis<br/>Yosys to sky130_fd_sc_hd"]
    SYN --> FP["Floorplan + power grid<br/>70 % core utilization, met4/met5 straps"]
    FP --> PL["Placement<br/>target density 75 %"]
    PL --> CTS["Clock tree synthesis<br/>TritonCTS"]
    CTS --> GRT["Global route<br/>+ post-route repair, 50 % slew/cap margins"]
    GRT --> DRT["Detailed route<br/>TritonRoute"]
    DRT --> RCX["Parasitic extraction<br/>OpenRCX"]
    RCX --> STA["Sign-off STA, 9 PVT corners<br/>setup +0.650 ns (ss) · hold +0.100 ns (ff)<br/>0 setup / hold / slew / cap violations"]
    RCX --> PV["Physical verification<br/>Magic + KLayout DRC · Netgen LVS · antenna<br/>all clean"]
    STA --> GDS["Signed-off GDSII<br/>55.6 MHz · 0.123 mm² · 8,555 cells"]
    PV --> GDS
    GDS --> GLS["Gate-level simulation<br/>functional (Icarus) · SDF at ss and ff (CVC)<br/>PASS"]
```

| Metric | Result |
|---|---|
| Toolchain | LibreLane 3.0.17: Verilator, Yosys, OpenROAD (TritonCTS, TritonRoute), OpenRCX, OpenSTA, Magic, KLayout, Netgen |
| PDK / cells | SkyWater sky130A / `sky130_fd_sc_hd` |
| Clock | 18 ns (**55.6 MHz**), signed off at 9 corners (nom / min / max × tt / ss / ff); v1: 25 ns, 40 MHz |
| Worst setup slack | **+0.650 ns** at `max_ss_100C_1v60` (v1: +3.13 ns at 40 MHz) |
| Worst hold slack | **+0.100 ns** at `max_ff_n40C_1v95` |
| Violations | **0** setup, hold, max slew and max cap at every corner |
| Physical verification | Magic + KLayout DRC clean, Netgen LVS match, antenna pass |
| Area | 122,580 µm² die (≈ 345 × 356 µm; v1 211,001 µm², −42 %), 89,187 µm² cells, 80.6 % utilization, 8,555 cells |
| Power | 12.32 mW at 55.6 MHz (vectorless estimate; v1 8.95 mW at 40 MHz) |
| Functional check | Original self-checking testbench passes on the ASIC core (25 cycles, CPI 1.316) |
| Gate-level simulation | Routed netlist: functional PASS (Icarus); SDF-annotated PASS at `max_ss` and `min_ff`, 0 timing-check violations (CVC) |
| IR drop | 1.4 mV worst static drop (0.08 % of 1.8 V), typical corner |

**Constraints and configuration.** 55.6 MHz (18 ns) clock with 0.25 ns setup and 0.10 ns hold uncertainty; inputs driven by `sky130_fd_sc_hd__buf_4`, 30 fF output load; 4 ns input/output delay budgets, with a 2.5 ns minimum input delay to cover the clock-tree insertion delay (~2.1 ns in v1). LibreLane runs with 70 % core utilization, 75 % placement density (chosen by a utilization sweep), post-global-route design and timing repair, and 50 % slew/cap repair margins. Files: [`asic/constraint.sdc`](asic/constraint.sdc), [`asic/config.json`](asic/config.json).

**Timing closure in short (v1).** The first full run at 20 ns failed setup by 1.29 ns at the slow corner, so the clock was relaxed to 25 ns. About 880 max-slew violations then remained at ss, on high-fanout register-file read-decode nets. Tightening `set_max_transition` and `set_max_fanout` made timing much worse (setup fell to −5 ns). The root cause was that the resizer repaired against optimistic estimated parasitics; adding post-global-route repair and 50 % slew/cap margins brought all violations to zero and raised setup slack from +1.59 to +3.13 ns. Run-by-run table: [asic/README.md](asic/README.md#timing-closure-v1).

**Timing optimisation in short (v2).** STA and SDF gate-level simulation both showed the critical path running forwarding → ALU subtract → 32-bit zero detect → branch decision → PC. Because the core only supports `beq`, a dedicated equality comparator on the forwarded operands replaced the ALU in the branch decision (+22 % Fmax), and a utilization sweep shrank the die by 42 %: signed off at **55.6 MHz**, 122,580 µm², 8,555 cells, with functional and SDF gate-level simulation passing. Details: [asic/README.md](asic/README.md#timing-optimisation-v2), [asic/V2_LOG.md](asic/V2_LOG.md).

**Signed-off GDSII:** [`asic/final/RISC_V_Pipeline_Top.gds.gz`](asic/final/)

## Architecture

![Pipelined processor schematic](RTL%20Modules%20and%20Schematics/RISC-V%20Processor%20Schematics.jpg)

| Stage | Main blocks |
|---|---|
| Fetch | Program counter, PC+4 adder, instruction memory, next-PC mux |
| Decode | Controller (main + ALU decoder), register file (write on falling edge), immediate extension |
| Execute | Forwarding muxes, ALU, branch-target adder, branch decision (`PCSrcE`); in the ASIC core (v2) a dedicated comparator decides `beq` |
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

### FPGA

**Synthesis** – Vivado 2023.2, Zynq-7000 `xc7z010clg400-1`, out-of-context, 100 MHz constraint:

| Metric | Value |
|---|---|
| Estimated Fmax | **~80 MHz** (WNS −2.48 ns at 10 ns, post-synthesis estimate) |
| LUTs | 636 (556 logic + 80 distributed RAM for data memory) |
| Flip-flops | 492 |
| BRAM / DSP | 0 / 0 |

> Resource numbers include the test program held in on-chip instruction ROM. Because that program only uses registers x2–x9, Vivado trims unused register-file entries, so these figures are a lower bound for the full core. Program-independent core-only numbers are on the roadmap.

**Critical path** (22 logic levels, 12.5 ns): `Rs2E` → forwarding mux → ALU subtraction (carry chain) → `Zero` → `PCSrcE` → next-PC mux → PC register. Branches are resolved in Execute using the ALU, so the branch decision and the PC update share one cycle. The ASIC v2 core shortens exactly this path with a dedicated branch comparator; the FPGA build in `RTL Code/` is still the original, pre-comparator design, so these FPGA numbers are for that version.

### ASIC (sky130)

55.6 MHz (v2), 0 violations at 9 PVT corners, DRC / LVS clean, 0.123 mm², 12.32 mW (vectorless estimate), gate-level simulation with SDF passing. See [ASIC implementation](#asic-implementation-skywater-130-nm) and [asic/README.md](asic/README.md). The same branch path (forwarding → ALU → zero-detect → branch decision) was also the critical path in silicon; v2 moved the branch decision to a dedicated comparator (+22 % Fmax).

## Debugging highlights

System-level testing exposed two bugs that unit and UVM tests of individual blocks could not catch, because both come from how the blocks interact:

1. **Writeback-to-Decode hazard.** With a rising-edge register-file write, an instruction three positions after its producer read a stale value (`or x4, x7, x2` produced 3 instead of 7). The hazard unit only forwards into Execute, so this case is resolved by writing the register file on the falling edge.
2. **First instruction executed twice after reset.** Instructions fetched while reset was held flowed through the un-reset pipeline registers. Fixed by clearing the Fetch/Decode and Decode/Execute registers during reset (`clr = Flush | rst`).

## Repository structure

```
RTL Code/                     SystemVerilog source, one module per file (FPGA version, pre-comparator)
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
asic/                         ASIC implementation (sky130, LibreLane) - see asic/README.md
  src/                          hardened core with memory ports and branch comparator
  sim/                          riscv_soc wrapper, memories, testbenches, gate-level simulation
    cvc/                          SDF gate-level simulation with CVC
  config.json, constraint.sdc   signed-off flow configuration and constraints (v2)
  sweep.sh, sta_rise.tcl        clock/utilization sweep, OpenSTA by capture edge
  V2_LOG.md                     v2 engineering log (prediction vs result for every step)
  final/                        signed-off GDSII (v2)
  *.lyp, *.py, open_layout.sh   KLayout colours, layout rendering, deep-zoom tiles
docs/                         GitHub Pages: interactive layout viewer (docs/layout/), images (docs/img/)
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

### ASIC flow (LibreLane)

```bash
python3 -m librelane --dockerized asic/config.json   # from the repository root
./asic/open_layout.sh                                # view the signed-off GDS in KLayout
```

Gate-level simulation of the routed netlist:

```bash
./asic/sim/run_gls.sh                                   # functional (Icarus)
./asic/sim/cvc/run_cvc.sh max_ss_100C_1v60 18 <run>     # SDF, slowest corner (CVC)
./asic/sim/cvc/run_cvc.sh min_ff_n40C_1v95 18 <run>     # SDF, fastest corner
```

Details: [asic/README.md](asic/README.md#reproducing-the-results)

### Synthesis

1. Add `Constraints/clock.xdc` as a constraint.
2. Settings → Synthesis → More Options: `-mode out_of_context`
3. Run Synthesis → Open Synthesized Design → `report_utilization`, `report_timing_summary`.

## Roadmap

- [ ] Program-independent, post-route resource and timing numbers (core with external instruction port)
- [x] Dedicated branch comparator to shorten the critical path (ASIC core, v2: +22 % Fmax)
- [ ] Port the branch comparator to the FPGA version in `RTL Code/` and re-run synthesis
- [ ] Remaining RV32I instructions (`bne`, `blt`, `jalr`, `lui`, `auipc`, shifts, byte/half loads and stores)
- [ ] Longer benchmarks (sorting, loops) and `riscv-tests` for compliance and steady-state CPI
- [x] ASIC implementation: RTL-to-GDSII in sky130 with LibreLane, signed off at 55.6 MHz in v2 ([asic/README.md](asic/README.md))
- [x] ASIC v2: gate-level simulation (functional + SDF), IR-drop analysis, branch comparator (55.6 MHz), utilization sweep ([asic/V2_LOG.md](asic/V2_LOG.md))
- [ ] Clock gating and workload-based power (planned for the CPU + cache project)
- [ ] Integration with the [direct-mapped write-back cache](https://github.com/Ajeeth93/direct-mapped-writeback-cache) and SRAM macros
- [ ] Same RTL through the Cadence flow (Genus, Innovus, Tempus) for a tool comparison

## Acknowledgments

Microarchitecture based on *Digital Design and Computer Architecture: RISC-V Edition* by Sarah L. Harris and David Money Harris.
