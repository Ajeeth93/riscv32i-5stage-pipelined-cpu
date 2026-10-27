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

`ifndef SYNTHESIS
    // simulation only: registers start at 0 (real silicon powers up random)
    initial begin
        for (int i = 0; i < 32; i++) begin
            RegFile[i] = 32'b0;
        end
    end
`endif

    // Asynchronous reads with hardwired zero register (x0 = 0)
    assign RD1 = (A1 == 5'b0) ? 32'b0 : RegFile[A1];
    assign RD2 = (A2 == 5'b0) ? 32'b0 : RegFile[A2];

    // Write on the FALLING clock edge so an instruction in Decode reads the value
    // being written back in the same cycle (x0 is never overwritten)
    always_ff @(negedge clk) begin
        if (WE3 && (A3 != 5'b0)) begin
            RegFile[A3] <= WD3;
        end
    end

endmodule
