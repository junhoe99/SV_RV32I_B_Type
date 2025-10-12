`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/22 14:41:33
// Design Name: 
// Module Name: mux_2x1
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


module mux_2x1(
    input logic sel,
    input logic [31:0] in0,
    input logic [31:0] in1,
    output logic [31:0] out
);

    always_comb begin
        case (sel)
            1'b0: out = in0; // reg_file2
            1'b1: out = in1; // imm_Ext
            default: out = 32'bx;
        endcase
    end

endmodule
