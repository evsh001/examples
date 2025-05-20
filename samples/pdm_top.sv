`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////


module pdm_top
  #
  (
   parameter RAM_SIZE = 65536,
   parameter CLK_FREQ = 44
   )
  (
   input wire          clk, // 44 Mhz clock
   output logic        tx_out,

   // Microphone interface
   output logic        m_clk,
//   output logic        m_lr_sel,
   input  wire         m_data,

   // Pushbutton interface
   input logic         BTNW,
   input logic         BTNR,
   input logic         BTNT,

   // LED Array
   output logic [3:0] LED,
//   output logic [3:0] LED1,  // TEST
   
   // Audio output
   output logic [7:0] audio_out
   );
   
  logic [7:0]          amplitude;
  logic                amplitude_valid;

  logic [2:0]          button_wsync;
  logic [2:0]          button_rsync;
  logic [2:0]          button_tsync;
  logic                start_capture;
  logic                start_playback;
  logic                start_transmit;
  logic                m_clk_en;
  
//  logic [12:0]         test_counter; // TEST
  
     // Capture RAM
  logic [7:0] amplitude_store[RAM_SIZE];
  logic [$clog2(RAM_SIZE)-1:0] ram_wraddr;
  logic [$clog2(RAM_SIZE)-1:0] ram_rdaddr;
  logic                        ram_we;
  logic [7:0]                  ram_dout;
  logic [3:0]                  clr_led;
  logic                        tx_start;
  logic                        tx_done;

 
  pdm_inputs u_pdm_inputs
    (
     .clk                 (clk),     // 2.2 Mhz

     // Microphone interface
     .m_clk               (m_clk),
     .m_clk_en            (m_clk_en),
     .m_data              (m_data),

     // Amplitude outputs
     .amplitude           (amplitude),
     .amplitude_valid     (amplitude_valid)
     );
   
  uart_tx_block u_uart_tx_block
    (
     .clk                 (clk),
     .data                (ram_dout),
     .tx_start            (tx_start),
     .tx_done             (tx_done),
     .tx_out              (tx_out)
    );
  

   
  initial begin
    button_rsync   = '0;
    button_wsync   = '0;
    button_tsync   = '0;
    ram_rdaddr     = '0;
    ram_wraddr     = '0;
    ram_we         = '0;
    start_capture  = '0;
    start_playback = '0;
    start_transmit = '0;
    LED            = '0;
    clr_led        = '0;
    
//    test_counter   = '0;  // TEST
//    LED1           = '1;  // TEST
  end
   
  // initial amplitude_store = '{0:7'd3, 1:7'd4, 2:7'd5, 3:7'd12, 4:7'd34, 5:7'd45, 6:7'd55, default: '0};
  
   // Capture the Audio data
  always @(posedge clk) begin
    button_wsync <= button_wsync << 1 | BTNW;
    ram_we       <= '0;
    
    for (int i = 0; i < 4; i++)
      if (clr_led[i]) LED[i] <= '0;

    if (button_wsync[2:1] == 2'b01) begin
      start_capture <= '1;
      LED           <= '0;
    end else if (start_capture && amplitude_valid) begin
      LED[ram_wraddr[$clog2(RAM_SIZE)-1:$clog2(RAM_SIZE)-2]] <= '1;
      ram_we                      <= '1;
      ram_wraddr                  <= ram_wraddr + 1'b1;
      if (&ram_wraddr) begin
        start_capture <= '0;
        ram_wraddr    <= '0;
      end
    end
  end
  
  always @(posedge clk) begin
    if (ram_we) amplitude_store[ram_wraddr] <= amplitude;
    ram_dout <= amplitude_store[ram_rdaddr];
  end
   
   
  logic [1:0] clr_addr;
  assign clr_addr = ~ram_rdaddr[$clog2(RAM_SIZE)-1:$clog2(RAM_SIZE)-2];
  
  // Playback Audio
  always @(posedge clk) begin
    button_rsync <= button_rsync << 1 | BTNR;
    button_tsync <= button_tsync << 1 | BTNT;
    tx_start     <= '0;
    clr_led      <= '0;
    
    if (button_rsync[2:1] == 2'b01)
      start_playback    <= '1;
    else if (start_playback && amplitude_valid) begin
      clr_led[clr_addr] <= '1;
      ram_rdaddr                  <= ram_rdaddr + 1'b1;
      if (&ram_rdaddr) begin
        start_playback  <= '0;
        ram_rdaddr      <= '0;
      end
    end
    
    if (button_tsync[2:1] == 2'b01)
      start_transmit    <= 1'b1;
    else if (start_transmit) begin
      ram_rdaddr        <= ram_rdaddr + 1'b1;
      tx_start          <= 1'b1;
      start_transmit    <= '0;
    end else if (tx_done)
      start_transmit  <= 1'b1;
       
    if (&ram_rdaddr) begin
      start_transmit  <= '0;
      ram_rdaddr      <= '0;
    end
  end
  
    // Send Audio
//  always @(posedge clk) begin
//    button_tsync <= button_tsync << 1 | BTNT;
//    tx_start     <= '0;
    
//    if (button_rsync[2:1] == 2'b01)
//      start_transmit    <= 1'b1;
//    else if (start_transmit) begin
//      ram_rdaddr        <= ram_rdaddr + 1'b1;
//      tx_start          <= 1'b1;
//      start_transmit    <= '0;
//    end else if (tx_done)
//      start_transmit  <= 1'b1;
       
//    if (&ram_rdaddr) begin
//      start_transmit  <= '0;
//      ram_rdaddr      <= '0;
//    end
//  end
  
  
  // TEST block
//  always @(posedge clk) begin
//    if (amplitude_valid) test_counter <= test_counter + 1'b1;
//    if (&test_counter && amplitude_valid) begin
//      LED1[0] <= ~LED1[0];
//    end
//  end
   
  assign audio_out = start_playback ? ram_dout : 'z; 
//  assign m_lr_sel = 1'b1;

endmodule

