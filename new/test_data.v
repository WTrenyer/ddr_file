//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           test_data
// Last modified Date:  2023/7/5 09:11:52
// Last Version:        V1.0
// Descriptions:        ddr3���ݲ���ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module test_data(
    input               clk_50m,
    input               rst_n,
    input               init_calib_complete  ,  //DDR3��ʼ�����
    input [15:0]        rd_data,
    
    output reg          rd_req,
    output reg [15:0]   wr_data,
    output reg          wr_en,
    output reg          error
    );

//parameter
//����д����������ֵ
parameter TEST_LENGTH = 12'd1024;

//reg define
reg [11:0] rd_cnt;
reg [11:0] rd_cnt_d0;
reg        wr_finish;
reg        init_done_d0; 
reg        init_done_d1;
reg        rd_valid;

//ͬ�� ddr3 ��ʼ������ź�
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        init_done_d0 <= 1'b0;
        init_done_d1 <= 1'b0;
    end
    else begin
        init_done_d0 <= init_calib_complete;
        init_done_d1 <= init_done_d0;
    end
end 

//ͬ����������
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        rd_cnt_d0 <= 1'b0;
    else 
        rd_cnt_d0 <= rd_cnt;
end

//д��������ɺ󣬶�ȡ��fifo���ݣ���ʹ��
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n)
        rd_req <= 1'b0;
    else if(wr_finish)
        rd_req <= 1'b1;
    else
        rd_req <= rd_req;
end 

//д���ݲ������
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n) 
        wr_finish <= 1'b0;
    else if(wr_data >= TEST_LENGTH - 1'b1)//д�������
        wr_finish <= 1'b1;
    else 
        wr_finish <= wr_finish;
end 

//дfifoдʹ�ܣ�д�����ݣ�1~1024��
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n) begin
        wr_data <= 16'd0;
        wr_en <= 1'b0;
    end
    else if((wr_data <= TEST_LENGTH - 1'b1) && init_done_d1 && !wr_finish)begin
        wr_data <= wr_data + 1'b1;//д�����ݣ�1~1024��
        wr_en <= 1'b1;            //дfifoдʹ��
    end
    else begin
        wr_data <= 16'b0;
        wr_en <= 1'b0;
    end
end 

//�Զ��������м���
always @(posedge clk_50m or negedge rst_n) begin
    if(~rst_n)
        rd_cnt <= 1'b1;
    else if(rd_req)begin
        if(rd_cnt >= TEST_LENGTH )
            rd_cnt <= 1'b1;
        else 
            rd_cnt <= rd_cnt + 1'b1; 
    end
end  

//��һ�ζ�ȡ��������Ч����������������ȡ�����ݲ���Ч
always @(posedge clk_50m or negedge rst_n)begin 
    if(!rst_n)
        rd_valid <= 1'b0;
    else if(rd_cnt_d0 == TEST_LENGTH)//�ȴ���һ�ζ���������
        rd_valid <= 1'b1;//������ȡ��������Ч
    else
        rd_valid <= rd_valid;
end 

//��������Чʱ,����ȡ���ݴ���,������־�ź�
always @(posedge clk_50m or negedge rst_n) begin
    if(~rst_n)
        error <= 1'b0; 
    else if(rd_valid)
        if(rd_cnt_d0 != rd_data )
            error <= 1'b1; 
        else
            error <= error;
    else 
        error <= error;
end  

endmodule