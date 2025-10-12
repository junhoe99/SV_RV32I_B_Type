`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/22 10:41:43
// Design Name: 
// Module Name: define
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

// All Commands
`define ADD 4'b0000   // ADD
`define SUB 4'b1000   // SUB
`define SLL 4'b0001   // Shift Left Logical
`define SRL 4'b0101   // Shift Right Logical
`define SRA 4'b1101   // Shift Right Arithmetic
`define SLT 4'b0010   // Set Less Than
`define SLTU 4'b0011   // Set Less Than Unsigned
`define XOR 4'b0100    // XOR
`define OR 4'b0110     // OR
`define AND 4'b0111    // AND

// Branch Commands
`define BEQ 3'b000   // Branch if Equal
`define BNE 3'b001   // Branch if Not Equal
`define BLT 3'b100   // Branch if Less Than
`define BGE 3'b101   // Branch if Greater than or Equal
`define BLTU 3'b110   // Branch if Less Than Unsigned
`define BGEU 3'b111  // Branch if Greater than or Equal Unsigned

// 각 type별 opcode 정의  
`define OP_R_TYPE 7'b0110011   // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
`define OP_S_TYPE 7'b0100011   // SW, SH, SB
`define OP_IL_TYPE 7'b0000011  // LW, LH, LB, LBU, LHU
`define OP_I_TYPE 7'b0010011   // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
`define OP_B_TYPE 7'b1100011  // BEQ, BNE, BLT, BGE, BLTU, BGEU
`define OP_U_LUI_TYPE 7'b0110111  // LUI
`define OP_U_AUIPC_TYPE 7'b0010111  // AUIPC
`define OP_J_JAL_TYPE 7'b1101111  // JAL
`define OP_I_JALR_TYPE 7'b1100111  // JALR