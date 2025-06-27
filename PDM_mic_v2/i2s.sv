`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
module i2s
   #
  (
  parameter SAMPLE_RATE = 34375,
  parameter CLK_FREQ    = 44000000,
  parameter DATA_WIDTH  = 16
  )
  (
  input wire          clk,
  input logic [DATA_WIDTH-1:0] sample,
  input logic         start, 
  output logic        lr_clk,
  output logic        b_clk,
  output logic        i2s_out,
  output logic        inc_mem  
  );

  typedef enum bit [1:0]
                 {IDLE        = 2'b00,
                  START       = 2'b01,
                  SEND_SAMPLE = 2'b10} s_state;
  
  s_state State;

//  localparam LRCLK  = int'(CLK_FREQ/(SAMPLE_RATE));
  localparam BCLK   = int'(CLK_FREQ/(SAMPLE_RATE*DATA_WIDTH));

  logic [$clog2(2*DATA_WIDTH):0]  lr_count;
  logic [$clog2(BCLK)-1:0]        bit_count;
  logic [2*DATA_WIDTH-1:0]        sample_tx;
  logic                           lr_en;
  

  initial begin
    lr_en       = '1;
    lr_clk      = '1;
    b_clk       = '0;
    i2s_out     = '0;
    inc_mem     = '0;
    bit_count   = '0;
    lr_count    = '0;
  end

  always @(posedge clk) begin
    lr_en       <= '1;
       
    if (bit_count == BCLK/2 - 1) begin
      b_clk     <= ~b_clk;
      lr_en     <= ~b_clk;
      bit_count <= '0;
    end else if (start)
      bit_count <= bit_count + 1;
    
    if (~start) begin
      lr_en  <= '1;
      b_clk  <= '0;
    end
  end


  always @(posedge clk) begin
    inc_mem     <= '0; 
    case (State)
      IDLE :
        if (start)
          State     <= START;
        else begin
          lr_clk    <= '1;
          State     <= IDLE;
        end
      START :
        if (~lr_en) begin
          inc_mem   <= '1;
          lr_clk    <= '0;
          lr_count  <= '0;
          sample_tx <= { sample, {DATA_WIDTH{1'b0}} };
          State     <= SEND_SAMPLE;
        end else
          State     <= START;
      SEND_SAMPLE :
        if (~start)
          State     <= IDLE;
        else if (lr_count == 2*DATA_WIDTH-1)      
          State     <= START;
        else if (~lr_en) begin
          {i2s_out, sample_tx}  <= {1'b0, sample_tx} << 1;
          if (lr_count == DATA_WIDTH-1) lr_clk      <= '1;
          lr_count  <= lr_count + 1;
          State     <= SEND_SAMPLE; 
        end else
          State     <= SEND_SAMPLE;
    endcase
  end

endmodule
