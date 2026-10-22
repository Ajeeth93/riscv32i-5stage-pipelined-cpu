// ============================================================================
// RISC-V RV32I (subset) 5-stage pipelined processor - top module
//
// Ports are the processor's external view only:
//   PC / Instr                    : instruction fetch
//   DataAdr / WriteData / MemWrite: data memory store
// These outputs also stop synthesis from optimising the core away.
// Internal signals are observed from the testbench, not exported here.
// ============================================================================

module RISC_V_Pipeline_Top (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] PC,         // address of the instruction being fetched
    output logic [31:0] Instr,      // fetched instruction
    output logic [31:0] DataAdr,    // data memory address
    output logic [31:0] WriteData,  // data being stored
    output logic        MemWrite    // store enable
);

    // ------------------------------------------------------------ Fetch (F)
    logic [31:0] PCF, PC_next, PCPlus4F, InstrF;

    // ----------------------------------------------------------- Decode (D)
    logic [31:0] InstrD, PCD, PCPlus4D, RD1D, RD2D, ImmExtD;
    logic [4:0]  Rs1D, Rs2D, RdD;
    logic        RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD;
    logic [1:0]  ResultSrcD, ImmSrcD;
    logic [2:0]  ALUControlD;

    // ---------------------------------------------------------- Execute (E)
    logic [31:0] RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
    logic [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE, PCTargetE;
    logic [4:0]  Rs1E, Rs2E, RdE;
    logic        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, ZeroE, PCSrcE;
    logic [1:0]  ResultSrcE;
    logic [2:0]  ALUControlE;

    // ----------------------------------------------------------- Memory (M)
    logic [31:0] ALUResultM, WriteDataM, PCPlus4M, ReadDataM;
    logic [4:0]  RdM;
    logic        RegWriteM, MemWriteM;
    logic [1:0]  ResultSrcM;

    // -------------------------------------------------------- Writeback (W)
    logic [31:0] ALUResultW, ReadDataW, PCPlus4W, ResultW;
    logic [4:0]  RdW;
    logic        RegWriteW;
    logic [1:0]  ResultSrcW;

    // ------------------------------------------------------------- Hazard
    logic [1:0]  ForwardAE, ForwardBE;
    logic        lwstall, StallF, StallD, FlushD, FlushE;

    // ================================================================ FETCH
    RISC_V_Pipeline_2to1Mux u_pcmux (
        .Port0 (PCPlus4F),
        .Port1 (PCTargetE),
        .Sel   (PCSrcE),
        .Out   (PC_next)
    );

    RISC_V_Pipeline_ProgramCounter u_pc (
        .en      (~StallF),
        .clk     (clk),
        .rst     (rst),
        .PC_next (PC_next),
        .PCF     (PCF)
    );

    RISC_V_Pipeline_PCPlus4Adder u_pcplus4 (
        .PCF     (PCF),
        .PCPlusF (PCPlus4F)
    );

    RISC_V_Pipeline_InstructionMemory u_imem (
        .A  (PCF),
        .RD (InstrF)
    );

    RISC_V_Pipeline_FetchDecodePipeline u_fd (
        .clk      (clk),
        .en       (~StallD),
        .clr      (FlushD | rst),   // also clear during reset
        .InstrF   (InstrF),
        .PCF      (PCF),
        .PCPlus4F (PCPlus4F),
        .InstrD   (InstrD),
        .PCD      (PCD),
        .PCPlus4D (PCPlus4D)
    );

    // =============================================================== DECODE
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD  = InstrD[11:7];

    RISC_V_Pipeline_Controller u_ctrl (
        .Opcode     (InstrD[6:0]),
        .funct3     (InstrD[14:12]),
        .funct7_5   (InstrD[30]),
        .RegWriteD  (RegWriteD),
        .ResultSrcD (ResultSrcD),
        .MemWriteD  (MemWriteD),
        .JumpD      (JumpD),
        .BranchD    (BranchD),
        .ALUSrcD    (ALUSrcD),
        .ImmSrcD    (ImmSrcD),
        .ALUControl (ALUControlD)
    );

    RISC_V_Pipeline_RegisterFile u_rf (
        .clk (clk),
        .WE3 (RegWriteW),
        .A1  (Rs1D),
        .A2  (Rs2D),
        .A3  (RdW),
        .WD3 (ResultW),
        .RD1 (RD1D),
        .RD2 (RD2D)
    );

    RISC_V_Pipeline_SignExtend u_ext (
        .InstrD  (InstrD),
        .ImmSrcD (ImmSrcD),
        .ImmExtD (ImmExtD)
    );

    RISC_V_Pipeline_DecodeExecutePipeline u_de (
        .clk         (clk),
        .clr         (FlushE | rst),   // also clear during reset
        .RegWriteD   (RegWriteD),
        .ResultSrcD  (ResultSrcD),
        .MemWriteD   (MemWriteD),
        .JumpD       (JumpD),
        .BranchD     (BranchD),
        .ALUControlD (ALUControlD),
        .ALUSrcD     (ALUSrcD),
        .RD1D        (RD1D),
        .RD2D        (RD2D),
        .PCD         (PCD),
        .Rs1D        (Rs1D),
        .Rs2D        (Rs2D),
        .RdD         (RdD),
        .ImmExtD     (ImmExtD),
        .PCPlus4D    (PCPlus4D),
        .RegWriteE   (RegWriteE),
        .ResultSrcE  (ResultSrcE),
        .MemWriteE   (MemWriteE),
        .JumpE       (JumpE),
        .BranchE     (BranchE),
        .ALUControlE (ALUControlE),
        .ALUSrcE     (ALUSrcE),
        .RD1E        (RD1E),
        .RD2E        (RD2E),
        .PCE         (PCE),
        .Rs1E        (Rs1E),
        .Rs2E        (Rs2E),
        .RdE         (RdE),
        .ImmExtE     (ImmExtE),
        .PCPlus4E    (PCPlus4E)
    );

    // ============================================================== EXECUTE
    RISC_V_Pipeline_3to1Mux u_fwdA (
        .Port00  (RD1E),
        .Port01  (ResultW),
        .Port10  (ALUResultM),
        .Forward (ForwardAE),
        .Out     (SrcAE)
    );

    RISC_V_Pipeline_3to1Mux u_fwdB (
        .Port00  (RD2E),
        .Port01  (ResultW),
        .Port10  (ALUResultM),
        .Forward (ForwardBE),
        .Out     (WriteDataE)
    );

    RISC_V_Pipeline_2to1Mux u_srcbmux (
        .Port0 (WriteDataE),
        .Port1 (ImmExtE),
        .Sel   (ALUSrcE),
        .Out   (SrcBE)
    );

    RISC_V_Pipeline_ALU u_alu (
        .SrcAE       (SrcAE),
        .SrcBE       (SrcBE),
        .ALUControlE (ALUControlE),
        .ALUResultE  (ALUResultE),
        .Zero        (ZeroE)
    );

    RISC_V_Pipeline_PCEImmExtEAdder u_pctarget (
        .PCE       (PCE),
        .ImmExtE   (ImmExtE),
        .PCTargetE (PCTargetE)
    );

    assign PCSrcE = (BranchE & ZeroE) | JumpE;

    RISC_V_Pipeline_ExecuteMemoryPipeline u_em (
        .clk        (clk),
        .RegWriteE  (RegWriteE),
        .MemWriteE  (MemWriteE),
        .ResultSrcE (ResultSrcE),
        .ALUResultE (ALUResultE),
        .WriteDataE (WriteDataE),
        .PCPlus4E   (PCPlus4E),
        .RdE        (RdE),
        .RegWriteM  (RegWriteM),
        .MemWriteM  (MemWriteM),
        .ResultSrcM (ResultSrcM),
        .ALUResultM (ALUResultM),
        .WriteDataM (WriteDataM),
        .PCPlus4M   (PCPlus4M),
        .RdM        (RdM)
    );

    // =============================================================== MEMORY
    RISC_V_Pipeline_DataMemory u_dmem (
        .A   (ALUResultM),
        .RD  (ReadDataM),
        .clk (clk),
        .WE  (MemWriteM),
        .WD  (WriteDataM)
    );

    RISC_V_Pipeline_MemoryWritePipeline u_mw (
        .clk        (clk),
        .RegWriteM  (RegWriteM),
        .ResultSrcM (ResultSrcM),
        .ALUResultM (ALUResultM),
        .ReadDataM  (ReadDataM),
        .PCPlus4M   (PCPlus4M),
        .RdM        (RdM),
        .RegWriteW  (RegWriteW),
        .ResultSrcW (ResultSrcW),
        .ALUResultW (ALUResultW),
        .ReadDataW  (ReadDataW),
        .PCPlus4W   (PCPlus4W),
        .RdW        (RdW)
    );

    // ============================================================ WRITEBACK
    RISC_V_Pipeline_3to1Mux u_resultmux (
        .Port00  (ALUResultW),
        .Port01  (ReadDataW),
        .Port10  (PCPlus4W),
        .Forward (ResultSrcW),
        .Out     (ResultW)
    );

    // =============================================================== HAZARD
    RISC_V_Pipeline_HazardUnit u_hazard (
        .Rs1E       (Rs1E),
        .Rs2E       (Rs2E),
        .RdE        (RdE),
        .RdM        (RdM),
        .RdW        (RdW),
        .Rs1D       (Rs1D),
        .Rs2D       (Rs2D),
        .RegWriteM  (RegWriteM),
        .RegWriteW  (RegWriteW),
        .PCSrcE     (PCSrcE),
        .ResultSrcE (ResultSrcE),
        .ForwardAE  (ForwardAE),
        .ForwardBE  (ForwardBE),
        .lwstall    (lwstall),
        .StallF     (StallF),
        .StallD     (StallD),
        .FlushD     (FlushD),
        .FlushE     (FlushE)
    );

    // ============================================================== OUTPUTS
    assign PC        = PCF;
    assign Instr     = InstrF;
    assign DataAdr   = ALUResultM;
    assign WriteData = WriteDataM;
    assign MemWrite  = MemWriteM;

endmodule
