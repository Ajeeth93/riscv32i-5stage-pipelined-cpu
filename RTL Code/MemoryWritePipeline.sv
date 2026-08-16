module RISC_V_Pipeline_MemoryWritePipeline (
    input  logic        clk,

    // Memory Stage Inputs (M)
    input  logic        RegWriteM,
    input  logic [1:0]  ResultSrcM,
    input  logic [31:0] ALUResultM,
    input  logic [31:0] ReadDataM,
    input  logic [31:0] PCPlus4M,
    input  logic [4:0]  RdM,

    // Writeback Stage Outputs (W)
    output logic        RegWriteW,
    output logic [1:0]  ResultSrcW,
    output logic [31:0] ALUResultW,
    output logic [31:0] ReadDataW,
    output logic [31:0] PCPlus4W,
    output logic [4:0]  RdW
);

    // Sequential pipeline register
    always_ff @(posedge clk) begin
        RegWriteW  <= RegWriteM;
        ResultSrcW <= ResultSrcM;
        ALUResultW <= ALUResultM;
        ReadDataW  <= ReadDataM;
        PCPlus4W   <= PCPlus4M;
        RdW        <= RdM;
    end

endmodule
