`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
//(* DONT_TOUCH = "yes" *)
module sinc3
  #
  (
   parameter   DEC_RATE  = 80
   )
  (
  input               mclk1,              /* used to mclk1 filter */
  //input logic         reset,              /* used to reset filter */
  input wire          mdata1,             /* input data to be filtered */
  //output logic [15:0] DATA, /* filtered output */
  output logic [7:0]  DATA, /* filtered output */
  output logic        data_en
   );
  
  /* Data is read on positive mclk1 edge */
  logic [$clog2(DEC_RATE)-1:0] word_count;
  //(* dont_touch = "true" *
  logic [21:0] acc1;
  logic [21:0] acc2;
  logic [21:0] acc3;
  logic [21:0] acc3_d2;
  logic [21:0] diff1;
  logic [21:0] diff2;
  logic [21:0] diff3;
  logic [21:0] diff1_d;
  logic [21:0] diff2_d;
  logic mclk1_en;
  
  initial begin
    acc1        = '0;
    acc2        = '0;
    acc3        = '0;
    acc3_d2     = '0;
    diff1_d     = '0;
    diff2_d     = '0;
    diff1       = '0;
    diff2       = '0;
    diff3       = '0;
    word_count  = '0;
    mclk1_en    = '0;
    data_en     = '0;
  end
  
  
  always @(posedge mclk1) begin
    mclk1_en     <= '0;
    data_en      <= '0;
    acc1 <= acc1 + mdata1;
    acc2 <= acc2 + acc1;
    acc3 <= acc3 + acc2;
    
    if (word_count == DEC_RATE - 1)
      word_count <= '0;
    else begin
      word_count <= word_count + 1;
      if (word_count == DEC_RATE - 2)
        mclk1_en   <= ~mclk1_en;
    end
  
    if (mclk1_en) begin
      data_en <= 1'b1;
      DATA    <= diff3[20:13];
    
      diff1   <= acc3 - acc3_d2;
      diff2   <= diff1 - diff1_d;
      diff3   <= diff2 - diff2_d;
      acc3_d2 <= acc3;
      diff1_d <= diff1;
      diff2_d <= diff2;
    end     
  end
  
endmodule

