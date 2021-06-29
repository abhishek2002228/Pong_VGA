`timescale 1s / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2021 15:29:39
// Design Name: 
// Module Name: tb_vga
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


module tb_vga();
    reg clk4, rst;
    wire [9:0] xcntr, ycntr;
    wire [19:0] cntr;
    wire hsync, vsync, write;
    
    vga v1(clk4, rst, xcntr, ycntr, cntr, hsync, vsync, write);
    always #0.5 clk4 = ~clk4;
    
    initial begin
        clk4 = 0;
        rst = 1;
        #10
        rst = 0;
        #100000000
        $finish;
    end
    
    
endmodule
