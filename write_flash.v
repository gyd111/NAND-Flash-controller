`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date:    16:43:47 04/03/2018 
// Design Name: 
// Module Name:    write_flash 

module write_flash(
	input clk,rst,tWrite,en_write_page,
	input	tclk,
	input [4:0]state,
	input [13:0]write_data_cnt,						//写数据计数
	output [7:0]write_flash_datain,					//写模块输出的数据，与flash的IO口对接
	input [7:0]write_flash_dataout,					//写模块输入的数据，与flash的IO口对接，用于读状态寄存器
	output reg [1:0]write_success,					//写成功标志,用于写操作中检测状态寄存器BIT0判断写入状况。0为未检测操作，1为操作成功，2为操作失败
	output reg write_complete,						//写完成标志，用于写操作中检测状态寄存器BIT0判断写入状态。0位没完成检测，1为完成检测（完成检测不一定检测结果时正确的）
	
	input [7:0] write_data,							//外部输入的写数据	
	input [23:0] addr_row,							//输入写地址
	output reg [1:0]write_addr_row_error,			//写操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
		
	output [11:0] write_bad_block_ram_addr,		     //检索坏块表地址
	input write_bad_block_ram_dataout,				 //坏块表输出的数据，1表示该块为坏块，0表示该块为好块
	
	output reg write_en_ECCram,write_we_ECCram,	     //操作ECCram的控制信号
	output reg [9:0] write_ECCram_addr,				 //操作ECCram的地址
	output reg [7:0] write_ECCram_datain,			 //ECCram输入信号，用于把每128B生成的3B的ECC码写入ram
	input [7:0] write_ECCram_dataout			     //ECCram输出信号，用于写完1页原始数据后，把该页生成的ECC码写入flash
    );
	 
	reg [7:0] write_ECC_data;
//*************     write_write_cmd模块      *************//
	wire [7:0] cmd_start,cmd_finish,cmd_data;

//*************     write_write_addr模块      *************//
	wire [15:0] addr_column;
	wire [7:0] addr_data;

//*************    write_generate_ECC模块     *************//
	reg write_ECC_start;			//ECC开始标志位，为1时对数据进行预处理，为0时获得cp和rp
	wire [6:0] writeECC_cnt;		//ECC计数，用于每128次计数产生3B的ECC码
	wire [7:0] write_ECC_cp;		//ECC码列校验
	wire [15:0] write_ECC_rp;		//ECC码行校验
//	wire write_ECC_out;				//ECC码输出标志位（暂时用定时来确定ECC码的输出，用不到该信号，根据仿真的时序结果来判断最终是否需要用该信号）

	reg [1:0]i,j;
	reg [1:0]n;
	reg m;

	assign writeECC_cnt[6:0] = write_data_cnt[6:0];			
	assign cmd_start   = 8'h80;									//起始命令80
	assign cmd_finish  = 8'h10;									//结束命令10
	assign addr_column = 16'h0000;								//列地址固定为0，每次从每一页的开头开始写
	
	/*
		for test , when write data cnt is 1, reverse the write data's bit 0
	*/
	wire	[7:0]	test_ecc_data;
	assign test_ecc_data = (write_data_cnt == 'd2) ? {write_data[7:1], ~write_data[0]} : write_data;
	// state == 11 是上电后的第一个复位命令
	assign write_flash_datain = (state == 11) ? 8'hff : (en_write_page ? (cmd_data | addr_data | test_ecc_data | write_ECC_data) : 0);  // test ecc data is write data

	always @(posedge clk or posedge rst)
	begin
		if(rst)
			write_ECC_start <= 0;
		else
			if((state == 9) & tWrite & ~(write_data_cnt[13]) )		//当处在状态9且tWrite为1且计数值小于8K的时候，ECC_start才为1
				write_ECC_start <= 1;
			else
				write_ECC_start <= 0;
	end
	
	assign write_bad_block_ram_addr = addr_row[18:7];	//用组合逻辑是为了确保ram输出的状态确实是当前行地址的状态，否则会因为延迟导致行地址上一个为坏块，这一块为好块时也跳到下一块
	
	always @(posedge clk or posedge rst)					//写地址初始化,检索坏块表以及每次写完一页后自动+1
	begin
	if(rst)
	begin
		write_addr_row_error <= 0;
		m <= 0;
	end
	else
		begin
			if(en_write_page)
			if(m == 0)
				m <= 1;
			else
			begin
				if(write_bad_block_ram_dataout)	// 坏块
						write_addr_row_error <= 2;
				else
					write_addr_row_error <= 1;
			end
			else
			begin
				write_addr_row_error <= 0;
				m <= 0;
			end
		end
	end
	
	always @(posedge clk or posedge rst)
	begin
	if(rst)
	begin
		i <= 0;
		j <= 0;
		write_en_ECCram <= 0;
		write_we_ECCram <= 0;
		write_ECCram_addr <= 0;
		write_ECCram_datain <= 0;
		write_ECC_data <= 0;
	end
	else
		if(state == 9)
		if(!write_data_cnt[13])						//判断计数是否小于8K，小于8K时往ECCram里写ECC码，大于8K时把ECC码读出
		if(!tWrite)
		begin
			write_en_ECCram <= 1;
			if(i < 2)
				i <= i+1;
			else
			begin
			case(j)
			0:
			begin
				write_we_ECCram <= 1;
				write_ECCram_addr <= write_data_cnt[12:7]*3+1;	//空出ram的最起始的地址，空闲时期停留在该地址处
				write_ECCram_datain <= write_ECC_rp[7:0];
				j <= 1;
			end
			1:
			begin
				write_we_ECCram <= 1;
				write_ECCram_addr <= write_data_cnt[12:7]*3+2;
				write_ECCram_datain <= write_ECC_rp[15:8];
				j <= 2;
			end
			2:
			begin
				write_we_ECCram <= 1;
				write_ECCram_addr <= write_data_cnt[12:7]*3+3;
				write_ECCram_datain <= write_ECC_cp[7:0];
				j <= 3;
			end
			3:j <= 3; 			//每次向RAM写完3B的ECC码后就停止
			endcase
			end
		end
		else
		begin
			write_en_ECCram <= 0;
			write_we_ECCram <= 0;
			write_ECCram_addr <= 0;
			write_ECCram_datain <= 0;
			i <= 0;
			j <= 0;
		end
		else
		begin
			write_ECCram_addr <= write_data_cnt[7:0]+1;		//读出ECC码
			write_en_ECCram <= 1;
			write_we_ECCram <= 0;
			write_ECC_data <= write_ECCram_dataout;
		end
		else
		begin
			i <= 0;
			j <= 0;
			write_en_ECCram <= 0;
			write_we_ECCram <= 0;
			write_ECCram_addr <= 0;
			write_ECCram_datain <= 0;
			write_ECC_data <= 0;
		end
	end

	always @(posedge clk or posedge rst)			//完成写操作后读取状态寄存器，给写成功信号赋值
	begin
	if(rst)
	begin
		write_success <= 0;
		n <= 0;
		write_complete <= 0;
	end
	else
		if(en_write_page)
		begin
		if(state == 16)
			if(n < 2)
				n <= n+1;
			else
			begin
				if( !write_flash_dataout[0] )
				begin
					write_success <= 1;
					write_complete <= 1;
				end
				else
				begin
					write_success <= 2;
					write_complete <= 1;
				end
			end
		end
		else
		begin
			n <= 0;
			write_success <= 0;
			write_complete <= 0;
		end
	end
//****************************************************//
//			 				写命令				 						//
//****************************************************//

	write_cmd  write_write_cmd(	
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

	write_addr  write_write_addr(	
	.clk(clk),
	.rst(rst),
	.addr_column(addr_column),
	.addr_row(addr_row),
	.addr_data(addr_data),
	.state(state)
	);
	
//****************************************************//
//			 				生成ECC码			 						//
//****************************************************//

	write_generate_ECC write_generate_ECC(
	.prior_data1(write_data),
	.rst(rst),
	.tclk(tclk),
	.clk(clk),
	.ECC_start(write_ECC_start),
	.data_cnt1(writeECC_cnt),
	.cp(write_ECC_cp),
	.rp(write_ECC_rp)
//	.ECC_out(write_ECC_out)
	);

endmodule
