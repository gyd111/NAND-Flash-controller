`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:17:09 09/09/2019
// Design Name: 
// Module Name:    LDI800采集存储板固件 
// Project Name: 
// Target Devices: 
// Tool versions:  19.09
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module test_nandflash(
	 
    input clk,rst,clk6M,clk12M,clk1M,clk1_5M,clk_96M,
	
	input en_MCU,
	input we_MCU,                      //0表示读，1表示写               
	input [14:0] address_MCU,
	input [7:0]MCU_datain,
	output [7:0] MCU_dataout,
	
	input ready_busy,
	output ce,cle,ale,we,re,
	
	inout [7:0] flash_IO,
	
	input vibstart,acc_dir,
	output clk_acc,
	

	output [2:0] FPGA_Crash,              //发送给mcu的FPGA程序死机的信号
/********************************************************************/
/*			             		直通的输入输出                             */
/********************************************************************/
	input 	A1_485_tx,           		//接收单片机的txd 5.6,A1代表单片机的第1套485
	output	A1_485_rx,						//向单片机输出rxd 5.7
	input 	A1_485_re,						//从单片机读取485控制re 5.4
	input		A1_485_de,						//从单片机读取485控制de 5.5
	
	output	_485A_txd,						
	input		_485A_rxd,						
	output	_485A_re,						
	output	_485A_de,					
	
	input 	A2_485_tx,           		//接收单片机的txd 9.4,A2代表单片机的第2套485
	output	A2_485_rx,						//向单片机输出rxd 9.5
	input 	A2_485_re,						//从单片机读取485控制re 9.6
	input		A2_485_de,						//从单片机读取485控制de 9.7
	
	output	_485B_txd,						
	input		_485B_rxd,						
	output	_485B_re,						
	output	_485B_de,						

	input 	A3_485_tx,           		//接收单片机的txd 10.4,A3代表单片机的第3套485
	output	A3_485_rx,						//向单片机输出rxd 10.5
	input 	A3_485_re,						//从单片机读取485控制re 10.6
	input		A3_485_de,						//从单片机读取485控制de 10.7
	
	output	_485C_txd,						
	input		_485C_rxd,						
	output	_485C_re,						
	output	_485C_de,
	
input start_w,
input start_r,
input start_e,
output [4:0]state,
input c_r,
output ram_adj,
output inout_flag
	
    );
	
//*************       Clock模块        *************//
	 wire clk,rst,clk6M,clk12M,clk1M,clk1_5M,clk_96M;

//*************     AD_Control模块      *************//
    wire cs_delay1,cs_delay2;         //ad输入ram控制模块的信号，控制ram的读写
    wire [12:0]ad_address1,ad_address2; //对AD输入的数据进行处理，加上扇区信息和长短源信息，变成13位的地址
  

//*************    Selection_AD 模块     *************//
    wire cs_delay;           
    wire ad_adj;              //定义的用于调节选择长短源的寄存器
    wire [12:0] address_in;
  

//**************    ram_control模块     **************//
    wire [7:0] ram1_control_data_out;
	 wire [7:0] ram2_control_data_out;
    wire [7:0] ram1_control_data_in;
	 wire [7:0] ram2_control_data_in;
    wire ram_busy;                    //当前ram是否处于工作状态
	 wire we_rw,en_rw;
	 wire [13:0]address_out;           //对13位地址进行处理，在最后一位加上高低位，使得两个高低地址里的数据可以表示一道能谱

//**************     Change_ram 模块     **************//
    wire ram_adj;       //当前操作ram的标志信号
    wire ram_change;    //ram切换的标志信号，切换的时候为1（一个时钟周期），其他时候为0
    wire change_ram;
//*************   VibrationModule 模块   *************//
	wire en_vibTransfer,end_vibTransfer;
	wire [15:0]acc_data;
	 
//*************     Command_Receiver     *************//
	wire en_clr;			//清除RAM使能
	wire change_ram2;		//切换ram信号
	wire start_cmd;		//命令到来脉冲信号.
	wire [31:0] cmd;
	wire en_demand_write_addr,end_demand_write_addr;
	wire uart_cmd_incomplete;

//*************        Clear_ram         *************//
	wire end_clr;			//清除RAM结束脉冲
	wire en_ram_clr;
	wire we_ram_clr;
	wire [7:0] ram_data_clr;
	wire [13:0] address_clr;
//**************       Sector 模块       **************//
    wire [3:0] sct_address;              //扇区信息
 	 wire [31:0] sct_period;              //周期计数
 	 wire [31:0] sct1_time;               //每个扇区的时间单独计数
	 wire [31:0] sct2_time;
	 wire [31:0] sct3_time;
	 wire [31:0] sct4_time;
	 wire [31:0] sct5_time;
	 wire [31:0] sct6_time;
	 wire [31:0] sct7_time;
	 wire [31:0] sct8_time;
	 wire [31:0] sct9_time;
	 wire [31:0] sct10_time;
	 wire [31:0] sct11_time;
	 wire [31:0] sct12_time;
	 wire [31:0] sct13_time;
	 wire [31:0] sct14_time;
	 wire [31:0] sct15_time;
	 wire [31:0] sct16_time;

//**************        ram 模块        **************//
	wire en1_a,en1_b,en2_a,en2_b,we1_a,we1_b,we2_a,we2_b;
	wire [13:0] address1_a,address1_b,address2_a,address2_b;
	wire [7:0] data_in1_a,data_in1_b,data_in2_a,data_in2_b;
	wire [7:0] data_out1_a,data_out1_b,data_out2_a,data_out2_b;
	
	wire ena_infoRAM,enb_infoRAM,wea_infoRAM;
	wire [9:0] addra_infoRAM,addrb_infoRAM;
	wire [7:0] datain_infoRAM,dataout_infoRAM;
	
	wire en_RAM,we_RAM;
	wire [14:0] address_RAM;
	reg en_MCU_dataram;
	reg we_MCU_dataram;
	reg en_MCU_infoRAM_a;
	reg we_MCU_infoRAM_a;
	wire [7:0] MCU_dataram_dataout;
	wire [13:0]addr_MCU_dataram;
	
	wire [7:0] MCU_sctram_dataout;
	wire [14:0]addr_MCU_sctram;	
	
	wire en_flash_dataram,we_flash_dataram;
	wire [7:0]flash_dataram_dataout,flash_dataram_datain;
	wire [13:0]addr_flash_dataram;
	 
//**************       NandFlash 模块       **************//
(*mark_debug="TRUE"*)    wire [7:0]flash_data;
(*mark_debug="TRUE"*)    wire cle,ale,we,re;
(*mark_debug="TRUE"*)    wire ready_busy;
	 wire [7:0]flash_datain;
	 wire [7:0]flash_dataout;
	 wire inout_flag;
	 wire read_flag;
	 
	 wire [14:0]flash_ram_addr;
	 wire [7:0] flash_ram_datain,flash_ram_dataout;
	 wire flash_en_ram,flash_we_ram;
	 wire nandflash_busy_Noresponse;
	 wire [23:0]write_addr_row;
	 wire en_write;
//**************** 	 Command_Transfer     ****************//
	 wire en_bad_block_renew_transfer;						//向MCU发送更新后的坏块表标志脉冲
	 wire [11:0]bad_block_renew_addr;						//坏块地址
	 wire flash_cmd_incomplete;
	 
	 wire en_writeAddr_Transfer,end_writeAddr_Transfer;
	 
	 
	 wire end_init_flash_addr,end_erase;
	 wire [7:0]baud_CMD;
	 wire en_baud_transfer;
	 wire end_baud_transfer;
//*************      FPAG控制软件UART下载数据   ***************//
   wire [7:0] data_ram_FPGA;        //ram中读出的数据给Data_download模块 
	wire en_FPGA,we_FPGA;
   wire [14:0] address_FPGA;
	wire end_read;
	wire change_bypass;              //切换直通信号
	wire f_rx,f_tx,f_re,f_de;
	wire return_bypass;
	wire en_read;
	wire [23:0]read_addr_FPGA;
	wire change_ram1;               //切换ram
	
	
//*************************************************//
//                 NAND FLASH接口                   //
//************************************************//
	assign flash_IO = inout_flag ? 8'hzz : flash_datain;  
	assign flash_dataout = inout_flag ? flash_IO : 8'h00;
	assign flash_data = inout_flag ? flash_dataout : flash_datain;
//*************************************************//
//              测试模块                              //
//*************************************************//
//ila_0 ila_inst_0(
//    .clk( clk),
//    .probe0( flash_dataout),
//    .probe1( cle),
//    .probe2(ale),
//    .probe3(we),
//    .probe4(re),
//    .probe5(ready_busy)
//);

//*************************************************//
//              FPAG控制软件UART下载数据              //
//*************************************************//
Data_download Data_download(
     .clk(clk),
     .clk12M(clk12M),
	  .clk_96M(clk_96M),
	  .rst(rst),
	  .end_read(end_read),
	  .change_bypass(change_bypass),
	  .return_bypass(return_bypass),
	  .data_ram(data_ram_FPGA),
	  .f_rx(f_rx),
	  .f_tx(f_tx),
	  .f_re(f_re),
	  .f_de(f_de),
	  .en(en_FPGA),
	  .we(we_FPGA),
	  .addr_ram(address_FPGA),
	  .en_read(en_read),
	  .read_addr(read_addr_FPGA),
     .change_ram(change_ram1),
	  .baud_CMD(baud_CMD),
     .en_baud_transfer(en_baud_transfer),
     .end_baud_transfer(end_baud_transfer)	  
);

//****************************************************//
//					直通模块											//
//****************************************************//	
	 Bypass Bypass (		//直通模块
    .A1_485_tx(A1_485_tx), 
    .A1_485_rx(A1_485_rx), 
    .A1_485_re(A1_485_re), 
    .A1_485_de(A1_485_de), 
    ._485A_txd(_485A_txd), 
    ._485A_rxd(_485A_rxd), 
    ._485A_re(_485A_re), 
    ._485A_de(_485A_de), 
    .A2_485_tx(A2_485_tx), 
    .A2_485_rx(A2_485_rx), 
    .A2_485_re(A2_485_re), 
    .A2_485_de(A2_485_de), 
    ._485B_txd(_485B_txd), 
    ._485B_rxd(_485B_rxd), 
    ._485B_re(_485B_re), 
    ._485B_de(_485B_de), 
    .A3_485_tx(A3_485_tx), 
    .A3_485_rx(A3_485_rx), 
    .A3_485_re(A3_485_re), 
    .A3_485_de(A3_485_de), 
    ._485C_txd(_485C_txd), 
    ._485C_rxd(_485C_rxd), 
    ._485C_re(_485C_re), 
    ._485C_de(_485C_de),
	 .change_bypass(change_bypass),
	 .f_tx(f_tx),
	 .f_rx(f_rx),
	 .f_re(f_re),
	 .f_de(f_de)
    );




	 Selection_AD Selection_AD (
    .clk(clk), 
    .rst(rst), 
    .cs_delay1(cs_delay1), 
    .cs_delay2(cs_delay2), 
    .ad_address1(ad_address1), 
    .ad_address2(ad_address2), 
    .ram_busy(ram_busy), 
	 .cs1(cs1),
	 .cs2(cs2),
    .cs_delay(cs_delay), 
	 .ad_adj(ad_adj),
    .ad_address(address_in)   
    );


    Ram_Control Ram_Control (
    .clk(clk), 
    .rst(rst), 
    .cs_delay(cs_delay), 
	 .ram_adj(ram_adj),
	 .ram_busy(ram_busy),
    .data1_in(ram1_control_data_in), 
    .data1_out(ram1_control_data_out), 
	 .data2_in(ram2_control_data_in),
	 .data2_out(ram2_control_data_out),
    .address_in(address_in), 
	 .address_out(address_out), 
    .en(en_rw), 
    .we(we_rw) 
    );


//****************************************************//
//         切换ram模块											//
//****************************************************//
	 Change_ram Change_ram(
	 .clk(clk),
	 .rst(rst),
	 .change_ram(change_ram),
	 .ram_busy(ram_busy),
	 .ram_change(ram_change),
	 .ram_adj(ram_adj)
	 );
assign change_ram = change_bypass ? change_ram1:change_ram2; //选择change_ram信号来源
	 
//****************************************************//
//              MCU指令接收模块									//
//****************************************************//
	Command_Receiver Command_Receiver (
    .clk(clk), 
    .rst(rst), 
.start_w( start_w),
.start_r( start_r),
.c_r(c_r),
.start_e(start_e),
    .end_clr(end_clr), 
    .end_demand_write_addr(end_demand_write_addr), 
    .en_demand_write_addr(en_demand_write_addr),  
    .change_ram(change_ram2), 
    .en_clr(en_clr), 
    .cmd(cmd), 
    .start_cmd(start_cmd),
	 .ram_change(ram_change),
	 .uart_cmd_incomplete(uart_cmd_incomplete),
	 .return_bypass(return_bypass),
	 .change_bypass(change_bypass)
    );
	 
//****************************************************//
//              MCU指令发送模块									//
//****************************************************//
	Command_Transfer Command_Transfer (
    .clk(clk), 
    .rst(rst), 
    .clk1M(clk1M), 
    .RXD_MCU(  ), 
    .en_bad_block_renew_transfer(en_bad_block_renew_transfer), 
    .bad_block_renew_addr(bad_block_renew_addr), 
    .en_vibTransfer(en_vibTransfer), 
    .acc_data(acc_data),
	 .baud_CMD(baud_CMD),
	 .en_baud_transfer(en_baud_transfer),
    .end_baud_transfer(end_baud_transfer),	 
    .end_vibTransfer(end_vibTransfer), 
    .en_writeAddr_Transfer(en_writeAddr_Transfer), 
    .end_writeAddr_Transfer(end_writeAddr_Transfer), 
    .write_addr_row(write_addr_row), 
    .en_demand_write_addr(en_demand_write_addr), 
    .end_demand_write_addr(end_demand_write_addr), 
    .end_init_flash_addr(end_init_flash_addr),
	 .end_erase(end_erase)
    );

	 
//****************************************************//
//               清除RAM模块									//
//****************************************************//
	Clear_ram Clear_ram (
		.en_clr(en_clr),
		.clk(clk),
		.rst(rst),
		.ram_change(ram_change),
		.en_ram_clr(en_ram_clr),
		.we_ram_clr(we_ram_clr),
		.ram_data_clr(ram_data_clr),
		.address_clr(address_clr),
		.end_clr(end_clr)
	);



//****************************************************//
//               flash控制模块									//
//****************************************************//
	 
	NANDflash_control NANDflash_control (
    .clk(clk), 
    .rst(rst), 
    .clk6M(clk6M), 
    .clk12M(clk12M), 
    .cmd(cmd), 
    .start_trs(start_cmd), 
    .flash_ram_dataout(flash_ram_dataout), 
    .flash_ram_datain(flash_ram_datain), 
    .flash_en_ram(flash_en_ram), 
    .flash_we_ram(flash_we_ram), 
    .flash_ram_addr(flash_ram_addr), 
    .inout_flag(inout_flag), 
    .read_flag(read_flag), 
    .flash_dataout(flash_dataout), 
    .flash_datain(flash_datain), 
    .ready_busy(ready_busy), 
    .ce(ce), 
    .cle(cle), 
    .ale(ale), 
    .we(we), 
    .re(re), 
    .en_bad_block_renew_transfer(en_bad_block_renew_transfer), 
    .bad_block_renew_addr(bad_block_renew_addr), 
    .end_writeAddr_Transfer(end_writeAddr_Transfer), 
    .en_writeAddr_Transfer(en_writeAddr_Transfer), 
    .write_addr_row(write_addr_row), 
    .end_init_flash_addr(end_init_flash_addr), 
    .end_erase(end_erase),
	 .nandflash_busy_Noresponse(nandflash_busy_Noresponse),
	 .flash_cmd_incomplete(flash_cmd_incomplete),
	 .change_bypass(change_bypass),
	 .end_read(end_read),
	 .en_read_FPGA(en_read),
	 .read_addr_FPGA(read_addr_FPGA),
	 .state( state)
    );

//****************************************************//
//                   FPGA死机输出  		       				//
//****************************************************//
System_Crash System_Crash(

   .clk(clk),
	.rst(rst),
	.uart_cmd_incomplete(uart_cmd_incomplete),
	.flash_cmd_incomplete(flash_cmd_incomplete),
	.nandflash_busy_Noresponse(nandflash_busy_Noresponse),
	.FPGA_Crash(FPGA_Crash)
);

//*****************************************************//
//                  RAM的控制信号选择                   //
//****************************************************//
assign en_RAM = change_bypass ? en_FPGA:en_MCU;
assign we_RAM = change_bypass ? we_FPGA:we_MCU;
assign address_RAM = change_bypass ? address_FPGA:address_MCU;
//****************************************************//
//                   判断赋值  		       				//
//****************************************************//
/*数据ram的A端口提供给flash和清除ram使用*/
	 assign en1_a = ram_adj ? (read_flag ? en_flash_dataram : 0) : (en_clr ? en_ram_clr : (read_flag ? 0 : en_flash_dataram));
	 assign we1_a = ram_adj ? (read_flag ? we_flash_dataram : 0) : (en_clr ? we_ram_clr : (read_flag ? 0 : we_flash_dataram));
	 
	 assign en2_a = ~ram_adj ? (read_flag ? en_flash_dataram : 0) : (en_clr ? en_ram_clr : (read_flag ? 0 : en_flash_dataram));
	 assign we2_a = ~ram_adj ? (read_flag ? we_flash_dataram : 0) : (en_clr ? we_ram_clr : (read_flag ? 0 : we_flash_dataram));
	 
    assign data_in1_a = ram_adj? (read_flag ? flash_dataram_datain : 0) : (en_clr ? ram_data_clr : (read_flag ? 0 : flash_dataram_datain));  	//判断写入的是AD采集的数据，还是需要写0清除ram
    assign data_in2_a = ~ram_adj? (read_flag ? flash_dataram_datain : 0) : (en_clr ? ram_data_clr : (read_flag ? 0 : flash_dataram_datain));   
	 
	 assign address1_a = ram_adj ? (read_flag ? addr_flash_dataram : 0) : (en_clr ? address_clr : (read_flag ? 0 : addr_flash_dataram));    //根据ram_adj的不同,ram的地址为ram控制模块输出的地址或者数据上传模块的地址
	 assign address2_a = ~ram_adj ? (read_flag ? addr_flash_dataram : 0) : (en_clr ? address_clr : (read_flag ? 0 : addr_flash_dataram)); 

	 assign flash_dataram_dataout = ram_adj ? (read_flag ? data_out1_a : data_out2_a) : (~read_flag ? data_out1_a : data_out2_a);
 
/*数据ram的b端口提供给MCU和采集使用*/
	 assign en1_b = ram_adj ? (read_flag ? 0 : en_rw) : en_MCU_dataram; //ram_adj为0时选中RAM1供给MCU读写使用，ram_adj为1时选中RAM2供给MCU读写使用 
	 assign we1_b = ram_adj ? we_rw : (we_MCU_dataram ? we_MCU_dataram : 0);
	 
	 assign en2_b = ~ram_adj ? (read_flag ? 0 : en_rw) : en_MCU_dataram;
	 assign we2_b = ~ram_adj ? we_rw : (we_MCU_dataram ? we_MCU_dataram : 0);
	
    assign data_in1_b = ram_adj? ram1_control_data_out : MCU_datain;   //判断写入的是AD采集的数据，还是MCU送来的数据
	 assign data_in2_b = ~ram_adj? ram2_control_data_out : MCU_datain;

	 assign ram1_control_data_in = data_out1_b;     
	 assign ram2_control_data_in = data_out2_b;
	 
	 assign MCU_dataram_dataout = ram_adj ? data_out2_b : data_out1_b;

	 assign address1_b = ram_adj ? address_out : addr_MCU_dataram;    //根据ram_adj的不同,ram的地址为ram控制模块输出的地址或者数据上传模块的地址
	 assign address2_b = ~ram_adj ? address_out : addr_MCU_dataram;
	 
	 //assign addr_MCU_dataram = ((change_bypass ? addr_ram_FPGA[14] : address_MCU[14]) == 0)? (change_bypass ?addr_ram_FPGA[13:0]:address_MCU[13:0]) : 0;
	 assign addr_MCU_dataram = (address_RAM[14] == 0)? address_RAM[13:0] : 0;
	 
	 always@(negedge clk or posedge rst)                //时钟下降沿改变能谱数据RAM读写和片选使能        
	 begin
	  if(rst)
	   begin
	    en_MCU_dataram<=0;
		 we_MCU_dataram<=0;
		end
     else
	   begin
       en_MCU_dataram <= ((address_RAM[14] == 0) && en_RAM) ? en_RAM : 0;	
		 we_MCU_dataram <= ((address_RAM[14] == 0) && en_RAM) ? we_RAM : 0;
      end		 
	 end
	 
/*MCU控制的inforam端口a赋值*/
	 assign ena_infoRAM = en_MCU_infoRAM_a;	
	 assign wea_infoRAM = we_MCU_infoRAM_a;
	 assign addra_infoRAM = address_RAM[9:0];
	 assign datain_infoRAM = MCU_datain;
	 assign addr_MCU_sctram = ((address_RAM[14:12] == 3'b100) && en_RAM) ? address_RAM : 0;	
	 assign MCU_dataout = en_RAM ? ((address_RAM[14:12] == 3'b100) ? MCU_sctram_dataout : ((address_RAM[14] == 0) ? MCU_dataram_dataout :0)) : 0;
    assign data_ram_FPGA = MCU_dataout;
	 always@(negedge clk or posedge rst)                //时钟下降沿改变infoRAM读写和片选使能
	 begin
	   if(rst)
		 begin
		   en_MCU_infoRAM_a <= 0;
		   we_MCU_infoRAM_a <= 0;
		 end
		else
		 begin
		   en_MCU_infoRAM_a <= ((address_RAM[14:12] == 3'b101) && en_RAM)? en_RAM : 0;
			we_MCU_infoRAM_a <= ((address_RAM[14:12] == 3'b101) && en_RAM)? we_RAM : 0;
		 end
	 end
/*flash控制的inforam端口b赋值*/
	 assign enb_infoRAM = (flash_en_ram && (flash_ram_addr[14] == 1)) ? flash_en_ram : 0;                 //端口b片选使能
	 assign addrb_infoRAM = (flash_en_ram && (flash_ram_addr[14] == 1)) ? flash_ram_addr[13:0] : 0;       //端口b地址
	 
	 assign en_flash_dataram = (flash_en_ram && (flash_ram_addr[14] == 0)) ? flash_en_ram : 0;            
	 assign we_flash_dataram = (flash_en_ram && (flash_ram_addr[14] == 0)) ? flash_we_ram : 0;
	 assign flash_dataram_datain = (flash_en_ram && (flash_ram_addr[14] == 0)) ? flash_ram_datain : 0;
	 assign addr_flash_dataram = (flash_en_ram && (flash_ram_addr[14] == 0)) ? flash_ram_addr[13:0] : 0;
	 
	 assign flash_ram_dataout = (flash_en_ram && (flash_ram_addr[14] == 0)) ? flash_dataram_dataout : ((flash_ram_addr[12:0]>1023) ? 8'hFF: dataout_infoRAM );  //写入Flash的数据
	 
	 Data_value Data_value(
	 .clk(clk),
	 .rst(rst),
	 .address(addr_MCU_sctram),
	 .sct_period(sct_period), 
    .sct1_time(sct1_time),
    .sct2_time(sct2_time),               
    .sct3_time(sct3_time), 
    .sct4_time(sct4_time), 
    .sct5_time(sct5_time), 
    .sct6_time(sct6_time), 
    .sct7_time(sct7_time), 
    .sct8_time(sct8_time), 
    .sct9_time(sct9_time), 
    .sct10_time(sct10_time), 
    .sct11_time(sct11_time), 
    .sct12_time(sct12_time), 
    .sct13_time(sct13_time), 
    .sct14_time(sct14_time), 
    .sct15_time(sct15_time), 
    .sct16_time(sct16_time),
	 .data_CF(MCU_sctram_dataout),
	 .ram_change(ram_change)
	 );


//****************************************************//
//                        RAM	  		       				//
//****************************************************//
	RAM1 RAM1 (
		.clka(clk), // input clka
		.ena(en1_a), // input ena
		.wea(we1_a), // input [0 : 0] wea
		.addra(address1_a), // input [13 : 0] addra
		.dina(data_in1_a), // input [7 : 0] dina
		.douta(data_out1_a), // output [7 : 0] douta
		.clkb(clk), // input clkb
		.enb(en1_b), // input enb
		.web(we1_b), // input [0 : 0] web
		.addrb(address1_b), // input [13 : 0] addrb
		.dinb(data_in1_b), // input [7 : 0] dinb
		.doutb(data_out1_b) // output [7 : 0] doutb
		);


	RAM2 RAM2 (
		.clka(clk), // input clka
		.ena(en2_a), // input ena
		.wea(we2_a), // input [0 : 0] wea
		.addra(address2_a), // input [13 : 0] addra
		.dina(data_in2_a), // input [7: 0] dina
		.douta(data_out2_a), // output [7 : 0] douta
		.clkb(clk), // input clkb
		.enb(en2_b), // input enb
		.web(we2_b), // input [0 : 0] web
		.addrb(address2_b), // input [13 : 0] addrb
		.dinb(data_in2_b), // input [7 : 0] dinb
		.doutb(data_out2_b) // output [7 : 0] doutb
    );

	info_RAM info_RAM (
  .clka(clk), // input clka
  .ena(ena_infoRAM), // input ena
  .wea(wea_infoRAM), // input [0 : 0] wea
  .addra(addra_infoRAM), // input [7 : 0] addra
  .dina(datain_infoRAM), // input [7 : 0] dina
  .clkb(clk), // input clkb
  .enb(enb_infoRAM), // input enb
  .addrb(addrb_infoRAM), // input [7 : 0] addrb
  .doutb(dataout_infoRAM) // output [7 : 0] doutb
	);

endmodule
