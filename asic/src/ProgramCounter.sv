module RISC_V_Pipeline_ProgramCounter (
    input  logic        en,
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] PC_next,
    output logic [31:0] PCF
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PCF <= 32'b0;
        end
        else if (en) begin
            PCF <= PC_next;
        end
    end

endmodule
