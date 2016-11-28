`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2016 01:06:35 PM
// Design Name: 
// Module Name: top
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


module top(
        input                   SYSCLK_P,
        input                   SYSCLK_N,
        input                   GPIO_SW_C,
        input                   GPIO_SW_N,
        
        output  logic           LCD_E_LS,
        output  logic           LCD_RW_LS,
        output  logic           LCD_RS_LS,
        output  logic           LCD_DB4_LS,
        output  logic           LCD_DB5_LS,
        output  logic           LCD_DB6_LS,
        output  logic           LCD_DB7_LS
    );
    
    logic        clk;
    logic        reset;
    logic [7:0]  word;
    logic [3:0]  LCD_DB_LS;
    logic [7:0]  wdata;
    logic [7:0]  rdata;
    logic        wfull;
    logic        rempty;
    logic [25:0] global_counter;
    logic        rinc;
    
    
    IBUFDS sysclkbuf ( .I(SYSCLK_P), .IB(SYSCLK_N), .O(clk));
    
    assign reset    = GPIO_SW_C;
    assign {LCD_DB7_LS,LCD_DB6_LS,LCD_DB5_LS,LCD_DB4_LS} = LCD_DB_LS;
              
    always_ff @ (posedge clk) begin
        if(reset) begin
            word    <= 0;
        end
        else if(~wfull && rinc) begin
            word    <= word + 1;
        end
    end
    
    assign wdata = word;
    
    fifo#(.DATASIZE(8), 
          .ADDR_WIDTH(6))
    lcd_fifo(
            .clk(clk),
            .rst(GPIO_SW_C),
            .wdata(wdata),
            .winc(~wfull && rinc),
            .rinc(rinc),
        
            .rdata(rdata), 
            .wfull(wfull),
            .rempty(rempty)
    );
    
    display_LCD display(
        .clk(clk),
        .reset(GPIO_SW_C),
        .stop_refresh(GPIO_SW_N),
        .LCD_display_in(rdata),
        
        .E(LCD_E_LS),
        .RW(LCD_RW_LS),
        .RS(LCD_RS_LS),
        .DB(LCD_DB_LS),
        .rinc(rinc)
    );
endmodule
