`timescale 1ns/1ps

module tb_vga_ctrl;

// Inputs
reg vga_clk;
reg sys_rst_n;
reg [15:0] pix_data;

// Outputs
wire [9:0] pix_x;
wire [9:0] pix_y;
wire hsync;
wire vsync;
wire [15:0] rgb;

// Test variables
integer h_sync_count;
integer v_sync_count;
integer frame_count;

// Instantiate the Unit Under Test (UUT)
vga_ctrl uut (
    .vga_clk(vga_clk),
    .sys_rst_n(sys_rst_n),
    .pix_data(pix_data),
    .pix_x(pix_x),
    .pix_y(pix_y),
    .hsync(hsync),
    .vsync(vsync),
    .rgb(rgb)
);

// VGA clock generation - 25MHz (40ns period)
initial begin
    vga_clk = 1'b0;
    forever #20 vga_clk = ~vga_clk;
end

// Test sequence
initial begin
    // Initialize
    sys_rst_n = 1'b0;
    pix_data = 16'hF800;
    h_sync_count = 0;
    v_sync_count = 0;
    frame_count = 0;
    
    $display("=== VGA Controller Testbench ===");
    
    // Apply reset
    #100;
    sys_rst_n = 1'b1;
    $display("Reset released");
    
    // Run basic tests
    #100000; // Run for longer time
    
    $display("Simulation completed");
    $finish;
end

// Simple monitoring - check timing basics
initial begin
    #1000; // Wait past reset
    
    // Check that signals are toggling
    if (hsync !== 1'b0 && hsync !== 1'b1) begin
        $display("ERROR: HSYNC not toggling");
    end
    if (vsync !== 1'b0 && vsync !== 1'b1) begin
        $display("ERROR: VSYNC not toggling");
    end
    
    // Monitor a few frames
    repeat(3) begin
        @(negedge vsync);
        frame_count = frame_count + 1;
        $display("Frame %0d started", frame_count);
    end
end

// Count sync pulses
always @(negedge hsync) begin
    if (sys_rst_n) h_sync_count = h_sync_count + 1;
end

always @(negedge vsync) begin
    if (sys_rst_n) v_sync_count = v_sync_count + 1;
end

// Monitor active area
always @(posedge vga_clk) begin
    if (sys_rst_n && pix_x < 640 && pix_y < 480) begin
        // In active area
        if (pix_x == 0 && pix_y == 0) begin
            $display("Active area start at %0t ns", $time);
        end
    end
end

// Check RGB output
always @(posedge vga_clk) begin
    if (sys_rst_n) begin
        // RGB should be zero outside active area
        if (pix_x == 10'h3ff && rgb != 16'h0000) begin
            $display("WARNING: RGB not zero in blanking at %0t ns", $time);
        end
    end
end

// Generate waveform file
initial begin
    $dumpfile("vga_ctrl_waveform.vcd");
    $dumpvars(0, tb_vga_ctrl);
end

// Final summary
initial begin
    #100000; // Wait for simulation to complete
    $display("\n=== Final Summary ===");
    $display("HSYNC pulses: %0d", h_sync_count);
    $display("VSYNC pulses: %0d", v_sync_count);
    $display("Frames: %0d", frame_count);
end

endmodule
