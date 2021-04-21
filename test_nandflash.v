`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    2021.4.20
// Design Name: 
// Module Name:    NAND Flash Controller
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
//////////////////////////////////////////////////////////////////////////////////
module test_nandflash(
	 
    input clk,rst,clk6M,clk12M,clk1M,clk1_5M,clk_96M,
	
	input en_MCU,
	input we_MCU,                      //0表示读，1表示写               
	input [14:0] address_MCU,
	input [7:0]MCU_datain,
	output [7:0] MCU_dataout,
	
	input ready_busy,                  // 空闲和忙信号
	output ce,cle,ale,we,re,          // NADN Flash基本控制信号
	
	inout [7:0] flash_IO,              // NAND Flash的双向数据IO
	
	input vibstart,acc_dir,
	output clk_acc,
	
input start_w,
input start_r,
input start_e,
output [4:0]state,
input c_r,                          // change ram
output ram_adj,
output inout_flag
	
    );
	
//**************    ram_control模块     **************//
    wire [7:0] ram1_control_data_out;
	 wire [7:0] ram2_control_data_out;
    wire [7:0] ram1_control_data_in;
	 wire [7:0] ram2_control_data_in;
    wire ram_busy;                    //当前ram是否处于工作状态
	 wire we_rw,en_rw;
	 wire [13:0]address_out;           //对13位地址进行处理，在最后一位加上高低位，使得两个高低地址里的数据可以表示一道能谱


//*************     Command_Receiver     *************//
	wire en_clr;			//清除RAM使能
	wire change_ram2;		//切换ram信号
	wire start_cmd;		//命令到来脉冲信号.
	wire [31:0] cmd;
	wire en_demand_write_addr,end_demand_write_addr;
	wire uart_cmd_incomplete;



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

	 
//****************************************************//
//              MCU指令接收模块									//
//****************************************************//
	Command_Receiver Command_Receiver (
    .clk(clk), 
    .rst(rst), 
    .start_w( start_w),
    .start_r( start_r),
    .start_e(start_e), 
    .cmd(cmd), 
    .start_cmd(start_cmd)
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
	 .end_read(end_read),
	 .en_read_FPGA(en_read),
	 .read_addr_FPGA(read_addr_FPGA),
	 .state( state)
    );


//*****************************************************//
//                  RAM的控制信号选择                   //
//****************************************************//
assign en_RAM = en_MCU;
assign we_RAM = we_MCU;
assign address_RAM = address_MCU;

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
	 

//****************************************************//
//                        RAM	  		       				//
//****************************************************//
	RAM1 RAM1 (
		.clka(clk), // input clka
		.ena(en_flash_dataram), // input ena
		.wea(we_flash_dataram), // input [0 : 0] wea
		.addra(addr_flash_dataram), // input [13 : 0] addra
		.dina(flash_dataram_datain), // input [7 : 0] dina
		.douta(flash_dataram_dataout), // output [7 : 0] douta
		.clkb(clk), // input clkb
		.enb(), // input enb
		.web(), // input [0 : 0] web
		.addrb(), // input [13 : 0] addrb
		.dinb(), // input [7 : 0] dinb
		.doutb() // output [7 : 0] doutb
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
