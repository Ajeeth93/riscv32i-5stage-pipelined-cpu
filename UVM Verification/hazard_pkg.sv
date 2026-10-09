`timescale 1ns/1ps

// UVM testbench for the hazard unit (forwarding, load-use stall, branch flush)
// directed scenarios first, then random. scoreboard has its own model of the hazard logic.
package hazard_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // transaction
    class hazard_item extends uvm_sequence_item;
        `uvm_object_utils(hazard_item)

        // inputs
        rand bit [4:0] Rs1E, Rs2E, RdE, RdM, RdW, Rs1D, Rs2D;
        rand bit       RegWriteM, RegWriteW, PCSrcE;
        rand bit [1:0] ResultSrcE;

        // outputs, filled in by the monitor.
        // kept as logic so an X on an output shows up as a mismatch
        logic [1:0] ForwardAE, ForwardBE;
        logic       lwstall, StallF, StallD, FlushD, FlushE;

        // 0 = random, 1-17 = directed scenario number
        int scenario = 0;

        // use x0-x7 most of the time, otherwise hazards almost never happen
        constraint c_reg_bias {
            Rs1E dist { [0:7] :/ 80, [8:31] :/ 20 };
            Rs2E dist { [0:7] :/ 80, [8:31] :/ 20 };
            RdE  dist { [0:7] :/ 80, [8:31] :/ 20 };
            RdM  dist { [0:7] :/ 80, [8:31] :/ 20 };
            RdW  dist { [0:7] :/ 80, [8:31] :/ 20 };
            Rs1D dist { [0:7] :/ 80, [8:31] :/ 20 };
            Rs2D dist { [0:7] :/ 80, [8:31] :/ 20 };
        }

        // ResultSrcE: 00 alu, 01 load, 10 pc+4
        constraint c_ctrl_bias {
            ResultSrcE dist { 2'b00 :/ 50, 2'b01 :/ 30, 2'b10 :/ 15, 2'b11 :/ 5 };
            PCSrcE     dist { 1'b0 := 80, 1'b1 := 20 };
        }

        // directed cases, see scenario_name() below
        constraint c_scenario {
            // 1: no hazard
            if (scenario == 1) { RegWriteM == 0; RegWriteW == 0; PCSrcE == 0; ResultSrcE[0] == 0; }
            // 2: A from MEM
            if (scenario == 2) { Rs1E != 0; RdM == Rs1E; RegWriteM == 1; }
            // 3: A from WB
            if (scenario == 3) { Rs1E != 0; RdW == Rs1E; RegWriteW == 1; !(RegWriteM && (RdM == Rs1E)); }
            // 4: A: MEM wins over WB
            if (scenario == 4) { Rs1E != 0; RdM == Rs1E; RdW == Rs1E; RegWriteM == 1; RegWriteW == 1; }
            // 5: A matches but regwrite off
            if (scenario == 5) { Rs1E != 0; RdM == Rs1E; RdW == Rs1E; RegWriteM == 0; RegWriteW == 0; }
            // 6: x0 on A
            if (scenario == 6) { Rs1E == 0; RdM == 0; RdW == 0; RegWriteM == 1; RegWriteW == 1; }
            // 7: B from MEM
            if (scenario == 7) { Rs2E != 0; RdM == Rs2E; RegWriteM == 1; }
            // 8: B from WB
            if (scenario == 8) { Rs2E != 0; RdW == Rs2E; RegWriteW == 1; !(RegWriteM && (RdM == Rs2E)); }
            // 9: B: MEM wins over WB
            if (scenario == 9) { Rs2E != 0; RdM == Rs2E; RdW == Rs2E; RegWriteM == 1; RegWriteW == 1; }
            // 10: x0 on B
            if (scenario == 10) { Rs2E == 0; RdM == 0; RdW == 0; RegWriteM == 1; RegWriteW == 1; }
            // 11: both operands
            if (scenario == 11) { Rs1E != 0; Rs2E != 0; Rs1E != Rs2E; RdM == Rs1E; RdW == Rs2E;
                                  RegWriteM == 1; RegWriteW == 1; }
            // 12: lw stall, rs1
            if (scenario == 12) { ResultSrcE == 2'b01; RdE == Rs1D; PCSrcE == 0; }
            // 13: lw stall, rs2
            if (scenario == 13) { ResultSrcE == 2'b01; RdE == Rs2D; RdE != Rs1D; PCSrcE == 0; }
            // 14: lw in EX, no dependency
            if (scenario == 14) { ResultSrcE == 2'b01; RdE != Rs1D; RdE != Rs2D; PCSrcE == 0; }
            // 15: not a load, no stall
            if (scenario == 15) { ResultSrcE[0] == 0; RdE == Rs1D; PCSrcE == 0; }
            // 16: branch taken
            if (scenario == 16) { PCSrcE == 1; ResultSrcE[0] == 0; }
            // 17: branch + lw stall
            if (scenario == 17) { PCSrcE == 1; ResultSrcE == 2'b01; RdE == Rs1D; }
        }

        function new(string name = "hazard_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf(
                "Rs1E=%0d Rs2E=%0d RdE=%0d RdM=%0d RdW=%0d Rs1D=%0d Rs2D=%0d RegWriteM=%0b RegWriteW=%0b PCSrcE=%0b ResultSrcE=%b | ForwardAE=%b ForwardBE=%b lwstall=%b StallF=%b StallD=%b FlushD=%b FlushE=%b",
                Rs1E, Rs2E, RdE, RdM, RdW, Rs1D, Rs2D, RegWriteM, RegWriteW, PCSrcE, ResultSrcE,
                ForwardAE, ForwardBE, lwstall, StallF, StallD, FlushD, FlushE);
        endfunction

    endclass

    // random sequence

    class hazard_rand_seq extends uvm_sequence#(hazard_item);
    `uvm_object_utils(hazard_rand_seq)

    int unsigned num_items = 1000;

    function new(string name = "hazard_rand_seq");
    super.new(name);
    endfunction

    task body();
        hazard_item item;
        repeat(num_items) begin
            item = hazard_item::type_id::create("item");
            start_item(item);
            item.scenario = 0;
            if (!item.randomize())
                `uvm_error("RAND_SEQ", "Randomization failed")
            finish_item(item);
            end
        endtask
    endclass

    // directed sequence, every scenario 'reps' times
    class hazard_directed_seq extends uvm_sequence #(hazard_item);
    `uvm_object_utils(hazard_directed_seq)

    int unsigned reps = 10;

    function new(string name = "hazard_directed_seq");
        super.new(name);
    endfunction

    function string scenario_name(int s);
        case(s)
            1:  return "No hazard";
            2:  return "ForwardAE from MEM (10)";
            3:  return "ForwardAE from WB (01)";
            4:  return "ForwardAE priority: MEM beats WB";
            5:  return "ForwardAE match but RegWrite=0";
            6:  return "ForwardAE: x0 never forwarded";
            7:  return "ForwardBE from MEM (10)";
            8:  return "ForwardBE from WB (01)";
            9:  return "ForwardBE priority: MEM beats WB";
            10: return "ForwardBE: x0 never forwarded";
            11: return "Both operands forwarded";
            12: return "Load-use stall on Rs1D";
            13: return "Load-use stall on Rs2D";
            14: return "Load in EX, no dependency (no stall)";
            15: return "Non-load with matching Rd (no stall)";
            16: return "Branch taken flush";
            17: return "Branch taken + load-use stall";
            default: return "Unknown";
         endcase
     endfunction

     task body();
        hazard_item item;
        for (int s = 1; s <= 17; s++) begin
            `uvm_info("DIR_SEQ", $sformatf("Scenario %0d: %s", s, scenario_name(s)), UVM_MEDIUM)
            repeat (reps) begin
                item = hazard_item::type_id::create("item");
                start_item(item);
                item.scenario = s;
                if (!item.randomize())
                    `uvm_error("DIR_SEQ", $sformatf("Randomization failed for scenario %0d", s))
                finish_item(item);
            end
         end
      endtask
  endclass

    // driver
    typedef uvm_sequencer #(hazard_item) hazard_sequencer;

    class hazard_driver extends uvm_driver #(hazard_item);
    `uvm_component_utils(hazard_driver)

    virtual hazard_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual hazard_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for driver")
        endfunction

    task run_phase(uvm_phase phase);
        hazard_item item;
        forever begin
            @(posedge vif.clk);
            seq_item_port.try_next_item(item);
            if(item != null) begin
                vif.Rs1E        <= item.Rs1E;
                vif.Rs2E        <= item.Rs2E;
                vif.RdE         <= item.RdE;
                vif.RdM         <= item.RdM;
                vif.RdW         <= item.RdW;
                vif.Rs1D        <= item.Rs1D;
                vif.Rs2D        <= item.Rs2D;
                vif.RegWriteM   <= item.RegWriteM;
                vif.RegWriteW   <= item.RegWriteW;
                vif.PCSrcE      <= item.PCSrcE;
                vif.ResultSrcE  <= item.ResultSrcE;
                vif.valid       <= 1'b1;
                `uvm_info("DRV", item.convert2string(), UVM_HIGH)
                seq_item_port.item_done();
            end
            else begin
                vif.valid <= 1'b0;
            end
            end
        endtask
    endclass

    // monitor
    class hazard_monitor extends uvm_monitor;
    `uvm_component_utils(hazard_monitor)

    virtual hazard_if vif;
    uvm_analysis_port #(hazard_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if(!uvm_config_db#(virtual hazard_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for monitor")
    endfunction

    task run_phase(uvm_phase phase);
        hazard_item tr;
        forever begin
            @(negedge vif.clk)
            if(vif.valid == 1'b1) begin
            tr = hazard_item::type_id::create("tr");
            // inputs
            tr.Rs1E         = vif.Rs1E;
            tr.Rs2E         = vif.Rs2E;
            tr.RdE          = vif.RdE;
            tr.RdM          = vif.RdM;
            tr.RdW          = vif.RdW;
            tr.Rs1D         = vif.Rs1D;
            tr.Rs2D         = vif.Rs2D;
            tr.RegWriteM    = vif.RegWriteM;
            tr.RegWriteW    = vif.RegWriteW;
            tr.PCSrcE       = vif.PCSrcE;
            tr.ResultSrcE   = vif.ResultSrcE;
            // outputs
            tr.ForwardAE    = vif.ForwardAE;
            tr.ForwardBE    = vif.ForwardBE;
            tr.lwstall      = vif.lwstall;
            tr.StallF       = vif.StallF;
            tr.StallD       = vif.StallD;
            tr.FlushD       = vif.FlushD;
            tr.FlushE       = vif.FlushE;
            `uvm_info("MON", tr.convert2string(), UVM_HIGH)
            ap.write(tr);
          end
       end
    endtask
endclass

    // agent
    class hazard_agent extends uvm_agent;
        `uvm_component_utils(hazard_agent)

        hazard_sequencer seqr;
        hazard_driver    drv;
        hazard_monitor   mon;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            seqr = hazard_sequencer::type_id::create("seqr", this);
            drv  = hazard_driver::type_id::create("drv", this);
            mon  = hazard_monitor::type_id::create("mon", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            drv.seq_item_port.connect(seqr.seq_item_export);
        endfunction
    endclass

    // scoreboard
    class hazard_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(hazard_scoreboard)

        uvm_analysis_imp #(hazard_item, hazard_scoreboard) item_imp;

        int unsigned num_checked = 0;
        int unsigned num_errors  = 0;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            item_imp = new("item_imp", this);
        endfunction

        // MEM first, then WB. never forward x0
        function bit [1:0] predict_forward(bit [4:0] rs, hazard_item t);
            if      ((rs == t.RdM) && t.RegWriteM && (rs != 5'd0)) return 2'b10;
            else if ((rs == t.RdW) && t.RegWriteW && (rs != 5'd0)) return 2'b01;
            else                                                    return 2'b00;
        endfunction

        function void check_sig(string name, logic [1:0] act, logic [1:0] exp, hazard_item t);
            if (act !== exp) begin
                num_errors++;
                `uvm_error("SCB_MISMATCH",
                    $sformatf("%s: expected %b, got %b | %s", name, exp, act, t.convert2string()))
            end
        endfunction

        function void write(hazard_item t);
            logic [1:0] exp_fa, exp_fb;
            logic [1:0] exp_lw, exp_fd, exp_fe;

            exp_fa = predict_forward(t.Rs1E, t);
            exp_fb = predict_forward(t.Rs2E, t);
            exp_lw = {1'b0, (t.ResultSrcE[0] && ((t.RdE == t.Rs1D) || (t.RdE == t.Rs2D)))};
            exp_fd = {1'b0, t.PCSrcE};
            exp_fe = {1'b0, (exp_lw[0] || t.PCSrcE)};

            check_sig("ForwardAE", t.ForwardAE,        exp_fa, t);
            check_sig("ForwardBE", t.ForwardBE,        exp_fb, t);
            check_sig("lwstall",   {1'b0, t.lwstall},  exp_lw, t);
            check_sig("StallF",    {1'b0, t.StallF},   exp_lw, t);
            check_sig("StallD",    {1'b0, t.StallD},   exp_lw, t);
            check_sig("FlushD",    {1'b0, t.FlushD},   exp_fd, t);
            check_sig("FlushE",    {1'b0, t.FlushE},   exp_fe, t);

            num_checked++;
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("SCB", $sformatf("Transactions checked: %0d, mismatches: %0d",
                                       num_checked, num_errors), UVM_NONE)
            if (num_checked == 0)
                `uvm_error("SCB", "No transactions were checked!")
            else if (num_errors == 0)
                `uvm_info("SCB", "*** TEST PASSED ***", UVM_NONE)
            else
                `uvm_error("SCB", "*** TEST FAILED ***")
        endfunction
    endclass

    // coverage
    // covergroup is outside the class on purpose, xsim gives VRFC 10-9909
    // if it's inside a class that extends uvm_subscriber
    covergroup hazard_cg with function sample (
        bit [1:0] fwdA,      bit [1:0] fwdB,     bit [1:0] resultsrc,
        bit       lw,        bit       flushD,   bit       flushE,
        bit       prioA,     bit       prioB,
        bit       x0A,       bit       x0B,
        bit       stall_rs1, bit       stall_rs2
    );
        option.per_instance = 1;

        cp_fwdA: coverpoint fwdA {
            bins none     = {2'b00};
            bins from_wb  = {2'b01};
            bins from_mem = {2'b10};
        }
        cp_fwdB: coverpoint fwdB {
            bins none     = {2'b00};
            bins from_wb  = {2'b01};
            bins from_mem = {2'b10};
        }
        cp_lwstall   : coverpoint lw;
        cp_flushD    : coverpoint flushD;
        cp_flushE    : coverpoint flushE;
        cp_resultsrc : coverpoint resultsrc;
        cp_prioA     : coverpoint prioA     { bins hit = {1}; }
        cp_prioB     : coverpoint prioB     { bins hit = {1}; }
        cp_x0A       : coverpoint x0A       { bins hit = {1}; }
        cp_x0B       : coverpoint x0B       { bins hit = {1}; }
        cp_stall_rs1 : coverpoint stall_rs1 { bins hit = {1}; }
        cp_stall_rs2 : coverpoint stall_rs2 { bins hit = {1}; }
        x_fwdA_fwdB  : cross cp_fwdA, cp_fwdB;
        x_stall_flush: cross cp_lwstall, cp_flushD;
    endgroup

    class hazard_coverage extends uvm_subscriber #(hazard_item);
        `uvm_component_utils(hazard_coverage)

        hazard_cg    cg;
        int unsigned num_sampled = 0;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            cg = new();
        endfunction

        function void write(hazard_item t);
            bit prioA, prioB, x0A, x0B, stall_rs1, stall_rs2;

            prioA     = t.RegWriteM && t.RegWriteW && (t.Rs1E == t.RdM) && (t.Rs1E == t.RdW) && (t.Rs1E != 0);
            prioB     = t.RegWriteM && t.RegWriteW && (t.Rs2E == t.RdM) && (t.Rs2E == t.RdW) && (t.Rs2E != 0);
            x0A       = (t.Rs1E == 0) && (t.RdM == 0) && t.RegWriteM;
            x0B       = (t.Rs2E == 0) && (t.RdM == 0) && t.RegWriteM;
            stall_rs1 = t.lwstall && (t.RdE == t.Rs1D);
            stall_rs2 = t.lwstall && (t.RdE == t.Rs2D) && (t.RdE != t.Rs1D);

            cg.sample(t.ForwardAE, t.ForwardBE, t.ResultSrcE,
                      t.lwstall, t.FlushD, t.FlushE,
                      prioA, prioB, x0A, x0B, stall_rs1, stall_rs2);
            num_sampled++;
        endfunction

        function real get_cov();
            return cg.get_inst_coverage();
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("COV", $sformatf("Functional coverage: %0.2f%% (%0d samples)",
                                       get_cov(), num_sampled), UVM_NONE)
        endfunction
    endclass

    // env
    class hazard_env extends uvm_env;
        `uvm_component_utils(hazard_env)

        hazard_agent      agent;
        hazard_scoreboard scb;
        hazard_coverage   cov;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            agent = hazard_agent::type_id::create("agent", this);
            scb   = hazard_scoreboard::type_id::create("scb", this);
            cov   = hazard_coverage::type_id::create("cov", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.mon.ap.connect(scb.item_imp);
            agent.mon.ap.connect(cov.analysis_export);
        endfunction
    endclass

    // test
    class hazard_test extends uvm_test;
        `uvm_component_utils(hazard_test)

        hazard_env   env;
        int unsigned num_random = 1000;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            int unsigned n;
            super.build_phase(phase);
            env = hazard_env::type_id::create("env", this);
            // can change the random count with +NUM_RAND=5000
            if ($value$plusargs("NUM_RAND=%d", n))
                num_random = n;
        endfunction

        function void end_of_elaboration_phase(uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            uvm_top.print_topology();
        endfunction

        task run_phase(uvm_phase phase);
            hazard_directed_seq dseq;
            hazard_rand_seq     rseq;

            phase.raise_objection(this);

            dseq = hazard_directed_seq::type_id::create("dseq");
            dseq.start(env.agent.seqr);

            rseq = hazard_rand_seq::type_id::create("rseq");
            rseq.num_items = num_random;
            rseq.start(env.agent.seqr);

            #50ns;   // give the last item time to get checked
            phase.drop_objection(this);
        endtask

        // summary at the end of the log. test's report_phase runs last
        function void report_phase(uvm_phase phase);
            uvm_report_server rs = uvm_report_server::get_server();
            int unsigned errs = rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL);
            bit pass = (errs == 0) && (env.scb.num_errors == 0) && (env.scb.num_checked > 0);

            `uvm_info("SUMMARY", $sformatf({"\n",
                "  ======================================================\n",
                "    RISC-V RV32I Hazard Unit : UVM Verification Summary\n",
                "  ======================================================\n",
                "    Test                  : %s\n",
                "    Directed scenarios    : 17 (x10 each)\n",
                "    Random transactions   : %0d\n",
                "    Transactions checked  : %0d\n",
                "    Scoreboard mismatches : %0d\n",
                "    Functional coverage   : %0.2f %%\n",
                "    UVM errors / fatals   : %0d / %0d\n",
                "  ------------------------------------------------------\n",
                "    RESULT                : %s\n",
                "  ======================================================"},
                get_type_name(), num_random, env.scb.num_checked, env.scb.num_errors,
                env.cov.get_cov(), rs.get_severity_count(UVM_ERROR), rs.get_severity_count(UVM_FATAL),
                pass ? "PASSED" : "FAILED"), UVM_NONE)
        endfunction
    endclass

endpackage