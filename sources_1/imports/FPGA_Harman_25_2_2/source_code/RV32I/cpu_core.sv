`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/19 14:15:41
// Design Name: 
// Module Name: cpu_core
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


module cpu_core (
    input logic clk,
    input logic rst,
    input logic [31:0] instr_code,
    input logic [31:0] dRdata,  // 데이터 메모리에서 읽은 데이터
    output logic [31:0] instr_rAddr,
    output logic d_wr_en,
    output logic [31:0] dAddr,
    output logic [31:0] dWdata,
    output logic [1:0] store_size,
    output logic [1:0] load_size  // LW 명령어에 해당하는 load_size 설정
);


    wire [31:0] w_instr_code;
    wire [3:0] w_ALU_Controls;
    wire w_reg_wr_en;
    wire w_ALUSrcMuxSel;
    wire [2:0] w_RAM2RegWSel; // 3비트로 확장
    wire [31:0] w_pc;
    wire w_branch;
    wire w_JAL;
    wire w_JALR;

    assign w_instr_code = instr_code;
    assign instr_rAddr  = w_pc;



    datapath U_DP (
        .clk(clk),
        .rst(rst),
        //Instruction
        .instr_code(w_instr_code),
        //Control signals
        .ALU_Controls(w_ALU_Controls),
        .ALUSrcMuxSel(w_ALUSrcMuxSel),
        .RAM2RegWSel(w_RAM2RegWSel),
        .branch(w_branch),
        .JAL(w_JAL),
        .JALR(w_JALR),
        .dRdata(dRdata),
        .reg_wr_en(w_reg_wr_en),
        .instr_rAddr(w_pc),
        .dAddr(dAddr),
        .dWdata(dWdata)
    );

    control_unit U_CU (
        .instr_code(w_instr_code),
        .ALU_Controls(w_ALU_Controls),
        .reg_wr_en(w_reg_wr_en),  //reg_file의 write enable
        .ALUSrcMuxSel(w_ALUSrcMuxSel),
        .RAM2RegWSel(w_RAM2RegWSel),
        .d_wr_en(d_wr_en),  // RAM의 write enable
        .store_size(store_size),
        .load_size(load_size),  // LW 명령어에 해당하는 load_size 설정
        .branch(w_branch),
        .JAL(w_JAL),
        .JALR(w_JALR)
    );



endmodule
