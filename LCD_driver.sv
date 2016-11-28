`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2016 12:12:55 PM
// Design Name: 
// Module Name: LCD_driver
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

module display_LCD(
    input                   clk,
    input                   reset,
    input                   stop_refresh,
    input [7:0]             LCD_display_in,
    
    output  logic           E,
    output  logic           RW,
    output  logic           RS,
    output  logic   [3:0]   DB,
    output  logic           rinc
    );
    
    parameter CLKS_PER_CYCLE    = 8192;                     //6000 * 5ns SYSCLK = 30us
    parameter STATE_LENGTH      = 27-$clog2(CLKS_PER_CYCLE);
    parameter DELAY_MAX         = 1; //2050us / CLKS_PER_CYCLE / 5ns  
    
    logic [5:0]                             code;
    logic                                   stop;
    logic                                   enable;
    logic                                   not_first;
    logic [$clog2(CLKS_PER_CYCLE)-1:0]      counter;
    logic                                   trigger, trigger_prev;
    logic [STATE_LENGTH-1:0]                state;
    logic [$clog2(DELAY_MAX)-1:0]           delay;
    
    assign enable   =   (counter[$clog2(CLKS_PER_CYCLE)-1] && !(|counter[$clog2(CLKS_PER_CYCLE)-2:0]));
    assign rinc     =   (enable) && (~state[0]) && not_first &&
                        (!(|state[STATE_LENGTH-1:7]) && state[5]);
                        
    assign {RS, RW, DB} = code;
    
    always_ff @ (posedge clk) begin
        if (reset) begin
            counter     <= 0;
        end
        else begin
            counter     <= counter + 1'b1;
        end
    end
    
    always_ff @ (posedge clk) begin
        if (reset) begin
            state       <= 0;
        end
        else if (&counter && ~stop) begin
            state       <= state + 1'b1;
        end
    end
    
    always_ff @ (posedge clk) begin
        if (reset) begin
            code        <= 0;
            stop        <= 0;
            not_first   <= 0;
            delay       <= 0; 
        end
        else if (enable) begin
            if ((&state) && stop_refresh)
                stop        <= ~stop;

            if ((&state) && ~not_first)
                not_first   <= 1;
            
            if (~stop) begin
                if (~not_first) begin
                    delay   <= 1;
                    if (!(|state[7:0])) begin
                        code    <= 6'b000011; // delay <= 20; //6'b000011; // // 8-bit bus mode function set 6'h03
                        delay   <= 0;
                    end
                    if (!(|state[6:0]) && state[7]) begin
                        code    <= 6'b000011;
                        delay   <= 0;
                    end
                    if (!(|state[5:0]) && (&state[7:6])) begin
                        code    <= 6'b000011;
                        delay   <= 0;
                    end
                    if (!(|state[4:0]) && (&state[7:5])) begin
                        code    <= 6'b000010; //6'b000010; // // 4-bit bus mode 6'h02
                        delay   <= 0;
                    end
                    if (!(|state[3:1]) && (&state[7:4])) begin
                        if (~state[0])
                            code    <= 6'b000010; //6'b000010; //
                        else
                            code    <= 6'b001100; //6'b001100; //
                        delay   <= 0;
                    end
                    if (!(|state[2:1]) && (&state[7:3])) begin
                        if (~state[0])
                            code    <= 6'b000000; //6'b000010; //
                        else
                            code    <= 6'b001100; //6'b001100; //
                        delay   <= 0;
                    end
                    if (~state[1] && (&state[7:2])) begin
                        if (~state[0])
                            code    <= 6'b000000; //6'b000010; //
                        else
                            code    <= 6'b000001; //6'b001100; //
                        delay   <= 0;
                    end
                    if (&state[7:1]) begin
                        if (~state[0])
                            code    <= 6'b000000; //6'b000010; //
                        else
                            code    <= 6'b000110; //6'b001100; //
                        delay   <= 0;
                    end
                end
                else begin
                    delay   <= 0;
                    if (!(|state[STATE_LENGTH-1:7]) && !state[6] && !state[5])
                        if (~state[0])
                            code    <= 6'b001000;
                        else
                            code    <= 6'b000000;
                    else if(!(|state[STATE_LENGTH-1:7]) && state[6] && !state[5])
                        if (~state[0])
                            code    <= 6'b001100;
                        else begin
                            code    <= 6'b000000;
                        end
                    else if(!(|state[STATE_LENGTH-1:7]) && state[5]) begin
                        if (~state[0])
                            code    <= {2'b10, LCD_display_in[7:4]};
                        else
                            code    <= {2'b10, LCD_display_in[3:0]};
                    end
                    else begin
                            code    <= 6'b110000;
                    end
                end
            end
        end
      end
      assign E = (stop || delay) ? 1 : counter[$clog2(CLKS_PER_CYCLE)-1]; // - E, at falling edge of E, LCD read RS, RW and DB
endmodule