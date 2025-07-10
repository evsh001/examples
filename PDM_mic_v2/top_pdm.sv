`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


module top_pdm
  #
  (
   parameter RAM_SIZE   = 65536,
   parameter CLK_FREQ   = 44,
   parameter DATA_WIDTH = 16
   )
  (
   input wire          clk, // 44 Mhz clock

   // Microphone interface
   input wire          m_data,
   output logic        m_clk,
   //output logic        m_lr_sel,
   
   // Pushbutton interface
   input logic         BTNW,
   input logic         BTNT,
   input logic         BTNI2S,
   //input logic         reset,
   
   // LED array
   output logic [3:0]  LED, 
    
   // UART output
   output logic        tx_out,
   
   // Audio I2S interface
   output logic        lr_clk,
   output logic        b_clk,
   output logic        i2s_out
   );
   
  logic [DATA_WIDTH-1:0]       amplitude;
  logic                        amplitude_valid;

  logic [2:0]                  button_wsync;
  logic [2:0]                  button_tsync;
  logic [2:0]                  button_isync;
  logic                        start_capture;
  logic                        start_transmit;
  logic                        start_i2s;
  logic [7:0]                  uart_data;
  logic [1:0]                  byte_index;  // for uart 
  logic                        inc_mem;


 
   // Capture RAM
  logic [DATA_WIDTH-1:0]       amplitude_store[RAM_SIZE];
  logic [$clog2(RAM_SIZE)-1:0] ram_wraddr;
  logic [$clog2(RAM_SIZE)-1:0] ram_rdaddr;
  logic                        ram_we;
  logic [1:0][7:0]             ram_dout;
  logic [3:0]                  clr_led;
  logic                        led_on;
  logic                        tx_busy;
  logic                        tx_done;
  logic                        tx_start;
  logic                        dump_cycle;
  
  sinc3 u_sinc3
    (
     //.reset               (reset),
     .clk                 (clk),
     .pdm_in              (m_data),
     .m_clk               (m_clk),
     .data_out            (amplitude),
     .data_valid          (amplitude_valid)
     );
  
  uart_tx_block u_uart_tx_block
    (
     .clk                 (clk),
     .data                (uart_data),
     .tx_start            (tx_start),
     .tx_done             (tx_done),
     .tx_busy             (tx_busy),
     .tx_out              (tx_out)
    );
    
  i2s u_i2s
    (
     .clk                 (clk),
     .sample              (ram_dout),
     .start               (start_i2s),
     .lr_clk              (lr_clk),
     .b_clk               (b_clk),
     .i2s_out             (i2s_out),
     .inc_mem             (inc_mem)
     );
   
  initial begin
    ram_rdaddr     = '0;
    ram_wraddr     = '0;
    ram_we         = '0;
    start_capture  = '0;
    start_transmit = '0;
    start_i2s      = '0;
    LED            = '0;
    clr_led        = '0;
    led_on         = '0;
    byte_index     = '0;  
  end
  
  // Memory initialization for testbench
//  initial amplitude_store = '{0:16'hC2A3, 1:16'h43F5, 2:16'h7788, default: '0};

    // Memory operations block
  always @(posedge clk) begin
    if (ram_we) amplitude_store[ram_wraddr] <= amplitude;
    ram_dout <= amplitude_store[ram_rdaddr];
  end
  
   // Capture the Audio data
  always @(posedge clk) begin
    button_wsync <= button_wsync << 1 | BTNW;
    ram_we       <= '0;
    
    for (int i = 0; i < 4; i++)
      if (clr_led[i])
        LED[i] <= '0;
        
    if (led_on)
      LED <= '1;

    if (button_wsync[2:1] == 2'b01) begin
      start_capture   <= '1;
      LED             <= '0;
    end else if (start_capture && amplitude_valid) begin
      LED[ram_wraddr[$clog2(RAM_SIZE)-1:$clog2(RAM_SIZE)-2]] <= '1;
      ram_we          <= '1;
      ram_wraddr      <= ram_wraddr + 1'b1;
      if (&ram_wraddr) begin
        start_capture <= '0;
        ram_wraddr    <= '0;
      end
    end
  end
    
  // For LED turn off while transmitting
  logic [1:0] clr_addr;
  assign clr_addr = ~ram_rdaddr[$clog2(RAM_SIZE)-1:$clog2(RAM_SIZE)-2];
  
// Send Audio via uart / I2S
  always @(posedge clk) begin
    button_tsync   <= button_tsync << 1 | BTNT;
    tx_start       <= '0;
	clr_led        <= '0;
	led_on         <= '0;
	dump_cycle     <= '0;
	start_transmit <= dump_cycle;
    	
    if (button_tsync[2:1] == 2'b01) begin
      dump_cycle          <= '1;
	  led_on              <= '1;
    end else if (start_transmit && ~tx_busy) begin
      tx_start            <= '1;
	  uart_data           <= ram_dout[byte_index];
	  byte_index          <= byte_index + 1;
    end else if (tx_done) begin
      dump_cycle          <= '1;      
      if (byte_index == 2'b10) begin
		byte_index        <= '0;
		ram_rdaddr        <= ram_rdaddr + 1;
		clr_led[clr_addr] <= '1;
	    if (&ram_rdaddr) begin
          ram_rdaddr      <= '0;
          dump_cycle      <= '0;
        end
      end
    end  
  
  // Send Audio to I2S interface
    button_isync   <= button_isync << 1 | BTNI2S;
    
    if (button_isync[2:1] == 2'b01)
      start_i2s  <= '1;
    
    if (inc_mem)
      ram_rdaddr <= ram_rdaddr + 1;
    
    if (&ram_rdaddr) begin
      ram_rdaddr <= '0;
      start_i2s  <= '0;
    end      
  end
  
//  assign audio_out = start_playback ? ram_dout : 'z; 
  
endmodule
