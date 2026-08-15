module RISC_V_Pipeline_3to1Mux #(
    parameter int WIDTH = 32
) (
    input  logic [WIDTH-1:0] Port00,
    input  logic [WIDTH-1:0] Port01,
    input  logic [WIDTH-1:0] Port10,
    input  logic [1:0]       Forward,
    output logic [WIDTH-1:0] Out
);

    // Combinational multiplexer logic using standard case matching
    always_comb begin
        case (Forward)
            2'b00:   Out = Port00;
            2'b01:   Out = Port01;
            2'b10:   Out = Port10;
            default: Out = Port00;
        endcase
    end

endmodule
