module RISC_V_Pipeline_HazardUnit_tb;

    // DUT inputs
    logic [4:0] Rs1E;
    logic [4:0] Rs2E;
    logic [4:0] RdE;
    logic [4:0] RdM;
    logic [4:0] RdW;
    logic [4:0] Rs1D;
    logic [4:0] Rs2D;

    logic       RegWriteM;
    logic       RegWriteW;
    logic       PCSrcE;
    logic [1:0] ResultSrcE;

    // DUT outputs
    logic [1:0] ForwardAE;
    logic [1:0] ForwardBE;

    logic       lwstall;
    logic       StallF;
    logic       StallD;
    logic       FlushD;
    logic       FlushE;

    // Instantiate DUT
    RISC_V_Pipeline_HazardUnit dut (
        .Rs1E       (Rs1E),
        .Rs2E       (Rs2E),
        .RdE        (RdE),
        .RdM        (RdM),
        .RdW        (RdW),
        .Rs1D       (Rs1D),
        .Rs2D       (Rs2D),

        .RegWriteM  (RegWriteM),
        .RegWriteW  (RegWriteW),
        .PCSrcE     (PCSrcE),
        .ResultSrcE (ResultSrcE),

        .ForwardAE  (ForwardAE),
        .ForwardBE  (ForwardBE),

        .lwstall    (lwstall),
        .StallF     (StallF),
        .StallD     (StallD),
        .FlushD     (FlushD),
        .FlushE     (FlushE)
    );

    // Task for checking outputs
    
    task check_outputs(
        input logic [1:0] exp_ForwardAE,
        input logic [1:0] exp_ForwardBE,
        input logic       exp_lwstall,
        input logic       exp_StallF,
        input logic       exp_StallD,
        input logic       exp_FlushD,
        input logic       exp_FlushE
    );
        begin
            #1;

            if (ForwardAE !== exp_ForwardAE)
                $error("ForwardAE mismatch: Expected=%b, Got=%b",
                       exp_ForwardAE, ForwardAE);

            if (ForwardBE !== exp_ForwardBE)
                $error("ForwardBE mismatch: Expected=%b, Got=%b",
                       exp_ForwardBE, ForwardBE);

            if (lwstall !== exp_lwstall)
                $error("lwstall mismatch: Expected=%b, Got=%b",
                       exp_lwstall, lwstall);

            if (StallF !== exp_StallF)
                $error("StallF mismatch: Expected=%b, Got=%b",
                       exp_StallF, StallF);

            if (StallD !== exp_StallD)
                $error("StallD mismatch: Expected=%b, Got=%b",
                       exp_StallD, StallD);

            if (FlushD !== exp_FlushD)
                $error("FlushD mismatch: Expected=%b, Got=%b",
                       exp_FlushD, FlushD);

            if (FlushE !== exp_FlushE)
                $error("FlushE mismatch: Expected=%b, Got=%b",
                       exp_FlushE, FlushE);

            $display("Test passed at time %0t", $time);
        end
    endtask

    // Test sequence
    
    initial begin

        $display("==============================================");
        $display(" RISC-V Pipeline Hazard Unit Testbench");
        $display("==============================================");

        // Initialize all inputs
        Rs1E       = 5'd0;
        Rs2E       = 5'd0;
        RdE        = 5'd0;
        RdM        = 5'd0;
        RdW        = 5'd0;
        Rs1D       = 5'd0;
        Rs2D       = 5'd0;

        RegWriteM  = 1'b0;
        RegWriteW  = 1'b0;
        PCSrcE     = 1'b0;
        ResultSrcE = 2'b00;

        #10;

        // TEST 1: No forwarding
        
        $display("\nTEST 1: No forwarding");

        Rs1E      = 5'd1;
        Rs2E      = 5'd2;
        RdM       = 5'd3;
        RdW       = 5'd4;
        RegWriteM = 1'b1;
        RegWriteW = 1'b1;

        check_outputs(
            2'b00,    // ForwardAE
            2'b00,    // ForwardBE
            1'b0,     // lwstall
            1'b0,     // StallF
            1'b0,     // StallD
            1'b0,     // FlushD
            1'b0      // FlushE
        );

        // TEST 2: Forward Operand A from MEM
        
        $display("\nTEST 2: Forward A from MEM");

        Rs1E      = 5'd5;
        Rs2E      = 5'd2;
        RdM       = 5'd5;
        RdW       = 5'd7;
        RegWriteM = 1'b1;
        RegWriteW = 1'b0;

        check_outputs(
            2'b10,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 3: Forward Operand B from MEM
        
        $display("\nTEST 3: Forward B from MEM");

        Rs1E      = 5'd1;
        Rs2E      = 5'd6;
        RdM       = 5'd6;
        RegWriteM = 1'b1;
        RegWriteW = 1'b0;

        check_outputs(
            2'b00,
            2'b10,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 4: Forward Operand A from WB
        
        $display("\nTEST 4: Forward A from WB");

        Rs1E      = 5'd8;
        Rs2E      = 5'd2;
        RdM       = 5'd9;
        RdW       = 5'd8;
        RegWriteM = 1'b0;
        RegWriteW = 1'b1;

        check_outputs(
            2'b01,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 5: Forward Operand B from WB
        
        $display("\nTEST 5: Forward B from WB");

        Rs1E      = 5'd1;
        Rs2E      = 5'd10;
        RdM       = 5'd9;
        RdW       = 5'd10;
        RegWriteM = 1'b0;
        RegWriteW = 1'b1;

        check_outputs(
            2'b00,
            2'b01,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 6: MEM forwarding has priority over WB
        
        $display("\nTEST 6: MEM forwarding priority");

        Rs1E      = 5'd11;
        Rs2E      = 5'd2;
        RdM       = 5'd11;
        RdW       = 5'd11;
        RegWriteM = 1'b1;
        RegWriteW = 1'b1;

        // Should select MEM = 10, not WB = 01
        check_outputs(
            2'b10,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 7: x0 must never be forwarded
        
        $display("\nTEST 7: x0 forwarding prevention");

        Rs1E      = 5'd0;
        Rs2E      = 5'd0;
        RdM       = 5'd0;
        RdW       = 5'd0;
        RegWriteM = 1'b1;
        RegWriteW = 1'b1;

        check_outputs(
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 8: Load-use hazard on Rs1D
        
        $display("\nTEST 8: Load-use hazard on Rs1D");

        RdE        = 5'd12;
        Rs1D       = 5'd12;
        Rs2D       = 5'd3;
        ResultSrcE = 2'b01;

        check_outputs(
            2'b00,
            2'b00,
            1'b1,     // lwstall
            1'b1,     // StallF
            1'b1,     // StallD
            1'b0,     // FlushD
            1'b1      // FlushE
        );

        // TEST 9: Load-use hazard on Rs2D
        
        $display("\nTEST 9: Load-use hazard on Rs2D");

        RdE        = 5'd13;
        Rs1D       = 5'd2;
        Rs2D       = 5'd13;
        ResultSrcE = 2'b01;

        check_outputs(
            2'b00,
            2'b00,
            1'b1,
            1'b1,
            1'b1,
            1'b0,
            1'b1
        );

        // TEST 10: No load-use hazard
        
        $display("\nTEST 10: No load-use hazard");

        RdE        = 5'd14;
        Rs1D       = 5'd2;
        Rs2D       = 5'd3;
        ResultSrcE = 2'b01;

        check_outputs(
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 11: ResultSrcE is not a load
        
        $display("\nTEST 11: Non-load instruction");

        RdE        = 5'd15;
        Rs1D       = 5'd15;
        Rs2D       = 5'd3;

        // ResultSrcE[0] = 0
        ResultSrcE = 2'b00;

        check_outputs(
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 12: Branch/Jump flush
        
        $display("\nTEST 12: Branch/Jump flush");

        PCSrcE     = 1'b1;
        ResultSrcE = 2'b00;
        RdE        = 5'd0;
        Rs1D       = 5'd1;
        Rs2D       = 5'd2;

        check_outputs(
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b1,     // FlushD
            1'b1      // FlushE
        );

        // TEST 13: Load-use + branch simultaneously
        
        $display("\nTEST 13: Load-use + branch");

        PCSrcE     = 1'b1;
        RdE        = 5'd16;
        Rs1D       = 5'd16;
        Rs2D       = 5'd2;
        ResultSrcE = 2'b01;

        check_outputs(
            2'b00,
            2'b00,
            1'b1,     // lwstall
            1'b1,     // StallF
            1'b1,     // StallD
            1'b1,     // FlushD
            1'b1      // FlushE
        );

        // TEST 14: Forward both operands from MEM
        
        $display("\nTEST 14: Forward both operands from MEM");

        PCSrcE     = 1'b0;
        RdE        = 5'd0;
        Rs1E       = 5'd17;
        Rs2E       = 5'd18;
        RdM        = 5'd17;
        RdW        = 5'd18;
        RegWriteM  = 1'b1;
        RegWriteW  = 1'b1;

        check_outputs(
            2'b10,
            2'b01,    // B matches WB
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // TEST 15: Forward both operands from WB
        
        $display("\nTEST 15: Forward both operands from WB");

        Rs1E       = 5'd19;
        Rs2E       = 5'd20;
        RdM        = 5'd21;
        RdW        = 5'd19;
        RegWriteM  = 1'b0;
        RegWriteW  = 1'b1;

        check_outputs(
            2'b01,
            2'b00,
            1'b0,
            1'b0,
            1'b0,
            1'b0,
            1'b0
        );

        // End simulation
        
        $display("\n==============================================");
        $display(" All hazard unit tests completed");
        $display("==============================================");

        $finish;
    end

endmodule
