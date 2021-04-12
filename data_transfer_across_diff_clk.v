`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 跨时钟域使能信号传输
// 可以进行快到慢传输
//data_transfer_across_diff_clk
//#(.lenth(6))
//trans1(
//.out_clk( ),
//.rst( ),
//.trigger_signal_fts(  ),
//.trigger_signal_stf(   ),
//.rise_edge_out_fts( ),
//.fall_edge_out_fts( ),
//.rise_edge_out_stf(  ),
//.fall_edge_out_stf( )
//);
//////////////////////////////////////////////////////////////////////////////////


module data_transfer_across_diff_clk
    #(parameter     lenth = 1)
    (
    input [lenth-1 : 0] trigger_signal_fts,//快时钟 到 慢时钟
    input [lenth-1 : 0] trigger_signal_stf,//慢时钟 到 快时钟
    input               out_clk,
    input               rst,
    output[lenth-1 : 0] rise_edge_out_fts,
    output[lenth-1 : 0] fall_edge_out_fts,
    output[lenth-1 : 0] rise_edge_out_stf,
    output[lenth-1 : 0] fall_edge_out_stf
    );

reg[lenth-1 : 0]  temp1 = 0,temp2,temp3,temp4,temp5;
reg clr;

always@(trigger_signal_fts,clr)
begin
    if(trigger_signal_fts != 0)
        temp1 = trigger_signal_fts;
    if(clr)
        temp1 = 0;
end

always@(posedge rst or posedge out_clk)
begin
    if(rst)
    begin
        clr <= 0;
        temp2 <= 0;
        temp3 <= 0;
    end
    else
    begin
        if(temp1 != 0)
            clr <= 1;
        else
            clr <= 0;
        temp2 <= temp1;
        temp3 <= temp2;
    end
end

assign rise_edge_out_fts = temp2 & ~ temp3;
assign fall_edge_out_fts = ~temp2 & temp3;

always@(posedge rst or posedge out_clk)
begin
    if(rst)
    begin
        temp4 <= 0;
        temp5 <= 0;
    end
    else
    begin
        temp4 <= trigger_signal_stf;
        temp5 <= temp4;
    end
end

assign rise_edge_out_stf = temp4 & ~ temp5;
assign fall_edge_out_stf = ~temp4 & temp5;

endmodule
