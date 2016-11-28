`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2016 05:20:00 PM
// Design Name: 
// Module Name: FIFO
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


module fifo(
        input                       clk,
        input                       rst,
        input   [DATASIZE-1:0]      wdata,
        input                       winc,
        input                       rinc,
        
        output logic [DATASIZE-1:0] rdata, 
        output logic                wfull,
        output logic                rempty
    );
    parameter DATASIZE      = 8;
    parameter ADDR_WIDTH    = 8;
    parameter MEM_DEPTH     = (1 << ADDR_WIDTH);
    
    logic   [ADDR_WIDTH:0]    waddr;
    logic   [ADDR_WIDTH:0]    raddr;
    logic   [DATASIZE-1:0]    mem   [0:MEM_DEPTH-1];
    
    assign  rempty  = (waddr == raddr);
    assign  wfull   = ({~waddr[ADDR_WIDTH],waddr[ADDR_WIDTH-1:0]} == raddr);
    assign  rdata   = mem[raddr[ADDR_WIDTH-1:0]];
    
    always_ff @ (posedge clk) begin
        if (rst) begin
            waddr       <= 'b0;
            raddr       <= 'b0;
        end
        else begin
            if (winc && rinc) begin
                mem[waddr[ADDR_WIDTH-1:0]]  <= wdata;
                waddr                       <= waddr + 1'b1;
                raddr                       <= raddr + 1'b1;
            end
            else begin
                if (winc && ~wfull) begin
                    mem[waddr[ADDR_WIDTH-1:0]]  <= wdata;
                    waddr                       <= waddr + 1'b1;
                end
                if (rinc && ~rempty) begin
                    raddr       <= raddr + 1'b1; 
                end
            end
        end
    end
endmodule
