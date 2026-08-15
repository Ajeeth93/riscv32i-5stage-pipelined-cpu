module RISC_V_Pipeline_HazardUnit (
    // Register Address Inputs
    input  logic [4:0] Rs1E,
    input  logic [4:0] Rs2E,
    input  logic [4:0] RdE,
    input  logic [4:0] RdM,
    input  logic [4:0] RdW,
    input  logic [4:0] Rs1D,
    input  logic [4:0] Rs2D,

    // Control Inputs
    input  logic       RegWriteM,
    input  logic       RegWriteW,
    input  logic       PCSrcE,
    input  logic [1:0] ResultSrcE,

    // Forwarding Control Outputs
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE,

    // Pipeline Hazard Control Outputs
    output logic       lwstall,
    output logic       StallF,
    output logic       StallD,
    output logic       FlushD,
    output logic       FlushE
);

    // Forwarding Logic for Execute Stage (Operand A)
    always_comb begin
        if ((Rs1E == RdM) && RegWriteM && (Rs1E != 5'b0)) begin
            ForwardAE = 2'b10; // Forward from Memory Stage
        end else if ((Rs1E == RdW) && RegWriteW && (Rs1E != 5'b0)) begin
            ForwardAE = 2'b01; // Forward from Writeback Stage
        end else begin
            ForwardAE = 2'b00; // No forwarding (use register file output)
        end
    end

    // Forwarding Logic for Execute Stage (Operand B)
    always_comb begin
        if ((Rs2E == RdM) && RegWriteM && (Rs2E != 5'b0)) begin
            ForwardBE = 2'b10; // Forward from Memory Stage
        end else if ((Rs2E == RdW) && RegWriteW && (Rs2E != 5'b0)) begin
            ForwardBE = 2'b01; // Forward from Writeback Stage
        end else begin
            ForwardBE = 2'b00; // No forwarding (use register file output)
        end
    end

    // Load-Use Stall & Branch Flush Hazard Logic
    always_comb begin
        lwstall = ResultSrcE[0] && ((RdE == Rs1D) || (RdE == Rs2D));
        StallF  = lwstall;
        StallD  = lwstall;
        FlushD  = PCSrcE;
        FlushE  = lwstall || PCSrcE;
    end

endmodule
