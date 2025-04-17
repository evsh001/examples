module sinc3
  #
  (
   parameter   DEC_RATE  = 100
   )
  (
  input mclk1,              /* used to mclk1 filter */
  input reset,              /* used to reset filter */
  input mdata1,             /* input data to be filtered */
  output logic [15:0] DATA, /* filtered output */
  output logic data_en,
   );
  
  /* Data is read on positive mclk1 edge */
  logic [$clog2(DEC_RATE)-1:0] word_count;
  logic [21:0] ip_data1;
  logic [21:0] acc1;
  logic [21:0] acc2;
  logic [21:0] acc3;
  logic [21:0] acc3_d2;
  logic [21:0] diff1;
  logic [21:0] diff2;
  logic [21:0] diff3;
  logic [21:0] diff1_d;
  logic [21:0] diff2_d;
  logic word_mclk1;
  //logic enable;
  
  /*Perform the Sinc action*/
  always_comb @(mdata1) begin
    if(mdata1==0)
      ip_data1 <= 22'd0;
  /* change 0 to a -1 for twos complement */
    else
      ip_data1 <= 22'd1;
  end
  
  /*Accumulator (Integrator)
  Perform the accumulation (IIR) at the speed of the modulator.
  Z = one sample delay Mmclk1OUT = modulators conversion bit rate */
  always @(negedge mclk1, posedge reset) begin
    if (reset) begin
  /* initialize acc registers on reset */
      acc1 <= 22'd0;
      acc2 <= 22'd0;
      acc3 <= 22'd0;
    end else begin
      /*perform accumulation process */
      acc1 <= acc1 + ip_data1;
      acc2 <= acc2 + acc1;
      acc3 <= acc3 + acc2;
    end
  end
  
  /*decimation stage (Mmclk1OUT/WORD_mclk1) */
  always @(posedge mclk1, posedge reset) begin
    if (reset)
      word_count <= 16'd0;
    else begin
      if ( word_count == DEC_RATE - 1 )
        word_count <= 16'd0;
      else
        word_count <= word_count + 16'b1;
    end
  end
  
  always @( posedge mclk1, posedge reset ) begin
    if ( reset )
      word_mclk1 <= 1'b0;
    else begin
      if ( word_count == DEC_RATE/2 - 1 )
        word_mclk1 <= 1'b1;
      else if ( word_count == DEC_RATE - 1 )
        word_mclk1 <= 1'b0;
    end
  end
  
  /*Differentiator (including decimation stage)
  Perform the differentiation stage (FIR) at a lower speed.
  Z = one sample delay WORD_mclk1 = output word rate */
  always @(posedge word_mclk1, posedge reset) begin
    if(reset) begin
      acc3_d2 <= 22'd0;
      diff1_d <= 22'd0;
      diff2_d <= 22'd0;
      diff1   <= 22'd0;
      diff2   <= 22'd0;
      diff3   <= 22'd0;
    end else begin
      diff1   <= acc3 - acc3_d2;
      diff2   <= diff1 - diff1_d;
      diff3   <= diff2 - diff2_d;
      acc3_d2 <= acc3;
      diff1_d <= diff1;
      diff2_d <= diff2;
    end
  end
  
  /* Clock the Sinc output into an output register WORD_mclk1 = output word rate
  always @ ( posedge word_mclk1 ) begin
    case ( DEC_RATE )
      16'd32:begin
        DATA <= (diff3[15:0] == 16'h8000) ? 16'hFFFF : {diff3[14:0], 1'b0};
      end
      16'd64:begin
        DATA <= (diff3[18:2] == 17'h10000) ? 16'hFFFF : diff3[17:2];
      end
      16'd128:begin
        DATA <= (diff3[21:5] == 17'h10000) ? 16'hFFFF : diff3[20:5];
      end
      16'd256:begin
        DATA <= (diff3[24:8] == 17'h10000) ? 16'hFFFF : diff3[23:8];
      end
      default:begin
        DATA <= (diff3[24:8] == 17'h10000) ? 16'hFFFF : diff3[23:8];
      end
    endcase
  end */
  
    
  always @( posedge word_mclk1 ) begin
    DATA <= diff3[20:5];
  
  /* Synchronize Data Output
  always@ ( posedge mclk1, posedge reset ) begin
    if ( reset ) begin
      data_en <= 1'b0;
      enable  <= 1'b1;
    end else begin
      if ( (word_count == DEC_RATE/2 - 1) && enable ) begin
        data_en <= 1'b1;
        enable  <= 1'b0;
      end else if ( (word_count == DEC_RATE - 1) && ~enable ) begin
        data_en <= 1'b0;
        enable  <= 1'b1;
      end else
        data_en <= 1'b0;
    end
  end */
  
  always @( posedge mclk1, posedge reset ) begin
    if ( reset ) begin
      data_en <= 1'b0;
    end else begin
      if ( word_count == DEC_RATE/2 - 1 )
        data_en <= 1'b1;
      else
        data_en <= 1'b0;
    end
  end
  
endmodule
