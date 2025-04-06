`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module tb();
    logic         clk;
    logic [7:0]   SW;
    logic         tx_out;    
    
    uart_top u_uart_top( .* );
    
    initial begin
      clk    = '0;
      SW     = 7'h63;
    end
    
    always begin
      clk = #5 ~clk;
    end
     
endmodule
