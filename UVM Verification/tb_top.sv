`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import hazard_pkg::*;

    // the hazard unit has no clock, this one is just for the testbench
    logic clk = 1'b0;
    always #5 clk = ~clk;

    hazard_if hif (clk);

    RISC_V_Pipeline_HazardUnit dut (
        .Rs1E       (hif.Rs1E),
        .Rs2E       (hif.Rs2E),
        .RdE        (hif.RdE),
        .RdM        (hif.RdM),
        .RdW        (hif.RdW),
        .Rs1D       (hif.Rs1D),
        .Rs2D       (hif.Rs2D),
        .RegWriteM  (hif.RegWriteM),
        .RegWriteW  (hif.RegWriteW),
        .PCSrcE     (hif.PCSrcE),
        .ResultSrcE (hif.ResultSrcE),
        .ForwardAE  (hif.ForwardAE),
        .ForwardBE  (hif.ForwardBE),
        .lwstall    (hif.lwstall),
        .StallF     (hif.StallF),
        .StallD     (hif.StallD),
        .FlushD     (hif.FlushD),
        .FlushE     (hif.FlushE)
    );

    initial begin
        uvm_config_db#(virtual hazard_if)::set(null, "uvm_test_top.*", "vif", hif);
        run_test("hazard_test");
    end

    // vcd dump, comment out if you don't need it
    initial begin
        $dumpfile("hazard_tb.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
