`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/19 11:36:34
// Design Name: 
// Module Name: register
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


module register(
    input logic clk,
    input logic rst,
    input logic[31:0] d,
    output logic [31:0] q
    );

    always_ff @(posedge clk or posedge rst)begin
        if(rst)begin
            q <= 0;
        end
        else begin
            q <= d;
        end
    end

endmodule
