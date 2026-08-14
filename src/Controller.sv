module RISC_V_Pipeline_Controller (
    input  logic [6:0] Opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,

    output logic       RegWriteD,
    output logic [1:0] ResultSrcD,
    output logic       MemWriteD,
    output logic       JumpD,
    output logic       BranchD,
    output logic       ALUSrcD,
    output logic [1:0] ImmSrcD,
    output logic [2:0] ALUControl
);

    logic [1:0] ALUOp;
    logic       Opcode_5;

    assign Opcode_5 = Opcode[5];

    RISC_V_Pipeline_MainDecoder MD1 (
        .RegWriteD  (RegWriteD),
        .ResultSrcD (ResultSrcD),
        .MemWriteD  (MemWriteD),
        .JumpD      (JumpD),
        .BranchD    (BranchD),
        .ALUSrcD    (ALUSrcD),
        .ImmSrcD    (ImmSrcD),
        .Opcode     (Opcode),
        .ALUOp      (ALUOp)
    );

    RISC_V_Pipeline_ALUDecoder ALUD1 (
        .Opcode_5  (Opcode_5),
        .ALUOp     (ALUOp),
        .funct3    (funct3),
        .funct7_5  (funct7_5),
        .ALUControl(ALUControl)
    );

endmodule
