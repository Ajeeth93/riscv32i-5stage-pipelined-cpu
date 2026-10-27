module RISC_V_Pipeline_SignExtend (
    input  logic [31:0] InstrD,
    input  logic [1:0]  ImmSrcD,
    output logic [31:0] ImmExtD
);

    always_comb begin
        case (ImmSrcD)
            2'b00:   ImmExtD = {{20{InstrD[31]}}, InstrD[31:20]};                                   // I-Type
            2'b01:   ImmExtD = {{20{InstrD[31]}}, InstrD[31:25], InstrD[11:7]};                     // S-Type
            2'b10:   ImmExtD = {{19{InstrD[31]}}, InstrD[31], InstrD[7], InstrD[30:25], InstrD[11:8], 1'b0};  // B-Type
            2'b11:   ImmExtD = {{11{InstrD[31]}}, InstrD[31], InstrD[19:12], InstrD[20], InstrD[30:21], 1'b0}; // J-Type
            default: ImmExtD = 32'b0;
        endcase
    end

endmodule
