module RISC_V_Pipeline_DecodeExecutePipeline (
    input  logic        clk,
    input  logic        clr,

    // Decode Stage Inputs (D)
    input  logic        RegWriteD,
    input  logic [1:0]  ResultSrcD,
    input  logic        MemWriteD,
    input  logic        JumpD,
    input  logic        BranchD,
    input  logic [2:0]  ALUControlD,
    input  logic        ALUSrcD,
    input  logic [31:0] RD1D,
    input  logic [31:0] RD2D,
    input  logic [31:0] PCD,
    input  logic [4:0]  Rs1D,
    input  logic [4:0]  Rs2D,
    input  logic [4:0]  RdD,
    input  logic [31:0] ImmExtD,
    input  logic [31:0] PCPlus4D,

    // Execute Stage Outputs (E)
    output logic        RegWriteE,
    output logic [1:0]  ResultSrcE,
    output logic        MemWriteE,
    output logic        JumpE,
    output logic        BranchE,
    output logic [2:0]  ALUControlE,
    output logic        ALUSrcE,
    output logic [31:0] RD1E,
    output logic [31:0] RD2E,
    output logic [31:0] PCE,
    output logic [4:0]  Rs1E,
    output logic [4:0]  Rs2E,
    output logic [4:0]  RdE,
    output logic [31:0] ImmExtE,
    output logic [31:0] PCPlus4E
);

    // Sequential pipeline register with synchronous clear/flush
    always_ff @(posedge clk) begin
        if (clr) begin
            RegWriteE   <= '0;
            ResultSrcE  <= '0;
            MemWriteE   <= '0;
            JumpE       <= '0;
            BranchE     <= '0;
            ALUControlE <= '0;
            ALUSrcE     <= '0;
            RD1E        <= '0;
            RD2E        <= '0;
            PCE         <= '0;
            Rs1E        <= '0;
            Rs2E        <= '0;
            RdE         <= '0;
            ImmExtE     <= '0;
            PCPlus4E    <= '0;
        end else begin
            RegWriteE   <= RegWriteD;
            ResultSrcE  <= ResultSrcD;
            MemWriteE   <= MemWriteD;
            JumpE       <= JumpD;
            BranchE     <= BranchD;
            ALUControlE <= ALUControlD;
            ALUSrcE     <= ALUSrcD;
            RD1E        <= RD1D;
            RD2E        <= RD2D;
            PCE         <= PCD;
            Rs1E        <= Rs1D;
            Rs2E        <= Rs2D;
            RdE         <= RdD;
            ImmExtE     <= ImmExtD;
            PCPlus4E    <= PCPlus4D;
        end
    end

endmodule
