`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


module top_pdm
  #
  (
   parameter RAM_SIZE = 131072,
   parameter CLK_FREQ = 44
   )
  (
   input wire          clk, // 44 Mhz clock

   // Microphone interface
   output logic        m_clk,
   output logic        m_lr_sel,
   input wire          m_data,

   // Pushbutton interface
   input logic         BTNW,
   input logic         BTNR,
   //input logic         reset,

   // LED Array
   output logic [3:0] LED,
   
   // Audio output
   output logic [7:0] audio_out
   );
   
  logic [7:0]          amplitude;
  logic                amplitude_valid;

  logic [2:0]          button_wsync;
  logic [2:0]          button_rsync;
  logic                start_capture;
  logic                m_clk1;
  logic                data_en;
  logic                amp_flag_en;
  
  

  assign m_lr_sel = '0;


  clk_pdm u_clk_pdm(
     .clk                  (clk),        // 2.75 Mhz
     .m_clk                (m_clk),
     .m_clk1               (m_clk1)
   );
   
  sinc3 u_sinc3
    (
     //.reset               (reset),
     .mclk1               (m_clk1),
     .mdata1              (m_data),
     .DATA                (amplitude),
     .data_en             (data_en)
     );
     
     
   // Capture RAM
  logic [7:0]                  amplitude_store[RAM_SIZE];
  logic                        start_playback;
  logic [$clog2(RAM_SIZE)-1:0] ram_wraddr;
  logic [$clog2(RAM_SIZE)-1:0] ram_rdaddr;
  logic                        ram_we;
  logic [7:0]                  ram_dout;
  logic [3:0]                  clr_led;
  logic                        led_on;
  
   
  initial begin
    ram_rdaddr     = '0;
    ram_wraddr     = '0;
    ram_we         = '0;
    start_capture  = '0;
    start_playback = '0;
    LED            = '0;
    clr_led        = '0;
    led_on         = '0;
    data_en        = '0;
    amp_flag_en    = '0;
    
  end

  always @(posedge clk) begin
    amplitude_valid <= '0;
    if (data_en && ~amp_flag_en) begin
      amplitude_valid <= 1'b1;
      amp_flag_en     <= 1'b1;
    end
    if (~data_en)
      amp_flag_en <= '0;
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
  
  // Memory operations block
  always @(posedge clk) begin
    if (ram_we) amplitude_store[ram_wraddr] <= amplitude;
    ram_dout <= amplitude_store[ram_rdaddr];
  end
   
  // For LED turn off while reading
  logic [1:0] clr_addr;
  assign clr_addr = ~ram_rdaddr[$clog2(RAM_SIZE)-1:$clog2(RAM_SIZE)-2];
  
  // Playback Audio
  always @(posedge clk) begin
    button_rsync <= button_rsync << 1 | BTNR;
    clr_led      <= '0;
    led_on       <= '0;
    
    if (button_rsync[2:1] == 2'b01) begin
      start_playback <= '1;
      led_on         <= '1;
    end else if (start_playback && amplitude_valid) begin
      clr_led[clr_addr] <= '1;
      ram_rdaddr                  <= ram_rdaddr + 1'b1;
      if (&ram_rdaddr) begin
        start_playback <= '0;
        ram_rdaddr     <= '0;
      end
    end
  end
  
   
  assign audio_out = start_playback ? ram_dout : 'z; 

   
endmodule


module clk_pdm
  #
  (
   parameter          CLK_FREQ    = 44,     // Mhz
   parameter          SAMPLE_RATE = 2750000 // Hz
   )
  (
   input  wire         clk,    // 44Mhz  
   output logic        m_clk,  // Microphone clock
   output logic        m_clk1
   );

  localparam CLK_COUNT = int'((CLK_FREQ*1000000)/(SAMPLE_RATE*2));
  logic [$clog2(CLK_COUNT)-1:0]      clk_counter;

  initial begin
    m_clk           = '0;
    m_clk1          = '0;
    clk_counter     = '0;
  end

  always @(posedge clk) begin
    if (clk_counter == CLK_COUNT - 1) begin
      clk_counter <= '0;
      m_clk       <= ~m_clk;
      m_clk1      <= ~m_clk1;
    end else
      clk_counter <= clk_counter + 1;
  end

endmodule
