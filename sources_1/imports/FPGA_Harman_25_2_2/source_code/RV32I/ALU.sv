`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/19 11:47:48
// Design Name: 
// Module Name: ALU
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

module ALU (
    input logic [31:0] A,
    input logic [31:0] B,
    input logic [3:0]   ALU_Controls,  // Control Unit으로부터 입력되는 신호
    output logic [31:0] ALU_Result,
    output logic taken
);




    always_comb begin
        case (ALU_Controls)
            `ADD:   ALU_Result    = A + B;  // 0. ADD
            `SUB:   ALU_Result    = A - B;  // 1. SUB
            `SLL:   ALU_Result    = A << B[4:0];  // 2. Shift Left Logical
            `SRL:   ALU_Result    = A >> B[4:0];  // 3. Shift Right Logical
            `SRA:   ALU_Result    = $signed(A) >>> B[4:0];  // 4. Shift Right Arithmetic
            `SLT:   ALU_Result    = ($signed(A) < $signed(B)) ? 32'h1 : 32'h0;  // 5. Set Less than (SIGNED)
            `SLTU:  ALU_Result   = ($unsigned(A) < $unsigned(B)) ? 32'h1 : 32'h0;  // 6. Set Less than Unsigned
            `XOR:   ALU_Result    = A ^ B;  // 7. XOR
            `OR:    ALU_Result     = A | B;  // 8. OR
            `AND:   ALU_Result    = A & B;  // 9. AND
            default: ALU_Result = 32'bx;  // X가 나오면 안됨.
        endcase
    end

    always_comb begin
        case(ALU_Controls[2:0])
            `BEQ : taken = ($signed(A) == $signed(B)) ? 1'b1 : 1'b0; // Branch if Equal
            `BNE : taken = ($signed(A) != $signed(B)) ? 1'b1 : 1'b0; // Branch if Not Equal
            `BLT : taken = ($signed(A) < $signed(B)) ? 1'b1 : 1'b0;  // Branch if Less Than
            `BGE : taken = ($signed(A) >= $signed(B)) ? 1'b1 : 1'b0; // Branch if Greater than or Equal
            `BLTU: taken = ($unsigned(A) < $unsigned(B)) ? 1'b1 : 1'b0; // Branch if Less Than Unsigned
            `BGEU: taken = ($unsigned(A) >= $unsigned(B)) ? 1'b1 : 1'b0; // Branch if Greater than or Equal Unsigned
            default: taken = 1'b0; // Branch 명령어가 아닐 때
        endcase
    end


endmodule
