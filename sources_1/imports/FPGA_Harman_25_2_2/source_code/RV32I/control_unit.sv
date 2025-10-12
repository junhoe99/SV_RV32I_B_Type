`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/19 13:49:27
// Design Name: 
// Module Name: control_unit
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

module control_unit (
    input logic [31:0] instr_code,
    output logic [3:0] ALU_Controls,
    output logic reg_wr_en,
    output logic ALUSrcMuxSel,
    output logic d_wr_en,
    output logic [2:0] RAM2RegWSel, // 0: ALU_Result, 1: dRdata, 2: LUI, 3: AUIPC, 4: JAL/JALR
    output logic [1:0] store_size,  // 00: sb(8bit), 01: sh(16bit), 10: sw(32bit),
    output logic [1:0] load_size,  // 00: lb(8bit signed), 01: lh(16bit signed), 10: lw(32bit), 11: lbu(8bit unsigned)
    output logic branch,
    output logic JAL,
    output logic JALR
);


    // controls 
    // 3-bit control signal for ALU operation
    wire  [6:0] funct7 = instr_code[31:25];
    wire  [2:0] funct3 = instr_code[14:12];
    wire  [6:0] opcode = instr_code[6:0];


    logic [8:0] controls;
    assign {RAM2RegWSel, ALUSrcMuxSel, reg_wr_en, d_wr_en, branch, JAL, JALR} = controls;


    always_comb begin
        case (opcode)
            `OP_R_TYPE:
            controls = 9'b000010000;  // R-type: (RAM2RegWSel=3'b000, ALUSrcMuxSel=0, reg_wr_en=1, d_wr_en=0, branch=0, JAL=0, JALR=0)
            `OP_S_TYPE:
            controls = 9'b000101000;  // S-type: (RAM2RegWSel=3'b000, ALUSrcMuxSel=1, reg_wr_en=0, d_wr_en=1, branch=0, JAL=0, JALR=0)
            `OP_IL_TYPE:
            controls = 9'b001110000;  // IL-type Load: (RAM2RegWSel=3'b001, ALUSrcMuxSel=1, reg_wr_en=1, d_wr_en=0, branch=0, JAL=0, JALR=0)
            `OP_I_TYPE:
            controls = 9'b000110000;  // I-type ALU: (RAM2RegWSel=3'b000, ALUSrcMuxSel=1, reg_wr_en=1, d_wr_en=0, branch=0, JAL=0, JALR=0)
            `OP_B_TYPE:
            controls = 9'b000000100;  // B-type: (RAM2RegWSel=3'b000, ALUSrcMuxSel=0, reg_wr_en=0, d_wr_en=0, branch=1, JAL=0, JALR=0)
            `OP_U_LUI_TYPE:
            controls = 9'b010110000;  // U-type LUI: (RAM2RegWSel=3'b010, ALUSrcMuxSel=1, reg_wr_en=1, d_wr_en=0, branch=0, JAL=0, JALR=0)
            `OP_U_AUIPC_TYPE:
            controls = 9'b011110000;  // U-type AUIPC: (RAM2RegWSel=3'b011, ALUSrcMuxSel=1, reg_wr_en=1, d_wr_en=0, branch=0, JAL=0, JALR=0)
            `OP_J_JAL_TYPE:
            controls = 9'b100010110;  // JAL: (RAM2RegWSel=3'b100, ALUSrcMuxSel=0, reg_wr_en=1, d_wr_en=0, branch=0, JAL=1, JALR=0)
            `OP_I_JALR_TYPE:
            controls = 9'b100010101;  // JALR: (RAM2RegWSel=3'b100, ALUSrcMuxSel=0, reg_wr_en=1, d_wr_en=0, branch=0, JAL=0, JALR=1)

        default: controls = 9'b000000000;
        endcase
    end

    // Write size control for S-type instructions based on funct3
    always_comb begin
        if (opcode == `OP_S_TYPE) begin
            case (funct3)
                3'b000:  store_size = 2'b00;  // sb (8-bit)
                3'b001:  store_size = 2'b01;  // sh (16-bit)
                3'b010:  store_size = 2'b10;  // sw (32-bit)
                default: store_size = 2'b10;  // default to sw
            endcase
        end else begin
            store_size = 2'b10;  // default to 32-bit for non S-type
        end
    end

    // Load size control for I-type Load instructions only
    always_comb begin
        if (opcode == `OP_IL_TYPE) begin
            case (funct3)
                3'b000:  load_size = 2'b00;  // lb (8-bit signed)
                3'b001:  load_size = 2'b01;  // lh (16-bit signed)
                3'b010:  load_size = 2'b10;  // lw (32-bit)
                3'b100:  load_size = 2'b11;  // lbu (8-bit unsigned)
                3'b101:  load_size = 2'b01;  // lhu (16-bit, unsigned는 data_memory에서 funct3로 구분)
                default: load_size = 2'b10;  // default to lw
            endcase
        end else begin
            load_size = 2'b10;  // default to lw for non-load instructions
        end
    end


    // ALU control signal generation
    always_comb begin
        case (opcode)
            //funct7[5], funct3[2:0]
            `OP_R_TYPE: ALU_Controls = {funct7[5], funct3};  // R-type. 
            `OP_S_TYPE: ALU_Controls = `ADD;  // S-type (always ADD)
            `OP_IL_TYPE: ALU_Controls = `ADD;  // IL-type Load (always ADD)
            `OP_I_TYPE: begin  // SLLI, SRLI, SRA은 구분이 필요. 
                if ({funct7[5], funct3} == 4'b1101) begin  // SRAI
                    ALU_Controls = {1'b1, funct3};  // SRAI
                end else  // SRLI, SLLI
                    ALU_Controls = {
                        1'b0, funct3
                    };  // I-type ALU (other than shifts)
            end
            `OP_B_TYPE:
            ALU_Controls = {
                1'b0, funct3
            };  //funct3만 나가면 되고, 0은 그냥 ALU_controls가 4비트라서 채운거
            `OP_U_LUI_TYPE: ALU_Controls = `ADD;  // LUI (ALU does not matter, just pass imm)
            `OP_U_AUIPC_TYPE: ALU_Controls = `ADD;  // AUIPC (ALU adds PC + imm)
            // JAL, JALR: ALU does not matter, just pass PC + 4
            `OP_J_JAL_TYPE: ALU_Controls = `ADD;  // JAL
            `OP_I_JALR_TYPE: ALU_Controls = `ADD;  // JALR
            default: ALU_Controls = 4'bx;  // Default to ADD
        endcase
    end


endmodule
