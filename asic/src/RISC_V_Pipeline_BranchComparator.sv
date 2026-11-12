// ============================================================================
// Dedicated branch comparator (ASIC v2 timing optimisation)
//
// Compares the two forwarded register operands directly, in parallel with the
// ALU. Before v2, beq used the ALU subtract followed by a 32-bit zero detect,
// which was the critical path (forwarding -> ALU -> zero -> PCSrcE -> PC).
// This core supports only beq, so equality is the whole branch decision.
// ============================================================================

module RISC_V_Pipeline_BranchComparator (
    input  logic [31:0] SrcAE,       // forwarded rs1
    input  logic [31:0] WriteDataE,  // forwarded rs2 (before the ALUSrc mux)
    output logic        EqE          // 1 when rs1 == rs2
);

    assign EqE = (SrcAE == WriteDataE);

endmodule
