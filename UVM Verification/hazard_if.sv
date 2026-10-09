`timescale 1ns/1ps

// interface for the hazard unit. no clocking blocks, xsim had trouble with them.
// the DUT is combinational, clk is only there to pace the testbench:
// driver changes inputs on posedge, monitor samples on negedge.
interface hazard_if (input logic clk);

    // inputs
    logic [4:0] Rs1E       = '0;
    logic [4:0] Rs2E       = '0;
    logic [4:0] RdE        = '0;
    logic [4:0] RdM        = '0;
    logic [4:0] RdW        = '0;
    logic [4:0] Rs1D       = '0;
    logic [4:0] Rs2D       = '0;
    logic       RegWriteM  = 1'b0;
    logic       RegWriteW  = 1'b0;
    logic       PCSrcE     = 1'b0;
    logic [1:0] ResultSrcE = '0;

    // tb only, high when the driver put a new item on the inputs
    logic       valid      = 1'b0;

    // outputs
    logic [1:0] ForwardAE;
    logic [1:0] ForwardBE;
    logic       lwstall;
    logic       StallF;
    logic       StallD;
    logic       FlushD;
    logic       FlushE;

endinterface
