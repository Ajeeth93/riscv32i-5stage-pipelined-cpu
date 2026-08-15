module RISC_V_Pipeline_PCPlus4Adder (
    input  logic [31:0] PCF,
    output logic [31:0] PCPlusF
);

    assign PCPlusF = PCF + 32'd4;

endmodule
