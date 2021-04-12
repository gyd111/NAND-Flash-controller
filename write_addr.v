`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:17:46 04/03/2018 
// Design Name: 
// Module Name:    write_addr 
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
module write_addr(
	input clk,rst,
	input [15:0] addr_column,
	input [23:0] addr_row,
	input [4:0] state,
	output reg [7:0] addr_data
    );
	always @(posedge clk or posedge rst)
		begin
		if(rst)
			addr_data <= 0;
		else
		begin
			case(state)
			4:
				addr_data <= addr_column[7:0];	// 写列地址C1
			5:
				addr_data <= addr_column[15:8];	// 写列地址C2
			6:
				addr_data <= addr_row[7:0];		// 写行地址R1
			7:
				addr_data <= addr_row[15:8];		// 写行地址R2
			8:
				addr_data <= addr_row[23:16];		// 写行地址R3
			default
				addr_data <= 8'h00;
			endcase
		end
		end

endmodule
