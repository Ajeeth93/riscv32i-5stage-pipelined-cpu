module RISC_V_Pipeline_InstructionMemory (
    input  logic [31:0] A,
    output logic [31:0] RD
);

    // 64-word x 32-bit memory array
    logic [31:0] RAM [0:63];

    // Load initial memory content at startup
    initial begin
        $readmemh("RISC-Vmem.txt", RAM);
    end

    // Continuous assignment using word-aligned indexing (A[7:2])
    assign RD = RAM[A[7:2]];

endmodule
