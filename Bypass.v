`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:05:36 03/07/2016 
// Design Name: 
// Module Name:    Bypass 
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
module Bypass(
   input    change_bypass,              //�ж�ֱͨ
	input    f_tx,                       //Data_downloadģ���ڵ�uart��
	input    f_re,f_de,                  //����485оƬ��״̬
	output   f_rx,            
	
	input 	A1_485_tx,           		 //���յ�Ƭ����txd 5.6,A1����Ƭ���ĵ�1��485
	output	A1_485_rx,						 //��Ƭ�����rxd 5.7
	input 	A1_485_re,					  	 //�ӵ�Ƭ����ȡ485����re 5.4
	input		A1_485_de,						 //�ӵ�Ƭ����ȡ485����de 5.5
	
	output	_485A_txd,						
	input		_485A_rxd,						
	output	_485A_re,						
	output	_485A_de,					
	
	input 	A2_485_tx,           		//���յ�Ƭ����txd 9.4,A2����Ƭ���ĵ�2��485
	output	A2_485_rx,						//��Ƭ�����rxd 9.5
	input 	A2_485_re,						//�ӵ�Ƭ����ȡ485����re 9.6
	input		A2_485_de,						//�ӵ�Ƭ����ȡ485����de 9.7
	
	output	_485B_txd,						
	input		_485B_rxd,						
	output	_485B_re,						
	output	_485B_de,						

	input 	A3_485_tx,           		//���յ�Ƭ����txd 10.4,A3����Ƭ���ĵ�3��485
	output	A3_485_rx,						//��Ƭ�����rxd 10.5
	input 	A3_485_re,						//�ӵ�Ƭ����ȡ485����re 10.6
	input		A3_485_de,						//�ӵ�Ƭ����ȡ485����de 10.7
	
	output	_485C_txd,						
	input		_485C_rxd,						
	output	_485C_re,						
	output	_485C_de							
   

    );
	
	assign _485A_txd = change_bypass ? f_tx : A1_485_tx;
	assign A1_485_rx = _485A_rxd;
	assign f_rx      = _485A_rxd;  
	assign _485A_re  = change_bypass ? f_re : A1_485_re;
	assign _485A_de  = change_bypass ? f_de : A1_485_de;
	
	assign _485B_txd = A2_485_tx;
	assign A2_485_rx = _485B_rxd;
	assign _485B_re = A2_485_re;
	assign _485B_de = A2_485_de;

	assign _485C_txd = A3_485_tx;
	assign A3_485_rx = _485C_rxd;
	assign _485C_re = A3_485_re;
	assign _485C_de = A3_485_de;

endmodule
