`timescale 1ns / 1ps

module i2c_demo_count (
    input  logic clk,
    input  logic reset,
    input  logic sw,
    output logic scl,
    inout  logic sda
);

    typedef enum logic [3:0] {
        IDLE,
        CMD_START,
        WAIT_START,
        CMD_ADDR,
        WAIT_ADDR,
        CMD_WRITE,
        WAIT_WRITE,
        CMD_STOP,
        WAIT_STOP
    } i2c_state_e;

    localparam logic [6:0] SLA = 7'h12;
    localparam logic [7:0] SLA_W = {SLA, 1'b0};  // address + write bit

    i2c_state_e       state;

    logic             cmd_start;
    logic             cmd_write;
    logic             cmd_read;
    logic             cmd_stop;

    logic       [7:0] tx_data;
    logic       [7:0] rx_data;
    logic             ack_in;
    logic             ack_out;
    logic             busy;
    logic             done;

    logic       [1:0] sw_sync;
    logic             sw_prev;
    logic             sw_posedge;

    assign sw_posedge = sw_sync[1] & ~sw_prev;

    // switch synchronizer + rising edge detect
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sw_sync <= 2'b00;
            sw_prev <= 1'b0;
        end else begin
            sw_sync[0] <= sw;
            sw_sync[1] <= sw_sync[0];
            sw_prev    <= sw_sync[1];
        end
    end

    I2C_Master_top U_I2C_Master (
        .clk  (clk),
        .reset(reset),

        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),

        .tx_data(tx_data),
        .rx_data(rx_data),
        .ack_in (ack_in),
        .ack_out(ack_out),

        .busy(busy),
        .done(done),

        .scl(scl),
        .sda(sda)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;

            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;

            tx_data   <= 8'd0;
            ack_in    <= 1'b1;  // read 시 master가 보낼 NACK 기본값
        end else begin
            // command 신호는 기본 0
            // 필요한 상태에서만 1클럭 pulse 발생
            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;

            case (state)

                IDLE: begin
                    if (sw_posedge) begin
                        state <= CMD_START;
                    end
                end

                // START command 1clk pulse
                CMD_START: begin
                    cmd_start <= 1'b1;
                    state     <= WAIT_START;
                end

                // START 완료 대기
                WAIT_START: begin
                    if (done) begin
                        state <= CMD_ADDR;
                    end
                end

                // SLA + Write byte 전송
                CMD_ADDR: begin
                    tx_data   <= SLA_W;
                    cmd_write <= 1'b1;
                    state     <= WAIT_ADDR;
                end

                WAIT_ADDR: begin
                    if (done) begin
                        // ack_out == 0이면 slave ACK
                        // 지금은 NACK이어도 다음으로 진행
                        state <= CMD_WRITE;
                    end
                end

                // Data byte 전송
                CMD_WRITE: begin
                    tx_data   <= 8'h55;
                    cmd_write <= 1'b1;
                    state     <= WAIT_WRITE;
                end

                WAIT_WRITE: begin
                    if (done) begin
                        state <= CMD_STOP;
                    end
                end

                // STOP command 1clk pulse
                CMD_STOP: begin
                    cmd_stop <= 1'b1;
                    state    <= WAIT_STOP;
                end

                WAIT_STOP: begin
                    if (done) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
