module RISC_V_Pipeline_DataMemory(A, RD, clk, WE, WD);
input [31:0] A;
input [31:0] WD;
input clk;
input WE;
output [31:0] RD;
reg [31:0] RAM [63:0];
assign RD = RAM[A[7:2]];
always @(posedge clk)
begin
if(WE)
begin
RAM[A[7:2]] <= WD;
end
end
endmodule
