`timescale 1ns / 1ps

module dedicated_cpu_counter (
    input        clk,
    input        rst,
    output [7:0] out
);
    wire asrc_sel, areg_load, out_sel, eq9;

    data_path u_data_path (.*);

    control_unit u_control_unit (.*);

endmodule



module data_path (
    input        clk,
    input        rst,
    input        asrc_sel,
    input        areg_load,
    input        out_sel,
    output       eq9,
    output [7:0] out
);
    logic [7:0] a_reg_out;
    logic [7:0] alu_out;
    logic [7:0] mux_out;


    mux2to1 u_mux (
        .a  (8'd0),
        .b  (alu_out),
        .sel(asrc_sel),
        .y  (mux_out)
    );


    a_reg u_areg (
        .clk (clk),
        .rst (rst),
        .load(areg_load),
        .d   (mux_out),
        .q   (a_reg_out)
    );

    alu u_alu(
        .a(a_reg_out),
        .b(8'd1),
        .alu_result(alu_out)
    );

    comp_eq9 u_comp_eq9(
        .in(a_reg_out),
        .compare(8'd9),
        .eq9(eq9)
    );


    assign out = out_sel ? a_reg_out : 8'bz;

endmodule



module mux2to1 (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic       sel,
    output logic [7:0] y
);
    // assign y = sel ? b : a;

    always_comb begin
        if (sel == 0) y = a;
        else y = b;
    end

endmodule

module a_reg (
    input  logic       clk,
    input  logic       rst,
    input  logic       load,
    input  logic [7:0] d,
    output logic [7:0] q
);

    logic [7:0] a_register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) a_register <= 8'd0;
        else if (load) a_register <= d;
    end

    assign q = a_register;
endmodule


module alu (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] alu_result
);
    assign alu_result = a + b;
endmodule

module comp_eq9(
    input  logic [7:0] in,
    input  logic [7:0] compare,
    output logic       eq9
);
    assign eq9 = (in == compare);
endmodule


module control_unit (
    input  logic clk,
    input  logic rst,
    input  logic eq9,
    output logic asrc_sel,
    output logic areg_load,
    output logic out_sel
);
    typedef enum logic [1:0] {
        S0 = 2'd0,
        S1 = 2'd1,
        S2 = 2'd2
    } state_t;
    state_t c_state, n_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) c_state <= S0;
        else c_state <= n_state;
    end

    always_comb begin
        n_state   = c_state;
        asrc_sel  = 1'b0;
        areg_load = 1'b0;
        out_sel   = 1'b0;

        case (c_state)
            S0: begin
                asrc_sel  = 1'b0;
                areg_load = 1'b1;
                out_sel   = 1'b0;
                n_state   = S1;
            end
            S1: begin
                if (eq9) begin
                    asrc_sel  = 0;
                    areg_load = 0;
                    out_sel   = 0;
                    n_state   = S2;
                end else begin
                    asrc_sel  = 1'b1;
                    areg_load = 1'b1;
                    out_sel   = 1'b0;
                    n_state   = S1;
                end
            end
            S2: begin
                asrc_sel  = 1'b0;
                areg_load = 1'b0;
                out_sel   = 1'b1;
                // next state 가 없는 이유? 
            end
        endcase
    end
endmodule
