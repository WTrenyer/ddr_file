//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_rw
// Last modified Date:  2023/7/5 09:05:05
// Last Version:        V1.0
// Descriptions:        ddr3��������дģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_rw(          
    input           ui_clk               ,  //�û�ʱ��
    input           ui_clk_sync_rst      ,  //��λ,����Ч
    input           init_calib_complete  ,  //DDR3��ʼ�����
    input           app_rdy              ,  //MIG IP�˿���
    input           app_wdf_rdy          ,  //MIGд���ݿ���
    input           app_rd_data_valid    ,  //��������Ч
    input    [9:0]  wfifo_rcount         ,  //д�˿�FIFO�е�������
    input    [9:0]  rfifo_wcount         ,  //���˿�FIFO�е�������
    input   [27:0]  app_addr_rd_min      ,  //��DDR3����ʼ��ַ
    input   [27:0]  app_addr_rd_max      ,  //��DDR3�Ľ�����ַ
    input   [7:0]   rd_bust_len          ,  //��DDR3�ж�����ʱ��ͻ������
    input   [27:0]  app_addr_wr_min      ,  //дDDR3����ʼ��ַ
    input   [27:0]  app_addr_wr_max      ,  //дDDR3�Ľ�����ַ
    input   [7:0]   wr_bust_len          ,  //��DDR3��д����ʱ��ͻ������
    input           ddr3_read_valid      ,  //DDR3 ��ʹ��  
             
    output          rfifo_wren           ,  //��ddr3�������ݵ���Чʹ�� 
    output  [27:0]  app_addr             ,  //DDR3��ַ                 
    output          app_en               ,  //MIG IP�˲���ʹ��
    output          app_wdf_wren         ,  //�û�дʹ��   
    output          app_wdf_end          ,  //ͻ��д��ǰʱ�����һ������ 
    output  [2:0]   app_cmd                 //MIG IP�˲������������д       
    );
    
//localparam 
localparam IDLE        = 4'b0001;   //����״̬
localparam DDR3_DONE   = 4'b0010;   //DDR3��ʼ�����״̬
localparam WRITE       = 4'b0100;   //��FIFO����״̬
localparam READ        = 4'b1000;   //дFIFO����״̬

//reg define 
reg    [27:0] app_addr_rd;          //DDR3����ַ
reg    [27:0] app_addr_wr;          //DDR3д��ַ
reg    [3:0]  state_cnt;            //״̬������
reg    [23:0] rd_addr_cnt;          //�û�����ַ����
reg    [23:0] wr_addr_cnt;          //�û�д��ַ���� 
reg    [27:0] app_addr_rd_min_a;    //��DDR3����ʼ��ַ
reg    [27:0] app_addr_rd_max_a;    //��DDR3�Ľ�����ַ
reg    [7:0]  rd_bust_len_a;        //��DDR3�ж�����ʱ��ͻ������
reg    [27:0] app_addr_wr_min_a;    //дDDR3����ʼ��ַ
reg    [27:0] app_addr_wr_max_a;    //дDDR3�Ľ�����ַ
reg    [7:0]  wr_bust_len_a;        //��DDR3��д����ʱ��ͻ������

//wire define 
wire          rst_n;

 //*****************************************************
//**                    main code
//***************************************************** 

//��������Ч�źŸ���wfifoдʹ��
assign rfifo_wren =  app_rd_data_valid;

assign rst_n = ~ui_clk_sync_rst;

//��д״̬MIG������д��Ч,�����ڶ�״̬MIG���У���ʱʹ���ź�Ϊ�ߣ��������Ϊ��
assign app_en = ((state_cnt == WRITE && (app_rdy && app_wdf_rdy))
                ||(state_cnt == READ && app_rdy)) ? 1'b1:1'b0;
                
//��д״̬,MIG������д��Ч����ʱ����дʹ��
assign app_wdf_wren = (state_cnt == WRITE && (app_rdy && app_wdf_rdy)) ? 1'b1:1'b0;

//��������DDR3оƬʱ�Ӻ��û�ʱ�ӵķ�Ƶѡ��4:1��ͻ������Ϊ8���������ź���ͬ
assign app_wdf_end = app_wdf_wren; 

//���ڶ���ʱ������ֵΪ1������ʱ������ֵΪ0
assign app_cmd = (state_cnt == READ) ? 3'd1 :3'd0; 

//�����ݶ�д��ַ����ddr��ַ
assign app_addr = (state_cnt == READ) ? {3'b0,app_addr_rd[24:0]}:{3'b0,app_addr_wr[24:0]};

//���첽�źŽ��д��Ĵ���
always @(posedge ui_clk or negedge rst_n)  begin
    if(~rst_n)begin
        app_addr_rd_min_a <= 28'd0;
        app_addr_rd_max_a <= 28'd0; 
        rd_bust_len_a <= 8'd0; 
        app_addr_wr_min_a <= 28'd0;  
        app_addr_wr_max_a <= 28'd0; 
        wr_bust_len_a <= 8'd0;                            
    end   
    else begin
        app_addr_rd_min_a <= app_addr_rd_min;
        app_addr_rd_max_a <= app_addr_rd_max; 
        rd_bust_len_a <= rd_bust_len; 
        app_addr_wr_min_a <= app_addr_wr_min;  
        app_addr_wr_max_a <= app_addr_wr_max; 
        wr_bust_len_a <= wr_bust_len;                    
    end    
end 
   
//DDR3��д�߼�ʵ��
always @(posedge ui_clk or negedge rst_n) begin
    if(~rst_n) begin 
        state_cnt    <= IDLE;              
        wr_addr_cnt  <= 24'd0;      
        rd_addr_cnt  <= 24'd0;       
        app_addr_wr  <= app_addr_wr_min_a;   
        app_addr_rd  <= app_addr_rd_min_a;  
    end
    else begin
        case(state_cnt)
            IDLE:begin
                if(init_calib_complete)
                    state_cnt <= DDR3_DONE ;
                else
                    state_cnt <= IDLE;
            end
            DDR3_DONE:begin//������������ַ�Զ���ַ����������
                if(app_addr_rd >= app_addr_rd_max_a - 4'd8)begin 
                    state_cnt <= DDR3_DONE;
                    rd_addr_cnt <= 24'd0; 
                    app_addr_rd <= app_addr_rd_min_a;
                end //��д��������ַ��д��ַ����������
                else if(app_addr_wr >= app_addr_wr_max_a - 4'd8)begin 
                    state_cnt <= DDR3_DONE;
                    rd_addr_cnt <= 24'd0; 
                    app_addr_wr <= app_addr_wr_min_a;
                end
               else if(wfifo_rcount >= (wr_bust_len_a - 2'd2))begin  
                    state_cnt <= WRITE;              //����д����
                    wr_addr_cnt  <= 24'd0;                       
                    app_addr_wr <= app_addr_wr;      //д��ַ���ֲ���
                end
                 //��rfifo�洢��������һ��ͻ������
                else if(rfifo_wcount <= (rd_bust_len_a - 2'd2) && ddr3_read_valid )begin  
                    state_cnt <= READ;                              //����������
                    rd_addr_cnt <= 24'd0;
                    app_addr_rd <= app_addr_rd;      //����ַ���ֲ���
                end 
                else begin
                    state_cnt <= state_cnt;   
                    wr_addr_cnt  <= 24'd0;      
                    rd_addr_cnt  <= 24'd0;                                      
                end
            end    
            WRITE:   begin 
                if((wr_addr_cnt >= (wr_bust_len_a - 1'b1)) && 
                   (app_rdy && app_wdf_rdy))begin    //д���趨�ĳ��������ȴ�״̬                  
                    state_cnt    <= DDR3_DONE;                 
                    app_addr_wr <= app_addr_wr + 4'd8;  //һ����д��8�������ʼ�8
                end       
                else if(app_rdy && app_wdf_rdy)begin   //д��������
                    wr_addr_cnt  <= wr_addr_cnt + 1'd1;//д��ַ�������Լ�
                    app_addr_wr  <= app_addr_wr + 4'd8;   //һ����д��8�������ʼ�8
                end
                else begin                             //д���������㣬���ֵ�ǰֵ     
                    wr_addr_cnt  <= wr_addr_cnt;
                    app_addr_wr  <= app_addr_wr; 
                end
            end
            READ:begin                      //�����趨�ĵ�ַ����    
                if((rd_addr_cnt >= (rd_bust_len_a - 1'b1)) && app_rdy)begin
                    state_cnt   <= DDR3_DONE;          //����������״̬ 
                    app_addr_rd <= app_addr_rd + 4'd8;
                end       
                else if(app_rdy)begin               //��MIG�Ѿ�׼����,��ʼ��
                    rd_addr_cnt <= rd_addr_cnt + 1'b1; //�û���ַ������ÿ�μ�һ
                    app_addr_rd <= app_addr_rd + 4'd8; //һ���Զ���8����,DDR3��ַ��8
                end
                else begin                         //��MIGû׼����,�򱣳�ԭֵ
                    rd_addr_cnt <= rd_addr_cnt;
                    app_addr_rd <= app_addr_rd; 
                end
            end             
            default:begin
                state_cnt    <= IDLE;
                wr_addr_cnt  <= 24'd0;
                rd_addr_cnt  <= 24'd0;
            end
        endcase
    end
end          
                
endmodule