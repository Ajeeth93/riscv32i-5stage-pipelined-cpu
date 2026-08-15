module RISC_V_Pipeline_ExecuteMemoryPipeline (
    input  logic        clk,

    // Execute Stage Inputs (E)
    input  logic        RegWriteE,
    input  logic        MemWriteE,
    input  logic [1:0]  ResultSrcE,
    input  logic [31:0] ALUResultE,
    input  logic [31:0] WriteDataE,
    input  logic [31:0] PCPlus4E,
    input  logic [4:0]  RdE,

    // Memory Stage Outputs (M)
    output logic        RegWriteM,
    output logic        MemWriteM,
    output logic [1:0]  ResultSrcM,
    output logic [31:0] ALUResultM,
    output logic [31:0] WriteDataM,
    output logic [31:0] PCPlus4M,
    output logic [4:0]  RdM
);

    // Sequential pipeline register
    always_ff @(posedge clk) begin
        RegWriteM  <= RegWriteE;
        MemWriteM  <= MemWriteE;
        ResultSrcM <= ResultSrcE;
        ALUResultM <= ALUResultE;
        WriteDataM <= WriteDataE;
        PCPlus4M   <= PCPlus4E;
        RdM        <= RdE;
    end

endmodule
