`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:33:51 11/01/2017 
// Design Name: 
// Module Name:    Clear_ram 
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
module Clear_ram(
	input en_clr,
	input clk,
	input rst,
	input ram_change,
	output reg en_ram_clr,
	output reg we_ram_clr,
	output [7:0] ram_data_clr,
	output reg [14:0] address_clr,
	output end_clr	
    );

	always @ (posedge clk or posedge rst)
	begin
		if(rst)
			begin
				en_ram_clr <= 0;
				we_ram_clr <= 0;
			end
		else
			if(en_clr)
			begin
				en_ram_clr <= 1;
				we_ram_clr <= 1;
			end
			else
				if(address_clr > 0)
				begin
					en_ram_clr <= 0;
					we_ram_clr <= 0;
				end
	end
	
	always @(posedge clk or posedge rst)
	begin
	   if(rst) 
			begin 
			address_clr <= 0;
			end
		else
			 begin 
				if(ram_change) address_clr <= 0;
				else if(en_clr && en_ram_clr && we_ram_clr) address_clr <= address_clr +1;
			 end
	end

	assign end_clr = (address_clr == 15'b1_0000_0_00000000_0); //ÇåÁãram½áÊø
	assign ram_data_clr = 8'b00000000;

endmodule
