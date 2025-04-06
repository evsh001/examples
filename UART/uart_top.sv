`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module uart_top
  (
  input wire           clk, // 44Mhz clock
  input wire [7:0]     SW,
  output logic         tx_out
  );

  logic [22:0]                 counter_st;
  //logic [6:0]                  counter_st;   // TESTBENCH
  logic                        start;
  logic                        clk_en;
  logic       	               done;


  initial begin
    counter_st = '0;
    start   = '0;
    clk_en  = '0;
    done    = '0;
  end

  uart_clk_gen u_uart_clk_gen
  (
   .clk            (clk),
   .clk_en         (clk_en)
   );
   
   tx_block u_tx_block
  (
   .clk            (clk),
   .start          (start),
   .mdata          (SW),
   .clk_en         (clk_en),
   .done           (done),
   .tx_out         (tx_out)
   );
  
  always @(posedge clk) begin
    start <= 0;
	if (&counter_st) begin
      start         <= 1'b1;
      counter_st    <= '0;     
    end else
      counter_st <= counter_st + 1;
  end
 
endmodule
