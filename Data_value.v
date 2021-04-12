`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:18:47 11/02/2017 
// Design Name: 
// Module Name:    Data_value 
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
module Data_value(
	 input clk,rst,ram_change,
	 input [14:0] address,
 	 input [31:0] sct_period,              //周期计数
 	 input [31:0] sct1_time,               //每个扇区的时间单独计数
	 input [31:0] sct2_time,
	 input [31:0] sct3_time,
	 input [31:0] sct4_time,
	 input [31:0] sct5_time,
	 input [31:0] sct6_time,
	 input [31:0] sct7_time,
	 input [31:0] sct8_time,
	 input [31:0] sct9_time,
	 input [31:0] sct10_time,
	 input [31:0] sct11_time,
	 input [31:0] sct12_time,
	 input [31:0] sct13_time,
	 input [31:0] sct14_time,
	 input [31:0] sct15_time,
	 input [31:0] sct16_time,
	 output reg [7:0] data_CF
    );
	 
	 reg [31:0] sct_period_buf,sct1_time_buf,sct2_time_buf,sct3_time_buf,sct4_time_buf,sct5_time_buf,sct6_time_buf,sct7_time_buf,sct8_time_buf;
	 reg [31:0] sct9_time_buf,sct10_time_buf,sct11_time_buf,sct12_time_buf,sct13_time_buf,sct14_time_buf,sct15_time_buf,sct16_time_buf;
	 
	always @ (posedge ram_change or posedge rst)
	begin 
		if(rst)
		begin
			sct_period_buf <= 0;
			sct1_time_buf <= 0;
			sct2_time_buf <= 0;
			sct3_time_buf <= 0;
			sct4_time_buf <= 0;
			sct5_time_buf <= 0;
			sct6_time_buf <= 0;
			sct7_time_buf <= 0;
			sct8_time_buf <= 0;
			sct9_time_buf <= 0;
			sct10_time_buf <= 0;
			sct11_time_buf <= 0;
			sct12_time_buf <= 0;
			sct13_time_buf <= 0;
			sct14_time_buf <= 0;
			sct15_time_buf <= 0;
			sct16_time_buf <= 0;
		end
		else
		begin
			sct_period_buf <= sct_period;
			sct1_time_buf <= sct1_time;
			sct2_time_buf <= sct2_time;
			sct3_time_buf <= sct3_time;
			sct4_time_buf <= sct4_time;
			sct5_time_buf <= sct5_time;
			sct6_time_buf <= sct6_time;
			sct7_time_buf <= sct7_time;
			sct8_time_buf <= sct8_time;
			sct9_time_buf <= sct9_time;
			sct10_time_buf <= sct10_time;
			sct11_time_buf <= sct11_time;
			sct12_time_buf <= sct12_time;
			sct13_time_buf <= sct13_time;
			sct14_time_buf <= sct14_time;
			sct15_time_buf <= sct15_time;
			sct16_time_buf <= sct16_time;
		end
	end

			

	always @ (posedge clk or posedge rst)
	begin
		if(rst)
			data_CF <= 0;
		else
			if(address[14])
			begin
				case(address[13:0])
				0:	data_CF <= sct_period_buf[7:0];
				1: data_CF <= sct_period_buf[15:8];
				2: data_CF <= sct_period_buf[23:16];
				3: data_CF <= sct_period_buf[31:24];
				4:	data_CF <= sct1_time_buf[7:0];
				5: data_CF <= sct1_time_buf[15:8];
				6: data_CF <= sct1_time_buf[23:16];
				7: data_CF <= sct1_time_buf[31:24];
				8:	data_CF <= sct2_time_buf[7:0];
				9: data_CF <= sct2_time_buf[15:8];
				10: data_CF <= sct2_time_buf[23:16];
				11: data_CF <= sct2_time_buf[31:24];
				12: data_CF <= sct3_time_buf[7:0];
				13: data_CF <= sct3_time_buf[15:8];
				14: data_CF <= sct3_time_buf[23:16];
				15: data_CF <= sct3_time_buf[31:24];
				16: data_CF <= sct4_time_buf[7:0];
				17: data_CF <= sct4_time_buf[15:8];
				18: data_CF <= sct4_time_buf[23:16];
				19: data_CF <= sct4_time_buf[31:24];
				20: data_CF <= sct5_time_buf[7:0];
				21: data_CF <= sct5_time_buf[15:8];
				22: data_CF <= sct5_time_buf[23:16];
				23: data_CF <= sct5_time_buf[31:24];
				24: data_CF <= sct6_time_buf[7:0];
				25: data_CF <= sct6_time_buf[15:8];
				26: data_CF <= sct6_time_buf[23:16];
				27: data_CF <= sct6_time_buf[31:24];
				28: data_CF <= sct7_time_buf[7:0];
				29: data_CF <= sct7_time_buf[15:8];
				30: data_CF <= sct7_time_buf[23:16];
				31: data_CF <= sct7_time_buf[31:24];
				32: data_CF <= sct8_time_buf[7:0];
				33: data_CF <= sct8_time_buf[15:8];
				34: data_CF <= sct8_time_buf[24:16];
				35: data_CF <= sct8_time_buf[31:24];
				36: data_CF <= sct9_time_buf[7:0];
				37: data_CF <= sct9_time_buf[15:8];
				38: data_CF <= sct9_time_buf[23:16];
				39: data_CF <= sct9_time_buf[31:24];
				40: data_CF <= sct10_time_buf[7:0];
				41: data_CF <= sct10_time_buf[15:8];
				42: data_CF <= sct10_time_buf[23:16];
				43: data_CF <= sct10_time_buf[31:24];
				44: data_CF <= sct11_time_buf[7:0];
				45: data_CF <= sct11_time_buf[15:8];
				46: data_CF <= sct11_time_buf[23:16];
				47: data_CF <= sct11_time_buf[31:24];
				48: data_CF <= sct12_time_buf[7:0];
				49: data_CF <= sct12_time_buf[15:8];
				50: data_CF <= sct12_time_buf[23:16];
				51: data_CF <= sct12_time_buf[31:24];
				52: data_CF <= sct13_time_buf[7:0];
				53: data_CF <= sct13_time_buf[15:8];
				54: data_CF <= sct13_time_buf[23:16];
				55: data_CF <= sct13_time_buf[31:24];
				56: data_CF <= sct14_time_buf[7:0];
				57: data_CF <= sct14_time_buf[15:8];
				58: data_CF <= sct14_time_buf[23:16];
				59: data_CF <= sct14_time_buf[31:24];
				60: data_CF <= sct15_time_buf[7:0];
				61: data_CF <= sct15_time_buf[15:8];
				62: data_CF <= sct15_time_buf[23:16];
				63: data_CF <= sct15_time_buf[31:24];
				64: data_CF <= sct16_time_buf[7:0];
				65: data_CF <= sct16_time_buf[15:8];
				66: data_CF <= sct16_time_buf[23:16];
				67: data_CF <= sct16_time_buf[31:24];
				endcase
			end
	end
			

endmodule
