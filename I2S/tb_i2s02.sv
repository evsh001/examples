`timescale 1ns/10ps


module tb_i2s02;
    logic         clk;           // 44 MHz system clock
    logic         reset_n;       // Active-low reset
    logic         BTNST;     
    logic         i2s_bclk;      // Bit clock (1.1 MHz = 32 x 34.375 kHz)
    logic         i2s_lrclk;     // Left/right clock (34.375 kHz)
    logic         i2s_dout;      // Serial data output (left channel only)


    i2s_top u_i2s_top( .* );

    initial begin
        //$monitor($time, " left_data=%d", left_data);
        $display("Start testbench");
        reset_n = 1;
        clk     = 0;
        BTNST    = 0;
      
        #3 reset_n = 0;
        #4 reset_n = 1;

        #2  BTNST = 1;
        #15 BTNST = 0;

        //$display("t=", $time, ", left_data = %d", left_data);

        repeat (7000) @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("i2s_GTK.vcd");
        $dumpvars(0, tb_i2s02);
    end

    always begin
        clk = #5 ~clk;
    end

endmodule
