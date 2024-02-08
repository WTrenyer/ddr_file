//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_fifo_ctrl
// Last modified Date:  2023/7/5 09:11:52
// Last Version:        V1.0
// Descriptions:        ddr3������fifo����ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`timescale 1ns / 1ps
module ddr3_fifo_ctrl(
    input               rst_n            ,  //��λ�ź�
    input               wr_clk           ,  //дfifoдʱ��
    input               rd_clk           ,  //��fifo��ʱ��
    input               ui_clk           ,  //�û�ʱ��
    input               wr_en            ,  //������Чʹ���ź�
    input  [15:0]       wrdata           ,  //д��Ч����
    input  [127:0]      rfifo_din        ,  //�û�������
    input               rdata_req        ,  //�����������ź� 
    input               rfifo_wren       ,  //��ddr3�������ݵ���Чʹ��
    input               wfifo_rden       ,  //wfifo��ʹ��       

    output [127:0]      wfifo_dout       ,  //�û�д����
    output [9:0]        rfifo_wcount     ,  //rfifoʣ�����ݼ���
    output [9:0]        wfifo_rcount     ,  //wfifoд�����ݼ���
    output reg [15:0]   rddata              //����Ч����     	
    );
           
//reg define
reg  [127:0] wrdata_t          ;  //��16bit����Դ������λƴ�ӵõ�   
reg  [3:0]   byte_cnt          ;  //д������λ������
reg  [3:0]   i                 ;  //��������λ������
reg          wfifo_wren        ;  //wfifoдʹ���ź�

//wire define 
wire [127:0] rfifo_dout        ;  //rfifo�������    
wire [127:0] wfifo_din         ;  //wfifoд����
wire [15:0]  dataout[0:15]     ;  //����������ݵĶ�ά����
wire         rfifo_rden        ;  //rfifo�Ķ�ʹ��

//*****************************************************
//**                    main code
//*****************************************************  
assign wfifo_din = wrdata_t ;

//��λ�Ĵ�������ʱ����rfifo����һ������
assign rfifo_rden = (rdata_req && (i == 4'd7)) ? 1'b1 : 1'b0; 

//rfifo��������ݴ浽��ά����
assign dataout[0] = rfifo_dout[127:112];
assign dataout[1] = rfifo_dout[111:96];
assign dataout[2] = rfifo_dout[95:80];
assign dataout[3] = rfifo_dout[79:64];
assign dataout[4] = rfifo_dout[63:48];
assign dataout[5] = rfifo_dout[47:32];
assign dataout[6] = rfifo_dout[31:16];
assign dataout[7] = rfifo_dout[15:0];

//16λ����ת128λ����        
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) begin
        wrdata_t <= 16'd0;
        byte_cnt <= 4'd0;
    end
    else if(wr_en) begin
        if(byte_cnt == 4'd7)begin
            byte_cnt <= 4'd0;
            wrdata_t <= {wrdata_t[111:0],wrdata};
        end
        else begin
            byte_cnt <= byte_cnt + 1'b1;
            wrdata_t <= {wrdata_t[111:0],wrdata};
        end
    end
    else begin
        byte_cnt <= 4'd0;
        wrdata_t <= wrdata_t;
    end    
end 

//wfifoдʹ�ܲ���
always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) 
        wfifo_wren <= 1'b0;
    else if(wfifo_wren == 1'b1)
        wfifo_wren <= 1'b0;
    else if(byte_cnt == 4'd7 && wr_en)  //����Դ���ݴ���8�Σ�дʹ������һ��
        wfifo_wren <= 1'b1;
    else 
        wfifo_wren <= 1'b0;
 end   

//��rfifo������128bit���ݲ���8��16bit����
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        rddata <= 16'b0;
        i <= 5'd0;
    end
    else if(rdata_req) begin
        if(i == 4'd7)begin
            rddata <= dataout[i];
            i <= 4'd0;
        end
        else begin
            rddata <= dataout[i];
            i <= i + 1'b1;
        end
    end 
    else begin
       rddata <= rddata;
       i <= 4'b0;
   end
end  

u_rd_fifo u_rd_fifo (
  .rst               (~rst_n),                    
  .wr_clk            (ui_clk),   
  .rd_clk            (rd_clk),    
  .din               (rfifo_din), 
  .wr_en             (rfifo_wren),
  .rd_en             (rfifo_rden),
  .dout              (rfifo_dout),
  .full              (),          
  .empty             (),          
  .rd_data_count     (),  
  .wr_data_count     (rfifo_wcount),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()      
);

u_wr_fifo u_wr_fifo (
  .rst               (~rst_n),
  .wr_clk            (wr_clk),            
  .rd_clk            (ui_clk),           
  .din               (wfifo_din),         
  .wr_en             (wfifo_wren),        
  .rd_en             (wfifo_rden),        
  .dout              (wfifo_dout),       
  .full              (),                  
  .empty             (),                  
  .rd_data_count     (wfifo_rcount),  
  .wr_data_count     (),  
  .wr_rst_busy       (),      
  .rd_rst_busy       ()    
);

endmodule 