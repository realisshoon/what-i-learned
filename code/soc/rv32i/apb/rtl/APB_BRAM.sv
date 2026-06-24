`timescale 1ns / 1ps

module APB_BRAM(
    input logic PCLK,
    input logic PRESET,
    input logic [31:0] PADDR,
    input logic[ 31:0] PWDATA,
    input logic PSEL,
    input logic PENABLE,
    input logic PWRITE,
    output logic PREADY,
    output logic [31:0] PRDATA
);

    logic [31:0] bram[0:63];

    assign PREADY = (PENABLE&PSEL) ? 1'b1:1'b0;
    assign PRDATA = bram[PADDR[31:2]];

    always_ff @( posedge PCLK ) begin
        if(PREADY&PWRITE) begin
            bram[PADDR[31:2]] <= PWDATA;
        end
    end



endmodule
