module RISC_V_Pipeline_RegisterFile (
    input  logic        clk,
    input  logic        WE3,
    input  logic [4:0]  A1,
    input  logic [4:0]  A2,
    input  logic [4:0]  A3,
    input  logic [31:0] WD3,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);

    // 32-word x 32-bit register file array
    logic [31:0] RegFile [0:31];

    // Initialize all registers to zero at power-on
    initial begin
        for (int i = 0; i < 32; i++) begin
            RegFile[i] = 32'b0;
        end
    end

    // Asynchronous reads with hardwired zero register (x0 = 0)
    assign RD1 = (A1 == 5'b0) ? 32'b0 : RegFile[A1];
    assign RD2 = (A2 == 5'b0) ? 32'b0 : RegFile[A2];

    // Synchronous write on rising clock edge (protects x0 from being overwritten)
    always_ff @(posedge clk) begin
        if (WE3 && (A3 != 5'b0)) begin
            RegFile[A3] <= WD3;
        end
    end

endmodule
