module RISC_V_Pipeline_FetchDecodePipeline (
    input  logic        clk,
    input  logic        en,
    input  logic        clr,
    input  logic [31:0] InstrF,
    input  logic [31:0] PCF,
    input  logic [31:0] PCPlus4F,
    output logic [31:0] InstrD,
    output logic [31:0] PCD,
    output logic [31:0] PCPlus4D
);

    // Synchronous reset with active-high enable control
    always_ff @(posedge clk) begin
        if (clr) begin
            InstrD   <= 32'h0000_0013; // RISC-V NOP (addi x0, x0, 0)
            PCD      <= '0;
            PCPlus4D <= '0;
        end else if (en) begin
            InstrD   <= InstrF;
            PCD      <= PCF;
            PCPlus4D <= PCPlus4F;
        end
    end

endmodule
