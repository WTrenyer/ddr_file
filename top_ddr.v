`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/14 17:10:33
// Design Name: 
// Module Name: ddr_mid
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ddr_mid(
    input uart_rxd,
    
    inout   [15:0]      ddr3_dq          ,   //ddr3 数据
    inout   [1:0]       ddr3_dqs_n       ,   //ddr3 dqs负
    inout   [1:0]       ddr3_dqs_p       ,   //ddr3 dqs正  
    output  [13:0]      ddr3_addr        ,   //ddr3 地址   
    output  [2:0]       ddr3_ba          ,   //ddr3 banck 选择
    output              ddr3_ras_n       ,   //ddr3 行选择
    output              ddr3_cas_n       ,   //ddr3 列选择
    output              ddr3_we_n        ,   //ddr3 读写选择
    output              ddr3_reset_n     ,   //ddr3 复位
    output  [0:0]       ddr3_ck_p        ,   //ddr3 时钟正
    output  [0:0]       ddr3_ck_n        ,   //ddr3 时钟负
    output  [0:0]       ddr3_cke         ,   //ddr3 时钟使能
    output  [0:0]       ddr3_cs_n        ,   //ddr3 片选
    output  [1:0]       ddr3_dm          ,   //ddr3_dm
    output  [0:0]       ddr3_odt         ,   //ddr3_odt  

    // input               ddr3_read_valid  ,  //DDR3 读使能 


    input [3:0]         btn              ,
    input clk,rst
    );


wire                  app_rdy              ;   //MIG IP核空闲
wire                  app_wdf_rdy          ;   //MIG写数据空闲
wire                  app_rd_data_valid    ;   //读数据有效
wire [27:0]           app_addr             ;   //ddr3 地址
wire [2:0]            app_cmd              ;   //用户读写命令
wire                  app_en               ;   //MIG IP核使能
wire [127:0]          app_rd_data          ;   //用户读数据
wire                  app_rd_data_end      ;   //突发读当前时钟最后一个数据 
wire [127:0]          app_wdf_data         ;   //用户写数据 
wire                  app_wdf_end          ;   //突发写当前时钟最后一个数据 
wire [15:0]           app_wdf_mask         ;   //写数据屏蔽                           
wire                  app_sr_active        ;   //保留                                 
wire                  app_ref_ack          ;   //刷新请求                             
wire                  app_zq_ack           ;   //ZQ 校准请求                                                
wire                  ui_clk               ;   //用户时钟                   
wire                  ui_clk_sync_rst      ;   //用户复位信号    
wire [9:0]            wfifo_rcount         ;  //wfifo写进数据计数                    
wire [9:0]            rfifo_wcount         ;  //rfifo剩余数据计数


    wire clk_200m,clk_50m,aaa;
    reg mid_clk;
  clk_wiz_0 timer
   (
    // Clock out ports
    .clk_out1(clk_200m),     // output clk_out1
    .clk_out2(aaa),     // output clk_out2
    // Status and control signals
    .reset(0), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk));      // input clk_in1

    always @(posedge clk_50m) begin
        if(!rst)begin
            mid_clk <=0;
        end else
            mid_clk = ~mid_clk;
    end






    // assign clk_200m = mid_clk;


    // module uart_rx(
    //     input               clk         ,  //系统时钟
    //     input               rst_n       ,  //系统复位，低有效
    
    //     input               uart_rxd    ,  //UART接收端口
    //     output  reg         uart_rx_done,  //UART接收完成信号
    //     output  reg  [7:0]  uart_rx_data   //UART接收到的数据
    //     );
    


    wire [7:0]uart_rx_data;
    wire uart_rx_done ;
    uart_rx rx_uut(
        .clk(aaa),
        .rst_n(1),
        .uart_rxd(uart_rxd),
        .uart_rx_done(uart_rx_done),
        .uart_rx_data(uart_rx_data)
    );



    reg [2:0]app_cmd_reg;
    reg app_wdf_end_reg ,   app_wdf_wren_reg    ,app_en_reg ,       app_rd_data_end_reg;
    reg [27:0] addr_data_wr,addr_data_rd;
    integer cnt_data;
    reg[27:0] wr_data_count;
    wire app_wdf_wren;

    



    parameter idle_begin = 4'b0001,     wr_mode = 4'b0010  ,rd_mode = 4'b0011   , radom_rd_mode = 4'b0100;
    reg [3:0] statu_now , statu_next;
    reg [27:0] wr_data_on;


    // 读写模式app_en使能
    assign app_en = ((statu_now == wr_mode || statu_now == rd_mode) && init_calib_complete && app_rdy) ? 1 : 0;

    //cmd使能
    assign app_cmd = (init_calib_complete && app_rdy) ? (statu_now == rd_mode ? 3'b001:3'b000): 3'bzzz;  

    // 写部分
    assign app_wdf_end = app_wdf_wren;
    assign app_wdf_wren = (statu_now == wr_mode && (app_rdy && app_wdf_rdy)) ? 1'b1:1'b0;


    // 数据
    assign app_wdf_data = (statu_now == rd_mode) ? 127'bzzz : {100'hafafafafafaf5858585,addr_data_wr} ;
    assign app_addr = (statu_now == rd_mode) ? addr_data_rd : addr_data_wr;


    reg done_mid;
    wire done_flag;
    always @(posedge ui_clk) begin
        done_mid <= uart_rx_done;
    end
    assign done_flag = (!done_mid) && uart_rx_done;



    always @(posedge ui_clk or negedge rst) begin
        if(!rst )begin
            statu_next <=0;
            wr_data_on<=0;
            addr_data_wr<=0;
            addr_data_rd<=0;
            // statu_now  <=0;
        end else  if(statu_now == wr_mode)begin
            if(app_rdy && app_wdf_rdy)begin //写条件满足
                if (addr_data_wr <=1024) begin
                    addr_data_wr <= addr_data_wr + 4'd8; //一次性写进 8 个数，故加 8    
                    
                end else  if(addr_data_wr > 1024) begin
                    statu_next <= idle_begin;
                end

            end



        end else if (statu_now == rd_mode) begin
            if(app_rdy)begin
                if (addr_data_rd <=1024 ) begin

                    addr_data_rd <= addr_data_rd + 4'd8; //一次性写进 8 个数，故加 8    
                    
                end else if(addr_data_rd > 1024) begin
                    statu_next <= idle_begin;
                end
            end
        end else if (statu_now == radom_rd_mode) begin
            if(app_rdy)begin
                if (addr_data_rd <=1024 && app_rd_data_valid) begin

                    addr_data_rd <= addr_data_rd + addr_data_rd + 4'd8; //一次性写进 8 个数，故加 8    
                    
                end else if(addr_data_rd > 1024) begin
                    statu_next <= idle_begin;
                end
            end
        end else begin
            if(done_flag) begin
                if (uart_rx_data == 8'h01) begin
                    statu_next <= wr_mode;
                    addr_data_wr  <= 0;
                end else if (uart_rx_data == 8'h02)begin
                    addr_data_rd  <= 8'h20;
                    statu_next <= rd_mode;
                end else if (uart_rx_data == 8'h03)begin
                    addr_data_rd  <= 8'h0;
                    statu_next <= radom_rd_mode;
                end
            end
        end
    end





always @(posedge ui_clk or negedge rst) begin
    if(!rst)begin
        statu_now   <= idle_begin;
        // statu_next <= idle_begin;
    end else begin
        statu_now = statu_next;
    end
end








    // always @(posedge ui_clk or negedge rst) begin
    //     if(!rst)begin
    //         cnt_data <=0;// -------------------------------------------------------
            
    //         addr_data<=10;
    //         app_en_reg<=0;
    //         wr_data_count<=20;
    //         app_cmd_reg <=3'b000;
    //     end else if(init_calib_complete && app_rdy) begin


            
    //         if(uart_rx_data == 8'h01)begin//read mode
    //             // if(app_rd_data_valid)begin
    //                 app_en_reg<=1;
    //                 app_cmd_reg<=3'b1;
    //                 app_wdf_end_reg <=0;
    //                 app_wdf_wren_reg<=0;
    //                 wr_data_count<=wr_data_count+8;
    //                 if(wr_data_count >= 50)begin
    //                     wr_data_count <=0;

    //                 end 
    //         //    end
    //         end else if(uart_rx_data == 8'h02)
    //         begin//write mode
    //             if(app_wdf_rdy)begin
    //                 app_en_reg<=1;
    //                 app_cmd_reg<=3'b0;
    //                 app_wdf_end_reg <= 1;
    //                 app_wdf_wren_reg<=1;
    //                 wr_data_count<=wr_data_count+8;
    //                 if(wr_data_count >= 50)begin
    //                     wr_data_count <=0;
    //                 end

    //             end else begin
    //                 app_wdf_end_reg <=0;
    //                 app_wdf_wren_reg<=0;
    //             end
    //         end else if (uart_rx_data == 8'h03) begin
    //             if(app_wdf_rdy)begin
    //                 app_en_reg<=1;
    //                 app_cmd_reg<=3'b0;
    //                 app_wdf_end_reg <= 1;
    //                 app_wdf_wren_reg<=1;
    //                 wr_data_count<=wr_data_count+8;
    //                 if(wr_data_count >= 60)begin
    //                     wr_data_count <=0;
    //                 end

    //             end else begin
    //                 app_wdf_end_reg <=0;
    //                 app_wdf_wren_reg<=0;
    //             end
    //         end else if (uart_rx_data == 8'h04) begin
    //             if(app_rd_data_valid)begin
    //                     app_en_reg<=1;
    //                     app_cmd_reg<=3'b1;
    //                     app_wdf_end_reg <=0;
    //                     app_wdf_wren_reg<=0;
    //                     wr_data_count<=wr_data_count+8;
    //                     if(wr_data_count >= 50)begin
    //                         wr_data_count <=0;

    //                     end 
    //             end
    //         end else if (uart_rx_data == 8'h05) begin
    //             // if(app_rd_data_valid)begin
    //                     app_en_reg<=1;
    //                     app_cmd_reg<=3'b1;
    //                     app_wdf_end_reg <=0;
    //                     app_wdf_wren_reg<=0;
    //                     wr_data_count<=27'h30;

    //             end else if (uart_rx_data == 8'h06) begin
    //                 if(app_wdf_rdy)begin
    //                     app_en_reg<=1;
    //                     app_cmd_reg<=3'b0;
    //                     app_wdf_end_reg <= 1;
    //                     app_wdf_wren_reg<=1;
    //                     wr_data_count<=wr_data_count+8;
    //                     if(wr_data_count >= 6000)begin
    //                         wr_data_count <=28'bz;
    //                     end
    
    //                 end else begin
    //                     app_wdf_end_reg <=0;
    //                     app_wdf_wren_reg<=0;
    //                 end
    //             end if(uart_rx_data == 8'h07)begin//read mode
    //                 app_cmd_reg<=3'b1;
    //                 // if(app_rd_data_valid)begin
    //                     app_en_reg<=1;

    //                     app_wdf_end_reg <=0;
    //                     app_wdf_wren_reg<=0;
    //                     wr_data_count<=wr_data_count+8;
    //                     if(wr_data_count >= 5000)begin
    //                         wr_data_count <=0;
    
    //                     end 
    //             //    end
    //             end

    //     end else begin
    //         wr_data_count <=0;
    //         app_en_reg<=0;

    //         end


mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr),  // output [13:0]		ddr3_addr


    .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba


    .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n


    .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]		ddr3_ck_n


    .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p


    .ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke


    .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n


    .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n


    .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n


    .ddr3_dq                        (ddr3_dq),  // inout [15:0]		ddr3_dq


    .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [1:0]		ddr3_dqs_n


    .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [1:0]		ddr3_dqs_p


    .init_calib_complete            (init_calib_complete),  // output			init_calib_complete


      


	.ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]		ddr3_cs_n


    .ddr3_dm                        (ddr3_dm),  // output [1:0]		ddr3_dm


    .ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_odt


    // Application interface ports


    .app_addr                       (app_addr),  // input [27:0]		app_addr


    .app_cmd                        (app_cmd),  // input [2:0]		app_cmd


    .app_en                         (app_en),  // input				app_en

    // .app_wdf_data                   (app_wdf_data),  // input [127:0]		app_wdf_data
    .app_wdf_data                   (app_wdf_data),  // input [127:0]		app_wdf_data


    .app_wdf_end                    (app_wdf_end),  // input				app_wdf_end


    .app_wdf_wren                   (app_wdf_wren),  // input				app_wdf_wren


    .app_rd_data                    (app_rd_data),  // output [127:0]		app_rd_data


    .app_rd_data_end                (app_rd_data_end),  // output			app_rd_data_end


    .app_rd_data_valid              (app_rd_data_valid),  // output			app_rd_data_valid


    .app_rdy                        (app_rdy),  // output			app_rdy


    .app_wdf_rdy                    (app_wdf_rdy),  // output			app_wdf_rdy


    .app_sr_req                     (0),  // input			app_sr_req


    .app_ref_req                    (0),  // input			app_ref_req


    .app_zq_req                     (0),  // input			app_zq_req


    .app_sr_active                  (app_sr_active),  // output			app_sr_active


    .app_ref_ack                    (app_ref_ack),  // output			app_ref_ack


    .app_zq_ack                     (app_zq_ack),  // output			app_zq_ack


    .ui_clk                         (ui_clk),  // output			ui_clk


    .ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rst


    .app_wdf_mask                   (16'b0000_0000_0000_0000),  // input [15:0]		app_wdf_mask


    // System Clock Ports


    .sys_clk_i                       (clk_200m),


    // Reference Clock Ports


    .clk_ref_i                      (clk_200m),


    .sys_rst                        (rst) // input sys_rst


    );



    
ila_0 db_uut (
	.clk(ui_clk), // input wire clk


	.probe0(app_wdf_data), // input wire [127:0]  probe0  
	.probe1(app_rd_data), // input wire [127:0]  probe1 
	.probe2(app_cmd), // input wire [2:0]  probe2 
	.probe3(app_rd_data_valid), // input wire [0:0]  probe3 
	.probe4(app_wdf_wren), // input wire [0:0]  probe4 
	.probe5(app_wdf_rdy), // input wire [0:0]  probe5 
	.probe6(app_rd_data_end), // input wire [0:0]  probe6 
	.probe7(app_rdy), // input wire [0:0]  probe7 
	.probe8(app_en), // input wire [0:0]  probe8 
	.probe9(app_wdf_end), // input wire [0:0]  probe9
    .probe10(app_addr), // input wire [27:0]  probe10
    .probe11(uart_rx_data),
    .probe12(statu_next),
    .probe13(statu_now)
    // .probe14(clk_200m)
);

endmodule
