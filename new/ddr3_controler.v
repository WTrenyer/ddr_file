//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ddr3_controler
// Last modified Date:  2023/7/5 09:11:52
// Last Version:        V1.0
// Descriptions:        ddr3����������ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ddr3_controler(
    inout   [15:0]      ddr3_dq          ,   //ddr3 ����
    inout   [1:0]       ddr3_dqs_n       ,   //ddr3 dqs��
    inout   [1:0]       ddr3_dqs_p       ,   //ddr3 dqs��  
    output  [13:0]      ddr3_addr        ,   //ddr3 ��ַ   
    output  [2:0]       ddr3_ba          ,   //ddr3 banck ѡ��
    output              ddr3_ras_n       ,   //ddr3 ��ѡ��
    output              ddr3_cas_n       ,   //ddr3 ��ѡ��
    output              ddr3_we_n        ,   //ddr3 ��дѡ��
    output              ddr3_reset_n     ,   //ddr3 ��λ
    output  [0:0]       ddr3_ck_p        ,   //ddr3 ʱ����
    output  [0:0]       ddr3_ck_n        ,   //ddr3 ʱ�Ӹ�
    output  [0:0]       ddr3_cke         ,   //ddr3 ʱ��ʹ��
    output  [0:0]       ddr3_cs_n        ,   //ddr3 Ƭѡ
    output  [1:0]       ddr3_dm          ,   //ddr3_dm
    output  [0:0]       ddr3_odt         ,   //ddr3_odt  
    output              init_calib_complete,
    input               sys_clk_i,
    input               clk_ref_i,
    input               ddr3_read_valid  ,  //DDR3 ��ʹ�� 
    
    input               rst_n            ,  //��λ�ź� 
    input [27:0]        app_addr_rd_min  ,
    input [27:0]        app_addr_rd_max  , 
    input [7:0]         rd_bust_len      , 
    input [27:0]        app_addr_wr_min  , 
    input [27:0]        app_addr_wr_max  , 
    input [7:0]         wr_bust_len      ,    
    
    input               wr_clk           ,  //дfifoдʱ��
    input               rd_clk           ,  //��fifo��ʱ��
    input               rd_req           ,  //����������ʹ��                                                                    
    input               wr_en            ,  //д����ʹ���ź�
    input  [15:0]       wrdata           ,  //д��Ч���� 
    output [15:0]       rddata              //����Ч���� 
    );
    
//wire define  
wire                  app_rdy              ;   //MIG IP�˿���
wire                  app_wdf_rdy          ;   //MIGд���ݿ���
wire                  app_rd_data_valid    ;   //��������Ч
wire [27:0]           app_addr             ;   //ddr3 ��ַ
wire [2:0]            app_cmd              ;   //�û���д����
wire                  app_en               ;   //MIG IP��ʹ��
wire [127:0]          app_rd_data          ;   //�û�������
wire                  app_rd_data_end      ;   //ͻ������ǰʱ�����һ������ 
wire [127:0]          app_wdf_data         ;   //�û�д���� 
wire                  app_wdf_end          ;   //ͻ��д��ǰʱ�����һ������ 
wire [15:0]           app_wdf_mask         ;   //д��������                           
wire                  app_sr_active        ;   //����                                 
wire                  app_ref_ack          ;   //ˢ������                             
wire                  app_zq_ack           ;   //ZQ У׼����                                                
wire                  ui_clk               ;   //�û�ʱ��                   
wire                  ui_clk_sync_rst      ;   //�û���λ�ź�    
wire [9:0]            wfifo_rcount         ;  //wfifoд�����ݼ���                    
wire [9:0]            rfifo_wcount         ;  //rfifoʣ�����ݼ���

//*****************************************************
//** main code
//***************************************************** 

//��дģ��                                                                            
 ddr3_rw u_ddr3_rw(                                                                   
    .ui_clk               (ui_clk)              ,                                     
    .ui_clk_sync_rst      (ui_clk_sync_rst | ~rst_n),                                      
    //MIG �ӿ�                                                                        
    .init_calib_complete  (init_calib_complete) ,   //ddr3��ʼ������ź�                                   
    .app_rdy              (app_rdy)             ,   //MIG IP�˿���                                   
    .app_wdf_rdy          (app_wdf_rdy)         ,   //д����                                   
    .app_rd_data_valid    (app_rd_data_valid)   ,   //��������Ч                                   
    .app_addr             (app_addr)            ,   //ddr3 ��ַ                                   
    .app_en               (app_en)              ,   //MIG IP��ʹ��                                   
    .app_wdf_wren         (app_wdf_wren)        ,   //ddr3 дʹ��                                    
    .app_wdf_end          (app_wdf_end)         ,   //ͻ��д��ǰʱ�����һ������                                   
    .app_cmd              (app_cmd)             ,   //�û���д����                                                                                                                         
    //DDR3 ��ַ����                                                                   
    .app_addr_rd_min      (app_addr_rd_min)     ,   //��ddr3����ʼ��ַ                                  
    .app_addr_rd_max      (app_addr_rd_max)     ,   //��ddr3�Ľ�����ַ                                  
    .rd_bust_len          (rd_bust_len)         ,   //��ddr3�ж�����ʱ��ͻ������                                  
    .app_addr_wr_min      (app_addr_wr_min)     ,   //дddr3����ʼ��ַ                                  
    .app_addr_wr_max      (app_addr_wr_max)     ,   //дddr3�Ľ�����ַ                                  
    .wr_bust_len          (wr_bust_len)         ,   //��ddr3��д����ʱ��ͻ������                                  
    //�û��ӿ�                                                 
    .rfifo_wren           (rfifo_wren)          ,   //��ddr3�������ݵ���Чʹ�� 
    .ddr3_read_valid      (ddr3_read_valid)     ,   //DDR3 ��ʹ��
    .wfifo_rcount         (wfifo_rcount)        ,   //wfifoд�����ݼ���                 
    .rfifo_wcount         (rfifo_wcount)            //rfifoʣ�����ݼ���
    );
    
//MIG IP��ģ��
mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr           (ddr3_addr)            ,         
    .ddr3_ba             (ddr3_ba)              ,            
    .ddr3_cas_n          (ddr3_cas_n)           ,         
    .ddr3_ck_n           (ddr3_ck_n)            ,        
    .ddr3_ck_p           (ddr3_ck_p)            ,          
    .ddr3_cke            (ddr3_cke)             ,            
    .ddr3_ras_n          (ddr3_ras_n)           ,         
    .ddr3_reset_n        (ddr3_reset_n)         ,      
    .ddr3_we_n           (ddr3_we_n)            ,        
    .ddr3_dq             (ddr3_dq)              ,            
    .ddr3_dqs_n          (ddr3_dqs_n)           ,        
    .ddr3_dqs_p          (ddr3_dqs_p)           ,                                                       
	.ddr3_cs_n           (ddr3_cs_n)            ,                         
    .ddr3_dm             (ddr3_dm)              ,    
    .ddr3_odt            (ddr3_odt)             ,          
    // Application interface ports                                        
    .app_addr            (app_addr)             ,         
    .app_cmd             (app_cmd)              ,          
    .app_en              (app_en)               ,        
    .app_wdf_data        (app_wdf_data)         ,      
    .app_wdf_end         (app_wdf_end)          ,       
    .app_wdf_wren        (app_wdf_wren)         ,           
    .app_rd_data         (app_rd_data)          ,       
    .app_rd_data_end     (app_rd_data_end)      ,                                        
    .app_rd_data_valid   (app_rd_data_valid)    ,     
    .init_calib_complete (init_calib_complete)  ,                                                                
    .app_rdy             (app_rdy)              ,      
    .app_wdf_rdy         (app_wdf_rdy)          ,          
    .app_sr_req          (0)                    ,                    
    .app_ref_req         (0)                    ,              
    .app_zq_req          (0)                    ,             
    .app_sr_active       (app_sr_active)        ,        
    .app_ref_ack         (app_ref_ack)          ,         
    .app_zq_ack          (app_zq_ack)           ,             
    .ui_clk              (ui_clk)               ,                
    .ui_clk_sync_rst     (ui_clk_sync_rst)      ,                                               
    .app_wdf_mask        (16'b0)                ,    
    // System Clock Ports                            
    .sys_clk_i           (sys_clk_i)            ,    
    // Reference Clock Ports                         
    .clk_ref_i           (clk_ref_i )           ,    
    .sys_rst             (rst_n)                 
    );                                               
                                                     
ddr3_fifo_ctrl u_ddr3_fifo_ctrl (
    .rst_n               (rst_n)          ,  
    //����Դ�ӿ�
    .wr_clk              (wr_clk)         ,
    .rd_clk              (rd_clk)         ,
    .ui_clk              (ui_clk)         ,   
    .wr_en               (wr_en)          ,
    .wrdata              (wrdata      )   ,
    .rfifo_din           (app_rd_data   ) ,
    .rdata_req           (rd_req     )    ,
    .rfifo_wren          (rfifo_wren  )   ,
    .wfifo_rden          (app_wdf_wren  ) ,  
    .wfifo_dout          (app_wdf_data  ) ,
    .wfifo_rcount        (wfifo_rcount)   ,
    .rfifo_wcount        (rfifo_wcount)   ,
    .rddata              (rddata      ) 
    );

endmodule
