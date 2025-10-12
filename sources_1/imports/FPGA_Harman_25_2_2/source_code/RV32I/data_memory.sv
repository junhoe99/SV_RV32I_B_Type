`timescale 1ns / 1ps

// Data Memory Controller - BRAM IP 인터페이스 및 로드/확장 처리 전담
// BRAM IP는 WRITE_FIRST 모드로 설정되어 있어야 함
module data_memory (
    input logic clk,
    input logic d_wr_en,
    input logic [31:0] dAddr,
    input logic [31:0] dWdata,
    input logic [1:0] store_size,
    input logic [1:0] load_size,  // 00: lb(8bit signed), 01: lh(16bit signed), 10: lw(32bit), 11: lbu(8bit unsigned)
    input logic [31:0] instr_code,  // funct3 확인용
    output logic [31:0] dRdata,
    
    // BRAM IP 인터페이스 신호들
    output logic [31:0] bram_addr,
    output logic [31:0] bram_din,
    input logic [31:0] bram_dout,
    output logic [3:0] bram_we,
    output logic bram_en
);

    // BRAM 주소 변환 (byte address -> word address)
    // BRAM IP는 5-bit 주소를 사용하므로 [4:0]만 필요
    assign bram_addr = {{27{1'b0}}, dAddr[6:2]};  // 5-bit word address for BRAM
    assign bram_en = 1'b1;  // Always enable BRAM

    // Write enable generation and data alignment for BRAM
    logic [1:0] byte_offset;
    assign byte_offset = dAddr[1:0];
    
    always_comb begin
        bram_we = 4'b0000;  // Default: no write
        bram_din = 32'b0;   // Default data
        
        if (d_wr_en) begin
            case (store_size)
                2'b00: begin  // sb (8-bit store) - Little Endian
                    case (byte_offset)
                        2'b00: begin  // Byte 0 (LSB)
                            bram_we = 4'b0001;
                            bram_din = {24'h000000, dWdata[7:0]};
                        end
                        2'b01: begin  // Byte 1
                            bram_we = 4'b0010;
                            bram_din = {16'h0000, dWdata[7:0], 8'h00};
                        end
                        2'b10: begin  // Byte 2  
                            bram_we = 4'b0100;
                            bram_din = {8'h00, dWdata[7:0], 16'h0000};
                        end
                        2'b11: begin  // Byte 3 (MSB)
                            bram_we = 4'b1000;
                            bram_din = {dWdata[7:0], 24'h000000};
                        end
                    endcase
                end
                2'b01: begin  // sh (16-bit store) - Little Endian
                    case (byte_offset[1])
                        1'b0: begin  // Lower halfword (bytes 1:0)
                            bram_we = 4'b0011;
                            bram_din = {16'h0000, dWdata[15:0]};
                        end
                        1'b1: begin  // Upper halfword (bytes 3:2)  
                            bram_we = 4'b1100;
                            bram_din = {dWdata[15:0], 16'h0000};
                        end
                    endcase
                end
                2'b10: begin  // sw (32-bit store)
                    bram_we = 4'b1111;
                    bram_din = dWdata;
                end
                default: begin
                    bram_we = 4'b1111;
                    bram_din = dWdata;
                end
            endcase
        end
    end

    // 데이터 로드 처리 로직 (Write-First 모드 활용)
    // Write-First 모드에서는 BRAM 출력이 쓰기 즉시 반영되므로 
    // 복잡한 bypass 로직이 불필요함
    data_load_extension_unit u_load_ext (
        .bram_dout(bram_dout),  // BRAM 출력을 직접 사용
        .dAddr(dAddr),
        .load_size(load_size),
        .instr_code(instr_code),
        .dRdata(dRdata)
    );

endmodule

// 데이터 로드 및 확장 처리 전용 모듈
module data_load_extension_unit (
    input logic [31:0] bram_dout,
    input logic [31:0] dAddr,
    input logic [1:0] load_size,
    input logic [31:0] instr_code,
    output logic [31:0] dRdata
);

    logic [1:0] byte_offset;
    logic [2:0] funct3;
    assign byte_offset = dAddr[1:0];
    assign funct3 = instr_code[14:12];

    // LB, LH, LW, LBU, LHU에 따른 데이터 로드 및 extension 처리
    always_comb begin
        case (load_size)
            2'b00: begin  // lb (8-bit signed load)
                case (byte_offset)
                    2'b00: dRdata = {{24{bram_dout[7]}}, bram_dout[7:0]};
                    2'b01: dRdata = {{24{bram_dout[15]}}, bram_dout[15:8]};
                    2'b10: dRdata = {{24{bram_dout[23]}}, bram_dout[23:16]};
                    2'b11: dRdata = {{24{bram_dout[31]}}, bram_dout[31:24]};
                endcase
            end
            2'b01: begin  // lh (16-bit signed) or lhu (16-bit unsigned)
                if (funct3 == 3'b101) begin  // lhu (unsigned)
                    case (byte_offset[1])
                        1'b0: dRdata = {16'h0000, bram_dout[15:0]};
                        1'b1: dRdata = {16'h0000, bram_dout[31:16]};
                    endcase
                end else begin  // lh (signed)
                    case (byte_offset[1])
                        1'b0: dRdata = {{16{bram_dout[15]}}, bram_dout[15:0]};
                        1'b1: dRdata = {{16{bram_dout[31]}}, bram_dout[31:16]};
                    endcase
                end
            end
            2'b10: begin  // lw (32-bit load)
                dRdata = bram_dout;
            end
            2'b11: begin  // lbu (8-bit unsigned load)
                case (byte_offset)
                    2'b00: dRdata = {24'h000000, bram_dout[7:0]};
                    2'b01: dRdata = {24'h000000, bram_dout[15:8]};
                    2'b10: dRdata = {24'h000000, bram_dout[23:16]};
                    2'b11: dRdata = {24'h000000, bram_dout[31:24]};
                endcase
            end
            default: begin
                dRdata = bram_dout;
            end
        endcase
    end

endmodule
