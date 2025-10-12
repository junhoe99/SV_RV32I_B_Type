`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/19 11:40:05
// Design Name: 
// Module Name: register_file
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


module register_file (
    input logic clk,
    input logic rst,  // reset 신호 추가
    //Inputs
    input logic [4:0] RA1,   //Read address가 5bit인 이유? 32개의 레지스터를 5bit로 표현 가능
    input logic [4:0] RA2,
    input logic [4:0] WA,
    input logic       reg_wr_en,
    input logic [31:0] WData,
    //Outputs
    output logic [31:0] RD1,
    output logic [31:0] RD2
);

    logic [31:0] reg_file[0:31];  //32개의 32bit 레지스터. RISC-V는 일반적으로 32개의 32비트 레지스터를 가짐

    //Write operation과 Reset 로직 결합
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset 시 레지스터 초기화 (S-type 비트 절단 효과 확인용)
            reg_file[0] <= 32'h00000000;  // x0: 항상 0
            reg_file[1] <= 32'h00000001;  
            reg_file[2] <= 32'h00000002; 
            reg_file[3] <= 32'h00000003; 
            reg_file[4] <= 32'h00000004; 
            reg_file[5] <= 32'h00000005; 
            reg_file[6] <= 32'h00000006; 
            reg_file[7] <= 32'h00000007;  
            reg_file[8] <= 32'h00000008;  
            reg_file[9] <= 32'h00000009; 
            reg_file[10] <= 32'h0000000A;  
            reg_file[11] <= 32'h0000000B;
            reg_file[12] <= 32'h0000000C;
            reg_file[13] <= 32'h0000000D;
            reg_file[14] <= 32'h0000000E;
            reg_file[15] <= 32'h0000000F;
            reg_file[16] <= 32'h00000010;
            reg_file[17] <= 32'h00000011;
            reg_file[18] <= 32'h00000012;
            reg_file[19] <= 32'h00000013;
            reg_file[20] <= 32'h00000014;
            reg_file[21] <= 32'h00000015;
            reg_file[22] <= 32'h00000016;
            reg_file[23] <= 32'h00000017;
            reg_file[24] <= 32'h00000018;
            reg_file[25] <= 32'h00000019;
            reg_file[26] <= 32'h0000001A;
            reg_file[27] <= 32'h0000001B;
            reg_file[28] <= 32'h0000001C;
            reg_file[29] <= 32'h0000001D;
            reg_file[30] <= 32'h0000001E;
            reg_file[31] <= 32'h0000001F;
        end
            else begin
            // 정상 동작 시 write operation
            if(reg_wr_en && WA != 5'b00000) begin  // x0 레지스터에는 쓰기 금지
                reg_file[WA] <= WData;
            end
        end
    end


    //Read operation - x0는 항상 0 반환
    assign RD1 = (RA1 == 5'b00000) ? 32'h00000000 : reg_file[RA1];
    assign RD2 = (RA2 == 5'b00000) ? 32'h00000000 : reg_file[RA2];
endmodule
