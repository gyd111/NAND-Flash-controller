`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:44:07 04/03/2018 
// Design Name: 
// Module Name:    erase_flash 
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
module erase_flash(
	input rst,clk,en_erase_page,
	input [4:0]state,
	input [23:0] erase_addr_row, 
	output reg [1:0]erase_addr_row_error,			//擦除坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	input [7:0]erase_flash_dataout,					//FLASH输出的数据，用于状态寄存器的检测
	output [7:0] erase_flash_datain,					//擦除模块数据输出，用于输出命令
	output [11:0]erase_bad_block_ram_addr,			//检索坏块表地址
	input erase_bad_block_ram_dataout,				//坏块表输出的数据，1表示该块为坏块，0表示该块为好块
	output reg [1:0] erase_success
    );


	reg [1:0] n;
	reg m;
//*************     write_write_cmd模块      *************//
	wire [7:0] cmd_start,cmd_finish,cmd_data;

//*************     write_write_add模块      *************//
	wire [15:0] addr_column;
	wire [7:0] addr_data;


	assign cmd_start = 8'h60;
	assign cmd_finish = 8'hD0;
	assign addr_column = 16'h0000;
	
	assign erase_flash_datain = en_erase_page ? (addr_data | cmd_data) : 0;
	assign erase_bad_block_ram_addr = erase_addr_row[18:7];
	
	always @(posedge clk or posedge rst)					//写地址初始化,检索坏块表以及每次写完一页后自动+1
	begin
	if(rst)
	begin
		erase_addr_row_error <= 0;
		m <= 0;
	end
	else
		begin
			if(en_erase_page)
			if(m == 0)
				m <= 1;
			else
			begin
				if(erase_bad_block_ram_dataout)	
						erase_addr_row_error <= 2;
				else
					erase_addr_row_error <= 1;
			end
			else
			begin
				erase_addr_row_error <= 0;
				m <= 0;
			end
		end
	end

	always @(posedge clk or posedge rst)			//完成擦除操作后读取状态寄存器，给写成功信号赋值
	begin
	if(rst)
	begin
		erase_success <= 0;
		n <= 0;
	end
	else
		if(en_erase_page)
		if(state == 16) // state 16 是读取状态寄存器值的状态
		begin
			if(n < 2)
				n <= n+1;
			else
			begin
				n <= 0;
				if( !erase_flash_dataout[0] )
					erase_success <= 1;
				else
					erase_success <= 2;
			end
		end
		else
			erase_success <= 0;
	end


//****************************************************//
//			 				写命令				 						//
//****************************************************//

	write_cmd  erase_write_cmd(	
	.clk(clk),
	.rst(rst),
	.cmd_start(cmd_start),
	.cmd_finish(cmd_finish),
	.cmd_data(cmd_data),
	.state(state)
	);

//****************************************************//
//			 				写地址				 						//
//****************************************************//

	write_addr  erase_write_addr(	
	.clk(clk),
	.rst(rst),
	.addr_column(addr_column),
	.addr_row(erase_addr_row),
	.addr_data(addr_data),
	.state(state)
	);

endmodule
