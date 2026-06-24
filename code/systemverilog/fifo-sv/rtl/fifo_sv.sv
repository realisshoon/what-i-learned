`timescale 1ns / 1ps

module fifo_sv(
    input clk,
    input rst,
    input [7:0] push_data,
    input push,
    input pop,
    output [7:0] pop_data,
    output full,
    output empty
    );

    logic [3:0] wptr;
    logic [3:0] rptr;
    logic       we;


    reg_file U_REGFILE (
        .*,
        .wdata(push_data),
        .waddr(wptr),
        .raddr(rptr),
        .we(push & ~full),
        .rdata(pop_data)
    );

    control_unit U_CNTL_UNIT (
        .*,
        .wptr(wptr),
        .rptr(rptr)
    );

endmodule

module reg_file (
    input clk,
    input [7:0] wdata,
    input [3:0] waddr,
    input [3:0] raddr,
    input       we,
    output[7:0] rdata
    );

    logic [7:0] reg_file [0:15];

    always_ff @(posedge clk) begin
        if(we) begin
            reg_file[waddr] <= wdata;
        end
    end

    assign rdata = reg_file[raddr];

endmodule

module control_unit(
    input         clk,
    input         rst,
    input         push,
    input         pop,
    output [3:0]  wptr,
    output [3:0]  rptr,
    output        full,
    output        empty
    );

    logic [3:0] n_wptr, c_wptr;
    logic [3:0] n_rptr, c_rptr;
    logic       n_empty, c_empty;
    logic       n_full,  c_full;

    assign wptr = c_wptr;
    assign rptr = c_rptr;
    assign full = c_full;
    assign empty = c_empty;

    always_ff@(posedge clk or posedge rst) begin
        if (rst) begin
            c_wptr <= 0;
            c_rptr <= 0;
            c_full <= 0;
            c_empty <= 1;
        end else begin
            c_wptr <= n_wptr;
            c_rptr <= n_rptr;
            c_full <= n_full;
            c_empty <= n_empty;
        end
    end

    always_comb begin
        n_wptr  = c_wptr;
        n_rptr  = c_rptr;
        n_full  = c_full;
        n_empty = c_empty;

        case ({push, pop})
            2'b10: begin // 2. push only
                if(!c_full) begin
                    n_wptr = c_wptr + 1; // ++;
                    n_empty = 1'b0;
                    if (n_wptr == c_rptr) n_full = 1'b1;
                end
            end
            2'b01: begin // 3. pop only
                if(!c_empty) begin
                    n_rptr = c_rptr + 1;
                    n_full = 1'b0;
                    if (n_rptr == c_wptr) n_empty = 1'b1;
                end
            end
            2'b11: begin // 4. push / pop 동시에 발생
                if (c_full) begin
                    n_rptr = c_rptr + 1;
                    n_full = 0;
                end else if (c_empty) begin
                    n_wptr = c_wptr + 1;
                    n_empty = 1'b0;
                end else begin
                    n_wptr = c_wptr + 1;
                    n_rptr = c_rptr + 1;
                end
            end
            2'b00: begin // 1. init
            end
        endcase
    end

endmodule
