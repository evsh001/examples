`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////

module testbench();
    logic       clk;
    
    // Microphone interface
    logic       m_clk;
    logic       m_data;
//    logic       m_lr_sel;
    
    logic       tx_out;
    
    logic       BTNW;
    logic       BTNT;
    logic       BTNI2S;
    
    logic [3:0] LED;
    
    // Audio I2S interface
    logic       lr_clk;
    logic       b_clk;
    logic       i2s_out;
      
    top_pdm u_top_pdm( .* );
        
    initial begin
      //$monitor($time, " button_csync=%b, start_capture=%b", u_pdm_top.button_csync, u_pdm_top.start_capture);
      m_data = '0;
      clk    = '0;
//      BTNW =   '0;
      BTNW =   '0;
      BTNT =   '0;
      LED  =   '0;
      BTNI2S = '0;
//      audio_out ='0;
      
      BTNI2S <= #20 1;
      BTNI2S <= #30 0;
      repeat (6000) @(posedge clk);
      $stop;
         
    end
    
    always begin
      clk = #5 ~clk;
    end
    
    always @(posedge m_clk) begin
      m_data <= $urandom_range(0,1);
      //$display($time, " counter[0]=%d, counter[1]=%d", u_pdm_top.pdm_inputs.counter[0], u_pdm_top.pdm_inputs.counter[1]);
      //$display($time, " sp_cntr[0]=%d, sp_cntr[1]=%d", u_pdm_top.pdm_inputs.sample_counter[0], u_pdm_top.pdm_inputs.sample_counter[1]);
    end
    
      
endmodule
