
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module tx_block(
  input  wire        clk,
  input  logic       start,
  input  logic [7:0] mdata,
  input  logic       clk_en,
  output logic       done,
  output logic       tx_out
 );

  localparam CLK_COUNT = 10;

  logic [9:0]   txdata;
  logic         tx;
  logic [$clog2(CLK_COUNT)-1:0]  index_counter;

  initial begin 
    txdata  = '0;
    tx      = '0;
    index_counter = '0;
    tx_out  = 1'b1;
  end

  always @(posedge clk) begin
    done        <= '0;
    if (start) begin
      tx        <= '1;
      txdata    <= {1'b1, mdata, '0};   //  stop bit + data + start bit
    end 
    if (tx && clk_en && index_counter < CLK_COUNT) begin
      tx_out <= txdata[0];
      txdata    <= txdata >> 1;
      index_counter   <= index_counter + 1'b1;
    end else if (clk_en && index_counter == CLK_COUNT) begin
      done      <= 1'b1;
      tx        <= '0;
      index_counter   <= '0;
    end
  end
    
endmodule
