`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:17:31 04/03/2018 
// Design Name: 
// Module Name:    write_cmd 
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
module write_cmd(
	input clk,rst,
	input [7:0] cmd_start,cmd_finish,
	input [4:0] state,
	output reg [7:0] cmd_data
    );


	always @(posedge clk or posedge rst)
		begin
			if(rst)
			begin
				cmd_data <= 0;
			end
			else
			begin
				case(state)
				2:						// д����״̬
				begin
					cmd_data <= cmd_start[7:0];	//д����
				end
				3:
				begin
					cmd_data <= cmd_finish[7:0]; //д��������
				end
				11:									//д��ʼ������
				begin
					cmd_data <= 8'hFF;
				end
				15:									//д���״̬�Ĵ�������
				begin
					cmd_data <= 8'h70;			
				end
				default
					cmd_data <= 8'h00;
				endcase
			end
		end


endmodule
