`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module FsmProbe(
    input logic clk, rstN, i, j,
    output logic x, y
    );

    enum bit [2:0] {A=2'b00, B=2'b01, C=2'b10, D=2'b11} State, nextState;

    always_ff @(posedge clk, negedge rstN) begin
        if (~rstN) State <= A;
        else State <= nextState;
    end

    always_comb begin
        {x,y} = 2'b10;
        case (State)
            A: begin
                if (i) begin
                    nextState = B;
                    {x,y} = 2'b11;
                end
                else begin
                    nextState = A;
                    {x,y} = 2'b10;
                end
            end
            B: begin
                if (j) begin
                    nextState = C;
                    {x,y} = 2'b01;
                end
                else begin
                    nextState = D;
                    {x,y} = 2'b10;
                end
            end
            C: begin 
                if ({i,j} == 2'b00) begin
                    nextState = D;
                    {x,y} = 2'b11;
                end
                else if ({i,j} == 2'b01) begin
                    nextState = C;
                    {x,y} = 2'b10;
                end
                else begin
                    nextState = B;
                    {x,y} = 2'b00;
                end
            end
            D: begin 
                if ({i,j} == 2'b00) begin
                    nextState = A;
                    {x,y} = 2'b00;
                end
                else if ({i,j} == 2'b01) begin
                    nextState = C;
                    {x,y} = 2'b10;
                end
                else begin
                    nextState = D;
                    {x,y} = 2'b00;
                end
            end
            default: nextState = A;
        endcase
    end
    
endmodule
