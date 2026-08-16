module RISC_V_Pipeline_2to1Mux #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH-1:0] Port0,
    input  logic [WIDTH-1:0] Port1,
    input  logic             Sel,
    output logic [WIDTH-1:0] Out
);

    assign Out = Sel ? Port1 : Port0;

endmodule
