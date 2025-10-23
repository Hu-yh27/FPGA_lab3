`timescale 1ns/1ps

module tb_pll;

// Inputs
reg sys_clk;
reg sys_rst_n;

// Outputs
wire vga_clk;

// Instantiate the Unit Under Test (UUT)
pll uut (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .vga_clk(vga_clk)
);

// Clock generation - 50MHz (20ns period)
initial begin
    sys_clk = 1'b0;
    forever #10 sys_clk = ~sys_clk; // 50MHz clock
end

// Test sequence
initial begin
    // Initialize inputs
    sys_rst_n = 1'b0;
    
    // Monitor signals
    $display("=== PLL Module Testbench ===");
    $display("Time\t sys_rst_n\t sys_clk\t vga_clk");
    $monitor("%0t\t %b\t\t %b\t\t %b", $time, sys_rst_n, sys_clk, vga_clk);
    
    // Apply reset
    #20;
    sys_rst_n = 1'b1;
    $display("\n=== Reset released at %0t ns ===", $time);
    
    // Test for several clock cycles
    #200; // Wait for 10 VGA clock cycles
    
    // Verify frequency
    $display("\n=== Frequency Verification ===");
    verify_frequency();
    
    // Test reset again
    #50;
    sys_rst_n = 1'b0;
    $display("\n=== Reset applied at %0t ns ===", $time);
    #40;
    sys_rst_n = 1'b1;
    $display("=== Reset released at %0t ns ===", $time);
    
    // Additional testing
    #100;
    
    $display("\n=== Test Completed ===");
    $finish;
end

// Frequency verification task
task verify_frequency;
    integer vga_cycles;
    real start_time, end_time, period, frequency;
    reg previous_vga_clk;
    begin
        // Wait for first rising edge of vga_clk
        @(posedge vga_clk);
        start_time = $time;
        
        // Count 5 full cycles of vga_clk
        vga_cycles = 0;
        previous_vga_clk = 1'b1;
        
        while (vga_cycles < 5) begin
            @(posedge vga_clk);
            if (previous_vga_clk === 1'b0) begin
                vga_cycles = vga_cycles + 1;
            end
            previous_vga_clk = vga_clk;
        end
        
        end_time = $time;
        period = (end_time - start_time) / 5.0;
        frequency = 1000.0 / period; // Convert to MHz
        
        $display("Measured VGA clock period: %0.2f ns", period);
        $display("Measured VGA clock frequency: %0.2f MHz", frequency);
        
        // Check if frequency is correct (should be 25MHz ± tolerance)
        if (frequency > 24.5 && frequency < 25.5) begin
            $display("✓ PASS: VGA clock frequency is correct (~25MHz)");
        end else begin
            $display("✗ FAIL: VGA clock frequency is incorrect");
            $display("  Expected: 25MHz, Measured: %0.2f MHz", frequency);
        end
    end
endtask

// Additional checks
always @(posedge sys_clk) begin
    if (sys_rst_n) begin
        // Check that vga_clk toggles only on sys_clk posedge
        if ($time > 100) begin // Skip initial unstable period
            if (vga_clk !== uut.clk_25) begin
                $display("✗ FAIL: vga_clk assignment mismatch at %0t ns", $time);
            end
        end
    end
end

// Reset behavior check
initial begin
    // Check initial state after reset
    #15; // Middle of first clock cycle while reset is active
    if (vga_clk !== 1'b0) begin
        $display("✗ FAIL: vga_clk should be 0 during reset");
    end else begin
        $display("✓ PASS: vga_clk is properly reset to 0");
    end
end

// Generate waveform file for visualization
initial begin
    $dumpfile("pll_waveform.vcd");
    $dumpvars(0, tb_pll);
end

endmodule
