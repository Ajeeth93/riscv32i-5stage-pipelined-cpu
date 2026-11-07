`timescale 1ns/1ps
// Gate-level testbench: checks the routed netlist only through its ports.
// PASS = store of 25 to address 100 (same program as the RTL testbench).
module tb_gls;
`ifndef CLK_NS
  `define CLK_NS 25.0
`endif
    localparam real CLK_PERIOD = `CLK_NS;   // default 25 ns = 40 MHz (sign-off)
    localparam int  MAX_CYCLES = 200;

    logic        clk = 1'b0;
    logic        rst = 1'b1;
    logic [31:0] PC, Instr, DataAdr, WriteData;
    logic        MemWrite;
    int          cycles = 0;

    riscv_soc dut (
        .clk(clk), .rst(rst), .PC(PC), .Instr(Instr),
        .DataAdr(DataAdr), .WriteData(WriteData), .MemWrite(MemWrite)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // Release reset on a falling edge, away from the rising edge the flops use
    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
    end

    // Timeout
    always @(posedge clk) if (!rst) begin
        cycles++;
        if (cycles > MAX_CYCLES) begin
            $display("FAIL: no PASS store after %0d cycles", MAX_CYCLES);
            $finish;
        end
    end

    // Checks on the memory bus, sampled half a cycle after the edge
    always @(negedge clk) if (!rst) begin
        if ($isunknown(PC)) begin
            $display("FAIL: PC is X at %0t ns", $time);
            $finish;
        end
        if (MemWrite) begin
            $display("[%0t] STORE addr=%0d data=%0d", $time, DataAdr, WriteData);
            if ($isunknown({DataAdr, WriteData})) begin
                $display("FAIL: X on the store bus");
                $finish;
            end
            if (DataAdr == 32'd100 && WriteData == 32'd25) begin
                $display("PASS: gate-level netlist stored 25 to address 100 after %0d cycles", cycles);
                $finish;
            end
        end
    end

    initial begin
        $dumpfile("gls.vcd");
        $dumpvars(0, tb_gls);
    end
`ifdef SDF_FILE
    initial begin
        $sdf_annotate(`SDF_FILE, dut.u_core);
        $display("SDF annotated: %s, clock %0.1f ns", `SDF_FILE, CLK_PERIOD);
    end
`endif
endmodule
