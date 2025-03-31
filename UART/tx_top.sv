module tx_data
  (
  input wire          clk, // 44Mhz clock
  input wire [7:0]    SW,
  output wire         tx_out,
  output wire         LED
  );

  logic [24:0]                 counter;
  logic                        start;
  logic clk_en                 clk_en;
  logic       	               done,


  uart_clk u_uart_clk
  (
   .clk            (clk),
   .clk_en         (clk_en)
   );
   
   tx_block u_uart_clk
  (
   .clk            (clk),
   .start          (start,)
   .m_data         (SW),
   .clk_en         (clk_en),
   .done           (done),
   .tx_out         (tx_out)
   );
  

  always @(posedge clk) begin
    start <= 0;
	if (&&counter)
    start <= 1b'1;
  else
    counter <= counter + 1;
  end
  
  assign LED = done;

endmodule
