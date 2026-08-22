module testbench;

    // Signals

    logic clk;
    logic rst;

    // DUT

    RISC_V_Pipeline_Top dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // Reset

    initial begin
        rst = 1'b1;

        // Hold reset for two clock cycles
        #22;

        rst = 1'b0;
    end

    // Pipeline monitor

    always @(negedge clk) begin

        $display(
            "TIME=%0t | PCF=%08h | InstrF=%08h | InstrD=%08h | ALU_E=%08h | ALU_M=%08h | MemWriteM=%b",
            $time,
            dut.PCF,
            dut.InstrF,
            dut.InstrD,
            dut.ALUResultE,
            dut.ALUResultM,
            dut.MemWriteM
        );

    end

    // Register-write monitor

    always @(negedge clk) begin

        if (dut.RegWriteW && (dut.RdW != 5'd0)) begin

            $display(
                "REGISTER WRITE: x%0d <= %0d (0x%08h)",
                dut.RdW,
                dut.ResultW,
                dut.ResultW
            );

        end

    end

    // Store monitor

    always @(negedge clk) begin

        if (dut.MemWriteM) begin

            $display(
                "STORE: Address=%0d (0x%08h), Data=%0d (0x%08h)",
                dut.ALUResultM,
                dut.ALUResultM,
                dut.WriteDataM,
                dut.WriteDataM
            );

        end

    end

    // PASS CONDITION
    //
    // Change these values if your program has a different
    // expected result.

    always @(negedge clk) begin

        if (dut.MemWriteM &&
            (dut.ALUResultM == 32'd100) &&
            (dut.WriteDataM == 32'd25)) begin

            $display("");
            $display("==============================================");
            $display("              SIMULATION PASSED");
            $display("==============================================");
            $display("Memory Address : %0d", dut.ALUResultM);
            $display("Memory Data    : %0d", dut.WriteDataM);
            $display("Simulation Time: %0t", $time);
            $display("==============================================");
            $display("");

            #10;
            $finish;

        end

    end

    // TIMEOUT

    initial begin

        #1000;

        $display("");
        $display("==============================================");
        $display("            SIMULATION TIMEOUT");
        $display("==============================================");
        $display("Expected store was not detected.");
        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
