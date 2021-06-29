module top(p1_up, p1_down, p2_up, p2_down, clk, reset, vga_hsync, vga_vsync, vga_r, vga_g, vga_b);
    input wire p1_up, p1_down, p2_up, p2_down;
    input wire clk, reset;
    output reg vga_hsync, vga_vsync;
    output reg [3:0] vga_r, vga_g, vga_b; //nexysA7 uses 12 bits for data
    
    wire up1, down1, up2, down2;
    
    Debounce_Switch db1(clk, p1_up, up1);
    Debounce_Switch db2(clk, p1_down, down1);
    Debounce_Switch db3(clk, p2_up, up2);
    Debounce_Switch db4(clk, p2_down, down2);

    wire clk4;
    clk_div c1(clk,reset, clk4);

    wire [9:0] xcntr, ycntr;
    wire hsync, vsync, write;

    vga v1(clk4, reset, xcntr, ycntr, hsync, vsync, write);
    parameter RES_X = 640;
    parameter RES_Y = 400;
    //pixel generation circuit
    wire update_frame = (ycntr == RES_Y && xcntr == 0);
    
    parameter black_space_L = 9;
    parameter black_space_R = 630;
    wire black_space_on = (xcntr <= black_space_L) || (xcntr >= black_space_R);
    wire [11:0] black_space_colour = 0;
    
    parameter middle_space_L = (RES_X)/2 - 2;
    parameter middle_space_R = (RES_X)/2 + 2;
    wire middle_space_on = (xcntr >= middle_space_L) && (xcntr <= middle_space_R);
    wire [11:0] middle_space_colour = 12'hFFF;
    
    //wall
    parameter LWALL_L = 10;
    parameter LWALL_R = 12;
    parameter RWALL_L = 627;
    parameter RWALL_R = 629;
    
    reg p1_col, p2_col;
    
    wire wall_on = (xcntr >= LWALL_L && xcntr <= LWALL_R) || (xcntr >= RWALL_L && xcntr <= RWALL_R) ; // WALL_R - WALL_L + 1 pixels wide
    wire [3:0] wall_r, wall_g, wall_b;
    wire [11:0] wall_colour;
    assign wall_r = 4'b1111;
    assign wall_g = 0;
    assign wall_b = 0;
    assign wall_colour = {wall_r, wall_g, wall_b};
    
    //paddle
    parameter pad2_L = 617;
    parameter pad2_R = 623;
    parameter pad1_L = 16;
    parameter pad1_R = 22; 
    parameter pad_len = 70;
    //parameter pad_T = (RES_Y/2) - (pad_len/2);
    //parameter pad_B = pad_T + pad_len - 1;
    parameter pad_V = 1;
    reg [9:0] pad1_t, pad2_t;

    wire pad1_on = (xcntr >= pad1_L && xcntr <= pad1_R) && (ycntr >= pad1_t && ycntr <= pad1_t + pad_len - 1);
    wire pad2_on = (xcntr >= pad2_L && xcntr <= pad2_R) && (ycntr >= pad2_t && ycntr <= pad2_t + pad_len - 1);
    wire [3:0] pad_r, pad_g, pad_b;
    assign pad_r = 4'hF;
    assign pad_g = 4'hF;
    assign pad_b = 4'hF;
    wire [11:0] pad_colour = {pad_r, pad_g, pad_b};
    
    always @(posedge clk4 or posedge reset)
    begin
        if(reset)
            pad1_t <= 0;
        else
            if(update_frame)
                if(down1 && (pad1_t + pad_len + pad_V < RES_Y))
                    pad1_t <=  pad1_t + pad_V;
                else if(up1 && (pad1_t > pad_V))    
                    pad1_t <= pad1_t - pad_V;
    end
    
    always @(posedge clk4 or posedge reset)
    begin
        if(reset)
            pad2_t <= 0;
        else
            if(update_frame)
                if(down2 && (pad2_t + pad_len + pad_V < RES_Y))
                    pad2_t <=  pad2_t + pad_V;
                else if(up2 && (pad2_t > pad_V))    
                    pad2_t <= pad2_t - pad_V;
    end
    
    //ball
    parameter ball_size = 8;
    parameter ball_L = 550;
    parameter ball_T = (RES_Y/2) - (ball_size/2);
    parameter ball_B = ball_T + ball_size - 1;
    parameter ball_R = ball_L + ball_size - 1;
    
    reg [9:0] bx, by;
    reg dx, dy;
    wire [9:0] spx = 1;
    wire [9:0] spy = 1;  
    
    wire ball_on = (xcntr >= bx) && (xcntr <= bx + ball_size - 1) && (ycntr >= by) && (ycntr <= by + ball_size -1);
    wire [3:0] ball_r, ball_g, ball_b;
    assign ball_r = 0;
    assign ball_g = 0;
    assign ball_b = 0;
    wire [11:0] ball_colour = {ball_r, ball_g, ball_b};

//detect collisions while drawing on screen, update ball position during update_frame period
// collision values set to 0 in the next update_frame period.
// This mechanism allows us to draw the collision on screen and subsequently update the position of ball

        
    always @(posedge clk4 or posedge reset)
    begin
        if(reset)
        begin
            bx <= 0;
            by <= 0;
            dx <= 0;
            dy <= 0;
        end
        else
        begin
            if(update_frame)
            begin
                if(p1_col)
                begin
                    dx <= 0;
                    bx <= bx + spx;
                end
                else if(p2_col)
                begin
                    dx <= 1;
                    bx <= bx - spx;
                end    
                else if (bx >= RWALL_L - (spx + ball_size))
                begin
                    dx <= 1;
                    bx <= bx - spx;
                end 
                else if (bx < (spx + LWALL_R))
                begin
                    dx <= 0;
                    bx <= bx + spx;
                end 
                else bx <= (dx) ? bx - spx : bx + spx;
    
                if (by >= RES_Y - (spy + ball_size)) 
                begin
                    dy <= 1;
                    by <= by - spy;
                end 
                else if (by < spy) 
                begin
                    dy <= 0;
                    by <= by + spy;
                end 
                else by <= (dy) ? by - spy : by + spy;         
            end
        end
    end
    
    //round ball
    wire [9:0] ball_t = by;
    wire [9:0] ball_l = bx;
    wire [2:0] rom_addr;
    reg [7:0] rom_data;
    wire rom_pixel;
    wire [3:0] round_ball_r = 4'b1111;
    wire [3:0] round_ball_g = 0;
    wire [3:0] round_ball_b = 0;
    wire [11:0] round_ball_colour = ball_colour;
    
    assign rom_addr = ycntr[2:0] - ball_t[2:0];
    wire [2:0] rom_col = xcntr[2:0] - ball_l[2:0];
    wire [7:0] temp = rom_data << rom_col;
    assign rom_pixel = temp[7];
    wire round_ball_on = ball_on && rom_pixel;

    
    always @(posedge clk4 or posedge reset)
    begin
        if(update_frame || reset)
        begin
            p1_col <= 0;
            p2_col <= 0;
        end
        else if(round_ball_on)
        begin
            if(pad1_on) p1_col <= 1; 
            if(pad2_on) p2_col <= 1;
        end
    end
    always @(*)
    begin
        case(rom_addr)
            3'h0: rom_data = 8'b00111100;
            3'h1: rom_data = 8'b01111110;
            3'h2: rom_data = 8'b11111111;
            3'h3: rom_data = 8'b11111111;
            3'h4: rom_data = 8'b11111111;
            3'h5: rom_data = 8'b11111111;
            3'h6: rom_data = 8'b01111110;
            3'h7: rom_data = 8'b00111100;
            default: rom_data = 8'h0;
        endcase        
    end
    
    //background
    wire [3:0] bg_r, bg_g, bg_b;
    assign bg_r = 0;
    assign bg_g = 4'hF;
    assign bg_b = 0;
    wire [11:0] bg_colour = {bg_r, bg_g, bg_b}; 
    
    
    //multiplexing
    always @(posedge clk4)
    begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        if(~write)
        begin
            {vga_r, vga_g, vga_b} <= 0;
        end
        else
        begin
            if(wall_on)
                {vga_r, vga_g, vga_b} <= wall_colour;
            else if(pad1_on)
                {vga_r, vga_g, vga_b} <= pad_colour;
            else if(pad2_on)
                {vga_r, vga_g, vga_b} <= pad_colour;                
            else if(round_ball_on)
                {vga_r, vga_g, vga_b} <= round_ball_colour;
            else if(black_space_on)
                {vga_r, vga_g, vga_b} <= black_space_colour;
            else if(middle_space_on)
                {vga_r, vga_g, vga_b} <= middle_space_colour;            
            else
                {vga_r, vga_g, vga_b} <= bg_colour;                           
        end
    end
    
endmodule