`timescale 1ns/1ps

module vga_pic(
    input wire vga_clk , //VGA working clock, 25MHz
    input wire sys_rst_n , //Reset signal. Low level is effective
    input wire [9:0] pix_x , //X coordinate of current pixel
    input wire [9:0] pix_y , //Y coordinate of current pixel
    output reg [15:0] pix_data //Color information
);

////
//\* Parameter and Internal Signal \//
////
//parameter define
parameter H_VALID = 10'd640 , //Maximum x value
          V_VALID = 10'd480 ; //Maximum y value

parameter WHITE = 16'hFFFF, //White
          BLACK = 16'h0000; //Black

parameter CHAR_WIDTH = 64;      
parameter CHAR_HEIGHT = 64;       
parameter CHAR_SPACING = 32;    


parameter M_START_X = (H_VALID - (4*CHAR_WIDTH + 3*CHAR_SPACING)) / 2;
parameter U_START_X = M_START_X + CHAR_WIDTH + CHAR_SPACING;
parameter S_START_X = U_START_X + CHAR_WIDTH + CHAR_SPACING;  
parameter T_START_X = S_START_X + CHAR_WIDTH + CHAR_SPACING;
parameter CHAR_START_Y = (V_VALID - CHAR_HEIGHT) / 2;


wire [3:0] char_sel;  
wire [5:0] char_x;    
wire [5:0] char_y;    
wire char_pixel;      

////
//\* Main Code \//
////


assign char_sel = (pix_x >= M_START_X && pix_x < M_START_X + CHAR_WIDTH && 
                   pix_y >= CHAR_START_Y && pix_y < CHAR_START_Y + CHAR_HEIGHT) ? 4'd1 :
                  (pix_x >= U_START_X && pix_x < U_START_X + CHAR_WIDTH && 
                   pix_y >= CHAR_START_Y && pix_y < CHAR_START_Y + CHAR_HEIGHT) ? 4'd2 :
                  (pix_x >= S_START_X && pix_x < S_START_X + CHAR_WIDTH && 
                   pix_y >= CHAR_START_Y && pix_y < CHAR_START_Y + CHAR_HEIGHT) ? 4'd3 :
                  (pix_x >= T_START_X && pix_x < T_START_X + CHAR_WIDTH && 
                   pix_y >= CHAR_START_Y && pix_y < CHAR_START_Y + CHAR_HEIGHT) ? 4'd4 : 4'd0;


assign char_x = (char_sel != 0) ? (pix_x - 
                 (char_sel == 1 ? M_START_X : 
                  char_sel == 2 ? U_START_X :
                  char_sel == 3 ? S_START_X : T_START_X)) : 6'd0;
assign char_y = (char_sel != 0) ? (pix_y - CHAR_START_Y) : 6'd0;


//Generate color data according coordinates
always@(posedge vga_clk or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
        pix_data <= 16'd0;
    else begin
        if(char_pixel) 
            pix_data <= WHITE;  
        else
            pix_data <= BLACK;  
    end
end

endmodule
