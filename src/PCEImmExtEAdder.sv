module RISC_V_Pipeline_PCEImmExtEAdder(PCE, ImmExtE, PCTargetE);
input logic [31:0] PCE;
input logic [31:0] ImmExtE;
output logic [31:0] PCTargetE;
assign PCTargetE = PCE + ImmExtE;
endmodule
