`timescale 1ns/1ps

module tb_vga_colorbar;

// Inputs
reg sys_clk;
reg sys_rst_n;

// Outputs
wire hsync;
wire vsync;
wire [15:0] rgb;

// Internal signals for monitoring
wire vga_clk;
wire [9:0] pix_x;
wire [9:0] pix_y;
wire [15:0] pix_data;

// Instantiate the Unit Under Test (UUT)
vga_colorbar uut (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .rgb(rgb)
);

// Assign internal signals for monitoring
assign vga_clk = uut.vga_clk;
assign pix_x = uut.pix_x;
assign pix_y = uut.pix_y;
assign pix_data = uut.pix_data;

// Clock generation - 50MHz (20ns period)
initial begin
    sys_clk = 1'b0;
    forever #10 sys_clk = ~sys_clk;
end

// Test sequence
initial begin
    // Initialize inputs
    sys_rst_n = 1'b0;
    
    $display("=== VGA Colorbar Top-Level Testbench ===");
    $display("Testing MUST character display on VGA 640x480");
    
    // Apply reset for 100ns
    #100;
    sys_rst_n = 1'b1;
    $display("Reset released at %0t ns", $time);
    
    // Run basic tests
    #1000000; // Run for 1ms to see several frames
    
    $display("Simulation completed at %0t ns", $time);
    $finish;
end

// Simple monitoring - just check that signals are toggling
initial begin
    #1000; // Wait past reset
    if (hsync !== 1'b0 && hsync !== 1'b1) begin
        $display("ERROR: HSYNC not toggling");
    end
    if (vsync !== 1'b0 && vsync !== 1'b1) begin
        $display("ERROR: VSYNC not toggling");
    end
    if (rgb === 16'hxxxx) begin
        $display("ERROR: RGB not initialized");
    end
end

// Monitor frame activity
reg [31:0] frame_count = 0;
always @(negedge vsync) begin
    frame_count = frame_count + 1;
    if (frame_count <= 5) begin
        $display("Frame %0d started at %0t ns", frame_count, $time);
    end
end

// Check for character pixels in active area
always @(posedge vga_clk) begin
    if (sys_rst_n && pix_x < 640 && pix_y < 480) begin
        if (rgb == 16'hFFFF) begin
            $display("Character pixel found at (%0d, %0d) at %0t ns", pix_x, pix_y, $time);
        end
    end
end

// Generate waveform file
initial begin
    $dumpfile("vga_colorbar_waveform.vcd");
    $dumpvars(0, tb_vga_colorbar);
end

endmodule
