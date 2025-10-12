`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/29
// Design Name: 
// Module Name: cpu_with_data_memory_dut
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: DUT for SystemVerilog TB - CPU Core + Data Memory without Instruction Memory
//              Instruction Memory functionality moved to TB for flexible testing
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// - Instruction Memory removed from DUT (TB will provide instructions directly)
// - CPU Core + Data Memory + BRAM IP combined as DUT
// - Observability signals added for verification
//////////////////////////////////////////////////////////////////////////////////

module cpu_with_data_memory_dut(
    // Clock and Reset
    input logic clk,
    input logic rst,
    
    // Instruction Interface (from TB)
    input logic [31:0] instr_code,      // TB에서 직접 제공하는 명령어
    output logic [31:0] instr_rAddr,    // PC 출력 (TB가 다음 명령어 결정에 사용)
    
    // Observability Signals for Verification
    output logic [31:0] reg_file_out[32], // 모든 레지스터 상태 관찰
    output logic [31:0] alu_result_out,   // ALU 결과 관찰
    output logic alu_taken_out,           // Branch taken 신호 관찰
    output logic [31:0] pc_out,           // 현재 PC 값
    
    // Memory Access Observability
    output logic [31:0] data_addr_out,    // 데이터 메모리 주소
    output logic [31:0] data_wdata_out,   // 데이터 메모리 쓰기 데이터
    output logic [31:0] data_rdata_out,   // 데이터 메모리 읽기 데이터
    output logic data_wr_en_out,          // 데이터 메모리 쓰기 활성화
    output logic [1:0] store_size_out,    // 저장 크기
    output logic [1:0] load_size_out      // 로드 크기
);

    // Internal Signals (기존 RV32I_TOP과 동일)
    logic w_wr_en;
    logic [31:0] w_dAddr, w_dData;
    logic [1:0] w_store_size;
    logic [31:0] w_dRdata;
    logic [1:0] w_load_size;
    
    // BRAM IP 연결 신호들
    logic [31:0] bram_addr;
    logic [31:0] bram_din;
    logic [31:0] bram_dout;
    logic [3:0] bram_we;
    logic bram_en;

    // CPU Core 인스턴스 (기존과 동일하지만 instruction_memory 제외)
    cpu_core U_CPU (
        .clk(clk),
        .rst(rst),
        .instr_code(instr_code),        // TB에서 직접 제공
        .instr_rAddr(instr_rAddr),      // PC를 TB로 출력
        .dRdata(w_dRdata),
        .d_wr_en(w_wr_en),
        .dAddr(w_dAddr),
        .dWdata(w_dData),
        .store_size(w_store_size),
        .load_size(w_load_size)
    );

    // Data Memory 인스턴스 (기존과 동일)
    data_memory U_DM (
        .clk(clk),
        .d_wr_en(w_wr_en),
        .dAddr(w_dAddr),
        .dWdata(w_dData),
        .store_size(w_store_size),
        .load_size(w_load_size),
        .instr_code(instr_code),        // Load 확장을 위해 필요
        .dRdata(w_dRdata),
        // BRAM IP 인터페이스 신호들
        .bram_addr(bram_addr),
        .bram_din(bram_din),
        .bram_dout(bram_dout),
        .bram_we(bram_we),
        .bram_en(bram_en)
    );

    // BRAM IP 인스턴스 (기존과 동일)
    blk_mem_gen_0 U_DATA_BRAM (
        .clka(clk),                     // Clock input
        .ena(bram_en),                  // Enable signal
        .wea(bram_we),                  // Write Enable (4-bit byte enable)
        .addra(bram_addr[4:0]),         // Address input (word address, 5-bit for 32 words)
        .dina(bram_din),                // Data input (32-bit)
        .douta(bram_dout)               // Data output (32-bit)
    );

    // Observability Signal Assignments for TB
    assign pc_out = instr_rAddr;
    assign data_addr_out = w_dAddr;
    assign data_wdata_out = w_dData;
    assign data_rdata_out = w_dRdata;
    assign data_wr_en_out = w_wr_en;
    assign store_size_out = w_store_size;
    assign load_size_out = w_load_size;
    
    // Register File 관찰을 위한 신호 연결
    // CPU Core 내부의 datapath에서 register file 출력을 가져옴
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : reg_observe
            assign reg_file_out[i] = U_CPU.U_DP.U_REG_FILE.reg_file[i];
        end
    endgenerate
    
    // ALU 출력 관찰
    assign alu_result_out = U_CPU.U_DP.U_ALU.ALU_Result;
    assign alu_taken_out = U_CPU.U_DP.U_ALU.taken;

endmodule