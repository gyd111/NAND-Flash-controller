`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:06:07 04/08/2015 
// Design Name: 
// Module Name:    Analog 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Sector_Counter(
	input sct1,sct2,rst,clk,
	input clk1M,
	input ram_change,
	
	input sct_id_ready,		//��Ƭ����õ������Ѿ�׼������
   input [3:0] sct_id_MCU,	//��Ƭ����õ�������
	output not_rotate,		//������ת����
	
	output [31:0] out_period,             //���ڼ���
	output [3:0] out_address,              //������ַ
	output [31:0] out_time1,               //ÿ��������ʱ�䵥������
	output [31:0] out_time2,
	output [31:0] out_time3,
	output [31:0] out_time4,
	output [31:0] out_time5,
	output [31:0] out_time6,
	output [31:0] out_time7,
	output [31:0] out_time8,
	output [31:0] out_time9,
	output [31:0] out_time10,
	output [31:0] out_time11,
	output [31:0] out_time12,
	output [31:0] out_time13,
	output [31:0] out_time14,
	output [31:0] out_time15,
	output [31:0] out_time16
		 );
   
   wire en1,en2,en3,en4,en5,en6,en7,en8,en9,en10,en11,en12,en13,en14,en15,en16;
	//����ÿ������ʱ���������ʹ���ź�
   
	//�������� 
   Counter_Period Sct_Period (      // ��������
    .out(out_period), 
	 .clk(clk),
    .rst(rst), 
    .sct1(sct1),
	 .ram_change(ram_change)	 
    );
   Counter_Address Sct_Address (       //����ÿ����������Ϊ��ַ
    .out(out_address), 
	 .clk(clk),
    .rst(rst), 
	 .sct_id_ready(sct_id_ready),		//��Ƭ����õ������Ѿ�׼������
    .sct_id_MCU(sct_id_MCU),	//��Ƭ����õ�������
	 .sct1(sct1),
    .sct2(sct2),
	 .not_rotate(not_rotate)
    );
	Counter_Time Sct_Time1 (          //����1��ʱ�����
	 .out(out_time1), 
    .rst(rst), 
    .en(en1),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	Counter_Time Sct_Time2 (          //����2��ʱ�����
	 .out(out_time2), 
    .rst(rst), 
    .en(en2),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time3 (
	 .out(out_time3), 
    .rst(rst), 
    .en(en3),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time4 (
	 .out(out_time4), 
    .rst(rst), 
    .en(en4),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time5 (
	 .out(out_time5), 
    .rst(rst), 
    .en(en5),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time6 (
	 .out(out_time6), 
    .rst(rst), 
    .en(en6),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time7 (
	 .out(out_time7), 
    .rst(rst), 
    .en(en7),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time8 (
	 .out(out_time8), 
    .rst(rst), 
    .en(en8),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time9 (
	 .out(out_time9), 
    .rst(rst), 
    .en(en9),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time10 (
	 .out(out_time10), 
    .rst(rst), 
    .en(en10),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time11 (
	 .out(out_time11), 
    .rst(rst), 
    .en(en11),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time12 (
	 .out(out_time12), 
    .rst(rst), 
    .en(en12),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );	 
	 Counter_Time Sct_Time13 (
	 .out(out_time13), 
    .rst(rst), 
    .en(en13),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time14 (
	 .out(out_time14), 
    .rst(rst), 
    .en(en14),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time15 (
	 .out(out_time15), 
    .rst(rst), 
    .en(en15),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 Counter_Time Sct_Time16 (
	 .out(out_time16), 
    .rst(rst), 
    .en(en16),
	 .ram_change(ram_change),
	 .clk(clk1M)
    );
	 
	 assign en1 = (out_address == 4'h0 && ~rst);    //ʹ���źŶ�̬��ֵ
	 assign en2 = (out_address == 4'h1 && ~rst);	 //��⵽��Ӧ����������󣬼�����Ӧʹ��
	 assign en3 = (out_address == 4'h2 && ~rst);
	 assign en4 = (out_address == 4'h3 && ~rst);
	 assign en5 = (out_address == 4'h4 && ~rst);
	 assign en6 = (out_address == 4'h5 && ~rst);
	 assign en7 = (out_address == 4'h6 && ~rst);
	 assign en8 = (out_address == 4'h7 && ~rst);
	 assign en9 = (out_address == 4'h8 && ~rst);
	 assign en10 = (out_address == 4'h9 && ~rst);
	 assign en11 = (out_address == 4'hA && ~rst);
	 assign en12 = (out_address == 4'hB && ~rst);
	 assign en13 = (out_address == 4'hC && ~rst);
	 assign en14 = (out_address == 4'hD && ~rst);
	 assign en15 = (out_address == 4'hE && ~rst);
	 assign en16 = (out_address == 4'hF && ~rst);
	 

endmodule
