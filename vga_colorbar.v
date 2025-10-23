`timescale 1ns/1ps

module vga_colorbar(
    input wire sys_clk,        // System Clock, 50MHz
    input wire sys_rst_n,      // Reset signal. Low level is effective
    output wire hsync,         // Line sync signal
    output wire vsync,         // Field sync signal
    output wire [15:0] rgb     // RGB565 color data
);

    // Internal signals
    wire vga_clk;              // VGA working clock, 25MHz
    wire [9:0] pix_x;          // x coordinate of current pixel
    wire [9:0] pix_y;          // y coordinate of current pixel
    wire [15:0] pix_data;      // color information

    // Instantiate PLL for clock generation
    pll pll_inst (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .vga_clk(vga_clk)
    );

    // Instantiate character display module
    vga_pic vga_pic_inst (
        .vga_clk (vga_clk),
        .sys_rst_n (sys_rst_n),
        .pix_x (pix_x),
        .pix_y (pix_y),
        .pix_data (pix_data)
    );

    // Instantiate VGA controller
    vga_ctrl vga_ctrl_inst (
        .vga_clk (vga_clk),
        .sys_rst_n (sys_rst_n),
        .pix_data (pix_data),
        .pix_x (pix_x),
        .pix_y (pix_y),
        .hsync (hsync),
        .vsync (vsync),
        .rgb (rgb)
    );

endmodule

// Character display module
module vga_pic(
    input wire vga_clk,
    input wire sys_rst_n,
    input wire [9:0] pix_x,
    input wire [9:0] pix_y,
    output reg [15:0] pix_data
);

    // Screen parameters
    parameter H_DISPLAY = 640;
    parameter V_DISPLAY = 480;
    
    // Character parameters
    parameter CHAR_WIDTH = 40;
    parameter CHAR_HEIGHT = 60;
    parameter CHAR_SPACING = 20;
    
    // Starting position to center the text
    parameter TEXT_START_X = (H_DISPLAY - (4*CHAR_WIDTH + 3*CHAR_SPACING)) / 2;
    parameter TEXT_START_Y = (V_DISPLAY - CHAR_HEIGHT) / 2;
    
    // Character positions
    parameter M_START_X = TEXT_START_X;
    parameter U_START_X = TEXT_START_X + CHAR_WIDTH + CHAR_SPACING;
    parameter S_START_X = TEXT_START_X + 2*CHAR_WIDTH + 2*CHAR_SPACING;
    parameter T_START_X = TEXT_START_X + 3*CHAR_WIDTH + 3*CHAR_SPACING;
    
    // Character display logic
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pix_data <= 16'h0000; // Black background
        end else begin
            // Check for M character - NO MIDDLE VERTICAL LINE
            if (pix_x >= M_START_X && pix_x < M_START_X + CHAR_WIDTH && 
                pix_y >= TEXT_START_Y && pix_y < TEXT_START_Y + CHAR_HEIGHT) begin
                // M character - without middle vertical line
                integer rel_x = pix_x - M_START_X;
                integer rel_y = pix_y - TEXT_START_Y;
                
                // Left vertical line
                if (rel_x < 5) begin
                    pix_data <= 16'hFFFF;
                end
                // Right vertical line
                else if (rel_x >= CHAR_WIDTH-5) begin
                    pix_data <= 16'hFFFF;
                end
                // Left diagonal line - extends to bottom
                else if ((rel_x >= 5 + rel_y/4 - 1 && rel_x <= 5 + rel_y/4 + 1) && rel_y < CHAR_HEIGHT) begin
                    pix_data <= 16'hFFFF;
                end
                // Right diagonal line - extends to bottom
                else if ((rel_x >= CHAR_WIDTH-5 - rel_y/4 - 1 && rel_x <= CHAR_WIDTH-5 - rel_y/4 + 1) && rel_y < CHAR_HEIGHT) begin
                    pix_data <= 16'hFFFF;
                end
                else begin
                    pix_data <= 16'h0000;
                end
            end
            // Check for U character - unchanged
            else if (pix_x >= U_START_X && pix_x < U_START_X + CHAR_WIDTH && 
                     pix_y >= TEXT_START_Y && pix_y < TEXT_START_Y + CHAR_HEIGHT) begin
                // U character - unchanged
                integer rel_x = pix_x - U_START_X;
                integer rel_y = pix_y - TEXT_START_Y;
                
                // Left vertical line
                if (rel_x < 5) begin
                    pix_data <= 16'hFFFF;
                end
                // Right vertical line
                else if (rel_x >= CHAR_WIDTH-5) begin
                    pix_data <= 16'hFFFF;
                end
                // Bottom horizontal line with rounded corners
                else if (rel_y >= CHAR_HEIGHT-8) begin
                    // Create a rounded bottom by making the corners shorter
                    if ((rel_x >= 5 && rel_x < CHAR_WIDTH-5) || 
                        (rel_x >= 0 && rel_x < 8 && rel_y >= CHAR_HEIGHT-5) ||
                        (rel_x >= CHAR_WIDTH-8 && rel_x < CHAR_WIDTH && rel_y >= CHAR_HEIGHT-5)) begin
                        pix_data <= 16'hFFFF;
                    end else begin
                        pix_data <= 16'h0000;
                    end
                end
                else begin
                    pix_data <= 16'h0000;
                end
            end
            // Check for S character - unchanged
            else if (pix_x >= S_START_X && pix_x < S_START_X + CHAR_WIDTH && 
                     pix_y >= TEXT_START_Y && pix_y < TEXT_START_Y + CHAR_HEIGHT) begin
                // S character - unchanged
                integer rel_x = pix_x - S_START_X;
                integer rel_y = pix_y - TEXT_START_Y;
                
                // Top horizontal line
                if (rel_y < 5) begin
                    pix_data <= 16'hFFFF;
                end
                // Top left vertical line
                else if (rel_x < 5 && rel_y < CHAR_HEIGHT/2) begin
                    pix_data <= 16'hFFFF;
                end
                // Middle horizontal line
                else if (rel_y >= CHAR_HEIGHT/2-3 && rel_y < CHAR_HEIGHT/2+3) begin
                    pix_data <= 16'hFFFF;
                end
                // Bottom right vertical line
                else if (rel_x >= CHAR_WIDTH-5 && rel_y >= CHAR_HEIGHT/2) begin
                    pix_data <= 16'hFFFF;
                end
                // Bottom horizontal line
                else if (rel_y >= CHAR_HEIGHT-5) begin
                    pix_data <= 16'hFFFF;
                end
                else begin
                    pix_data <= 16'h0000;
                end
            end
            // Check for T character - unchanged
            else if (pix_x >= T_START_X && pix_x < T_START_X + CHAR_WIDTH && 
                     pix_y >= TEXT_START_Y && pix_y < TEXT_START_Y + CHAR_HEIGHT) begin
                // T character - unchanged
                integer rel_x = pix_x - T_START_X;
                integer rel_y = pix_y - TEXT_START_Y;
                
                if (rel_y < 5) begin
                    pix_data <= 16'hFFFF;
                end
                else if (rel_x >= CHAR_WIDTH/2-3 && rel_x <= CHAR_WIDTH/2+2) begin
                    pix_data <= 16'hFFFF;
                end
                else begin
                    pix_data <= 16'h0000;
                end
            end
            else begin
                pix_data <= 16'h0000; // Background
            end
        end
    end

endmodule

// VGA controller module - unchanged
module vga_ctrl(
    input wire vga_clk,
    input wire sys_rst_n,
    input wire [15:0] pix_data,
    output reg [9:0] pix_x,
    output reg [9:0] pix_y,
    output reg hsync,
    output reg vsync,
    output reg [15:0] rgb
);

    // VGA timing parameters for 640x480@60Hz
    parameter H_SYNC = 96;
    parameter H_BACK = 48;
    parameter H_DISP = 640;
    parameter H_FRONT = 16;
    parameter H_TOTAL = 800;
    
    parameter V_SYNC = 2;
    parameter V_BACK = 33;
    parameter V_DISP = 480;
    parameter V_FRONT = 10;
    parameter V_TOTAL = 525;
    
    reg [9:0] h_cnt;
    reg [9:0] v_cnt;
    
    // Horizontal counter
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            h_cnt <= 10'd0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 10'd0;
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end
    
    // Vertical counter
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            v_cnt <= 10'd0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                if (v_cnt == V_TOTAL - 1) begin
                    v_cnt <= 10'd0;
                end else begin
                    v_cnt <= v_cnt + 1'b1;
                end
            end
        end
    end
    
    // Generate sync signals
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            // Horizontal sync
            hsync <= (h_cnt < H_SYNC) ? 1'b0 : 1'b1;
            // Vertical sync
            vsync <= (v_cnt < V_SYNC) ? 1'b0 : 1'b1;
        end
    end
    
    // Calculate pixel coordinates
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pix_x <= 10'd0;
            pix_y <= 10'd0;
        end else begin
            pix_x <= (h_cnt >= H_SYNC + H_BACK) && (h_cnt < H_SYNC + H_BACK + H_DISP) ? 
                    h_cnt - (H_SYNC + H_BACK) : 10'd0;
            pix_y <= (v_cnt >= V_SYNC + V_BACK) && (v_cnt < V_SYNC + V_BACK + V_DISP) ? 
                    v_cnt - (V_SYNC + V_BACK) : 10'd0;
        end
    end
    
    // Output RGB data
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rgb <= 16'h0000;
        end else begin
            if ((h_cnt >= H_SYNC + H_BACK) && (h_cnt < H_SYNC + H_BACK + H_DISP) &&
                (v_cnt >= V_SYNC + V_BACK) && (v_cnt < V_SYNC + V_BACK + V_DISP)) begin
                rgb <= pix_data;
            end else begin
                rgb <= 16'h0000;
            end
        end
    end

endmodule

// PLL module for clock generation - unchanged
module pll(
    input wire sys_clk,
    input wire sys_rst_n,
    output wire vga_clk
);
    // Simple clock divider for simulation
    reg vga_clk_reg;
    
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            vga_clk_reg <= 1'b0;
        end else begin
            vga_clk_reg <= ~vga_clk_reg;
        end
    end
    
    assign vga_clk = vga_clk_reg;
    
endmodule
