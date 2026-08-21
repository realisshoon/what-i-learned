`timescale 1ns / 1ps

module uart_rx_led_top #(
    parameter int CLK_FREQ_HZ = 100_000_000,
    parameter int BAUD_RATE   = 115_200
) (
    input logic sys_clock,
    input logic reset,
    input logic rx,

    output logic [7:0] GPIOC,
    output logic [7:0] GPIOD
);

    localparam int CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;
    localparam int CNT_WIDTH = $clog2(CLKS_PER_BIT);

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t                 state;

    logic   [CNT_WIDTH-1:0] clk_cnt;
    logic   [          2:0] bit_idx;
    logic   [          7:0] rx_shift;
    logic   [          7:0] rx_data;
    logic                   rx_done;
    logic                   rx_meta;
    logic                   rx_sync;

    always_ff @(posedge sys_clock) begin
        if (reset) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    // UART RX FSM
    always_ff @(posedge sys_clock) begin
        if (reset) begin
            state    <= IDLE;
            clk_cnt  <= '0;
            bit_idx  <= 3'd0;
            rx_shift <= 8'd0;
            rx_data  <= 8'd0;
            rx_done  <= 1'b0;
        end else begin
            rx_done <= 1'b0;

            case (state)
                IDLE: begin
                    clk_cnt <= '0;
                    bit_idx <= 3'd0;

                    // UART idle은 1, start bit는 0
                    if (rx_sync == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    // start bit 중앙에서 다시 0인지 확인
                    if (clk_cnt == (CLKS_PER_BIT / 2) - 1) begin
                        clk_cnt <= '0;

                        if (rx_sync == 1'b0) begin
                            state <= DATA;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                DATA: begin
                    // 각 bit 중앙 타이밍에서 샘플링
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= '0;

                        // UART는 LSB first
                        rx_shift[bit_idx] <= rx_sync;

                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= '0;
                        rx_data <= rx_shift;
                        rx_done <= 1'b1;
                        state   <= IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // LED 표시부
    always_ff @(posedge sys_clock) begin
        if (reset) begin
            GPIOC <= 8'h00;
            GPIOD <= 8'h00;
        end else begin
            if (rx_done) begin
                // 받은 UART 데이터 표시
                GPIOC <= rx_data;

                // 수신 이벤트 표시: 받을 때마다 bit0 토글
                GPIOD[0] <= ~GPIOD[0];
                GPIOD[7:1] <= 7'b0000000;
            end
        end
    end

endmodule
