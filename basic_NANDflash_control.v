`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:38:22 04/03/2018 
// Design Name: 
// Module Name:    basic_NANDflash_control 
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
module basic_NANDflash_control(
	input clk,rst,clk12M,clk24M,								// clk is 6M
	output [4:0] state,											//状态，用于通知外部模块输入数据的时间
	input en_write_page,en_read,en_erase_page,			//使能信号
	output end_write_page,end_read,end_erase_page,		//结束信号
	
	input [7:0]flash_dataout,									//flash输出数据
	output [7:0]flash_datain,									//flash输入数据
	input ready_busy,												//flash空闲/忙碌标志信号
	output ce,cle,ale,we,re,								//flash控制信号
	
	input [7:0] init_bad_block_ram_data,					//初始化坏块表ram数据
	input [8:0] init_bad_block_ram_addr,					//初始化坏块表ram地址
	input en_init_bad_block_ram,we_init_bad_block_ram, //初始化坏块表ram的控制信号
	
	input [7:0] write_data,										//外部输入写入flash的数据
	input [23:0] write_addr_row,								//外部输入的写地址
	output [13:0]write_data_cnt,								//写计数，用于控制外部输入的数据
	output [1:0]write_addr_row_error,						//写操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	output [1:0]write_success,									//写成功标志,用于写操作中检测状态寄存器BIT0判断写入状况。1为操作成功，0为操作失败
	
	input [23:0] read_addr_row,								//外部输入的读地址
	output [7:0]read_data,										//输出的从flash内读到的数据
	output [13:0]read_data_cnt,								//读数据计数
	output [1:0]read_addr_row_error,							//读操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏
	output [1:0]read_data_ECCstate,							//数据ECC状态，0为没完成检测，1为ECC校验正确，2为ECC校验错误但是可以修正，3为ECC校验后数据无效
	output [16:0]read_data_change_addr,						//需要修改的数据所在位置，前13位为错误的字节地址，后3位为翻转位为该字节的位置
//	output read_data_flag,
	
	input [23:0]erase_addr_row,
	output [1:0]erase_addr_row_error,						//擦除操作坏块检索，用于输入了块地址后检查该地址是否为坏块,0为未检索，1为好块，2为块坏

	output en_bad_block_renew_transfer,						//向MCU发送更新后的坏块表标志脉冲
	output [11:0]bad_block_renew_addr,						//坏块地址
	output nandflash_busy_Noresponse
	 );

//*************   state_control模块    *************//


//*************    write_flash模块     *************//
	wire write_complete;								//写完成标志，用于写操作中检测状态寄存器BIT0判断写入状态。0位没完成检测，1为完成检测（完成检测不一定检测结果是正确的）
	wire [11:0] write_bad_block_ram_addr;		//检索坏块表地址
	wire write_bad_block_ram_dataout;			//坏块表输出的数据，1表示该块为坏块，0表示该块为好块
	wire write_en_ECCram,write_we_ECCram;		//操作ECCram的控制信号
	wire [9:0] write_ECCram_addr;					//操作ECCram的地址
	wire [7:0] write_ECCram_datain;				//ECCram输入信号，用于把每128B生成的3B的ECC码写入ram
	wire [7:0] write_ECCram_dataout;				//ECCram输出信号，用于写完1页原始数据后，把该页生成的ECC码写入flash
	wire [7:0]write_flash_datain;					//写模块输出的数据，与flash的IO口对接
	wire [7:0]write_flash_dataout;				//写模块输入的数据，与flash的IO口对接，用于读状态寄存器
	wire tWrite;										//写暂停标志，每写128B需要暂停一段时间进行ECC码生成

	
//*************     read_flash模块     *************//
	wire [7:0] read_flash_dataout;
	wire [7:0] read_flash_datain;
	wire [11:0] read_bad_block_ram_addr;		//检索坏块表地址
	wire read_bad_block_ram_dataout;				//坏块表输出的数据，1表示该块为坏块，0表示该块为好块
	wire read_en_ECCram;								//操作ECCram的使能信号
	wire read_we_ECCram;								//操作ECCram的写控制信号
	wire [9:0] read_ECCram_addr;					//操作ECCram的地址
	wire[7:0] read_ECCram_datain;					//ECCram输入信号，用于把每128B生成的3B的ECC码写入ram，以及把每页读出的ECC数据写入RAM
	wire [7:0] read_ECCram_dataout;				//ECCram输出信号，用于写完1页ECC码后，把该页生成的ECC码和flash读出的ECC码全读出进行对比
	wire read_ECC_success;
	wire tRead;											//读暂停标志，每读128B需要暂停一段时间生成ECC码


//*************     erase_flash模块     *************//
	wire [7:0]erase_flash_dataout;				//FLASH输出的数据，用于状态寄存器的检测
	wire [7:0] erase_flash_datain;				//擦除模块数据输出，用于输出命令
	wire [11:0]erase_bad_block_ram_addr;		//检索坏块表地址
	wire erase_bad_block_ram_dataout;			//坏块表输出的数据，1表示该块为坏块，0表示该块为好块
	wire [1:0] erase_success;


//*************   bad_block_manage模块  *************//
	wire end_bad_block_renew;							//结束坏块更新，控制状态
	wire we_bad_block_renew;
	wire bad_block_renew_datain;			

//*************    bad_block_ram模块    *************//
	wire en_bad_block_ram;
	wire we_bad_block_ram;
	wire bad_block_ram_datain;
	wire bad_block_ram_dataout;
	wire bad_block_ram_dataout_reg;
	wire [11:0] bad_block_ram_addr;
	
//*************      ECC_RAM模块        *************//
	wire en_ECCram,we_ECCram;
	wire [9:0] ECCram_addr;
	wire [7:0] ECCram_datain;
	wire [7:0] ECCram_dataout;
//**************    测试 需要删除  *******************//
    wire en_ecc;
    wire[9:0]add_ecc;
    wire	[6:0]	ECC_cnt;
//debug
//ECC_signa your_instance_name (
//	.clk(clk24M), // input wire clk
//	.probe0(state), // input wire [4:0]  probe0  
//	.probe1(en_ECCram), // input wire [0:0]  probe1 
//	.probe2(we_ECCram), // input wire [0:0]  probe2 
//	.probe3(ECCram_addr), // input wire [9:0]  probe3 
//	.probe4(ECCram_datain), // input wire [7:0]  probe4 
//	.probe5(ECCram_dataout), // input wire [7:0]  probe5
//	.probe6(ECC_cnt)
//);
	assign flash_datain = read_flash_datain | write_flash_datain | erase_flash_datain;
	assign write_flash_dataout = (state == 16) ? flash_dataout : 0; // 处于读状态寄存器的时候
	assign read_flash_dataout  = (state == 10) ? flash_dataout : 0;	// 处于读flash的时候
	assign erase_flash_dataout = (state == 16) ? flash_dataout : 0; // 处于读状态寄存器的时候

	assign en_ECCram       = (state == 9) ? write_en_ECCram : (((state == 10) | (state == 18)) ? read_en_ECCram : 0);//测试ecc ram 需要改为0 
	assign we_ECCram       = (state == 9) ? write_we_ECCram : (((state == 10) | (state == 18)) ? read_we_ECCram : 0);
	assign ECCram_datain   = (state == 9) ? write_ECCram_datain : (((state == 10) | (state == 18)) ? read_ECCram_datain : 0);
	assign write_ECCram_dataout = (state == 9) ? ECCram_dataout : 0;
	assign read_ECCram_dataout  = ((state == 10) | (state == 18)) ? ECCram_dataout : 0;
	assign ECCram_addr     = (state == 9) ? write_ECCram_addr : (((state == 10) | (state == 18)) ? read_ECCram_addr : 0);//测试ecc ram 需要改为0 

	assign bad_block_ram_addr = (state == 17) ? bad_block_renew_addr : (en_write_page ? write_bad_block_ram_addr : (en_erase_page ? erase_bad_block_ram_addr : (en_read ? read_bad_block_ram_addr : 0)));
	assign en_bad_block_ram = 1;
	assign we_bad_block_ram = we_bad_block_renew;
	assign bad_block_ram_datain = bad_block_renew_datain;
	assign read_bad_block_ram_dataout = en_read ? bad_block_ram_dataout : 0;
	assign write_bad_block_ram_dataout = en_write_page ? bad_block_ram_dataout : 0;
	assign erase_bad_block_ram_dataout = en_erase_page ? bad_block_ram_dataout : 0;
	
	assign bad_block_ram_dataout = (en_write_page | en_erase_page | en_read) ? bad_block_ram_dataout_reg : 0;
   //assign bad_block_ram_dataout = (en_write_page | en_erase_page | en_read) ? (bad_block_ram_addr == 12'h604 ? temp : bad_block_ram_dataout_reg) : 0;
    reg  temp;
    always @(posedge clk24M) begin
        if(bad_block_ram_addr == 12'h604)
            temp    <= 1'b1;
        else
            temp    <= 1'b0;
    end 
//****************************************************//
//    	  		  test mod   							//
//****************************************************//	 
//vio_1 vio_inst_1(
//    .clk(clk24M ),
//    .probe_in0( ECCram_dataout ),
////    .probe_in1(state),
////    .probe_in2(test_nf),
//    .probe_out0( en_ecc ),
//    .probe_out1( add_ecc )
////    .probe_out2( start_w),
////    .probe_out3( start_r),
////    .probe_out4(change_ram)
//);

//****************************************************//
//    	  		  产生状态及控制信号 							//
//****************************************************//	 

	state_control state_control(
	.rst(rst),
	.ready_busy(ready_busy),
	.clk(clk),
	.clk12M(clk12M),
	.tclk(clk24M),             // 测试使用，用来做ila的时钟信号
	.en_erase_page(en_erase_page),
	.en_write_page(en_write_page),
	.en_read(en_read),
	.end_write_page(end_write_page),
	.end_read(end_read),
	.end_erase_page(end_erase_page),
	.state(state),
	.tWrite(tWrite),
	.tRead(tRead),
//	.read_data_flag(read_data_flag),
	.write_data_cnt(write_data_cnt),
	.read_data_cnt(read_data_cnt),
	.erase_success(erase_success),
	.write_complete(write_complete),
	.read_ECC_success(read_ECC_success),
	.erase_addr_row_error(erase_addr_row_error),
	.write_addr_row_error(write_addr_row_error),
	.read_addr_row_error(read_addr_row_error),
	.end_bad_block_renew(end_bad_block_renew),
	.nandflash_busy_Noresponse(nandflash_busy_Noresponse),
	.ce(ce),
	.cle1(cle),
	.ale1(ale),
	.we1(we),
	.re1(re)
	);	

//****************************************************//
//    	  			  写FLASH模块 								//
//****************************************************//	 
	
	write_flash write_flash(
	.clk(clk),
	.tclk(clk24M),				// for test 
	.rst(rst),
	.tWrite(tWrite),
	.en_write_page(en_write_page),
	.state(state),
	.write_data_cnt(write_data_cnt),
	.write_flash_datain(write_flash_datain),
	.write_flash_dataout(write_flash_dataout),
	.write_complete(write_complete),
	.write_success(write_success),
	.write_data(write_data),
	.addr_row(write_addr_row),
	.write_addr_row_error(write_addr_row_error),
	.write_bad_block_ram_addr(write_bad_block_ram_addr),
	.write_bad_block_ram_dataout(write_bad_block_ram_dataout),
	.write_en_ECCram(write_en_ECCram),
	.write_we_ECCram(write_we_ECCram),
	.write_ECCram_addr(write_ECCram_addr),
	.write_ECCram_datain(write_ECCram_datain),
	.write_ECCram_dataout(write_ECCram_dataout)
	);

//****************************************************//
//    	  			  读FLASH模块 								//
//****************************************************//	 

	read_flash read_flash(
	.clk(clk),
	.tclk(clk24M),             // 临时信号
	.rst(rst),
	.tRead(tRead),
	.en_read(en_read),
	.state(state),
	.read_data_cnt(read_data_cnt),
	.read_flash_dataout(read_flash_dataout),
	.read_flash_datain(read_flash_datain),
	.addr_row(read_addr_row),
	.read_addr_row_error(read_addr_row_error),
	.read_bad_block_ram_addr(read_bad_block_ram_addr),
	.read_bad_block_ram_dataout(read_bad_block_ram_dataout),
	.read_en_ECCram(read_en_ECCram),
	.read_we_ECCram(read_we_ECCram),
	.read_ECCram_addr(read_ECCram_addr),
	.read_ECCram_datain(read_ECCram_datain),
	.read_ECCram_dataout(read_ECCram_dataout),
	.read_ECC_success(read_ECC_success),
	.read_data(read_data),
	.read_data_ECCstate(read_data_ECCstate),
	.read_data_change_addr(read_data_change_addr),
	.ECC_cnt(ECC_cnt)
	);

//****************************************************//
//    	  			  擦除FLASH模块 							//
//****************************************************//	 

	erase_flash erase_flash(
	.clk(clk),
	.rst(rst),
	.en_erase_page(en_erase_page),
	.state(state),
	.erase_flash_dataout(erase_flash_dataout),
	.erase_flash_datain(erase_flash_datain),
	.erase_addr_row(erase_addr_row),
	.erase_addr_row_error(erase_addr_row_error),
	.erase_bad_block_ram_addr(erase_bad_block_ram_addr),
	.erase_bad_block_ram_dataout(erase_bad_block_ram_dataout),
	.erase_success(erase_success)
	);

//****************************************************//
//    	  				  坏块表管理								//
//****************************************************//	 

	bad_block_manage bad_block_manage(
	.clk(clk),
	.rst(rst),
	.erase_addr_row(erase_addr_row),
	.en_erase_page(en_erase_page),
	.state(state),
	.en_bad_block_renew_transfer(en_bad_block_renew_transfer),
	.end_bad_block_renew(end_bad_block_renew),
	.bad_block_renew_addr(bad_block_renew_addr),
	.we_bad_block_renew(we_bad_block_renew),
	.bad_block_renew_datain(bad_block_renew_datain)
	);

//****************************************************//
//    	  				  坏块表RAM 								//
//****************************************************//	 

	bad_block_ram bad_block_ram (
  .clka(clk24M), 								// input clka
  .ena(en_init_bad_block_ram), 		// input ena
  .wea(we_init_bad_block_ram), 		// input [0 : 0] wea
  .addra(init_bad_block_ram_addr), 	// input [8 : 0] addra
  .dina(init_bad_block_ram_data), 	// input [7 : 0] dina
  .clkb(clk),							   // input clkb
  .enb(en_bad_block_ram),				// input enb, always be 1
  .web(we_bad_block_ram), 				// input [0 : 0] web
  .addrb(bad_block_ram_addr),			// input [11 : 0] addrb
  .dinb(bad_block_ram_datain), 		// input [0 : 0] dinb
  .doutb(bad_block_ram_dataout_reg) 		// output [0 : 0] doutb
);

//****************************************************//
//    	  			  ECC数据RAM 								//
//****************************************************//	 
		
	ECC_RAM ECC_RAM (
  .clka(clk), 					// input clka
  .ena(en_ECCram), 			// input ena
  .wea(we_ECCram), 			// input [0 : 0] wea
  .addra(ECCram_addr), 		// input [9 : 0] addra
  .dina(ECCram_datain), 	// input [7 : 0] dina
  .douta(ECCram_dataout) 	// output [7 : 0] douta
);

endmodule
