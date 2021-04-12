`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:44:47 04/03/2018 
// Design Name: 
// Module Name:    bad_blcok_manage 
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
module bad_block_manage(
	input rst,clk,
	input [23:0]erase_addr_row,
	input en_erase_page,
	input [4:0] state,
	
	output reg end_bad_block_renew,							//结束坏块更新，控制状态
	output [11:0]bad_block_renew_addr,
	output reg we_bad_block_renew,
	output bad_block_renew_datain,			
	output reg en_bad_block_renew_transfer					//向MCU发送更新后的坏块表标志信号
    );
	 	 
	reg [11:0] bad_block_addr;
	reg [1:0] i;

	assign bad_block_renew_addr = bad_block_addr;
	assign bad_block_renew_datain = (state == 17) ? 1 : 0;

	always @(posedge clk or posedge rst)			//确定坏块地址
	begin
		if(rst)
			bad_block_addr <= 0;
		else
			if(state == 17)
			begin
				if(en_erase_page)
				bad_block_addr <= erase_addr_row[18:7];
			end
			else
				bad_block_addr <= 0;
	end
	
	always @(posedge clk or posedge rst)		//对we赋值，以保证每次写坏块ram都是在地址已经被赋值为坏块地址后
	begin
		if(rst)
		begin
			we_bad_block_renew <= 0;
			end_bad_block_renew <= 0;
			en_bad_block_renew_transfer <= 0;
			i<=0;
		end
		else
			if(state == 17)
				if(i < 2)
				begin
					we_bad_block_renew <=0;
					i <= i+1;
				end
				else if(i == 2)
				begin
					we_bad_block_renew <= 1;
					en_bad_block_renew_transfer <= 1;
					i <= 3;
				end
				else
				begin
					end_bad_block_renew <= 1;
					we_bad_block_renew <= 0;
					en_bad_block_renew_transfer <= 0;
				end
			else
			begin
				i <= 0;
				we_bad_block_renew <= 0;
				end_bad_block_renew <= 0;
				en_bad_block_renew_transfer <= 0;
			end
	end

endmodule
