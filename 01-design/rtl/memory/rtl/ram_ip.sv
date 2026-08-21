`timescale 1ns / 1ps

module ram_ip(
    input       clk,
    input [7:0] addr,
    input [7:0] wdata,
    input       we,
    output [7:0] rdata
    );

    logic [7:0] ram [0:255];


    always_ff @(posedge clk) begin
        if (we) begin
            ram[addr] <= wdata;
        end
    end

    assign rdata = ram[addr];

endmodule
