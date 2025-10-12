`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/22 14:27:03
// Design Name: 
// Module Name: extend
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

`include "define.sv"

module extend (
    input [31:0] instr_code,
    output logic [31:0] imm_Ext
);

    wire [6:0] opcode = instr_code[6:0];
    wire [3:0] funct3 = instr_code[14:12];


    //function3값에 따라, sb, sh, sw 구분해야함


    always_comb begin
        case (opcode)
            `OP_R_TYPE:
            imm_Ext = 32'bx  ; // R-type 명령어는 immediate 값이 없으므로 X 처리
            
            `OP_S_TYPE:
            imm_Ext = {
                {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
            };  // S-type 명령어의 immediate 값 추출 및 확장. sign-extends
            
            `OP_IL_TYPE:
            imm_Ext = {
                {20{instr_code[31]}}, instr_code[31:20]
            };  // I-type Load 명령어의 immediate 값 추출 및 확장. sign-extends
            
            `OP_I_TYPE: begin
                imm_Ext = {{20{instr_code[31]}}, instr_code[31:20]};  // I-type ALU 명령어의 immediate 값 추출 및 확장. sign-extends
            end
            
            `OP_B_TYPE:
            imm_Ext = {
                {20{instr_code[31]}}, instr_code[7], instr_code[30:25], instr_code[11:8], 1'b0
            };  // B-type 명령어의 immediate 값 추출 및 확장.
                // imm[12|10:5|4:1|11|0] 형태로 비트들이 흩어져 있으므로 이를 재조합
            
            `OP_U_LUI_TYPE:
            imm_Ext = {instr_code[31:12], 12'b0}; // U-type LUI 명령어의 immediate 값 추출 및 확장. 상위 20비트는 그대로, 하위 12비트는 0으로 채움
            
            `OP_U_AUIPC_TYPE:
            imm_Ext = {instr_code[31:12], 12'b0}; // U-type AUIPC 명령어의 immediate 값 추출 및 확장. 상위 20비트는 그대로, 하위 12비트는 0으로 채
            
            `OP_J_JAL_TYPE:
            imm_Ext = {
                {12{instr_code[31]}}, instr_code[19:12], instr_code[20], instr_code[30:21], 1'b0
            }; // J-type JAL 명령어의 immediate 값 추출 및 확장.
                // imm[20|10:1|11|19:12|0] 형태로 비트들이 흩어져 있으므로 이를 재조합
            
            `OP_I_JALR_TYPE:
            imm_Ext = {
                {20{instr_code[31]}}, instr_code[31:20]
            };  // I-type JALR 명령어의 immediate 값 추출 및 확장. sign-extends
            
            default: begin
                imm_Ext = 32'bx; // 정의되지 않은 명령어에 대해선 X 처리
            end
        endcase
    end
endmodule



// Computing Architecture에서 Extend의 종류
// 1. MSB Extend(Sign Extends)  : 부호 비트를 최상위 비트로 확장 (부호 확장 표현에 사용)
// 2. Zero-Extend               : 최상위 비트를 0으로 확장 (양수 표현에 사용)
// 3. Padding                   : 특정 패턴으로 확장 (비트 필드 정렬에 사용)
