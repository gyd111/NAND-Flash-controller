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
	 input cs_delay,            //接控制AD转换还是读取的使能信号
	 input [7:0] data1_in,       //ram向fpga输出，即fpga读取数据
	 input [7:0] data2_in,
	 input [12:0] address_in,
	 
	 input ram_adj,
	 
	 
	 output reg [7:0] data1_out,   //fpga向ram输出
	 output reg [7:0] data2_out,
	 output wire [13:0] address_out,   //ram地址
	 output ram_busy,
	 output reg we,
	 output reg en
	 
	 
    );
	 
	 reg [3:0]i_read;            //用于读的时候定时
	 reg [3:0]i_write;            //用于写的时候定时
	 reg [7:0] data1_low;
	 reg [7:0] data1_high;
	 reg [7:0] data2_low;
	 reg [7:0] data2_high; 
	 reg address_out_r;
	 
	 assign address_out[13:1] = address_in;             //这个模块不进行高位地址改变，只进行最低位的地址变化。
	 assign address_out[0] = address_out_r;
	 
	 assign ram_busy = en;       //当en信号有效的时候，就代表着ram处于读或者写状态，所以ram_busy实际上等于en信号，为了方便区分和理解，分成两个信号
	 
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
		    if(i_read <= 4'b1001) i_read <= i_read+1;          //每步操作使用三个时钟，保证读写操作不会出现时序问题（原理上说每步操作一个时钟也是可行的）
			 else                                               //完成整个存储过程需要10*2*42=840ns
			   begin
				  en <= 1;
				  we <= 1; 
				end
		  end
		else if(en && we) 
		  begin
		    if(i_write <= 4'b0011) i_write <= i_write+1;       //fpga片内ram所用时钟也为clk，尝试每三个时钟写入一个值，看看还会不会报错  
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
					4'b0000 : address_out_r <= 0;                  //先读出低八位
					4'b0010 : data1_low <= data1_in; 
					4'b0100 : address_out_r <= 1;                  //读高八位
					4'b0110 : data1_high <= data1_in; 
					4'b1000 : {data1_high,data1_low} <= {data1_high,data1_low} + 1;   //低八位和高八位放在一起，就是一个能谱数据，对获取的能谱数据+1
					endcase
				else if(en && we)
					case(i_write)
					4'b0000 :begin address_out_r <= 0; data1_out <= data1_low;  end               //把低八位写入ram
					4'b0010 :begin address_out_r <= 1; data1_out <= data1_high; end                 //把高八位写入ram
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
