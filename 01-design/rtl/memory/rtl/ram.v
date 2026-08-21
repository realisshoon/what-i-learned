`timescale 1ns / 1ps

module ram(
    input        clk,
    input [7:0]  addr,
    input [7:0]  wdata,
    input        we,
    output [7:0] rdata
    );

    reg [7:0] ram [0:255]; // 8bit 를 256개 저장할 수 있는 메모리 생성
    // reg [7:0] rdata_reg;
    // assign rdata = rdata_reg;

    always @(posedge clk) begin
        if (we) begin
            // write to ram
            ram[addr] <= wdata;
        end 
        // else begin
        //     // read from ram
        //     // SL output
        //     rdata_reg <= ram[addr];
        // end
    end


    assign rdata = ram[addr];



endmodule
