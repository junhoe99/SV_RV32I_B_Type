`timescale 1ns / 1ps

// Enable backdoor access to register file for verification
`define USE_BACKDOOR_ACCESS  // Enable for register value injection
//`define DEBUG_MODE  // Enable detailed debugging

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/30 
// Design Name: 
// Module Name: tb_B_type
// Project Name: RV32I B-type Instruction Verification
// Target Devices: 
// Tool Versions: 
// Description: SystemVerilog Testbench for B-type instruction verification
//              Uses SVA, CDV, and Randomization techniques
// 
// Dependencies: cpu_with_data_memory_dut.sv, define.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// - Comprehensive B-type instruction verification
// - Includes BEQ, BNE, BLT, BGE, BLTU, BGEU
// - SVA for PC update rules verification
// - Coverage-driven verification for complete testing
//////////////////////////////////////////////////////////////////////////////////

// Define constants directly for compilation
`define BEQ  3'b000
`define BNE  3'b001
`define BLT  3'b100
`define BGE  3'b101
`define BLTU 3'b110
`define BGEU 3'b111
`define OP_B_TYPE 7'b1100011

//------------
// Interface
//------------
interface rv32i_intf;
    logic clk;
    logic rst;
    logic [31:0] instr_code;
    logic [31:0] instr_rAddr;
    logic [31:0] reg_file_out[32];
    logic [31:0] alu_result_out;
    logic alu_taken_out;
    logic [31:0] pc_out;
    logic [31:0] data_addr_out;
    logic [31:0] data_wdata_out;
    logic [31:0] data_rdata_out;
    logic data_wr_en_out;
    logic [1:0] store_size_out;
    logic [1:0] load_size_out;
endinterface

//------------
// Transaction Class
//------------
class b_type_transaction;
    // B-type instruction format: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
    
    // Randomizable fields for B-type instruction
    rand logic [4:0] rs1;              // Source register 1 (5 bits)
    rand logic [4:0] rs2;              // Source register 2 (5 bits)
    rand logic [2:0] funct3;           // Function code for branch type
    rand logic signed [12:0] imm;      // 13-bit signed immediate (branch offset)
    
    // Randomizable register values
    rand logic signed [31:0] rs1_value; // Value to be written to rs1
    rand logic signed [31:0] rs2_value; // Value to be written to rs2
    
    // Computed fields
    logic [31:0] instruction;          // Complete 32-bit instruction
    logic [31:0] pc_current;           // Current PC value
    logic [31:0] pc_expected;          // Expected next PC value
    logic branch_taken_expected;       // Expected branch taken result
    
    // Constraints for realistic testing
    constraint valid_funct3 {
        funct3 inside {3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111}; // BEQ, BNE, BLT, BGE, BLTU, BGEU
    }
    
    constraint register_constraints {
        // x0 저확률, 일반 레지스터 고확률
        rs1 dist {0 := 1, [1:31] := 10};
        rs2 dist {0 := 1, [1:31] := 10};
        rs1 != rs2; // 의미있는 Test를 위해 rs1, rs2는 다르게
    }
    
    constraint immediate_constraints {
        // Ensure word-aligned branch targets (imm[0] = 0)
        imm[0] == 1'b0;
        // Distribute immediate values for good coverage
        imm dist {
            //[-2048:-1024] := 1,    // Large negative (backward branch)
            [-1023:-4]    := 1,    // Small negative (backward branch)
            [4:1023]      := 5,    // Small positive (forward branch)
            [1024:2047]   := 4     // Large positive (forward branch)
        };
    }
    
    constraint register_value_constraints {
        // Generate diverse register values for comprehensive testing
        rs1_value dist {
            32'h00000000 := 5,           // Zero
            [32'h00000001:32'h000000FF] := 3,  // Small positive
            [32'h80000000:32'hFFFFFFFF] := 3,  // Negative
            [32'h7FFFFFFF:32'h7FFFFF00] := 3   // Large positive
        };
        
        rs2_value dist {
            32'h00000000 := 5,           // Zero
            [32'h00000001:32'h000000FF] := 3,  // Small positive
            [32'h80000000:32'hFFFFFFFF] := 3,  // Negative  
            [32'h7FFFFFFF:32'h7FFFFF00] := 3   // Large positive
        };
    }
    
    // Constructor
    function new();
        // Initialize default values
        this.pc_current = 32'h00000000;
    endfunction
    
    // Build complete B-type instruction
    function void build_instruction();
        // B-type instruction format: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
        instruction = {
            imm[12],           // bit 31: imm[12]
            imm[10:5],         // bits 30:25: imm[10:5]
            rs2,               // bits 24:20: rs2
            rs1,               // bits 19:15: rs1
            funct3,            // bits 14:12: funct3
            imm[4:1],          // bits 11:8: imm[4:1]
            imm[11],           // bit 7: imm[11]
            7'b1100011         // bits 6:0: B-type opcode
        };
    endfunction
    
    // Calculate expected branch result
    function void calculate_expected();
        case (funct3)
            3'b000: branch_taken_expected = (rs1_value == rs2_value);  // BEQ
            3'b001: branch_taken_expected = (rs1_value != rs2_value);  // BNE
            3'b100: branch_taken_expected = (rs1_value < rs2_value);   // BLT
            3'b101: branch_taken_expected = (rs1_value >= rs2_value);  // BGE
            3'b110: branch_taken_expected = ($unsigned(rs1_value) < $unsigned(rs2_value));  // BLTU
            3'b111: branch_taken_expected = ($unsigned(rs1_value) >= $unsigned(rs2_value)); // BGEU
            default: branch_taken_expected = 1'b0;
        endcase
        
        // Calculate expected PC
        if (branch_taken_expected) begin
            pc_expected = pc_current + {{19{imm[12]}}, imm[12:0]}; // Sign-extend immediate
        end else begin
            pc_expected = pc_current + 32'd4; // Next sequential instruction
        end
    endfunction
    
    // Display transaction information
    task display(string name);
        string funct3_name;
        case (funct3)
            3'b000: funct3_name = "BEQ";
            3'b001: funct3_name = "BNE";
            3'b100: funct3_name = "BLT";
            3'b101: funct3_name = "BGE";
            3'b110: funct3_name = "BLTU";
            3'b111: funct3_name = "BGEU";
            default: funct3_name = "UNKNOWN";
        endcase
        
        $display("%0t: [%s] %s: rs1=%0d(0x%08x) %s rs2=%0d(0x%08x), imm=%0d, taken=%b", 
                 $time, name, funct3_name, rs1, rs1_value, 
                 (funct3 == 3'b000) ? "==" : 
                 (funct3 == 3'b001) ? "!=" :
                 (funct3 == 3'b100 || funct3 == 3'b110) ? "<" : ">=",
                 rs2, rs2_value, imm, branch_taken_expected);
        $display("         PC: 0x%08x -> 0x%08x, Instruction: 0x%08x", 
                 pc_current, pc_expected, instruction);
    endtask
endclass

//------------
// SVA (SystemVerilog Assertions) for PC Update Rules
//------------
interface assertion_intf(input logic clk, rst);
    
    // Internal signals for assertion monitoring
    logic [31:0] pc_current, pc_next, pc_expected;
    logic [31:0] instruction;
    logic [2:0] funct3;
    logic [31:0] rs1_value, rs2_value;
    logic [12:0] imm;
    logic branch_taken;
    logic is_branch_instr;
    
    // Extract branch instruction fields
    assign funct3 = instruction[14:12];
    assign imm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    assign is_branch_instr = (instruction[6:0] == `OP_B_TYPE);
    
    // Calculate expected PC based on branch condition and taken signal
    always_comb begin
        if (is_branch_instr && branch_taken) begin
            pc_expected = pc_current + {{19{imm[12]}}, imm[12:0]};
        end else begin
            pc_expected = pc_current + 32'd4;
        end
    end
    
    // SVA Properties for B-type instructions
    
    // Property 1: Branch taken case - PC should update to PC + sign_ext(imm)
    property branch_taken_pc_update;
        @(posedge clk) disable iff (rst)
        (is_branch_instr && branch_taken) |=> (pc_next == (pc_current + {{19{imm[12]}}, imm[12:0]}));
    endproperty
    
    // Property 2: Branch not taken case - PC should update to PC + 4
    property branch_not_taken_pc_update;
        @(posedge clk) disable iff (rst)
        (is_branch_instr && !branch_taken) |=> (pc_next == (pc_current + 32'd4));
    endproperty
    
    // Property 3: x0 register comparison - should always read 0
    property x0_register_value;
        @(posedge clk) disable iff (rst)
        (is_branch_instr && (instruction[19:15] == 5'b00000)) |-> (rs1_value == 32'h00000000);
    endproperty
    
    property x0_register_value_rs2;
        @(posedge clk) disable iff (rst)
        (is_branch_instr && (instruction[24:20] == 5'b00000)) |-> (rs2_value == 32'h00000000);
    endproperty
    
    // Property 4: Branch instruction alignment - PC should be word-aligned after branch
    property branch_target_alignment;
        @(posedge clk) disable iff (rst)
        (is_branch_instr && branch_taken) |=> (pc_next[1:0] == 2'b00);
    endproperty
    
    // Assertion instances
    assert_branch_taken: assert property(branch_taken_pc_update)
        else $error("ASSERTION FAILED: Branch taken PC update incorrect at time %0t", $time);
        
    assert_branch_not_taken: assert property(branch_not_taken_pc_update)
        else $error("ASSERTION FAILED: Branch not taken PC update incorrect at time %0t", $time);
        
    assert_x0_rs1: assert property(x0_register_value)
        else $error("ASSERTION FAILED: x0 register (rs1) not zero at time %0t", $time);
        
    assert_x0_rs2: assert property(x0_register_value_rs2)
        else $error("ASSERTION FAILED: x0 register (rs2) not zero at time %0t", $time);
        
    assert_alignment: assert property(branch_target_alignment)
        else $error("ASSERTION FAILED: Branch target not word-aligned at time %0t", $time);
        
    // Coverage properties (for coverage feedback)
    cover_branch_taken: cover property(branch_taken_pc_update);
    cover_branch_not_taken: cover property(branch_not_taken_pc_update);
    cover_x0_usage: cover property(x0_register_value);
    
endinterface

//------------
// Coverage Model (CDV)
//------------
class coverage_model;
    
    // Coverage groups for comprehensive B-type instruction testing
    
    // Covergroup 1: Branch taken vs not taken
    covergroup branch_decision_cg with function sample(logic taken, logic [2:0] funct3);
        // Coverpoint for branch taken/not taken
        cp_branch_taken: coverpoint taken {
            bins taken = {1};
            bins not_taken = {0};
        }
        
        // Coverpoint for all B-type funct3 values
        cp_funct3: coverpoint funct3 {
            bins beq  = {`BEQ};
            bins bne  = {`BNE};
            bins blt  = {`BLT};
            bins bge  = {`BGE};
            bins bltu = {`BLTU};
            bins bgeu = {`BGEU};
        }
        
        // Cross coverage: each funct3 should be tested with both taken and not taken
        cross_funct3_taken: cross cp_funct3, cp_branch_taken;
    endgroup
    
    // Covergroup 2: Immediate value characteristics
    covergroup immediate_cg with function sample(logic signed [12:0] imm);
        cp_imm_sign: coverpoint imm {
            bins negative = {[-2048:-1]};
            bins zero = {0};
            bins positive = {[1:2047]};
        }
        
        cp_imm_magnitude: coverpoint imm {
            bins small_neg = {[-100:-1]};
            bins large_neg = {[-2048:-101]};
            bins small_pos = {[1:100]};
            bins large_pos = {[101:2047]};
            bins zero = {0};
        }
    endgroup
    
    // Covergroup 3: Register value relationships
    covergroup register_relation_cg with function sample(logic signed [31:0] rs1_val, logic signed [31:0] rs2_val);
        cp_rs1_zero: coverpoint (rs1_val == 0) {
            bins zero = {1};
            bins non_zero = {0};
        }
        
        cp_rs2_zero: coverpoint (rs2_val == 0) {
            bins zero = {1};
            bins non_zero = {0};
        }
        
        cp_comparison_result: coverpoint (rs1_val < rs2_val) {
            bins rs1_less = {1};
            bins rs1_greater_equal = {0};
        }
        
        cp_unsigned_comparison: coverpoint ($unsigned(rs1_val) < $unsigned(rs2_val)) {
            bins rs1_less_unsigned = {1};
            bins rs1_greater_equal_unsigned = {0};
        }
        
        // Cross coverage for zero register usage
        cross_zero_usage: cross cp_rs1_zero, cp_rs2_zero;
    endgroup
    
    // Covergroup 4: Edge cases
    covergroup edge_cases_cg with function sample(logic [4:0] rs1, logic [4:0] rs2, logic signed [31:0] rs1_val, logic signed [31:0] rs2_val);
        cp_register_x0_usage: coverpoint rs1 {
            bins x0 = {5'b00000};
            bins non_x0 = {[5'b00001:5'b11111]};
        }
        
        cp_register2_x0_usage: coverpoint rs2 {
            bins x0 = {5'b00000};
            bins non_x0 = {[5'b00001:5'b11111]};
        }
        
        cp_extreme_rs1_values: coverpoint rs1_val {
            bins zero = {32'h00000000};
            bins max_positive = {32'h7FFFFFFF};
            bins min_negative = {32'h80000000};
            bins small_positive = {[32'h00000001:32'h000000FF]};
            bins small_negative = {[32'hFFFFFF00:32'hFFFFFFFF]};
        }
        
        cp_extreme_rs2_values: coverpoint rs2_val {
            bins zero = {32'h00000000};
            bins max_positive = {32'h7FFFFFFF};
            bins min_negative = {32'h80000000};
            bins small_positive = {[32'h00000001:32'h000000FF]};
            bins small_negative = {[32'hFFFFFF00:32'hFFFFFFFF]};
        }
        
        // Cross coverage for x0 register usage
        cross_x0_usage: cross cp_register_x0_usage, cp_register2_x0_usage;
    endgroup
    
    // Constructor
    function new();
        branch_decision_cg = new();
        immediate_cg = new();
        register_relation_cg = new();
        edge_cases_cg = new();
    endfunction
    
    // Sample all coverage groups
    function void sample_coverage(b_type_transaction tr, logic actual_taken);
        branch_decision_cg.sample(actual_taken, tr.funct3);
        immediate_cg.sample(tr.imm);
        register_relation_cg.sample(tr.rs1_value, tr.rs2_value);
        edge_cases_cg.sample(tr.rs1, tr.rs2, tr.rs1_value, tr.rs2_value);
    endfunction
    
    // Get coverage report
    function void report_coverage();
        $display("\n=== COVERAGE REPORT ===");
        $display("Branch Decision Coverage: %.2f%%", branch_decision_cg.get_coverage());
        $display("Immediate Coverage: %.2f%%", immediate_cg.get_coverage());
        $display("Register Relation Coverage: %.2f%%", register_relation_cg.get_coverage());
        $display("Edge Cases Coverage: %.2f%%", edge_cases_cg.get_coverage());
        $display("=======================\n");
    endfunction
    
endclass

//------------
// Generator Class - Event Driven Single Clock Generation
//------------
class generator;
    virtual rv32i_intf vif;
    b_type_transaction tr;
    mailbox #(b_type_transaction) gen2drv_mbox;
    int test_count = 0;
    int total_tests = 0;

    // Constructor
    function new(virtual rv32i_intf vif, mailbox#(b_type_transaction) gen2drv_mbox);
        this.vif = vif;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    // Generate specified number of B-type transactions - Clock based
    task body(int count);
        total_tests = count;
        
        for (int i = 0; i < count; i++) begin
            // Create new transaction each time
            tr = new();
            
            // Randomize transaction
            if (!tr.randomize()) begin
                $error("[GENERATOR] Randomization failed at time %0t", $time);
                continue;
            end
            
            // Build instruction and calculate expected results
            tr.build_instruction();
            tr.calculate_expected();
            
            // Display generated transaction
            tr.display("Generator");
            
            // Send to driver mailbox immediately
            gen2drv_mbox.put(tr);
            test_count++;
            
            $display("[GENERATOR] Generated instruction %0d (0x%08x) at time %0t", test_count, tr.instruction, $time);
            
            // Wait for positive clock edge before generating next
            @(posedge vif.clk);
        end
        
        $display("[GENERATOR] Generated %0d B-type transactions", test_count);
    endtask

endclass

//------------
// Driver Class - Event Driven Single Clock Execution
//------------
class driver;
    virtual rv32i_intf vif;
    b_type_transaction tr;
    mailbox #(b_type_transaction) gen2drv_mbox;

    // Constructor
    function new(virtual rv32i_intf vif, mailbox#(b_type_transaction) gen2drv_mbox);
        this.vif = vif;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    // Reset task
    task reset();
        vif.clk = 0;
        vif.rst = 1;
        vif.instr_code = 32'h00000013; // NOP instruction (ADDI x0, x0, 0)
        
        repeat (3) @(posedge vif.clk);
        vif.rst = 0;
        repeat (2) @(posedge vif.clk);
        $display("[DRIVER] Reset completed at time %0t - Initial instruction: 0x%08x", $time, vif.instr_code);
    endtask

    // Write register values to register file using backdoor access
    task write_registers(logic [4:0] rs1, logic [4:0] rs2, logic [31:0] rs1_val, logic [31:0] rs2_val);
        // For debugging - show what we're trying to write
        $display("[DRIVER] Setting registers: r%0d=0x%08x, r%0d=0x%08x", rs1, rs1_val, rs2, rs2_val);
        
        `ifdef USE_BACKDOOR_ACCESS
            // Correct DUT hierarchy path to register file
            if (rs1 != 0) tb_B_type.dut.U_CPU.U_DP.U_REG_FILE.reg_file[rs1] = rs1_val;
            if (rs2 != 0) tb_B_type.dut.U_CPU.U_DP.U_REG_FILE.reg_file[rs2] = rs2_val;
            $display("[DRIVER] Backdoor access: Updated r%0d=0x%08x, r%0d=0x%08x", rs1, rs1_val, rs2, rs2_val);
        `else
            $display("[DRIVER] Register values set (interface mode)");
        `endif
    endtask

    // Main driver run task - Clock based simple execution
    task run();
        forever begin
            // Check if there's a new transaction in mailbox
            if (gen2drv_mbox.try_get(tr)) begin
                // Wait for positive clock edge to apply instruction
                @(posedge vif.clk);
                
                // Capture current PC at the moment of instruction application
                tr.pc_current = vif.pc_out;
                
                // Set register values immediately
                write_registers(tr.rs1, tr.rs2, tr.rs1_value, tr.rs2_value);
                
                // Recalculate expected results with actual PC
                tr.calculate_expected();
                
                // Drive new instruction immediately
                vif.instr_code = tr.instruction;
                tr.display("Driver");
                $display("[DRIVER] Instruction 0x%08x driven at time %0t - PC=0x%08x", tr.instruction, $time, tr.pc_current);
            end else begin
                // Wait a bit if no transaction available
                @(posedge vif.clk);
            end
        end
    endtask

endclass

//------------
// Monitor Class
//------------
class monitor;
    virtual rv32i_intf vif;
    b_type_transaction tr;
    mailbox #(b_type_transaction) mon2scb_mbox;

    // Constructor
    function new(virtual rv32i_intf vif, mailbox#(b_type_transaction) mon2scb_mbox);
        this.vif = vif;
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction

    // Main monitor run task - Clock based monitoring
    task run();
        forever begin
            // Wait for positive clock edge to monitor
            @(posedge vif.clk);
            
            // Only monitor if instruction is not NOP (indicating active test)
            if (vif.instr_code != 32'h00000013) begin
                // Small delay to ensure signals are stable
                #1;
                
                tr = new();
                
                // Capture all relevant signals
                tr.instruction = vif.instr_code;
                tr.pc_current = vif.pc_out;  // Use pc_out instead of instr_rAddr for current PC
                
                $display("[MONITOR] Monitoring instruction 0x%08x at time %0t - PC=0x%08x", tr.instruction, $time, tr.pc_current);
                
                // Extract instruction fields
                tr.funct3 = tr.instruction[14:12];
                tr.rs1 = tr.instruction[19:15];
                tr.rs2 = tr.instruction[24:20];
                tr.imm = {tr.instruction[31], tr.instruction[7], tr.instruction[30:25], tr.instruction[11:8], 1'b0};
                
                // Get register values from interface
                if (tr.rs1 < 32) tr.rs1_value = vif.reg_file_out[tr.rs1];
                if (tr.rs2 < 32) tr.rs2_value = vif.reg_file_out[tr.rs2];
                
                // Calculate expected results
                tr.calculate_expected();
                
                tr.display("Monitor");
                $display("[MONITOR] Captured instruction result at time %0t", $time);
                
                // Send to scoreboard
                mon2scb_mbox.put(tr);
            end
        end
    endtask

endclass

//------------
// Scoreboard Class
//------------
class scoreboard;
    virtual rv32i_intf vif;
    b_type_transaction tr;
    mailbox #(b_type_transaction) mon2scb_mbox;
    coverage_model cov_model;
    
    // Scoreboard statistics
    int total_tests = 0;
    int passed_tests = 0;
    int failed_tests = 0;
    int assertion_errors = 0;

    // Constructor
    function new(virtual rv32i_intf vif, mailbox#(b_type_transaction) mon2scb_mbox);
        this.vif = vif;
        this.mon2scb_mbox = mon2scb_mbox;
        this.cov_model = new();
    endfunction

    // Check PC update correctness
    function bit check_pc_update(b_type_transaction tr, logic [31:0] actual_pc_next);
        logic [31:0] expected_pc_next;
        logic actual_taken;
        
        // Determine if branch was actually taken based on PC update
        actual_taken = (actual_pc_next != tr.pc_current + 32'd4);
        
        // Calculate expected PC
        if (tr.branch_taken_expected) begin
            expected_pc_next = tr.pc_current + {{19{tr.imm[12]}}, tr.imm[12:0]};
        end else begin
            expected_pc_next = tr.pc_current + 32'd4;
        end
        
        // Check correctness
        if (actual_pc_next == expected_pc_next) begin
            $display("[SCOREBOARD] ✓ PASS: PC update correct. Expected: 0x%08x, Actual: 0x%08x", 
                     expected_pc_next, actual_pc_next);
            return 1;
        end else begin
            $display("[SCOREBOARD] ✗ FAIL: PC update incorrect. Expected: 0x%08x, Actual: 0x%08x", 
                     expected_pc_next, actual_pc_next);
            return 0;
        end
    endfunction

    // Check branch condition evaluation
    function bit check_branch_condition(b_type_transaction tr, logic actual_taken);
        if (actual_taken == tr.branch_taken_expected) begin
            $display("[SCOREBOARD] ✓ PASS: Branch condition correct. Expected taken: %b, Actual taken: %b", 
                     tr.branch_taken_expected, actual_taken);
            return 1;
        end else begin
            $display("[SCOREBOARD] ✗ FAIL: Branch condition incorrect. Expected taken: %b, Actual taken: %b", 
                     tr.branch_taken_expected, actual_taken);
            return 0;
        end
    endfunction

    // Main scoreboard run task - Clock based sequential processing
    task run();
        logic [31:0] actual_pc_next;
        logic actual_taken;
        bit pc_check_passed, branch_check_passed;
        
        forever begin
            // Get transaction from monitor
            mon2scb_mbox.get(tr);
            
            total_tests++;
            
            // Wait for next positive edge to read updated PC
            @(posedge vif.clk);
            #1; // Minimal delay for signal stability
            
            // Read the next PC value - this should be instr_rAddr
            actual_pc_next = vif.instr_rAddr;
            actual_taken = (actual_pc_next != tr.pc_current + 32'd4);
            
            // Enhanced logging for PC debugging
            $display("=== SCOREBOARD ANALYSIS [Test %0d] ===", total_tests);
            $display("Time: %0t", $time);
            $display("Current PC (from Monitor): 0x%08x", tr.pc_current);
            $display("Actual Next PC (instr_rAddr): 0x%08x", actual_pc_next);
            $display("Expected PC calc: Branch=%b, Imm=0x%h (%0d)", tr.branch_taken_expected, tr.imm, $signed(tr.imm));
            if (tr.branch_taken_expected)
                $display("Expected Next PC: 0x%08x (Current + Imm)", tr.pc_current + $signed(tr.imm));
            else
                $display("Expected Next PC: 0x%08x (Current + 4)", tr.pc_current + 32'd4);
            $display("PC Increment: +%0d (0x%h)", $signed(actual_pc_next - tr.pc_current), actual_pc_next - tr.pc_current);
            
            // Perform checks
            pc_check_passed = check_pc_update(tr, actual_pc_next);
            branch_check_passed = check_branch_condition(tr, actual_taken);
            
            // Update statistics
            if (pc_check_passed && branch_check_passed) begin
                passed_tests++;
                $display("[SCOREBOARD] ✅ Test %0d: PASSED", total_tests);
            end else begin
                failed_tests++;
                $display("[SCOREBOARD] ❌ Test %0d: FAILED", total_tests);
            end
            
            // Sample coverage
            cov_model.sample_coverage(tr, actual_taken);
            
            $display("=====================================");
        end
    endtask
    
    // Final report
    task final_report();
        $display("\n==================== FINAL TEST REPORT ====================");
        $display("Total Tests:        %0d", total_tests);
        $display("Passed Tests:       %0d", passed_tests);
        $display("Failed Tests:       %0d", failed_tests);
        $display("Pass Rate:          %.2f%%", (real'(passed_tests) / real'(total_tests)) * 100.0);
        $display("Assertion Errors:   %0d", assertion_errors);
        $display("============================================================");
        
        // Coverage report
        cov_model.report_coverage();
        
        if (failed_tests == 0 && assertion_errors == 0) begin
            $display("🎉 ALL TESTS PASSED! B-type instruction verification successful.");
        end else begin
            $display("❌ SOME TESTS FAILED! Please review failed test cases.");
        end
    endtask

endclass

//------------
// Environment Class - Simple Clock-Based Architecture
//------------
class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    virtual rv32i_intf vif;
    virtual assertion_intf assert_if;
    
    // Mailboxes for communication
    mailbox #(b_type_transaction) gen2drv_mbox;
    mailbox #(b_type_transaction) mon2scb_mbox;

    // Constructor
    function new(virtual rv32i_intf vif, virtual assertion_intf assert_if);
        this.vif = vif;
        this.assert_if = assert_if;
        
        // Create mailboxes
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        
        // Create verification components with simplified constructors
        gen = new(vif, gen2drv_mbox);
        drv = new(vif, gen2drv_mbox);
        mon = new(vif, mon2scb_mbox);
        scb = new(vif, mon2scb_mbox);
    endfunction

    // Main test execution
    task run(int num_tests = 20);
        $display("\n🚀 Starting B-type Instruction Verification Environment");
        $display("Target: %0d test transactions", num_tests);
        $display("Verification Features: Randomization + SVA + Coverage");
        $display("=======================================================\n");
        
        // Reset the DUT
        drv.reset();
        
        // Connect assertion interface signals to DUT
        connect_assertions();
        
        // Fork all verification components
        fork
            // Generate specified number of tests
            gen.body(num_tests);
            
            // Run driver, monitor, and scoreboard concurrently
            drv.run();
            mon.run();
            scb.run();
            
            // Timeout watchdog (optional)
            begin
                #(num_tests * 1000); // Generous timeout
                $display("⚠️ TIMEOUT: Test execution exceeded expected time");
                $finish;
            end
        join_any
        
        // Allow some time for final transactions to complete
        #1000;
        
        // Display final results
        scb.final_report();
        
        $display("\n🏁 B-type Instruction Verification Complete");
        $finish;
    endtask
    
    // Connect assertion interface signals to DUT interface
    task connect_assertions();
        fork
            forever begin
                @(posedge vif.clk);
                assert_if.pc_current = vif.pc_out;
                assert_if.pc_next = vif.instr_rAddr;
                assert_if.instruction = vif.instr_code;
                assert_if.branch_taken = vif.alu_taken_out;
                
                // Extract register values for assertion checking
                if (assert_if.instruction[19:15] < 32)
                    assert_if.rs1_value = vif.reg_file_out[assert_if.instruction[19:15]];
                if (assert_if.instruction[24:20] < 32) 
                    assert_if.rs2_value = vif.reg_file_out[assert_if.instruction[24:20]];
            end
        join_none
    endtask

endclass

//------------
// Top-level Testbench Module
//------------
module tb_B_type();

    // Clock and reset generation
    logic clk = 0;
    logic rst = 1;
    
    // Clock generation - 100MHz (10ns period)
    always #5 clk = ~clk;
    
    // Interface instances
    rv32i_intf intf();
    assertion_intf assert_intf(.clk(clk), .rst(rst));
    
    // Connect interface signals
    assign intf.clk = clk;
    assign intf.rst = rst;
    
    // Environment instance
    environment env;
    
    // DUT instance - CPU with data memory
    cpu_with_data_memory_dut dut (
        .clk(intf.clk),
        .rst(intf.rst),
        .instr_code(intf.instr_code),
        .instr_rAddr(intf.instr_rAddr),
        .reg_file_out(intf.reg_file_out),
        .alu_result_out(intf.alu_result_out),
        .alu_taken_out(intf.alu_taken_out),
        .pc_out(intf.pc_out),
        .data_addr_out(intf.data_addr_out),
        .data_wdata_out(intf.data_wdata_out),
        .data_rdata_out(intf.data_rdata_out),
        .data_wr_en_out(intf.data_wr_en_out),
        .store_size_out(intf.store_size_out),
        .load_size_out(intf.load_size_out)
    );
    
    // Test execution with timeout control
    initial begin
        int num_tests;
        
        // Initialize environment
        env = new(intf, assert_intf);
        
        // Configure test parameters
        `ifdef DEBUG_MODE
            num_tests = 5; // Limited tests for debugging
            $display("🔧 DEBUG MODE: Limited test execution");
        `else
            num_tests = 20; // Full test suite
        `endif
        
        $display("🔧 SystemVerilog B-type Instruction Testbench");
        $display("Features: Randomization, SVA, Coverage-Driven Verification");
        $display("Target: Single-cycle RV32I B-type instruction verification");
        $display("==================================================");
        
        // Start verification with timeout
        fork
            env.run(num_tests);
            begin
                #5000000; // 5ms timeout for all tests
                $display("⏰ [TIMEOUT] Test execution exceeded time limit");
                $finish;
            end
        join_any
        disable fork;
    end
    
    // Waveform dumping (for debugging)
    initial begin
        $dumpfile("tb_B_type.vcd");
        $dumpvars(0, tb_B_type);
    end
    
    // Monitor assertion failures
    initial begin
        forever begin
            @(posedge clk);
            // Additional monitoring can be added here if needed
        end
    end

endmodule
