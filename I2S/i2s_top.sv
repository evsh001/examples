`timescale 1ns/10ps

module i2s_top
    #
    (
    parameter SAMPLE_RATE = 34375,
    parameter CLK         = 44_000_000,
    parameter DATA_WIDTH  = 16,
    parameter RAM_SIZE    = 4    
    )
    (
    input  wire     clk,
    input  logic    BTNST,
    input  logic    reset_n,
    output logic    i2s_bclk,      // Bit clock
    output logic    i2s_lrclk,     // Left/right clock (34.375 kHz)
    output logic    i2s_dout
    );

    localparam SRATE = CLK / SAMPLE_RATE;

    logic [$clog2(SRATE)-1:0]     counter; 
    logic [DATA_WIDTH-1:0]        store[RAM_SIZE];
    logic [$clog2(RAM_SIZE)-1:0]  ram_rdaddr;
    logic [DATA_WIDTH-1:0]        ram_dout;

    logic [2:0] btn_stsync;
    logic       start_i2s;
    logic       clr_start;
    
    // Memory initialization for testbench
    initial store = '{0:16'hC2A3, 1:16'h43F5, 2:16'h7788, default: '1};

    i2s_max9835a u_i2s_max9835a(
        .clk        (clk),
        .reset_n    (reset_n),
        .left_data  (ram_dout),
        .data_valid (start_i2s),
        .i2s_bclk   (i2s_bclk),
        .i2s_lrclk  (i2s_lrclk),
        .i2s_dout   (i2s_dout)
    );


    always_ff @(posedge clk or negedge reset_n) begin
        ram_dout <= store[ram_rdaddr];
    end


    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter    <= '0;
            start_i2s  <= '0;
            ram_rdaddr <= '0;
            clr_start  <= '0;
        end else begin
            clr_start  <= '0;
            btn_stsync <= btn_stsync << 1 | BTNST;

            if (btn_stsync[2:1] == 2'b01) begin
                start_i2s  <= '1;
                counter    <= '0;
            end
            
            if (start_i2s && counter == SRATE-1) begin
                ram_rdaddr <= ram_rdaddr + 1;
                counter    <= '0;
                if (&ram_rdaddr) begin
                    ram_rdaddr <= '0;
                    clr_start  <= '1;    // delay to read last value from RAM
                end
            end else
                counter <= counter + 1;

            if (clr_start) start_i2s <= '0;

        end
    end

endmodule
