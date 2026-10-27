module RISC_V_Pipeline_ALU(SrcAE, SrcBE, ALUControlE, ALUResultE, Zero);
input [31:0] SrcAE;
input [31:0] SrcBE;
input [2:0] ALUControlE;
output reg [31:0] ALUResultE;
output Zero;
always @(*)
begin
case(ALUControlE)
3'b000: ALUResultE = SrcAE + SrcBE;
3'b001: ALUResultE = SrcAE - SrcBE;
3'b010: ALUResultE = SrcAE & SrcBE;
3'b011: ALUResultE = SrcAE | SrcBE;
3'b101: ALUResultE = ($signed(SrcAE) < $signed(SrcBE)) ? 32'd1 : 32'd0;
default: ALUResultE = 32'b0;
endcase
end
assign Zero = (ALUResultE == 32'b0);
endmodule
