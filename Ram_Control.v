`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:05:36 04/27/2015 
// Design Name: 
// Module Name:    Ram_Control 
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
 module Ram_Control(
    input clk,rst,
	 input cs_delay,            //�ӿ���ADת�����Ƕ�ȡ��ʹ���ź�
	 input [7:0] data1_in,       //ram��fpga�������fpga��ȡ����
	 input [7:0] data2_in,
	 input [12:0] address_in,
	 
	 input ram_adj,
	 
	 
	 output reg [7:0] data1_out,   //fpga��ram���
	 output reg [7:0] data2_out,
	 output wire [13:0] address_out,   //ram��ַ
	 output ram_busy,
	 output reg we,
	 output reg en
	 
	 
    );
	 
	 reg [3:0]i_read;            //���ڶ���ʱ��ʱ
	 reg [3:0]i_write;            //����д��ʱ��ʱ
	 reg [7:0] data1_low;
	 reg [7:0] data1_high;
	 reg [7:0] data2_low;
	 reg [7:0] data2_high; 
	 reg address_out_r;
	 
	 assign address_out[13:1] = address_in;             //���ģ�鲻���и�λ��ַ�ı䣬ֻ�������λ�ĵ�ַ�仯��
	 assign address_out[0] = address_out_r;
	 
	 assign ram_busy = en;       //��en�ź���Ч��ʱ�򣬾ʹ�����ram���ڶ�����д״̬������ram_busyʵ���ϵ���en�źţ�Ϊ�˷������ֺ���⣬�ֳ������ź�
	 
	 always @(posedge clk or posedge rst)
	 begin
	 if(rst)
	   begin
		we <= 1'b0;
		en <= 1'b0;
		end
		else
		begin
	   if(cs_delay)
		  begin
		  en <= 1'b1;
		  we <= 1'b0;
		  end
	   else if(en && ~we)
        begin 
		    if(i_read <= 4'b1001) i_read <= i_read+1;          //ÿ������ʹ������ʱ�ӣ���֤��д�����������ʱ�����⣨ԭ����˵ÿ������һ��ʱ��Ҳ�ǿ��еģ�
			 else                                               //��������洢������Ҫ10*2*42=840ns
			   begin
				  en <= 1;
				  we <= 1; 
				end
		  end
		else if(en && we) 
		  begin
		    if(i_write <= 4'b0011) i_write <= i_write+1;       //fpgaƬ��ram����ʱ��ҲΪclk������ÿ����ʱ��д��һ��ֵ���������᲻�ᱨ��  
			 else 
			   begin
				  en <= 0;
				  we <= 0;
				end
		  end
		else
		  begin
		    i_read <= 0;
			 i_write <= 0;
			 en <= 0;
			 we <= 0;
		  end
		end
	 end
	 
	 
	 always @(posedge clk or posedge rst)
	 begin
		if(rst) 
			begin
			address_out_r <= 0; 
			end
		else if(ram_adj)
			begin
				if(en && ~we)
					case(i_read)
					4'b0000 : address_out_r <= 0;                  //�ȶ����Ͱ�λ
					4'b0010 : data1_low <= data1_in; 
					4'b0100 : address_out_r <= 1;                  //���߰�λ
					4'b0110 : data1_high <= data1_in; 
					4'b1000 : {data1_high,data1_low} <= {data1_high,data1_low} + 1;   //�Ͱ�λ�͸߰�λ����һ�𣬾���һ���������ݣ��Ի�ȡ����������+1
					endcase
				else if(en && we)
					case(i_write)
					4'b0000 :begin address_out_r <= 0; data1_out <= data1_low;  end               //�ѵͰ�λд��ram
					4'b0010 :begin address_out_r <= 1; data1_out <= data1_high; end                 //�Ѹ߰�λд��ram
					4'b0100 : data1_out <= data1_out;
					endcase
			end
		else if(~ram_adj)
			begin
				if(en && ~we)
					case(i_read)
					4'b0000 : address_out_r <= 0; 
					4'b0010 : data2_low <= data2_in; 
					4'b0100 : address_out_r <= 1;
					4'b0110 : data2_high <= data2_in; 
					4'b1000 : {data2_high,data2_low} <= {data2_high,data2_low} + 1;
					endcase
				else if(en && we)
					case(i_write)
					4'b0000 : begin address_out_r <= 0;data2_out <= data2_low; end
					4'b0010 : begin address_out_r <= 1;data2_out <= data2_high; end
					4'b0100 : data2_out <= data2_out;
					endcase
			end
	 end
	 
			

endmodule
