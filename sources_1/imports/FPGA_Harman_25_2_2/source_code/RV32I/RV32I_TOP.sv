`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/22 11:24:47
// Design Name: 
// Module Name: RV32I_TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RV32I_TOP(
    input logic clk,
    input logic rst
    );

    logic [31:0] w_instr_code, w_instr_rAddr;
    logic [3:0] w_ALU_Controls;
    logic w_wr_en;
    logic [31:0] w_dAddr, w_dData;
    logic [1:0] w_store_size;
    logic [31:0] w_dRdata;
    logic [1:0] w_load_size; // LW 명령어에 해당하는 load_size 설정
    
    // BRAM IP 연결 신호들
    logic [31:0] bram_addr;
    logic [31:0] bram_din;
    logic [31:0] bram_dout;
    logic [3:0] bram_we;
    logic bram_en;
  

    instruction_memory U_IM (
        .rAddr(w_instr_rAddr),
        .rData(w_instr_code)
    );

    cpu_core U_CPU (
        .clk(clk),
        .rst(rst),
        .instr_code(w_instr_code),
        .instr_rAddr(w_instr_rAddr),
        .dRdata(w_dRdata),
        .d_wr_en(w_wr_en),
        .dAddr(w_dAddr),
        .dWdata(w_dData),
        .store_size(w_store_size),
        .load_size(w_load_size) // LW 명령어에 해당하는 load_size 설정
    );

    data_memory U_DM (
        .clk(clk),
        .d_wr_en(w_wr_en),
        .dAddr(w_dAddr),
        .dWdata(w_dData),
        .store_size(w_store_size),
        .load_size(w_load_size),
        .instr_code(w_instr_code),
        .dRdata(w_dRdata),
        // BRAM IP 인터페이스 신호들
        .bram_addr(bram_addr),
        .bram_din(bram_din),
        .bram_dout(bram_dout),
        .bram_we(bram_we),
        .bram_en(bram_en)
    );

    // BRAM IP 인스턴스 (blk_mem_gen_0는 Vivado에서 생성된 IP 이름)
    blk_mem_gen_0 U_DATA_BRAM (
        .clka(clk),           // Clock input
        .ena(bram_en),        // Enable signal
        .wea(bram_we),        // Write Enable (4-bit byte enable)
        .addra(bram_addr[4:0]), // Address input (word address, 5-bit for 32 words)
        .dina(bram_din),      // Data input (32-bit)
        .douta(bram_dout)     // Data output (32-bit)
    );

endmodule
