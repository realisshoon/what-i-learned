`timescale 1ns / 1ps

module i2c_master (
    input logic clk,
    input logic rst,

    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    input  logic       ack_in,
    output logic       ack_out,
    output logic       busy,
    output logic       done,

    output logic scl,
    output logic sda_o,
    input  logic sda_i
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    localparam int CLK_FREQ_HZ = 100_000_000;
    localparam int I2C_FREQ_HZ = 100_000;
    localparam int QTR_DIV = CLK_FREQ_HZ / (I2C_FREQ_HZ * 4);
    localparam int DIV_WIDTH = $clog2(QTR_DIV);

    // current / next state registers
    i2c_state_e c_state, n_state;

    logic [DIV_WIDTH-1:0] c_div_cnt, n_div_cnt;
    logic c_qtr_tick, n_qtr_tick;

    logic c_scl, n_scl;
    logic c_sda_o, n_sda_o;

    logic [1:0] c_step, n_step;

    logic [7:0] c_tx_shift_reg, n_tx_shift_reg;
    logic [7:0] c_rx_shift_reg, n_rx_shift_reg;
    logic [7:0] c_rx_data, n_rx_data;

    logic [2:0] c_bit_cnt, n_bit_cnt;

    logic c_is_read, n_is_read;
    logic c_ack_in_r, n_ack_in_r;
    logic c_ack_out, n_ack_out;
    logic c_done, n_done;

    assign scl     = c_scl;
    assign sda_o   = c_sda_o;
    assign rx_data = c_rx_data;
    assign ack_out = c_ack_out;
    assign done    = c_done;
    assign busy    = (c_state != IDLE);

    // next logic
    always_comb begin
        // 기본 유지
        n_state        = c_state;
        n_div_cnt      = c_div_cnt;
        n_qtr_tick     = 1'b0;

        n_scl          = c_scl;
        n_sda_o        = c_sda_o;
        n_step         = c_step;

        n_tx_shift_reg = c_tx_shift_reg;
        n_rx_shift_reg = c_rx_shift_reg;
        n_rx_data      = c_rx_data;

        n_bit_cnt      = c_bit_cnt;

        n_is_read      = c_is_read;
        n_ack_in_r     = c_ack_in_r;
        n_ack_out      = c_ack_out;

        // done은 1클럭 pulse
        n_done         = 1'b0;

        // quarter tick generator
        if (c_div_cnt == QTR_DIV - 1) begin
            n_div_cnt  = '0;
            n_qtr_tick = 1'b1;
        end else begin
            n_div_cnt = c_div_cnt + 1'b1;
        end

        case (c_state)

            IDLE: begin
                n_scl   = 1'b1;
                n_sda_o = 1'b1;  // release
                n_step  = 2'd0;

                if (cmd_start) begin
                    n_state = START;
                    n_step  = 2'd0;
                end
            end

            START: begin
                if (c_qtr_tick) begin
                    case (c_step)
                        2'd0: begin
                            n_scl   = 1'b1;
                            n_sda_o = 1'b1;  // release
                            n_step  = 2'd1;
                        end

                        2'd1: begin
                            // START condition: SCL high에서 SDA 1 -> 0
                            n_scl   = 1'b1;
                            n_sda_o = 1'b0;  // drive low
                            n_step  = 2'd2;
                        end

                        2'd2: begin
                            n_scl   = 1'b0;
                            n_sda_o = 1'b0;
                            n_step  = 2'd3;
                        end

                        2'd3: begin
                            n_step  = 2'd0;
                            n_done  = 1'b1;
                            n_state = WAIT_CMD;
                        end
                    endcase
                end
            end

            WAIT_CMD: begin
                if (cmd_write) begin
                    n_tx_shift_reg = tx_data;
                    n_bit_cnt      = 3'd0;
                    n_is_read      = 1'b0;
                    n_step         = 2'd0;
                    n_state        = DATA;
                end else if (cmd_read) begin
                    n_rx_shift_reg = 8'd0;
                    n_bit_cnt      = 3'd0;
                    n_is_read      = 1'b1;
                    n_ack_in_r     = ack_in;
                    n_step         = 2'd0;
                    n_state        = DATA;
                end else if (cmd_stop) begin
                    n_step  = 2'd0;
                    n_state = STOP;
                end else if (cmd_start) begin
                    n_step  = 2'd0;
                    n_state = START;
                end
            end

            DATA: begin
                if (c_qtr_tick) begin
                    case (c_step)
                        2'd0: begin
                            // SCL low에서 data setup
                            n_scl = 1'b0;

                            if (c_is_read) begin
                                n_sda_o = 1'b1;  // release
                            end else begin
                                n_sda_o = c_tx_shift_reg[7];
                            end

                            n_step = 2'd1;
                        end

                        2'd1: begin
                            n_scl  = 1'b1;
                            n_step = 2'd2;
                        end

                        2'd2: begin
                            // SCL high에서 sample
                            n_scl = 1'b1;

                            if (c_is_read) begin
                                n_rx_shift_reg = {c_rx_shift_reg[6:0], sda_i};
                            end

                            n_step = 2'd3;
                        end

                        2'd3: begin
                            n_scl = 1'b0;

                            if (!c_is_read) begin
                                n_tx_shift_reg = {c_tx_shift_reg[6:0], 1'b0};
                            end

                            if (c_bit_cnt == 3'd7) begin
                                n_bit_cnt = 3'd0;
                                n_step    = 2'd0;
                                n_state   = DATA_ACK;
                            end else begin
                                n_bit_cnt = c_bit_cnt + 1'b1;
                                n_step    = 2'd0;
                            end
                        end
                    endcase
                end
            end

            DATA_ACK: begin
                if (c_qtr_tick) begin
                    case (c_step)
                        2'd0: begin
                            n_scl = 1'b0;

                            if (c_is_read) begin
                                n_sda_o = c_ack_in_r;  // ACK=0, NACK=1
                            end else begin
                                n_sda_o = 1'b1;  // release for slave ACK
                            end

                            n_step = 2'd1;
                        end

                        2'd1: begin
                            n_scl  = 1'b1;
                            n_step = 2'd2;
                        end

                        2'd2: begin
                            n_scl = 1'b1;

                            if (!c_is_read) begin
                                n_ack_out = sda_i;  // ACK=0, NACK=1
                            end else begin
                                n_rx_data = c_rx_shift_reg;
                            end

                            n_step = 2'd3;
                        end

                        2'd3: begin
                            n_scl   = 1'b0;
                            n_sda_o = 1'b1;
                            n_step  = 2'd0;
                            n_done  = 1'b1;
                            n_state = WAIT_CMD;
                        end
                    endcase
                end
            end

            STOP: begin
                if (c_qtr_tick) begin
                    case (c_step)
                        2'd0: begin
                            n_scl   = 1'b0;
                            n_sda_o = 1'b0;
                            n_step  = 2'd1;
                        end

                        2'd1: begin
                            n_scl   = 1'b1;
                            n_sda_o = 1'b0;
                            n_step  = 2'd2;
                        end

                        2'd2: begin
                            // STOP condition: SCL high에서 SDA 0 -> 1
                            n_scl   = 1'b1;
                            n_sda_o = 1'b1;
                            n_step  = 2'd3;
                        end

                        2'd3: begin
                            n_step  = 2'd0;
                            n_done  = 1'b1;
                            n_state = IDLE;
                        end
                    endcase
                end
            end

            default: begin
                n_state = IDLE;
            end

        endcase
    end

    // register update
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state        <= IDLE;

            c_div_cnt      <= '0;
            c_qtr_tick     <= 1'b0;

            c_scl          <= 1'b1;
            c_sda_o        <= 1'b1;

            c_step         <= 2'd0;

            c_tx_shift_reg <= 8'd0;
            c_rx_shift_reg <= 8'd0;
            c_rx_data      <= 8'd0;

            c_bit_cnt      <= 3'd0;

            c_is_read      <= 1'b0;
            c_ack_in_r     <= 1'b1;
            c_ack_out      <= 1'b1;
            c_done         <= 1'b0;
        end else begin
            c_state        <= n_state;

            c_div_cnt      <= n_div_cnt;
            c_qtr_tick     <= n_qtr_tick;

            c_scl          <= n_scl;
            c_sda_o        <= n_sda_o;

            c_step         <= n_step;

            c_tx_shift_reg <= n_tx_shift_reg;
            c_rx_shift_reg <= n_rx_shift_reg;
            c_rx_data      <= n_rx_data;

            c_bit_cnt      <= n_bit_cnt;

            c_is_read      <= n_is_read;
            c_ack_in_r     <= n_ack_in_r;
            c_ack_out      <= n_ack_out;
            c_done         <= n_done;
        end
    end

endmodule
