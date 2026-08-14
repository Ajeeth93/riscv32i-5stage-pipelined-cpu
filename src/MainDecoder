module RISC_V_Pipeline_MainDecoder (
    input  logic [6:0] Opcode,
    output logic       RegWriteD,
    output logic [1:0] ResultSrcD,
    output logic       MemWriteD,
    output logic       JumpD,
    output logic       BranchD,
    output logic       ALUSrcD,
    output logic [1:0] ImmSrcD,
    output logic [1:0] ALUOp
);

  logic [10:0] controls;

  // Concatenate output signals to map from the internal controls vector
  assign {RegWriteD, ImmSrcD, ALUSrcD, MemWriteD, ResultSrcD, BranchD, ALUOp, JumpD} = controls;

  always_comb begin
    case (Opcode)
      // RegWriteD_ImmSrcD_ALUSrcD_MemWriteD_ResultSrcD_BranchD_ALUOp_JumpD
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_00_0_0_00_0_10_0; // R-type (ImmSrc default 00)
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      default:    controls = 11'b0_00_0_0_00_0_00_0; // default / unhandled
    endcase
  end

endmodule
