//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           top_ddr3_rw
// Last modified Date:  2023/7/5 09:04:34
// Last Version:        V1.0
// Descriptions:        ddr3��д���Զ���ģ��
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module top_ddr3_rw(
    input              sys_clk             ,   //ϵͳʱ�ӣ�50MHz
    input              sys_rst_n           ,   //��λ,����Ч        
    // DDR3 IO�ӿ� 
    inout   [15:0]     ddr3_dq             ,   //ddr3 ����
    inout   [1:0]      ddr3_dqs_n          ,   //ddr3 dqs��
    inout   [1:0]      ddr3_dqs_p          ,   //ddr3 dqs��  
    output  [13:0]     ddr3_addr           ,   //ddr3 ��ַ   
    output  [2:0]      ddr3_ba             ,   //ddr3 banck ѡ��
    output             ddr3_ras_n          ,   //ddr3 ��ѡ��
    output             ddr3_cas_n          ,   //ddr3 ��ѡ��
    output             ddr3_we_n           ,   //ddr3 ��дѡ��
    output             ddr3_reset_n        ,   //ddr3 ��λ
    output  [0:0]      ddr3_ck_p           ,   //ddr3 ʱ����
    output  [0:0]      ddr3_ck_n           ,   //ddr3 ʱ�Ӹ�
    output  [0:0]      ddr3_cke            ,   //ddr3 ʱ��ʹ��
    output  [0:0]      ddr3_cs_n           ,   //ddr3 Ƭѡ
    output  [1:0]      ddr3_dm             ,   //ddr3_dm
    output  [0:0]      ddr3_odt            ,   //ddr3_odt      
    //�û�
    output  [1:0]      led                     //led��
    );                
                      
//wire define  
wire                  clk_50m                    ;
wire                  clk_200m                  ;                                          
wire                  init_calib_complete  ;   //ddr3��ʼ������ź� 
wire                  error;   
wire [15:0]           rd_data              ;   //��ȡDDR3������
wire [15:0]           wr_data              ;   //д��DDR3������
wire [27:0]           app_addr_rd_min     ;
wire [27:0]           app_addr_rd_max     ;  
wire [7:0]            rd_bust_len         ;  
wire [27:0]           app_addr_wr_min     ;  
wire [27:0]           app_addr_wr_max     ;  
wire [7:0]            wr_bust_len         ;  
wire                  wr_en                        ;  
wire                  locked                        ;   
                                                                                                                                       
//*****************************************************                               
//**                    main code                                                     
//*****************************************************     
                          
assign app_addr_rd_min = 28'd0;
assign app_addr_rd_max = 28'd1024;
assign rd_bust_len     = 8'd64;
assign app_addr_wr_min = 28'd0;
assign app_addr_wr_max = 28'd1024;
assign wr_bust_len     = 8'd64; 

//��λ�ź�
assign rst_n =  locked && sys_rst_n; 
                                                                                  
//��дģ��                                                                            
 ddr3_controler u_ddr3_controler(                                                                               
    //MIG �ӿ�                                                                        
    .init_calib_complete  (init_calib_complete),   //ddr3��ʼ������ź�                                                                                                                                                            
    //DDR3 ��ַ����                                                                  
    .app_addr_rd_min      (app_addr_rd_min)    ,   //��ddr3����ʼ��ַ                                  
    .app_addr_rd_max      (app_addr_rd_max)    ,   //��ddr3�Ľ�����ַ                                  
    .rd_bust_len          (rd_bust_len)        ,   //��ddr3�ж�����ʱ��ͻ������                                  
    .app_addr_wr_min      (app_addr_wr_min)    ,   //дddr3����ʼ��ַ                                  
    .app_addr_wr_max      (app_addr_wr_max)    ,   //дddr3�Ľ�����ַ                                  
    .wr_bust_len          (wr_bust_len)        ,   //��ddr3��д����ʱ��ͻ������                                  
    // Memory interface port
    .ddr3_addr           (ddr3_addr)           ,         
    .ddr3_ba             (ddr3_ba)             ,            
    .ddr3_cas_n          (ddr3_cas_n)          ,         
    .ddr3_ck_n           (ddr3_ck_n)           ,        
    .ddr3_ck_p           (ddr3_ck_p)           ,          
    .ddr3_cke            (ddr3_cke)            ,            
    .ddr3_ras_n          (ddr3_ras_n)          ,         
    .ddr3_reset_n        (ddr3_reset_n)        ,      
    .ddr3_we_n           (ddr3_we_n)           ,        
    .ddr3_dq             (ddr3_dq)             ,            
    .ddr3_dqs_n          (ddr3_dqs_n)          ,        
    .ddr3_dqs_p          (ddr3_dqs_p)          ,                                                       
	.ddr3_cs_n           (ddr3_cs_n)           ,                         
    .ddr3_dm             (ddr3_dm)             ,    
    .ddr3_odt            (ddr3_odt)            ,
    // System Clock Ports                            
    .sys_clk_i           (clk_200m)            ,
    .rst_n               (rst_n)               ,   
    // Reference Clock Ports                         
    .clk_ref_i           (clk_200m )           ,       
    .ddr3_read_valid     (1'b1)                   ,   //DDR3 ��ʹ��
    //�û��ӿ�                                                                      
    .rd_req              (rd_req)              ,   //��fifo��ʹ��
    .wr_clk              (clk_50m)             ,
    .rd_clk              (clk_50m)             ,
    .wr_en               (wr_en)               ,
    .wrdata              (wr_data      )       ,
    .rddata              (rd_data      ) 
    );

test_data u_test_data(
    .clk_50m             (clk_50m      ),      
    .rst_n               (rst_n        ),
    .init_calib_complete (init_calib_complete) ,   //ddr3��ʼ������ź�                
    .rd_data             (rd_data      ),   
    .rd_req              (rd_req       ),  
    .wr_data             (wr_data      ),      
    .wr_en               (wr_en        ),                                                           
    .error               (error        )
);   

led_disp u_led_disp(
    .clk_50m (clk_50m),
    .rst_n (rst_n),
    //DDR3��ʼ��ʧ�ܻ��߶�д������Ϊ��ʵ��ʧ��
    .error_flag (error),
    .init_calib_complete (init_calib_complete) , 
    .led (led) 
);

clk_wiz_0 u_clk_wiz(
  // Clock out ports
  .clk_out1(clk_200m),// output clk_out1
  .clk_out2(clk_50m), // output clk_out2
  // Status and control signals
  .reset(~sys_rst_n),  // input reset
  .locked(locked),    // output locked
 // Clock in ports
  .clk_in1(sys_clk)   // input clk_in1
);      



ila_0 db_uut (
	.clk(clk_50m), // input wire clk


	.probe0(rd_data), // input wire [15:0]  probe0  
	.probe1(wr_data), // input wire [15:0]  probe1 
	.probe2(app_addr_rd_min), // input wire [27:0]  probe2 
	.probe3(app_addr_rd_max), // input wire [27:0]  probe3 
	.probe4(rd_bust_len), // input wire [7:0]  probe4 
	.probe5(clk_200m), // input wire [0:0]  probe5 
	.probe6(wr_en) // input wire [0:0]  probe6
);
endmodule