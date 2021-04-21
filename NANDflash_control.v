`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:12:14 04/08/2018 
// Design Name: 
// Module Name:    NANDflash_control 
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
module NANDflash_control(
	input clk,rst,clk6M,clk12M,
	
	input [31:0]cmd,						//命令接收模块接收并初步处理后的命令,[31:24]为命令，[23:16]为计数，[15:0]为数据
	input start_trs,						//命令到来脉冲信号
	
	input en_read_FPGA,                    //Data_download模块输出的读使能信号
	input [23:0] read_addr_FPGA,          //Data_download模块输出的读地址
	input [7:0]flash_ram_dataout,
	output [7:0]flash_ram_datain,
	output flash_en_ram,flash_we_ram,
	output reg[14:0]flash_ram_addr,
	
	output inout_flag,							//表示flash的io口何时处于输出何时处于输入用,0为输入，1为输出
	output read_flag,								//表示flash处于读状态，因为读状态时FLASH操作的ram和MCU操作的是两个ram，而写状态是操作同一个ram		
	
	input [7:0]flash_dataout,									//flash输出数据
	output [7:0]flash_datain,									//flash输入数据
	input ready_busy,												//flash空闲/忙碌标志信号
	output ce,cle,ale,we,re,									//flash控制信号
	
	output en_bad_block_renew_transfer,						//向MCU发送更新后的坏块表标志脉冲
	output [11:0]bad_block_renew_addr,						//坏块地址
	
	input end_writeAddr_Transfer,
	output en_writeAddr_Transfer,
	output [23:0]write_addr_row,
	
	output end_init_flash_addr,
	output end_erase,
	output flash_cmd_incomplete,
	output nandflash_busy_Noresponse,
	output end_read ,
	
	output wire [4:0]state
	
    );
//*************   command_receive模块    *************//
	wire [23:0] erase_addr_start,erase_addr_finish;		//擦除模块的起始地址和结束地址
	wire [23:0] read_addr_row_reg,read_addr_row_reg_1;	//读模块的行地址
	wire en_read_1,en_read;
	wire en_erase;
	wire en_write;
	wire en_log_write;
    
	wire [23:0] init_addr_row;									//写模块的初始化写地址
	wire en_init_flash_addr;
	wire end_write;
	
	wire [7:0] init_bad_block_ram_data;						//初始化坏块表ram数据
	wire [8:0] init_bad_block_ram_addr;						//初始化坏块表ram地址
	wire en_init_bad_block_ram,we_init_bad_block_ram;	//初始化坏块表ram的控制信号
	
	wire en_infopage_write,end_infopage_write;
//*************    read_flash_control模块    *************//
	wire [7:0]read_data;
	wire [23:0] read_addr_row;
	
	wire [7:0]read_ram_dataout;
	wire [7:0]read_ram_datain;
	wire [14:0]read_ram_addr;
	wire read_en_ram,read_we_ram;
	
//*************   write_flash_control模块    *************//
	wire en_write_page,end_write_page;
	wire [7:0] write_data;
	
	wire write_en_ram;						
	wire [14:0]write_ram_addr;
	wire [7:0]write_ram_dataout;
	
//*************   erase_flash_control模块    *************//
	wire en_erase_page,end_erase_page;
	wire [23:0]erase_addr_row;

//************* basic_NANDflash_control模块  *************//
	

	wire [13:0]write_data_cnt;
	wire [1:0]write_addr_row_error;						//写操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	wire [1:0]write_success;								//写成功标志,用于写操作中检测状态寄存器BIT0判断写入状况。1为操作成功，0为操作失败

	wire [13:0]read_data_cnt;								//读数据计数
	wire [1:0]read_addr_row_error;						//读操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	wire [1:0]read_data_ECCstate;							//数据ECC状态，0为没完成检测，1为ECC校验正确，2为ECC校验错误但是可以修正，3为ECC校验后数据无效
	wire [15:0]read_data_change_addr;					//需要修改的数据所在位置，前13位为错误的字节地址，后3位为翻转位为该字节的位置								//读标志，用于区分状态10内是在读数据还是在读ECC码。

	wire [1:0]erase_addr_row_error;						//擦除操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	
	assign flash_en_ram = en_write ? write_en_ram :  read_en_ram ;
	assign flash_we_ram = read_we_ram;
	assign flash_ram_datain = read_ram_datain;
	assign write_ram_dataout = en_write ? flash_ram_dataout : 0;
	assign read_ram_dataout = flash_ram_dataout;
	
	assign inout_flag = (state == 10 | state == 16) ? 1 : 0;
	
//	assign en_read = change_bypass ? en_read_FPGA:en_read_1;     //修改，取消fpga读取
    assign en_read = en_read_1;
//	assign read_addr_row_reg = change_bypass ? read_addr_FPGA:read_addr_row_reg_1;   //修改
    assign read_addr_row_reg = read_addr_row_reg_1;
	assign read_flag = en_read_1;
	
   //***************测试程序段**************//
	always@(negedge clk or posedge rst)
	begin
	  if(rst)
	    flash_ram_addr <=0;
     else
       flash_ram_addr <= en_write ? write_ram_addr :  read_ram_addr;	  
	end
	
//****************************************************//
//    	 			  flash相关命令接受 						//
//****************************************************//	 

	flash_command_receiver flash_command_receiver (
    .clk(clk), 
    .rst(rst), 
    .cmd(cmd), 
    .start_trs(start_trs), 
    .end_erase(end_erase), 
    .end_read(end_read), 
    .en_erase(en_erase), 
    .en_read(en_read_1), 
    .erase_addr_start(erase_addr_start), 
    .erase_addr_finish(erase_addr_finish), 
    .read_addr_row_reg(read_addr_row_reg_1), 
    .en_init_flash_addr(en_init_flash_addr), 
    .end_init_flash_addr(end_init_flash_addr), 
    .init_addr_row(init_addr_row), 
    .init_bad_block_ram_data(init_bad_block_ram_data), 
    .init_bad_block_ram_addr(init_bad_block_ram_addr), 
    .en_init_bad_block_ram(en_init_bad_block_ram), 
    .we_init_bad_block_ram(we_init_bad_block_ram), 
    .end_infopage_write(end_infopage_write), 
    .en_infopage_write(en_infopage_write),
	 .en_write(en_write),
	 .end_write(end_write),
	 .flash_cmd_incomplete(flash_cmd_incomplete),
	 .en_log_write(en_log_write)
    );
	 
//****************************************************//
//    	 				 读flash控制  							//
//****************************************************//	 

	read_flash_control read_flash_control(
    .clk(clk6M), 
    .rst(rst), 
    .en_read(en_read), 
    .state(state), 
    .read_addr_row_reg(read_addr_row_reg), 
    .read_addr_row(read_addr_row), 
    .read_data(read_data), 
    .read_data_cnt(read_data_cnt), 
    .read_addr_row_error(read_addr_row_error), 
    .read_data_ECCstate(read_data_ECCstate), 
    .read_data_change_addr(read_data_change_addr), 
    .read_ram_dataout(read_ram_dataout), 
    .read_ram_datain(read_ram_datain), 
    .read_ram_addr(read_ram_addr), 
    .read_en_ram(read_en_ram), 
    .read_we_ram(read_we_ram)
    );
//****************************************************//
//    	 				 擦除flash控制  						//
//****************************************************//	 

	erase_flash_control	erase_flash_control(
    .clk(clk6M), 
    .rst(rst), 
    .en_erase(en_erase), 
    .end_erase_page(end_erase_page), 
    .end_erase(end_erase), 
    .en_erase_page(en_erase_page), 
    .erase_addr_row_error(erase_addr_row_error), 
    .erase_addr_start(erase_addr_start), 
    .erase_addr_finish(erase_addr_finish), 
    .erase_addr_row(erase_addr_row)
    );

//****************************************************//
//    	 				 写flash控制  						//
//****************************************************//	 

	write_flash_control	write_flash_control(
    .clk(clk6M), 
    .rst(rst), 
    .en_write(en_write), 
    .end_write_page(end_write_page), 
    .en_write_page(en_write_page), 
    .end_write(end_write),
	 .en_infopage_write(en_infopage_write),
	 .end_infopage_write(end_infopage_write),
    .state(state), 
    .write_data_cnt(write_data_cnt), 
    .write_data(write_data), 
    .write_addr_row(write_addr_row), 
    .write_addr_row_error(write_addr_row_error), 
    .write_success(write_success), 
    .init_addr_row(init_addr_row), 
    .en_init_flash_addr(en_init_flash_addr), 
    .end_init_flash_addr(end_init_flash_addr), 
    .write_en_ram(write_en_ram), 
    .write_ram_addr(write_ram_addr), 
    .write_ram_dataout(write_ram_dataout),
	 .en_writeAddr_Transfer(en_writeAddr_Transfer),
	 .end_writeAddr_Transfer(end_writeAddr_Transfer),
	 .en_log_write(en_log_write)
    );


//****************************************************//
//    	 		  控制flash实现基本功能 						//
//****************************************************//	 

	basic_NANDflash_control basic_NANDflash_control (
    .clk(clk6M), 
    .rst(rst), 
    .clk12M(clk12M), 
	 .clk24M(clk),
    .state(state), 
    .en_write_page(en_write_page), 
    .en_read(en_read), 
    .en_erase_page(en_erase_page), 
    .end_write_page(end_write_page), 
    .end_read(end_read), 
    .end_erase_page(end_erase_page), 
    .flash_dataout(flash_dataout), 
    .flash_datain(flash_datain), 
    .ready_busy(ready_busy), 
    .ce(ce), 
    .cle(cle), 
    .ale(ale), 
    .we(we), 
    .re(re), 
    .init_bad_block_ram_data(init_bad_block_ram_data), 
    .init_bad_block_ram_addr(init_bad_block_ram_addr), 
    .en_init_bad_block_ram(en_init_bad_block_ram), 
    .we_init_bad_block_ram(we_init_bad_block_ram), 
    .write_data(write_data), 
    .write_addr_row(write_addr_row), 
    .write_data_cnt(write_data_cnt), 
    .write_addr_row_error(write_addr_row_error), 
    .write_success(write_success), 
    .read_addr_row(read_addr_row), 
    .read_data(read_data), 
    .read_data_cnt(read_data_cnt), 
    .read_addr_row_error(read_addr_row_error), 
    .read_data_ECCstate(read_data_ECCstate), 
    .read_data_change_addr(read_data_change_addr), 
//	 .read_data_flag(read_data_flag),
    .erase_addr_row(erase_addr_row), 
    .erase_addr_row_error(erase_addr_row_error), 
    .en_bad_block_renew_transfer(en_bad_block_renew_transfer), 
    .bad_block_renew_addr(bad_block_renew_addr),
	 .nandflash_busy_Noresponse(nandflash_busy_Noresponse)
    );

endmodule
