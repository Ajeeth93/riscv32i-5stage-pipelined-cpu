# UVM Verification – Hazard Unit

A constrained-random **UVM** testbench (SystemVerilog) that verifies the pipeline
hazard unit of the 5-stage RV32I processor: **operand forwarding**, **load-use
stalls** and **branch flushes**. The DUT is [`RTL Code/HazardUnit.sv`](../RTL%20Code/HazardUnit.sv).

**Skills shown:** UVM 1.2 · SystemVerilog OOP · constrained-random stimulus ·
directed sequences · self-checking scoreboard with a reference model ·
functional coverage (coverpoints + crosses) · Vivado xsim

**Result:** ✅ PASSED · 1,170 transactions checked · 0 scoreboard mismatches ·
**99.21 % functional coverage** · 0 UVM errors / fatals ([full log](hazard_sim.log))

## Testbench architecture

```
                         hazard_test
                              │
                          hazard_env
       ┌──────────────────────┼───────────────────────┐
       │                      │                       │
  hazard_agent        hazard_scoreboard        hazard_coverage
 ┌─────┴──────┬───────────┐   ▲  (reference model)    ▲ (covergroup)
 sequencer  driver    monitor │                       │
     ▲        │          │    └──── analysis port ────┘
     │        ▼          │
 sequences  hazard_if ◄──┘
 (directed      │
  + random)     ▼
     RISC_V_Pipeline_HazardUnit (DUT)
```

| Component | File | What it does |
|---|---|---|
| `hazard_item` | `hazard_pkg.sv` | Transaction with all 11 hazard-unit inputs, constraints biased toward x0–x7 so hazards actually occur, and a `scenario` field that selects a directed case |
| `hazard_directed_seq` | `hazard_pkg.sv` | Runs the 17 directed scenarios below, 10 randomized items each |
| `hazard_rand_seq` | `hazard_pkg.sv` | Unconstrained-scenario random stimulus (default 1000 items, `+NUM_RAND=N`) |
| `hazard_driver` | `hazard_pkg.sv` | Drives inputs on the clock's rising edge |
| `hazard_monitor` | `hazard_pkg.sv` | Samples inputs and outputs on the falling edge and broadcasts them |
| `hazard_scoreboard` | `hazard_pkg.sv` | Independent reference model; checks all 7 outputs with `!==` so X/Z is caught |
| `hazard_coverage` | `hazard_pkg.sv` | Covergroup over forwarding sources, stall/flush, priority and x0 corner cases, plus crosses |
| `hazard_if` | `hazard_if.sv` | Interface between the UVM components and the DUT |
| `tb_top` | `tb_top.sv` | Top module: clock, DUT instance, `run_test()` |

The hazard unit is purely combinational; the clock only paces the testbench
(drive on posedge, sample on negedge).

## Directed scenarios

| # | Scenario | # | Scenario |
|---|---|---|---|
| 1 | No hazard | 10 | ForwardBE: x0 never forwarded |
| 2 | ForwardAE from MEM (`10`) | 11 | Both operands forwarded |
| 3 | ForwardAE from WB (`01`) | 12 | Load-use stall on Rs1D |
| 4 | ForwardAE priority: MEM beats WB | 13 | Load-use stall on Rs2D |
| 5 | ForwardAE match but RegWrite=0 | 14 | Load in EX, no dependency (no stall) |
| 6 | ForwardAE: x0 never forwarded | 15 | Non-load with matching Rd (no stall) |
| 7 | ForwardBE from MEM (`10`) | 16 | Branch taken flush |
| 8 | ForwardBE from WB (`01`) | 17 | Branch taken + load-use stall |
| 9 | ForwardBE priority: MEM beats WB | | |

## Functional coverage

- `ForwardAE` / `ForwardBE`: none, from WB, from MEM, and their **cross**
- `lwstall`, `FlushD`, `FlushE`, `ResultSrcE` values
- Corner cases: MEM-over-WB priority (A and B), x0 never forwarded (A and B),
  stall caused by Rs1D vs Rs2D
- Cross of load-use stall × branch flush

## Running it (Vivado xsim)

```bash
cd "UVM Verification"
./run_xsim.sh          # 170 directed + 1000 random transactions
./run_xsim.sh 5000     # 170 directed + 5000 random transactions
```

At the end of the log the test prints a summary with the number of transactions
checked, scoreboard mismatches, functional coverage and PASS/FAIL.

## Results

Vivado 2026.1 xsim, UVM 1.2, default run (170 directed + 1000 random transactions):

```
  ======================================================
    RISC-V RV32I Hazard Unit : UVM Verification Summary
  ======================================================
    Test                  : hazard_test
    Directed scenarios    : 17 (x10 each)
    Random transactions   : 1000
    Transactions checked  : 1170
    Scoreboard mismatches : 0
    Functional coverage   : 99.21 %
    UVM errors / fatals   : 0 / 0
  ------------------------------------------------------
    RESULT                : PASSED
  ======================================================
```

The complete simulation output, including the printed UVM topology and every
directed scenario, is in [`hazard_sim.log`](hazard_sim.log).

### Waveform

Random phase of the test (≈10.9–11.05 µs). Branch-taken cycles (`PCSrcE`=1)
assert `FlushD` and `FlushE` together, and near the end `ForwardBE` switches to
`10` when `Rs2E` = `RdM` = x8 with `RegWriteM` = 1 (forward from MEM).

![Hazard unit UVM waveform](../Simulation%20%26%20Testing/HazardUnit_UVM.PNG)
