`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:23:41 03/14/2016 
// Design Name: 
// Module Name:    Change_ram 
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
module Change_ram(
	input clk,
	input rst,
	input change_ram,
	input ram_busy,
	
	output ram_change,      //��ӳram_adj�ı仯�����ram_adj�仯��Ϊ1������Ϊ0
	output reg ram_adj
    );
	
	reg a1_ram_adj,a2_ram_adj;//���ڼ��ram_adj���������½���
	wire pos_change_ram;
	
	reg change_ram_r1; //���������
	reg change_ram_r2;
	reg hold_change;	//���������л�ָ��
	
	
	always@(posedge clk or posedge rst)   //���������
	begin
		if(rst) begin change_ram_r1 <= 0; change_ram_r2 <= 0; end
		else 
			begin
			change_ram_r1 <= change_ram;
			change_ram_r2 <= change_ram_r1;
			end
	end
	
	assign pos_change_ram = ~change_ram_r2 && change_ram_r1;  //���������
	
	
	always@(posedge clk or posedge rst)  //�л�ram
	begin
		if(rst) begin 
		  ram_adj <= 0; 
		  hold_change <= 0;
		end
		else 
			begin
				if(ram_busy)
					begin
						if(pos_change_ram) hold_change <= 1; //����յ��л�ram��ָ�����ram���ڶ�д����ͨ��hold_change�������л�ָ�
					end
				else
					begin
						if(pos_change_ram) begin ram_adj <= ~ram_adj; hold_change <= 0; end
						else if(hold_change) begin ram_adj <= ~ram_adj; hold_change <= 0; end //���ram��busy�ˣ��ּ�⵽�ոձ�����л�ָ����л�ram��
					end
			end
	end
	
	 always @(posedge clk or posedge rst)      //�ж�ram_adj�ı仯�������ػ����½���
	 begin
	   if(rst)
		  begin
		  a1_ram_adj <= 1;                      //ͨ���ı��������ĳ�ʼֵ���Ծ����ʼ�ĵ�һ������ 
	     a2_ram_adj <= 1;
		  end
		else 
		  begin
		  a1_ram_adj <= ram_adj;
		  a2_ram_adj <= a1_ram_adj;
		  end
	 end
	 
	 assign ram_change = (a1_ram_adj != a2_ram_adj)? 1'b1:1'b0;  //������������ʱ��˵��ram_adj�����˱仯

endmodule
