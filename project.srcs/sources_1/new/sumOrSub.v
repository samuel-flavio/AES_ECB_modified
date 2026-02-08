`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.12.2025 22:24:42
// Design Name: 
// Module Name: sumOrSub
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
module sumOrSub(
    input [0:7] A,
    input [0:7] B,
    output [0:7] OUT
    );
    
    assign OUT = A^B;
endmodule