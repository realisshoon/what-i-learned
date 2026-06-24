module spi_master (
    input logic clk,
    input logic reset,

    input logic       start,
    input logic       cpol,
    input logic       cpha,
    input logic [7:0] clk_div,

    input  logic [7:0] tx_data,
    output logic       tx_busy,
    output logic [7:0] rx_data,
    output logic       rx_done,

    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic cs_n
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        LOAD,
        DATA,
        STOP
    } spi_state_e;

    // current registers
    spi_state_e c_state, n_state;

    logic [7:0] c_div_cnt, n_div_cnt;
    logic [7:0] c_clk_div, n_clk_div;

    logic c_sclk, n_sclk;
    logic c_mosi, n_mosi;
    logic c_cs_n, n_cs_n;
    logic c_tx_busy, n_tx_busy;
    logic c_rx_done, n_rx_done;

    logic [7:0] c_tx_shift_reg, n_tx_shift_reg;
    logic [7:0] c_rx_shift_reg, n_rx_shift_reg;
    logic [7:0] c_rx_data, n_rx_data;

    logic [2:0] c_bit_cnt, n_bit_cnt;

    logic half_tick;

    assign sclk    = c_sclk;
    assign mosi    = c_mosi;
    assign cs_n    = c_cs_n;
    assign tx_busy = c_tx_busy;
    assign rx_done = c_rx_done;
    assign rx_data = c_rx_data;

    always_comb begin
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

        // half tick generation
        if (c_state == DATA) begin
            if (c_div_cnt == c_clk_div) begin
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
                n_sclk    = 1'b0;   // Mode0 CPOL=0
                n_mosi    = 1'b0;   // idle value
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

                // first bit preload
                n_mosi         = tx_data[7];
                n_tx_shift_reg = {tx_data[6:0], 1'b0};

                n_rx_shift_reg = 8'd0;
                n_bit_cnt      = 3'd0;
                n_state        = DATA;
            end

            DATA: begin
                if (half_tick) begin
                    // SCLK toggle
                    n_sclk = ~c_sclk;

                    if (c_sclk == 1'b0) begin
                        // current sclk=0, next sclk=1
                        // rising edge: sample MISO
                        n_rx_shift_reg = {c_rx_shift_reg[6:0], miso};
                        if (c_bit_cnt == 3'd7) begin
                            n_rx_data = {c_rx_shift_reg[6:0], miso};
                            n_state   = STOP;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1'b1;
                        end
                    end else begin
                        // current sclk=1, next sclk=0
                        // falling edge: update next MOSI bit
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

    // =========================
    // Sequential register update
    // =========================
    always_ff @(posedge clk or posedge reset) begin
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
