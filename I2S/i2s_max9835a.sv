`timescale 1ns/10ps

module i2s_max9835a 
    #
    (
    parameter  SAMPLE_RATE = 34375,
    parameter  DATA_WIDTH  = 16,
    parameter  CLK         = 44_000_000
    )
    (
    input  wire          clk,     // 44 MHz system clock
    input  wire          reset_n,       // Active-low reset
    input  wire [15:0]   left_data,     // 16-bit left channel data
    input  wire          data_valid,    // Assert when left_data is valid
    output logic         i2s_bclk,      // Bit clock (1.1 MHz = 32 x 34.375 kHz)
    output logic         i2s_lrclk,     // Left/right clock (34.375 kHz)
    output logic         i2s_dout       // Serial data output (left channel only)
    );

    // Constants calculated for 44 MHz system clock
    localparam BCLK_DIV  = CLK / (SAMPLE_RATE*2*DATA_WIDTH*2);         // bit clock rate - 32 clock per 1 sample
    localparam LRCLK_DIV = 32;        // 32 BCLK cycles per half-period
    
    // Counters
    logic [$clog2(BCLK_DIV)-1:0]  bclk_counter;      // Counts 0-19 for BCLK generation
    logic [$clog2(LRCLK_DIV)-1:0] bit_counter;       // Counts 0-31 for data shifting
    
    // Data register
    logic [15:0] data_reg;

    // Generate BCLK 
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bclk_counter <= '0;
            i2s_bclk     <= '0;
        end else begin
            if (bclk_counter == BCLK_DIV-1) begin
                bclk_counter <= 0;
                i2s_bclk <= ~i2s_bclk;
            end else begin
                bclk_counter <= bclk_counter + 1;
            end
        end
        
    end

    // Generate LRCLK and shift data
    always_ff @(negedge i2s_bclk or negedge reset_n) begin
        if (!reset_n) begin
            bit_counter <= '0;
            i2s_lrclk   <= '0;
            i2s_dout    <= '0;
            data_reg    <= '0;
        end else begin
            bit_counter <= bit_counter + 1;
            
            // Load new data at start of left channel
            if (bit_counter == LRCLK_DIV-1) begin
                i2s_lrclk <= 0;
                if (data_valid)
                    data_reg <= left_data;
                else
                    data_reg <= '0;
            end
            // Toggle LRCLK to mark end of left channel
            else if (bit_counter == 15) begin
                i2s_lrclk <= 1;
            end
            
            // Output data MSB-first (left channel only)
            if (bit_counter < 16) begin
                i2s_dout <= data_reg[15 - bit_counter[3:0]];
            end else begin
                i2s_dout <= 0;  // Right channel muted
            end
        end
    end

endmodule
