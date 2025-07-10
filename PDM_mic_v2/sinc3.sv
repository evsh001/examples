`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
//
//(* DONT_TOUCH = "yes" *)

module sinc3
  #
  (
   parameter          DEC_RATE    = 80,
   parameter          CLK_FREQ    = 44,       // Mhz
   parameter          SAMPLE_RATE = 2750000,  // Hz
   parameter          REG_WIDTH   = 24,
   parameter          DATA_WIDTH  = 16
   )
  (
  input  wire                   clk,                // 44Mhz  
  input  wire                   pdm_in,             /* input data to be filtered */
  //output logic [15:0] DATA,              /* filtered output */
  output logic [DATA_WIDTH-1:0] data_out,               /* filtered output */
  output logic                  m_clk,              /* used to clock mic */
  output logic                  data_valid
  );
  

  localparam CLK_COUNT  = int'((CLK_FREQ*1000000)/(SAMPLE_RATE*2));
  
  logic [$clog2(DEC_RATE)-1:0]    word_count;
  logic [$clog2(CLK_COUNT)-1:0]   clk_counter;
  //(* dont_touch = "true" *
  logic [REG_WIDTH-1:0] acc1, acc2, acc3; 
  logic [REG_WIDTH-1:0] diff1_reg, diff2_reg, diff3_reg;
  logic [REG_WIDTH-1:0] diff1_out, diff2_out, diff3_out;

  logic                 mclk1_en;
  logic                 mclk2_en;
  
  initial begin
    acc1        = '0;
    acc2        = '0;
    acc3        = '0;
    diff1_reg   = '0;
    diff2_reg   = '0;
    diff3_reg   = '0;
    diff1_out   = '0;
    diff2_out   = '0;
    diff3_out   = '0;
    clk_counter = '0;
	word_count  = '0;
	m_clk       = '0;
    mclk1_en    = '0;
	mclk2_en    = '0;
  end
  
  always @(posedge clk) begin
    mclk1_en      <= '0;
    if (clk_counter == CLK_COUNT - 1) begin
      clk_counter <= '0;
      m_clk       <= ~m_clk;
    end else begin
      clk_counter <= clk_counter + 1;
      if (clk_counter == 1)
        mclk1_en  <= m_clk;
    end
  
    if (mclk1_en) begin
      if (pdm_in) 
        acc1 <= acc1 + 1;
      else
        acc1 <= acc1 + { REG_WIDTH{1'b1} };
      acc2 <= acc2 + acc1;
      acc3 <= acc3 + acc2;
    end
  end
  
  always @(posedge m_clk) begin
    mclk2_en     <= '0;
    if (word_count == DEC_RATE - 1) begin
      word_count <= '0;
      mclk2_en   <= ~mclk2_en;
    end else
      word_count <= word_count + 1;
  end    
   
  always @(posedge clk) begin 
    data_valid     <= '0;  
	if (mclk1_en & mclk2_en) begin
      data_valid   <= 1'b1;

      // diff computation 
      diff1_reg   <= acc3;   
      diff1_out   <= acc3  - diff1_reg;
      
      diff2_reg   <= diff1_out;
      diff2_out   <= diff1_out - diff2_reg;
      
      diff3_reg   <= diff2_out;
      diff3_out   <= diff2_out - diff3_reg;
      
      // Output assignment with saturation
      if (diff3_out[REG_WIDTH-1] == 1'b0 && |diff3_out[REG_WIDTH-2:DATA_WIDTH-1])
        // Positive overflow
        data_out <= {1'b0, {DATA_WIDTH-1{1'b1}}};
      else if (diff3_out[REG_WIDTH-1] == 1'b1 && ~&diff3_out[REG_WIDTH-2:DATA_WIDTH-1])
        // Negative overflow
        data_out <= {1'b1, {DATA_WIDTH-1{1'b0}}};
      else
        // Normal case
        data_out <= diff3_out[DATA_WIDTH-1:0];                 
    end     
  end
    
endmodule
