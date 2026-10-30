module RISC_V_Pipeline_InstructionMemory (
    input  logic [31:0] A,
    output logic [31:0] RD
);

    logic [31:0] RAM [0:255];

    integer i;

    initial begin

        // Initialize entire instruction memory to RISC-V NOP
        for (i = 0; i < 256; i = i + 1)
            RAM[i] = 32'h00000013;

        // Load program
        $readmemh("RISC-Vmem.txt", RAM);

    end

    assign RD = RAM[A[31:2]];

endmodule
