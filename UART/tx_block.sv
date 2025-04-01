
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module tx_block(
  input  wire        clk,
  input  logic       start,
  input  logic [7:0] mdata,
  input  logic       clk_en,
  output logic       done,
  output wire        tx_out
 );

  localparam CLK_COUNT = 10;

  logic [9:0]   txdata;
  logic         tx;
  logic [$clog2(CLK_COUNT)-1:0]  counter;

  always_ff @( posedge clk ) begin
    done        <= '0;
    if (start) begin
      tx        <= '1;
      txdata    <= {1'b1, mdata, '0};   //  stop bit + mdata + start bit
      counter   <= '0;
    end 
    if (tx && clk_en && counter < CLK_COUNT) begin
      txdata    <= txdata >> 1;
      counter   <= counter + 1'b1;
    end else begin
      done      <= 1'b1;
      tx        <= '0;
    end
  end

  assign tx_out = tx ? txdata[0] : 1'b1;  

endmodule
