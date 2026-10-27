`timescale 1ns / 1ps
// ============================================================================
// Testbench for RISC_V_Pipeline_Top
//
// Only the signals worth looking at are declared here, so Vivado's waveform
// window starts clean instead of listing every internal wire:
//   Top level   : clk, rst, PC, Instr, instruction_ascii
//   Instruction : fields of the instruction in the Decode stage
//   Core        : hazard unit, branch, ALU result, write-back, store bus
//   Registers   : architectural registers by ABI name
// Internal signals are read through hierarchical references (dut.xxx).
// Run "source wave.tcl" in the Tcl console for the grouped view.
//
// Program: RISC-Vmem.txt (see riscvtest.s). PASS = store of 25 to address 100.
// ============================================================================

module testbench;

    localparam int CLK_PERIOD = 10;    // 100 MHz
    localparam int MAX_CYCLES = 100;   // timeout

    // ------------------------------------------------------------ Top level
    logic        clk;
    logic        rst;
    logic [31:0] PC;          // fetch address
    logic [31:0] Instr;       // fetched instruction
    logic [31:0] DataAdr;     // data memory address
    logic [31:0] WriteData;   // store data
    logic        MemWrite;    // store enable

    RISC_V_Pipeline_Top dut (
        .clk       (clk),
        .rst       (rst),
        .PC        (PC),
        .Instr     (Instr),
        .DataAdr   (DataAdr),
        .WriteData (WriteData),
        .MemWrite  (MemWrite)
    );

    // ---------------------------------------- Instruction (Decode stage)
    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] imm;

    assign instruction = dut.InstrD;
    assign opcode      = dut.InstrD[6:0];
    assign rd          = dut.InstrD[11:7];
    assign funct3      = dut.InstrD[14:12];
    assign rs1         = dut.InstrD[19:15];
    assign rs2         = dut.InstrD[24:20];
    assign funct7      = dut.InstrD[31:25];
    assign imm         = dut.ImmExtD;

    logic [8*8-1:0] instruction_ascii;   // radix ASCII in the waveform

    always_comb begin
        case (opcode)
            7'b0000011: instruction_ascii = (funct3 == 3'b010) ? "lw" : "load?";
            7'b0100011: instruction_ascii = (funct3 == 3'b010) ? "sw" : "store?";
            7'b0110011:
                case (funct3)
                    3'b000:  instruction_ascii = funct7[5] ? "sub" : "add";
                    3'b010:  instruction_ascii = "slt";
                    3'b110:  instruction_ascii = "or";
                    3'b111:  instruction_ascii = "and";
                    default: instruction_ascii = "r-type?";
                endcase
            7'b0010011:
                if (instruction == 32'h0000_0013)
                    instruction_ascii = "nop";        // also flush bubbles
                else
                    case (funct3)
                        3'b000:  instruction_ascii = "addi";
                        3'b010:  instruction_ascii = "slti";
                        3'b110:  instruction_ascii = "ori";
                        3'b111:  instruction_ascii = "andi";
                        default: instruction_ascii = "i-type?";
                    endcase
            7'b1100011: instruction_ascii = (funct3 == 3'b000) ? "beq" : "branch?";
            7'b1101111: instruction_ascii = "jal";
            default:    instruction_ascii = "unknown";
        endcase
    end

    // ---------------------------------------------------------------- Core
    // Hazard unit
    logic        StallF, StallD, FlushD, FlushE, lwstall;
    logic [1:0]  ForwardAE, ForwardBE;
    // Execute
    logic        PCSrcE;          // branch / jump taken
    logic [31:0] ALUResultE;
    // Write-back (value being written into the register file)
    logic        RegWriteW;
    logic [4:0]  RdW;
    logic [31:0] ResultW;

    assign StallF     = dut.StallF;
    assign StallD     = dut.StallD;
    assign FlushD     = dut.FlushD;
    assign FlushE     = dut.FlushE;
    assign lwstall    = dut.lwstall;
    assign ForwardAE  = dut.ForwardAE;
    assign ForwardBE  = dut.ForwardBE;
    assign PCSrcE     = dut.PCSrcE;
    assign ALUResultE = dut.ALUResultE;
    assign RegWriteW  = dut.RegWriteW;
    assign RdW        = dut.RdW;
    assign ResultW    = dut.ResultW;

    // ----------------------------------------------------------- Registers
    logic [31:0] ra, sp, gp, tp, t0, t1, t2, s0, s1;

    assign ra = dut.u_rf.RegFile[1];
    assign sp = dut.u_rf.RegFile[2];
    assign gp = dut.u_rf.RegFile[3];
    assign tp = dut.u_rf.RegFile[4];
    assign t0 = dut.u_rf.RegFile[5];
    assign t1 = dut.u_rf.RegFile[6];
    assign t2 = dut.u_rf.RegFile[7];
    assign s0 = dut.u_rf.RegFile[8];
    assign s1 = dut.u_rf.RegFile[9];

    // ------------------------------------------------------ Clock / reset
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        #22;               // hold reset for two clock cycles
        rst = 1'b0;
    end

    // Fail immediately if the program was not loaded (memory left as nops)
    initial begin
        #1;
        if (dut.InstrF === 32'h0000_0013)
            $fatal(1, "RISC-Vmem.txt not loaded - add it as a simulation source and relaunch");
    end

    // ------------------------------------------------ Performance counters
    // An instruction is counted as issued when it moves from Decode to Execute without
    // being flushed; flush bubbles are nops (0x00000013) and are not counted.
    int cycles, instret, lw_stalls, taken_ctrl;

    initial begin
        cycles = 0; instret = 0; lw_stalls = 0; taken_ctrl = 0;
    end

    always @(posedge clk) begin
        if (!rst) begin
            cycles++;
            if (!dut.FlushE && dut.InstrD !== 32'h0000_0013 && !$isunknown(dut.InstrD))
                instret++;
            if (dut.lwstall) lw_stalls++;
            if (dut.PCSrcE)  taken_ctrl++;
            if (cycles >= MAX_CYCLES) begin
                $display("");
                $display("==============================================");
                $display("            SIMULATION TIMEOUT");
                $display("==============================================");
                $display("Expected store was not detected after %0d cycles.", MAX_CYCLES);
                report_performance();
                $finish;
            end
        end
    end

    function automatic void report_performance();
        $display("------------------ Performance ---------------");
        $display("Cycles                : %0d", cycles);
        $display("Instructions issued   : %0d", instret);
        if (instret > 0)
            $display("CPI                   : %0.3f", real'(cycles) / real'(instret));
        $display("Load-use stall cycles : %0d", lw_stalls);
        $display("Taken branches/jumps  : %0d (%0d flushed slots)", taken_ctrl, 2 * taken_ctrl);
        $display("==============================================");
        $display("");
    endfunction

    // --------------------------------------------------- Console monitors
    always @(negedge clk) begin
        if (!rst && RegWriteW && (RdW != 5'd0))
            $display("[%0t] REGISTER WRITE: x%0d <= %0d (0x%08h)", $time, RdW, ResultW, ResultW);
        if (!rst && MemWrite)
            $display("[%0t] STORE: Address=%0d (0x%08h), Data=%0d (0x%08h)",
                     $time, DataAdr, DataAdr, WriteData, WriteData);
    end

    // -------------------------------------------------------- PASS check
    // Change these values if your program has a different expected result.
    always @(negedge clk) begin
        if (MemWrite && (DataAdr == 32'd100) && (WriteData == 32'd25)) begin
            $display("");
            $display("==============================================");
            $display("              SIMULATION PASSED");
            $display("==============================================");
            $display("Memory Address : %0d", DataAdr);
            $display("Memory Data    : %0d", WriteData);
            $display("Simulation Time: %0t", $time);
            report_performance();
            #10;
            $finish;
        end
    end

endmodule
