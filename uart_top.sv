
module uart_top
  #
  (
  parameter RAM_SIZE     = 16,
  parameter CLK_FREQ     = 44,
  )
  (
  input wire          clk, // 44Mhz clock

  // Pushbutton interface
  input logic         BTNTX,
  //input logic         BTNRX,

  // UART pins
  // output wire         rx_in,
  output wire         tx_out
);

  logic [7:0]                  ram_store[RAM_SIZE];
  logic [$clog2(RAM_SIZE)-1:0] ram_rdaddr;
  logic [7:0]                  ram_dout;


  always @(posedge clk) begin
    ram_dout <= ram_store[ram_rdaddr];
  end



endmodule
