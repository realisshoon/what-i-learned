`timescale 1ns / 1ps

module dedicated_cpu_counter (
    input        clk,
    input        rst,
    output [7:0] out
);
    wire asrc_sel, areg_load, sumsrc_sel, sumreg_load, outreg_load, alusrc_sel, ag10;

    data_path u_data_path (
        .clk(clk),
        .rst(rst),
        .asrc_sel(asrc_sel),
        .sumsrc_sel(sumsrc_sel),
        .areg_load(areg_load),
        .sumreg_load(sumreg_load),
        .outreg_load(outreg_load),
        .alusrc_sel(alusrc_sel),
        .ag10(ag10),
        .out(out)
    );

    control_unit u_control_unit (
        .clk(clk),
        .rst(rst),
        .ag10(ag10),
        .asrc_sel(asrc_sel),
        .sumsrc_sel(sumsrc_sel),
        .areg_load(areg_load),
        .sumreg_load(sumreg_load),
        .outreg_load(outreg_load),
        .alusrc_sel(alusrc_sel)
    );

endmodule



module data_path (
    input        clk,
    input        rst,
    input        asrc_sel,
    input        sumsrc_sel,
    input        areg_load,
    input        sumreg_load,
    input        outreg_load,
    input        alusrc_sel,
    output       ag10,
    output [7:0] out
);

    logic [7:0] sumreg_mux_out, areg_mux_out, alusrc_mux_out;
    logic [7:0] areg_out, sumreg_out, alu_result;




    mux2to1 ASRC_MUX (
        .a  (8'd0),
        .b  (alu_result),
        .sel(asrc_sel),
        .y  (areg_mux_out)
    );

    mux2to1 SUMSRC_MUX (
        .a  (8'd0),
        .b  (alu_result),
        .sel(sumsrc_sel),
        .y  (sumreg_mux_out)
    );

    register U_A_REG (
        .clk (clk),
        .rst (rst),
        .load(areg_load),
        .d   (areg_mux_out),
        .q   (areg_out)
    );

    register U_SUM_REG (
        .clk (clk),
        .rst (rst),
        .load(sumreg_load),
        .d   (sumreg_mux_out),
        .q   (sumreg_out)
    );


    mux2to1 ALUSRC_MUX (
        .a  (8'h01),
        .b  (sumreg_out),
        .sel(alusrc_sel),
        .y  (alusrc_mux_out)
    );


    alu U_ALU(
        .a(areg_out),
        .b(alusrc_mux_out),
        .alu_result(alu_result)
    );

    comparator U_COMP_AG10(
        .in(a_reg_out),
        .compare(8'd10),
        .comp_out(ag10)
    );


    register U_OUT_REG (
    .clk (clk),
    .rst (rst),
    .load(outreg_load),
    .d   (sumreg_out),
    .q   (out)
    );

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

module register (
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

module comparator(
    input  logic [7:0] in,
    input  logic [7:0] compare,
    output logic       comp_out
);
    assign comp_out = (in > compare);
endmodule


module control_unit (
    input  logic clk,
    input  logic rst,
    input  logic ag10,
    output logic asrc_sel,
    output logic sumsrc_sel,
    output logic areg_load,
    output logic sumreg_load,
    output logic outreg_load,
    output logic alusrc_sel
);
    typedef enum {
        S0 = 0,
        S1,
        S2,
        S3,
        S4,
        S5
    } state_t;
    state_t c_state, n_state;

    // State register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) c_state <= S0;
        else c_state <= n_state;
    end

    always_comb begin
            n_state   = c_state;
            asrc_sel=   0;
            sumsrc_sel= 0;
            areg_load=  0;
            sumreg_load=0;
            outreg_load=0;
            alusrc_sel= 0;

        case (c_state)
            S0: begin
                    asrc_sel=   0;
                    sumsrc_sel= 0;
                    areg_load=  1;
                    sumreg_load=1;
                    outreg_load=0;
                    alusrc_sel= 0;
                    n_state   = S1;
            end
            S1: begin
                    asrc_sel=   0;
                    sumsrc_sel= 0;
                    areg_load=  0;
                    sumreg_load=0;
                    outreg_load=0;
                    alusrc_sel= 0;
                if (!ag10) begin
                    n_state   = S2;
                end else begin
                    n_state   = S5;
                end
            end
            S2: begin
                    asrc_sel=   0;
                    sumsrc_sel= 0;
                    areg_load=  0;
                    sumreg_load=0;
                    outreg_load=1;
                    alusrc_sel= 0;
                    n_state = S3;
            end
            S3: begin
                    //
                    asrc_sel=   1;
                    sumsrc_sel= 0;
                    areg_load=  1;
                    sumreg_load=0;
                    outreg_load=0;
                    alusrc_sel= 0;
                    n_state = S4;
            end
            S4: begin
                    //sum+=a
                    asrc_sel=   0;
                    sumsrc_sel= 1;
                    areg_load=  0;
                    sumreg_load=1;
                    outreg_load=0;
                    alusrc_sel= 1;
                    n_state = S5;
            end
            S5 : begin
                    // halt
                    asrc_sel=   0;
                    sumsrc_sel= 0;
                    areg_load=  0;
                    sumreg_load=0;
                    outreg_load=1;
                    alusrc_sel= 0;
            end
        endcase
    end
endmodule
