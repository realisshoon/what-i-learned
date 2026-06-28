`timescale 1 ns / 1 ps

// Standalone SPI master RTL used by spi_v1_0.
module spi_master (
    input wire clk,
    input wire reset,

    input wire       start,
    input wire [7:0] clk_div,

    input  wire [7:0] tx_data,
    output wire       tx_busy,
    output wire [7:0] rx_data,
    output wire       rx_done,

    output wire sclk,
    output wire mosi,
    input  wire miso,
    output wire cs_n
);

    localparam [1:0] IDLE = 2'b00;
    localparam [1:0] LOAD = 2'b01;
    localparam [1:0] DATA = 2'b10;
    localparam [1:0] STOP = 2'b11;

    reg [1:0] c_state;
    reg [1:0] n_state;

    reg [7:0] c_div_cnt;
    reg [7:0] n_div_cnt;

    reg [7:0] c_clk_div;
    reg [7:0] n_clk_div;

    reg c_sclk;
    reg n_sclk;

    reg c_mosi;
    reg n_mosi;

    reg c_cs_n;
    reg n_cs_n;

    reg c_tx_busy;
    reg n_tx_busy;

    reg c_rx_done;
    reg n_rx_done;

    reg [7:0] c_tx_shift_reg;
    reg [7:0] n_tx_shift_reg;

    reg [7:0] c_rx_shift_reg;
    reg [7:0] n_rx_shift_reg;

    reg [7:0] c_rx_data;
    reg [7:0] n_rx_data;

    reg [2:0] c_bit_cnt;
    reg [2:0] n_bit_cnt;

    reg half_tick;

    assign sclk    = c_sclk;
    assign mosi    = c_mosi;
    assign cs_n    = c_cs_n;
    assign tx_busy = c_tx_busy;
    assign rx_done = c_rx_done;
    assign rx_data = c_rx_data;

    always @(*) begin
        n_state        = c_state;

        n_div_cnt      = c_div_cnt;
        n_clk_div      = c_clk_div;

        n_sclk         = c_sclk;
        n_mosi         = c_mosi;
        n_cs_n         = c_cs_n;
        n_tx_busy      = c_tx_busy;
        n_rx_done      = 1'b0;

        n_tx_shift_reg = c_tx_shift_reg;
        n_rx_shift_reg = c_rx_shift_reg;
        n_rx_data      = c_rx_data;
        n_bit_cnt      = c_bit_cnt;

        half_tick      = 1'b0;

        // Generate one half SCLK period from the programmed divider.
        if (c_state == DATA) begin
            if (c_div_cnt >= c_clk_div) begin
                n_div_cnt = 8'd0;
                half_tick = 1'b1;
            end else begin
                n_div_cnt = c_div_cnt + 1'b1;
            end
        end else begin
            n_div_cnt = 8'd0;
        end

        case (c_state)
            IDLE: begin
                n_sclk    = 1'b0;   // Mode 0: CPOL=0
                n_mosi    = 1'b0;
                n_cs_n    = 1'b1;
                n_tx_busy = 1'b0;
                n_bit_cnt = 3'd0;

                if (start) begin
                    n_state = LOAD;
                end
            end

            LOAD: begin
                n_cs_n         = 1'b0;
                n_tx_busy      = 1'b1;
                n_clk_div      = clk_div;

                // First MOSI bit is preloaded for SPI mode 0.
                n_mosi         = tx_data[7];
                n_tx_shift_reg = {tx_data[6:0], 1'b0};

                n_rx_shift_reg = 8'd0;
                n_bit_cnt      = 3'd0;
                n_state        = DATA;
            end

            DATA: begin
                if (half_tick) begin
                    n_sclk = ~c_sclk;

                    if (c_sclk == 1'b0) begin
                        // Rising edge: sample MISO.
                        n_rx_shift_reg = {c_rx_shift_reg[6:0], miso};

                        if (c_bit_cnt == 3'd7) begin
                            n_rx_data = {c_rx_shift_reg[6:0], miso};
                            n_state   = STOP;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1'b1;
                        end
                    end else begin
                        // Falling edge: update MOSI.
                        n_mosi         = c_tx_shift_reg[7];
                        n_tx_shift_reg = {c_tx_shift_reg[6:0], 1'b0};
                    end
                end
            end

            STOP: begin
                n_sclk    = 1'b0;
                n_cs_n    = 1'b1;
                n_tx_busy = 1'b0;
                n_rx_done = 1'b1;
                n_mosi    = 1'b0;
                n_state   = IDLE;
            end

            default: begin
                n_state = IDLE;
            end
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            c_state        <= IDLE;

            c_div_cnt      <= 8'd0;
            c_clk_div      <= 8'd0;

            c_sclk         <= 1'b0;
            c_mosi         <= 1'b0;
            c_cs_n         <= 1'b1;
            c_tx_busy      <= 1'b0;
            c_rx_done      <= 1'b0;

            c_tx_shift_reg <= 8'd0;
            c_rx_shift_reg <= 8'd0;
            c_rx_data      <= 8'd0;
            c_bit_cnt      <= 3'd0;
        end else begin
            c_state        <= n_state;

            c_div_cnt      <= n_div_cnt;
            c_clk_div      <= n_clk_div;

            c_sclk         <= n_sclk;
            c_mosi         <= n_mosi;
            c_cs_n         <= n_cs_n;
            c_tx_busy      <= n_tx_busy;
            c_rx_done      <= n_rx_done;

            c_tx_shift_reg <= n_tx_shift_reg;
            c_rx_shift_reg <= n_rx_shift_reg;
            c_rx_data      <= n_rx_data;
            c_bit_cnt      <= n_bit_cnt;
        end
    end

endmodule
