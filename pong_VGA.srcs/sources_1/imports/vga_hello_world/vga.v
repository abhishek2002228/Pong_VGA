module vga(clk4, rst, xcntr, ycntr, hsync, vsync, write);
    input wire clk4, rst;
    output reg [9:0] xcntr, ycntr; //640 needs 10 bits to represent
    output wire hsync, vsync, write;

    //parameters for 640x400 @ 70Hz
    //calculations (640(dp)+16(fp)+96(hsync)+48(bp) = 800) * (400(dp)+12(fp)+2(vsync)+35(bp) = 449)
    //screen res = 800x449 and image res = 640x400

    parameter HA_END = 639; //visible area
    parameter HS_START = HA_END + 16; //Horizontal Sync start
    parameter HS_END = HS_START + 96;
    parameter LINE = 799; //or HS_END + 48

    parameter VA_END = 399; //visible area
    parameter VS_START = VA_END + 12; //Vertical Sync start
    parameter VS_END = VS_START + 2;
    parameter SCREEN = 448; //or HS_END + 48

    //counters (position in screen)
    always @(posedge clk4 or posedge rst)
    begin
        if(rst)
        begin
            xcntr <= 0;
            ycntr <= 0;
        end
        else
        begin
            if(xcntr==LINE)
            begin
                xcntr <= 0;
                ycntr <= (ycntr==SCREEN) ? 0 : ycntr + 1;
            end
            else
            begin
                xcntr <= xcntr + 1;
            end
        end
    end


    assign hsync = ~(xcntr >= HS_START && xcntr < HS_END); //active low
    assign vsync = (ycntr >= VS_START && ycntr <VS_END); //active high
    assign write = (xcntr <= HA_END && ycntr <= VA_END); //visible area
endmodule