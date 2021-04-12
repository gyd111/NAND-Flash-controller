`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:52:40 04/08/2018 
// Design Name: 
// Module Name:    write_flash_control 
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
module write_flash_control(
	input clk,rst,en_write,end_write_page,
	output reg en_write_page,
	output end_write,
	input en_infopage_write,
	input en_log_write,
	output end_infopage_write,
	
	
	input [4:0]state,
	input [13:0]write_data_cnt,					//写计数，用于控制输入flash模块的数据
	output [7:0] write_data,						//写数据
	output reg [23:0] write_addr_row,			//写地址
	input [1:0]write_addr_row_error, 			//写操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏（保持在2两个周期）
	input [1:0]write_success,						//写成功标志,用于写操作中检测状态寄存器BIT0判断写入状况。0为未操作，1为操作成功，2为操作失败（保持在2两个周期）
	
	input [23:0] init_addr_row,					//上电后输入该地址，标志写操作的首地址，以后操作从该地址开始写
	input en_init_flash_addr,						//MCU给FPGA发送初始化地址后FPGA产生的使能信号
	output reg end_init_flash_addr,				//完成初始化地址后的结束信号

	output write_en_ram,								//控制能谱数据及信息数据ram
	output [14:0]write_ram_addr,
	input [7:0]write_ram_dataout,
	
	input end_writeAddr_Transfer,
	output reg en_writeAddr_Transfer
    );

	reg n;
	reg [1:0]write_time;								//写次数，用于控制一个周期写三页数据
	reg [7:0]write_page_info;						//写入第127页的该块写页数信息
	wire [7:0]write_ram_data_reg,write_page_info_reg;
	
	wire [3:0]write_state;
	reg en_write_info;
	
	
	assign write_data = en_write_info ? write_page_info_reg : write_ram_data_reg;
	assign write_ram_addr[14:13] = write_time[1:0];
	assign write_ram_addr[12:0] = (write_data_cnt[13] == 0) ? write_data_cnt[12:0] : 0;
	assign write_ram_data_reg = (state == 9) ? ( (write_data_cnt[13] == 0) ? write_ram_dataout : 8'h00) : 8'h00;
	assign write_page_info_reg = (state == 9) ? ( (write_data_cnt[13] == 0) ?   write_page_info  : 8'h00) : 8'h00;
	assign write_en_ram = (state == 9) ? 1 : 0;
	
//	assign end_write = (write_state == 13) ? 1 : 0;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			en_writeAddr_Transfer <= 0;
		else
		begin
			if(end_writeAddr_Transfer)
				en_writeAddr_Transfer <= 0;
			else if(write_state == 13)
				en_writeAddr_Transfer <= 1;
		end
	end
	
	
	always @(posedge clk or posedge rst)	//对写次数赋值
	begin
		if(rst)
			write_time <= 0;
		else
		begin
			if(write_state == 2)
				write_time <= 0;
			else if(write_state == 7)
				write_time <= 1;
			else if(write_state == 8)
				write_time <= 2;
		end
	end
	
	always @(posedge clk or posedge rst)			//在写1、2、3页及信息页开始状态时令写单页使能为1，当结束写单页标志为1或者检测到坏块时写单页使能为0
	begin
		if(rst)
			en_write_page <= 0;
		else
		begin
			if(write_state == 5 | end_write_page)
				en_write_page <= 0;
			else if(write_state == 2 | write_state == 7 | write_state == 8 |write_state == 10)
					en_write_page <= 1;
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			en_write_info <= 0;
		else
			if(write_state == 10)
				en_write_info <= 1;
			else	if(write_state == 2)
				en_write_info <= 0;
	end
	
	always @(posedge clk or posedge rst)		//用于控制当处于状态6及写信息页成功后，跳块只进行一次
	begin
		if(rst)
			n<=0;
		else
			if(write_state == 6)
				n <= 1;
			else if(write_state == 8)
				n <= 0;
	end
	
	always @(posedge clk or posedge rst)					//控制写页地址
	begin
		if(rst)
		  begin
		  	 write_addr_row <= 0;
			 end_init_flash_addr <= 0;
		  end
		else
			begin
			   if((end_init_flash_addr ==1)&&(en_init_flash_addr==0))
				  begin
				    end_init_flash_addr <= 0; 
				  end
				else
				  begin
				    if(en_init_flash_addr)					//地址初始化
			         begin
		   		     write_addr_row <= init_addr_row;	//减去1是因为当开始一次写入时地址会++
					     end_init_flash_addr <= 1;
				      end			 
				    else
				     begin
					   if(write_state == 15)								//写完后地址++
						   write_addr_row <= write_addr_row + 1;
					   else if(write_state == 5 | write_state == 14 )			//检测到坏块/写完127页后进行跳块
						  begin
							 write_addr_row[18:7] <= write_addr_row[18:7]+1;
							 write_addr_row[6:0] <= 0;
						  end
					   else if(write_state == 6 & en_write_info)					//写完信息页且成功后进行跳块操作
						  if(n == 0)
						   begin
								write_addr_row[18:7] <= write_addr_row[18:7]+1;
								write_addr_row[6:0] <= 0;
						   end
					   else if(write_state == 10)								//需要写信息页时跳至该块127页
						  begin
						   write_addr_row[18:7] <= write_addr_row[18:7];
							write_addr_row[6:0] <= 127;
						  end
						else
						 write_addr_row <= write_addr_row; 
				     end
				  end
			end
	end
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			write_page_info <= 0;
		else
			if(write_state == 10)
				write_page_info <= write_addr_row[6:0];
		 //     write_page_info <= 8'h55;
	end
	
	
	
//****************************************************//
//    	  		  写FLASH状态控制 								//
//****************************************************//	 

	write_flash_state_control write_flash_state_control(
    .clk(clk), 
    .rst(rst), 
    .en_write(en_write), 
	 .en_infopage_write(en_infopage_write),
 // .end_infopage_write(end_infopage_write),
    .state(state), 
    .write_success(write_success), 
    .write_addr_row_error(write_addr_row_error), 
    .write_addr_row(write_addr_row), 
    .write_time(write_time), 
    .en_write_info(en_write_info), 
    .write_state(write_state),
	 .end_write(end_write),
	 .en_log_write(en_log_write)
    );
	 
	 
endmodule
