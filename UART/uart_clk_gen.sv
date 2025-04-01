`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module uart_clk_gen
 #
 (
  parameter          CLK_FREQ      = 44,     // Mhz
  parameter          BAUD_RATE     = 9600    // bod
 )
 (
  input wire         clk,
  output logic       clk_en      
 );
  
  localparam CLK_COUNT = int'((CLK_FREQ*1000000)/(BAUD_RATE));
  logic [$clog2(CLK_COUNT)-1:0]      clk_counter;
  

  always_ff @( posedge clk ) begin
    clk_en        <= '0;
    if (clk_counter == CLK_COUNT - 1) begin
      clk_counter <= '0;
      clk_en    <= ~clk_en;
    end else
      clk_counter <= clk_counter + 1;
  end
  
endmodule
