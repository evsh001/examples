`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////

module uart_tx_block
 #
 (
  parameter          CLK_FREQ      = 44_000_000,     // Hz
  parameter          BAUD_RATE     = 230_400         // Bod
 )
 (
  input  wire        clk,
  input  logic [7:0] data,
  input  logic       tx_start,
  output logic       tx_done,
  output logic       tx_busy,
  output logic       tx_out
 );

  localparam DATA_LEN  = 10;
  localparam CLK_COUNT = int'(CLK_FREQ/BAUD_RATE + 1);  // 190 + 1 that is round (depending on the input frequency)
  
//  logic                              tx_busy;
  logic                              clk_en;
  logic [DATA_LEN-1:0]               tx_data;
  logic [$clog2(DATA_LEN)-1:0]       index;
  logic [$clog2(CLK_COUNT)-1:0]      clk_en_cnt;
  

  initial begin
    // clock gen variables
    clk_en        = '0; 
    clk_en_cnt    = '0;
    // uart tx block  variables
    tx_data       = '0;
    tx_busy       = '0;
    index         = '0;
    tx_out        = 1'b1;
    tx_done       = '0;   
  end


  always @(posedge clk) begin
    clk_en        <= '0;
    if (clk_en_cnt == CLK_COUNT - 1 || tx_start) begin
      clk_en_cnt <= '0;
      clk_en    <= ~clk_en;
    end else
      clk_en_cnt <= clk_en_cnt + 1;
  end
  
  always @(posedge clk) begin
    tx_done        <= '0;
    if (tx_start && ~tx_busy) begin
      tx_busy   <= '1;
      tx_data   <= {1'b1, data, '0};   //  stop bit + data[MSB...LSB] + start bit
    end 
    if (tx_busy && clk_en && index < DATA_LEN) begin
      tx_out    <= tx_data[0];
      tx_data   <= tx_data >> 1;
      index     <= index + 1'b1;
    end else if (clk_en && index == DATA_LEN) begin
      tx_done   <= 1'b1;
      tx_busy   <= '0;
      index     <= '0;
    end
  end
    

endmodule
