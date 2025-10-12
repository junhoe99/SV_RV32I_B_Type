`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/19 11:55:51
// Design Name: 
// Module Name: instruction
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

// Instruction Memory, 즉 ROM을 설계
module instruction_memory (
    input  logic [31:0] rAddr,
    output logic [31:0] rData
);

    logic [31:0] rom[0:63];  // 64개의 32bit 명령어 저장 가능

    initial begin
        // ===== RV32I 전체 명령어 집합 검증 테스트 =====
        // 모든 instruction type을 최소 1회씩 테스트하여 CPU 동작 완전 검증
        
        // === I-type Instructions (즉시값 연산) ===
        rom[0] = 32'h00500513;   // addi a0, x0, 5      ; a0 = 0 + 5 = 5
        rom[1] = 32'h00750593;   // addi a1, a0, 7      ; a1 = 5 + 7 = 12
        rom[2] = 32'h00252513;   // slti a0, a0, 2      ; a0 = (5 < 2) = 0
        rom[3] = 32'h0ff5b593;   // sltiu a1, a1, 255   ; a1 = (12 < 255) = 1
        rom[4] = 32'h00A54513;   // xori a0, a0, 10     ; a0 = 0 ^ 10 = 10
        rom[5] = 32'h00F5E593;   // ori a1, a1, 15      ; a1 = 1 | 15 = 15
        rom[6] = 32'h00757513;   // andi a0, a0, 7      ; a0 = 10 & 7 = 2
        rom[7] = 32'h00259593;   // slli a1, a1, 2      ; a1 = 15 << 2 = 60
        rom[8] = 32'h0025D513;   // srli a0, a1, 2      ; a0 = 3C >> 2 = 0F
        rom[9] = 32'h4035D593;   // srai a1, a1, 3      ; a1 = 0F >>> 3 = 0x1
        
        // === R-type Instructions (레지스터 연산) ===
        rom[10] = 32'h00B50633;  // add a2, a0, a1      ; a2 = 15(F) + 7 = 16()
        rom[11] = 32'h41060633;  // sub a2, a2, a6      ; a2 = 16 - 10 = 6
        rom[12] = 32'h00181533;  // sll a0, a6, x1      ; a0 = F << (1) = F << 1 = 20
        rom[13] = 32'h00A5A633;  // slt a2, a1, a0      ; a2 = (0 < 15) = 1
        
        // SLT vs SLTU 비교 테스트를 위한 음수값 설정
        rom[14] = 32'hFFF00493;  // addi x9, x0, -1     ; x9 = -1 (0xFFFFFFFF)
        rom[15] = 32'h00952633;  // slt a2, x9, a0      ; slt a2, a0, x9 / a2 = ( 15 < -1 signed) ? 1 : 0 = 0 (양수 < 음수는 거짓)
        rom[16] = 32'h00953633;  // sltu a2, x9, a0     ; a2 = (-1 < 15 unsigned) = (0xFFFFFFFF < 15) = 0 / a2 = (15 < FFFFFFFF) ? 1 : 0 = 1 (15 < 4294967295는 참)
        
        rom[17] = 32'h00A5C633;  // xor a2, a1, a0      ; a2 = 07 ^ 20 = 15(F)
        rom[18] = 32'h00155533;  // srl a0, a0, x1      ; a0 = 32 >> 1 = 16
        rom[19] = 32'h40255533;  // sra a0, a0, x2      ; a0 = 32 >>> (2) = 32 >>> 2 = 8
        rom[20] = 32'h00A5E633;  // or a2, a1, a0       ; a2 = 07 | 04 = 0F
        rom[21] = 32'h00A5F633;  // and a2, a1, a0      ; a2 = 07 & 08 = 00

        // === U-type Instructions (상위 즉시값 로드) ===
        rom[22] = 32'h12345537;  // lui a0, 0x12345     ; a0 = 0x12345000 = 305397760
        rom[23] = 32'h00006597;  // auipc a1, 6         ; a1 = PC + (64 + 12) = 88 + 24576 = 24664
        
        // === Load/Store Instructions ===
        // Store 테스트용 데이터 준비
        rom[24] = 32'h12345537;  // lui a0, 0x12345     ; a0 = 0x12345000
        rom[25] = 32'h67850513;  // addi a0, a0, 0x678  ; a0 = 0x12345678
        rom[26] = 32'h00000593;  // addi a1, x0, 0      ; a1 = 0 (메모리 주소)
        
        // S-type Instructions (Store) - 각각 독립적인 워드에 저장
        rom[27] = 32'h00A5A023;  // sw a0, 0(a1)        ; mem[0] = 0x12345678 (Word 0)
        rom[28] = 32'h00A59223;  // sh a0, 4(a1)        ; mem[4] = 0x5678 (Word 1) 
        rom[29] = 32'h00A58423;  // sb a0, 8(a1)        ; mem[8] = 0x78 (Word 2)
        
        // I-type Load Instructions - 수정된 주소에 맞게 조정
        rom[30] = 32'h0005A683;  // lw a3, 0(a1)        ; a3 = mem[0] = 0x12345678 (Word 0)
        rom[31] = 32'h0045D703;  // lhu a4, 4(a1)       ; a4 = mem[4] = 0x5678 (Word 1, unsigned)
        rom[32] = 32'h00459783;  // lh a5, 4(a1)        ; a5 = mem[4] = 0x5678 (Word 1, signed)
        rom[33] = 32'h00858803;  // lbu a6, 8(a1)       ; a6 = mem[8] = 0x78 (Word 2, unsigned)
        rom[34] = 32'h00858883;  // lb a7, 8(a1)        ; a7 = mem[8] = 0x78 (Word 2, signed)
        
        // === Branch Instructions ===
        // Branch 테스트용 데이터 준비
        rom[35] = 32'h00500513;  // addi a0, x0, 5      ; a0 = 5
        rom[36] = 32'h00500593;  // addi a1, x0, 5      ; a1 = 5
        rom[37] = 32'h00300613;  // addi a2, x0, 3      ; a2 = 3
        
        // B-type Instructions
        rom[38] = 32'h00B50463;  // beq a0, a1, +8      ; if(5==5) jump to rom[40] (skip rom[39])
        rom[39] = 32'h00100693;  // addi a3, x0, 1      ; a3 = 1 (이 명령은 건너뛰어짐)
        rom[40] = 32'h00C51463;  // bne a0, a2, +8      ; if(5!=3) jump to rom[42] (skip rom[41])
        rom[41] = 32'h00200693;  // addi a3, x0, 2      ; a3 = 2 (이 명령은 건너뛰어짐)
        rom[42] = 32'h00C54463;  // blt a0, a2, +8      ; if(5<3) jump (거짓이므로 점프 안하고 PC값은 +4, ROM[43]으로 이동)
        rom[43] = 32'h00C55463;  // bge a0, a2, +8      ; if(5>=3) jump to rom[45] (skip rom[44])
        rom[44] = 32'h00300693;  // addi a3, x0, 3      ; a3 = 3 (이 명령은 건너뛰어짐)
        rom[45] = 32'h00C56463;  // bltu a0, a2, +8     ; if(5<3 unsigned) jump (거짓이므로 점프 안함)
        rom[46] = 32'h00C57463;  // bgeu a0, a2, +8     ; if(5>=3 unsigned) jump to rom[48] (skip rom[47])
        rom[47] = 32'h00400693;  // addi a3, x0, 4      ; a3 = 4 (이 명령은 건너뛰어짐)
        
        // === J-type Instructions (Jump) ===
        rom[48] = 32'h008000EF;  // jal x1, +8          ; x1 = PC+8, jump to rom[50]
        rom[49] = 32'h00500693;  // addi a3, x0, 5      ; a3 = 5 (이 명령은 건너뛰어짐)
        rom[50] = 32'h00008067;  // jalr x0, 0(x1)      ; PC = x1 + 0, jump back to rom[49]+4=rom[51]
        rom[51] = 32'h00600693;  // addi a3, x0, 6      ; a3 = 6
        
        // === 추가 테스트용 명령어 ===
        rom[52] = 32'h00000013;  // nop (addi x0, x0, 0)
        rom[53] = 32'h00000013;  // nop
        
        // Initialize remaining ROM locations
        for (int i = 54; i < 64; i = i + 1) begin
            rom[i] = 32'h00000013; // nop
        end
    end

    assign rData = rom[rAddr[31:2]]; // ROM은 word align 형태이므로, 주소의 하위 2비트는 무시하고 사용
endmodule







