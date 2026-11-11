`timescale 1ns/1ps
// Gate-level testbench for CVC (Verilog-2005 only, no SystemVerilog).
// DUT : routed power-aware netlist (pnl) of RISC_V_Pipeline_Top
// SDF : optional, from one sign-off corner (define SDF; MIN_DELAYS for min_* corners)
// PASS: store of 25 to address 100, same program as the RTL testbench.
module tb_gls_cvc;
`ifndef CLK_NS
  `define CLK_NS 25
`endif
    localparam real    CLK_PERIOD = `CLK_NS;   // 25 ns = 40 MHz sign-off clock
    localparam integer MAX_CYCLES = 200;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    wire [31:0] imem_addr, imem_rdata;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire        dmem_we, dmem_req;
    integer     cycles = 0;
    integer     i;

    supply1 VPWR;
    supply0 VGND;

    // ---------------------------------------------------------------- DUT
    RISC_V_Pipeline_Top u_core (
        .VPWR(VPWR), .VGND(VGND),
        .clk(clk), .rst(rst),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we), .dmem_req(dmem_req),
        .dmem_rdata(dmem_rdata), .dmem_ready(1'b1)
    );

    // --------------------------------------- behavioural memories (as in RTL)
    reg [31:0] imem [0:255];
    reg [31:0] dmem [0:63];

    initial begin
        for (i = 0; i < 256; i = i + 1) imem[i] = 32'h0000_0013;   // nop
        $readmemh("RISC-Vmem.txt", imem);
    end

    assign imem_rdata = imem[imem_addr[31:2]];
    assign dmem_rdata = dmem[dmem_addr[7:2]];
    always @(posedge clk) if (dmem_we) dmem[dmem_addr[7:2]] <= dmem_wdata;

    // -------------------------------------------------------- clock / reset
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin                  // release reset on a falling edge
        repeat (3) @(negedge clk);
        rst = 1'b0;
    end

    // ------------------------------------------------------------- checks
    always @(posedge clk) if (!rst) begin
        cycles = cycles + 1;
        if (cycles > MAX_CYCLES) begin
            $display("FAIL: no PASS store after %0d cycles", MAX_CYCLES);
            $finish;
        end
    end

    // sampled half a cycle after the rising edge; (^bus === 1'bx) means some bit is X
    always @(negedge clk) if (!rst) begin
        if (^imem_addr === 1'bx) begin
            $display("FAIL: PC is X at %0t ns", $time);
            $finish;
        end
        if (dmem_we === 1'bx) begin
            $display("FAIL: dmem_we is X at %0t ns", $time);
            $finish;
        end
        if (dmem_we) begin
            $display("[%0t] STORE addr=%0d data=%0d", $time, dmem_addr, dmem_wdata);
            if (^{dmem_addr, dmem_wdata} === 1'bx) begin
                $display("FAIL: X on the store bus");
                $finish;
            end
            if (dmem_addr == 32'd100 && dmem_wdata == 32'd25) begin
                $display("PASS: gate-level netlist stored 25 to address 100 after %0d cycles", cycles);
                $finish;
            end
        end
    end

    // ------------------------------------------------- SDF and waveforms
`ifdef SDF
    initial begin
`ifdef MIN_DELAYS
        $sdf_annotate("corner.sdf", u_core, , "sdf_annotate.log", "MINIMUM");
`else
        $sdf_annotate("corner.sdf", u_core, , "sdf_annotate.log", "MAXIMUM");
`endif
        $display("SDF annotated from corner.sdf, clock %0.1f ns", CLK_PERIOD);
    end
`endif

    initial begin
        $dumpfile("gls_cvc.vcd");
        $dumpvars(1, tb_gls_cvc);   // top-level signals only, keeps the file small
    end
endmodule
