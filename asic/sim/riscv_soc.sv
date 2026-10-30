// Simulation-only SoC: the ASIC core plus behavioural instruction/data memories.
// Keeps the old top-level ports so the original testbench works unchanged.
`timescale 1ns/ 1ps

module riscv_soc (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] PC,
    output logic [31:0] Instr,
    output logic [31:0] DataAdr,
    output logic [31:0] WriteData,
    output logic        MemWrite
);
    logic [31:0] dmem_rdata;

    RISC_V_Pipeline_Top u_core (
        .clk        (clk),
        .rst        (rst),
        .imem_addr  (PC),
        .imem_rdata (Instr),
        .dmem_addr  (DataAdr),
        .dmem_wdata (WriteData),
        .dmem_we    (MemWrite),
        .dmem_req   (),            // not used by these simple memories
        .dmem_rdata (dmem_rdata),
        .dmem_ready (1'b1)         // memory always answers in time
    );

    RISC_V_Pipeline_InstructionMemory u_imem (
        .A  (PC),
        .RD (Instr)
    );

    RISC_V_Pipeline_DataMemory u_dmem (
        .A   (DataAdr),
        .RD  (dmem_rdata),
        .clk (clk),
        .WE  (MemWrite),
        .WD  (WriteData)
    );
endmodule