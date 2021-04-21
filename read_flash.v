`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:43:55 04/03/2018 
// Design Name: 
// Module Name:    read_flash 
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
 module read_flash(
	input clk,rst,tRead,
	input en_read,
	input [4:0] state,
	input [13:0] read_data_cnt,
	input [7:0] read_flash_dataout,
	output [7:0] read_flash_datain,
	
	input [23:0] addr_row,
	output reg [1:0]read_addr_row_error,		//读操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
		
	output [11:0] read_bad_block_ram_addr,		//检索坏块表地址
	input read_bad_block_ram_dataout,			//坏块表输出的数据，1表示该块为坏块，0表示该块为好块
	
	output read_en_ECCram,							//操作ECCram的使能信号
	output reg read_we_ECCram,						//操作ECCram的写控制信号
	output [9:0] read_ECCram_addr,				//操作ECCram的地址
	output reg [7:0] read_ECCram_datain,		//ECCram输入信号，用于把每128B生成的3B的ECC码写入ram，以及把每页读出的ECC数据写入RAM
	input [7:0] read_ECCram_dataout,				//ECCram输出信号，用于写完1页ECC码后，把该页生成的ECC码和flash读出的ECC码全读出进行对比
	output reg read_ECC_success,
	
	output [7:0]read_data,
	
	output reg [1:0]read_data_ECCstate,			//数据ECC状态，0为没完成检测，1为ECC校验正确，2为ECC校验错误但是可以修正，3为ECC校验后数据无效
	output reg [15:0]read_data_change_addr		//需要修改的数据所在位置，前13位为错误的字节地址，后3位为翻转位为该字节的位置
    );
	 
	 reg read_en_ECCram_write,read_en_ECCram_read;
	 reg m;
	 reg [1:0] i,j;
	 reg [9:0] ECCram_addr1_reg,ECCram_addr2_reg;				//在ECC比较的时候记录ram地址，因为两组ECC码存在同一个ram中，需要用两个寄存器记录两组ECC码当前的地址
	 reg [3:0] ECCcompare_state;										//在ECC比较的时候进行计数，前6个状态从ram里读取数据，组成两个完整的ECC码进行比较
	 reg [23:0] read_ECC_data1,read_ECC_data2;					//完整的ECC码两组，用来进行比较。ECC1为随读数产生的数据，ECC2为读出的数据，如果两组数据不一致，需要根据ECC2来修改
	 reg [23:0] ECC_compare_reg;										//对两组完整的ECC码进行异或得到的结果,用于判断校验结果
	 reg [9:0] ECC_compare1,ECC_compare2;							//异或得到的ECC校验值中有用的部分，从高到低分别为cp5,cp3,cp1,rp13,rp11,rp9,rp7,rp5,rp3,rp1
	 reg [6:0] ECC_cnt;													//ECC计数器，用于在ECC比较的过程中记录进行到第几个ECC码的比较
	 reg [9:0] read_ECCram_addr_write,read_ECCram_addr_read;	//读/写时操作ECCram的地址
	 
//*************     read_write_cmd模块      *************//
	wire [7:0] cmd_start,cmd_finish,cmd_data;

//*************     read_write_addr模块     *************//
	wire [15:0] addr_column;
	wire [7:0] addr_data;

//*************    read_generate_ECC模块    *************//
	reg read_ECC_start;			//ECC开始标志位，为1时对数据进行预处理，为0时获得cp和rp
	wire [6:0] readECC_cnt;		//ECC计数，用于每128次计数产生3B的ECC码
	wire [7:0] read_ECC_cp;		//ECC码列校验
	wire [15:0] read_ECC_rp;	//ECC码行校验
//	wire write_ECC_out;			//ECC码输出标志位（暂时用定时来确定ECC码的输出，用不到该信号，根据仿真的时序结果来判断最终是否需要用该信号）

	assign read_data = read_flash_dataout;
	
	assign readECC_cnt[6:0] = read_data_cnt[6:0];			
	assign cmd_start = 8'h00;										//起始命令00
	assign cmd_finish = 8'h30;										//结束命令30
	assign addr_column = 16'h0000;								//列地址固定为0，每次从每一页的开头开始读
		
	assign read_flash_datain = en_read ? (cmd_data | addr_data) : 0;
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
			read_ECC_start <= 0;
		else
			if( (state == 10) & tRead & ~(read_data_cnt[13]) )		//当处在状态10且tRead为1且计数值小于8K的时候，ECC_start才为1
				read_ECC_start <= 1;
			else
				read_ECC_start <= 0;
	end
	assign read_bad_block_ram_addr = addr_row[18:7];	//用组合逻辑是为了确保ram输出的状态确实是当前行地址的状态，否则会因为延迟导致行地址上一个为坏块，这一块为好块时也跳到下一块
	
	always @(posedge clk or posedge rst)					//写地址初始化,检索坏块表以及每次写完一页后自动+1
	begin
	if(rst)
	begin
		m <= 0;
		read_addr_row_error <= 0;
	end
	else
		begin
			if(en_read)
			begin
				if(read_bad_block_ram_dataout)		
				if(m == 0)
					m <= 1;
				else
				begin
					m <= 0;
					read_addr_row_error <= 2;
				end
				else
					read_addr_row_error <= 1;
			end
			else
				read_addr_row_error <= 0;
		end
	end

	assign read_ECCram_addr = (state == 10) ? read_ECCram_addr_write : ((state == 18) ? read_ECCram_addr_read : 0);
	assign read_en_ECCram = (state == 10) ? read_en_ECCram_write : ((state == 18) ? read_en_ECCram_read : 0);
	
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			i <= 0;
			j <= 0;
			read_en_ECCram_write <= 0;					//ECCram使能
			read_we_ECCram <= 0;					//ECCram写使能
			read_ECCram_addr_write <= 0;		//ECCram地址
			read_ECCram_datain <= 0;			//输出到ECCram中的ECC码，分为两种，一种是每读128B数据产生3B的，另一种是从flash里读出的
		end
		else
		begin
			if(state == 10)						//若状态为10，则处于向ram里存ECC码的过程
			begin
				read_ECCram_addr_write[9] <= read_data_cnt[13];
				if(!read_data_cnt[13])			//向ECCram中写入随着读数据产生的ECC数据
					if(!tRead)
					begin
						read_en_ECCram_write <= 1;
						if(i < 2)
						i <= i+1;
						else
						case(j)
						0:
						begin
							read_we_ECCram <= 1;
							read_ECCram_addr_write[8:0] <= read_data_cnt[12:7]*3+1;	//空出ram的最起始的地址，空闲时期停留在该地址处
							read_ECCram_datain <= read_ECC_rp[7:0];
							j <= 1;
						end
						1:
						begin
							read_we_ECCram <= 1;
							read_ECCram_addr_write[8:0] <= read_data_cnt[12:7]*3+2;
							read_ECCram_datain <= read_ECC_rp[15:8];
							j <= 2;
						end
						2:
						begin
							read_we_ECCram <= 1;
							read_ECCram_addr_write[8:0] <= read_data_cnt[12:7]*3+3;
							read_ECCram_datain <= read_ECC_cp[7:0];
							j <= 3;
						end
						3:j <= 3; 			//每次向RAM写完3B的ECC码后就停止
						endcase
					end
					else
					begin
						read_en_ECCram_write <= 0;
						read_we_ECCram <= 0;
						read_ECCram_addr_write <= 0;
						read_ECCram_datain <= 0;
						i <= 0;
						j <= 0;
					end
				else									//向ECCram中写入从flash读出的ECC数据
				begin
					read_en_ECCram_write <= 1;
					read_we_ECCram <= 1;
					read_ECCram_addr_write[8:0] <= read_data_cnt[8:0]+1;	//空出起始地址
					read_ECCram_datain <= read_flash_dataout;
				end
			end
			else
			begin
				read_en_ECCram_write <= 0;
				read_we_ECCram <= 0;
				read_ECCram_addr_write <= 0;
				read_ECCram_datain <= 0;
			end
		end
	end
	
	always @(posedge clk or posedge rst)	//在状态18下，把两组ECC码从ECCram中读出并进行比较
	begin
		if(rst)
		begin
			read_ECC_data1 <= 0;					//从ram里输出的随读数产生的ECC码,从高到低分别为cp,rp2,rp1
			read_ECC_data2 <= 0;					//从ram里输出的从flash里读出的ECC码
			read_ECC_success <=0 ;				//ECC码检查完成标志信号
			ECCram_addr1_reg <= 1;				//ECC比较中的地址1
			ECCram_addr2_reg <= 10'b1000_0000_01;				//ECC比较中的地址2
			ECCcompare_state <= 0;				//ECC比较状态
			ECC_cnt <= 0;							//ECC计数器
			read_ECCram_addr_read <= 0;			//ECCram地址
			read_en_ECCram_read <= 0;			//ECCram使能信号
			ECC_compare1 <= 0;
			ECC_compare2 <= 0;
			read_data_ECCstate <= 0;
			read_data_change_addr <= 0;
		end
		else
		begin
			if(state == 18)
			begin
			if(ECC_cnt < 64)
			begin
				read_en_ECCram_read <=1;
				read_ECC_success <= 0;
				case(ECCcompare_state)
				0:
				begin
					ECCcompare_state <= 1;							//读取ECCram的地址进行赋值，读随读产生ECC码的rp1
					read_ECCram_addr_read <= ECCram_addr1_reg;
					ECCram_addr1_reg <= ECCram_addr1_reg+1;
				end
				1:
				begin
					ECCcompare_state <= 2;							//地址变更为rp2
					read_ECCram_addr_read <= ECCram_addr1_reg;
					ECCram_addr1_reg <= ECCram_addr1_reg+1;
				end
				2:
				begin
					ECCcompare_state <= 3;							//地址变更为cp，数据为rp1
					read_ECCram_addr_read <= ECCram_addr1_reg;
					ECCram_addr1_reg <= ECCram_addr1_reg+1;
					read_ECC_data1[7:0] <= read_ECCram_dataout;
				end
				3:
				begin
					ECCcompare_state <= 4;							//地址变更为从flash读出的ECC码的rp1，数据为rp2
					read_ECCram_addr_read <= ECCram_addr2_reg;
					ECCram_addr2_reg <= ECCram_addr2_reg+1;
					read_ECC_data1[15:8] <= read_ECCram_dataout;
				end
				4:
				begin
					ECCcompare_state <= 5;							//地址变更为从flash读出的ECC码的rp2，数据为随读产生的cp
					read_ECCram_addr_read <= ECCram_addr2_reg;
					ECCram_addr2_reg <= ECCram_addr2_reg+1;
					read_ECC_data1[23:16] <= read_ECCram_dataout;
				end
				5:
				begin
					ECCcompare_state <= 6;							//地址变更为从flash读出的ECC码的cp，数据为从flash读出的ECC码的rp1
					read_ECCram_addr_read <= ECCram_addr2_reg;
					ECCram_addr2_reg <= ECCram_addr2_reg+1;
					read_ECC_data2[7:0] <= read_ECCram_dataout;
				end
				6:
				begin
					ECCcompare_state <= 7;						//数据为从flash读出的ECC码的rp2
					read_ECC_data2[15:8] <= read_ECCram_dataout;
				end
				7:														//数据为从flash读出的ECC码的cp
				begin
					read_ECC_data2[23:16] <= read_ECCram_dataout;
					ECCcompare_state <= 8;
				end
				8:
				begin
					ECCcompare_state <= 9;							//对获得的两组ECC码进行异或
					ECC_compare_reg <= (read_ECC_data1 & ~read_ECC_data2)|(~read_ECC_data1 & read_ECC_data2);
				end
				9: 
				begin														//把有用的部分提出
					ECCcompare_state <= 10;
					ECC_compare1[9] <= ECC_compare_reg[21];
					ECC_compare1[8] <= ECC_compare_reg[19];
					ECC_compare1[7] <= ECC_compare_reg[17];
					ECC_compare1[6] <= ECC_compare_reg[13];
					ECC_compare1[5] <= ECC_compare_reg[11];
					ECC_compare1[4] <= ECC_compare_reg[9];
					ECC_compare1[3] <= ECC_compare_reg[7];
					ECC_compare1[2] <= ECC_compare_reg[5];
					ECC_compare1[1] <= ECC_compare_reg[3];
					ECC_compare1[0] <= ECC_compare_reg[1];
					ECC_compare2[9] <= ECC_compare_reg[20];
					ECC_compare2[8] <= ECC_compare_reg[18];
					ECC_compare2[7] <= ECC_compare_reg[16];
					ECC_compare2[6] <= ECC_compare_reg[12];
					ECC_compare2[5] <= ECC_compare_reg[10];
					ECC_compare2[4] <= ECC_compare_reg[8];
					ECC_compare2[3] <= ECC_compare_reg[6];
					ECC_compare2[2] <= ECC_compare_reg[4];
					ECC_compare2[1] <= ECC_compare_reg[2];
					ECC_compare2[0] <= ECC_compare_reg[0];
				end
				10:
				begin														
					if(ECC_compare1 == ~ECC_compare2 | (ECC_compare1 == 0 & ECC_compare2 == 0))	//判断是否为无效数据
					begin
					if((ECC_compare1 == 0)&(ECC_compare2 == 0) )					//判断异或值是否正确，若不正确，对ram地址进行赋值获得需要修改的值的地址
					begin
						ECCcompare_state <= 11;
						ECC_cnt <= ECC_cnt+1;
						ECC_compare_reg <= 0;
						ECC_compare1 <= 0;
						read_data_ECCstate <= 1;
					end
					else
					begin
						read_data_change_addr[15:10] <= ECC_cnt;
						read_data_change_addr[9:3] <= ECC_compare1[6:0];
						read_data_change_addr[2:0] <= ECC_compare1[9:7];
						read_data_ECCstate <= 2;
						ECCcompare_state <= 11;
					end
					end
					else
					begin
						read_data_ECCstate <= 3;				
						ECCcompare_state <= 11;
					end
				end
				11:
				begin												//结束该次ECC修正，进行下一次ECC码修正判断
					ECCcompare_state <= 0;
					ECC_cnt <= ECC_cnt+1;
					ECC_compare_reg <= 0;
					ECC_compare1 <= 0;
					ECC_compare2 <= 0;
					read_data_ECCstate <= 0;
					read_data_change_addr <= 0;
				end
				default:
					ECCcompare_state <= 0;
				endcase
			end
			else if(ECC_cnt == 64)
					begin
						ECC_cnt <= 65;
						read_en_ECCram_read <= 0;
						read_ECC_success <= 1;
						read_ECC_data1 <= 0;					
						read_ECC_data2 <= 0;					
						ECCram_addr1_reg <= 1;				
						ECCram_addr2_reg <= 10'b1000_0000_01;				
						ECCcompare_state <= 0;				
						read_ECCram_addr_read <= 0;
					end
					else
						read_ECC_success <= 0;
			end
		else
			ECC_cnt <= 0;
		end
	end
	
//****************************************************//
//			 				写命令				 						//
//****************************************************//

	write_cmd  read_write_cmd(	
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

	write_addr  read_write_addr(	
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

	read_generate_ECC read_generate_ECC(
	.prior_data1(read_data),
	.rst(rst),
	.clk(clk),
	.ECC_start(read_ECC_start),
	.data_cnt1(readECC_cnt),
	.cp(read_ECC_cp),
	.rp(read_ECC_rp)
//	.ECC_out(write_ECC_out)
	);

endmodule
