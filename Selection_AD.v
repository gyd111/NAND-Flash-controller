`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:44:39 12/06/2015 
// Design Name: 
// Module Name:    Selection_AD 
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
module Selection_AD(
	input clk,rst,
	input cs_delay1,
	input cs_delay2,
	input [12:0] ad_address1,
	input [12:0] ad_address2,
	input cs1,
	input cs2,
	input ram_busy,
	
	output cs_delay,
	output reg ad_adj,
	output [12:0] ad_address  //�����ram_controlģ�飬������ַ
    );
	
	reg cs1_r1,cs1_r2;          //���������ػ����½��ص��ж�
	reg cs2_r1,cs2_r2;
	reg ram_busy_r1,ram_busy_r2;
	reg ad1_sel,ad2_sel;
	wire neg_cs1;
	wire neg_cs2;
	wire neg_ram_busy;
	
	always @(posedge clk or posedge rst)			//ͬ�� �첽�ź�
	begin
	  if(rst)
	    begin
		 cs1_r1 <= 0; cs1_r2 <= 0;
		 cs2_r1 <= 0; cs2_r2 <= 0;
		 ram_busy_r1 <= 0; ram_busy_r2 <= 0;
		 end
	  else
	    begin
		 cs1_r1 <= cs1; cs1_r2 <= cs1_r1;
		 cs2_r1 <= cs2; cs2_r2 <= cs2_r1;
		 ram_busy_r1 <= ram_busy; ram_busy_r2 <= ram_busy_r1;
		 end
	end
	
	assign neg_cs1 = ~cs1_r1 && cs1_r2;
	assign neg_cs2 = ~cs2_r1 && cs2_r2;
	assign neg_ram_busy = ~ram_busy_r1 && ram_busy_r2;
	
	//����һ��ad��ʼ�������źţ�����ź�ֱ����һ��ram--busy���������ͣ���������źſ�����ֹ����һ��ad��ʼ�ɼ����������ݴ洢����
	//��һ��ʱ��������һ��adҲ��ʼ�ɼ��ˣ���ôѡ��ad�ı�־λ ����ѡ��ڶ�����ʼ�ɼ���ad
	//�������Ϊ��һ��ad�ӿ�ʼ�ɼ����������ݴ洢�����ı�־λ
	//20160715
	always @(posedge clk or posedge rst)		
	begin
		if(rst) ad1_sel <= 0;
		else
		begin
			if(neg_ram_busy && cs1) ad1_sel <= 0;
			else if(neg_cs1) ad1_sel <= 1;
			else ad1_sel <= ad1_sel;
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if(rst) ad2_sel <= 0;
		else
		begin
			if(neg_ram_busy && cs2) ad2_sel <= 0;
			else if(neg_cs2) ad2_sel <= 1;
			else ad2_sel <= ad2_sel;
		end
	end
	
	always @(posedge clk)						//��������
		begin
			if(neg_cs1 || neg_cs2 || neg_ram_busy)
			begin
				if(neg_ram_busy) ad_adj <= ~ad_adj;  //ram_busy�½��أ���ram�洢������ʱ��ѡ����һ��ad
				else if(~cs1 && ~ad2_sel) ad_adj <= 1;	//ad1�½���ͬʱ����һ��adû�д��ڲɼ��洢�����У�ѡ��ad1
				else if(~cs2 && ~ad1_sel) ad_adj <= 0;
            else ad_adj <= ad_adj;				
			end
		end
	 
	 assign cs_delay = ad_adj ? cs_delay1 : cs_delay2;
	 assign ad_address = ad_adj ? ad_address1 : ad_address2;

endmodule
