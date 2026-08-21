`timescale 1ns / 1ps


module i2c_transaction_top #(
    parameter logic [6:0] SLAVE_ADDR = 7'h12
) (
    input logic clk,
    input logic rst,

    // SPI처럼 보이게 만든 외부 인터페이스
    input logic       start,
    input logic [7:0] tx_data,

    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,

    // I2C 상태 표시용
    output logic ack_ok,

    // I2C external pins
    output logic scl,
    inout  wire  sda
);

    // ------------------------------------------------------------
    // i2c_cmd_controller <-> i2c_master_top 연결 신호
    // ------------------------------------------------------------
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] cmd_tx_data;
    logic       ack_in;

    logic [7:0] i2c_rx_data;
    logic       i2c_ack_out;
    logic       i2c_busy;
    logic       i2c_done;
    logic       i2c_ack_error;

    logic [7:0] rx_data_latched;
    logic       ctrl_busy;
    logic       ctrl_done;

    // ------------------------------------------------------------
    // I2C transaction sequencer
    // 버튼 start 한 번을 전체 I2C transaction으로 변환
    // ------------------------------------------------------------
    i2c_cmd_controller #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) u_i2c_cmd_controller (
        .clk(clk),
        .rst(rst),

        .start_pulse (start),
        .master_tx_sw(tx_data),

        .i2c_busy   (i2c_busy),
        .i2c_done   (i2c_done),
        .i2c_ack_out(i2c_ack_out),
        .i2c_rx_data(i2c_rx_data),

        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (cmd_tx_data),
        .ack_in   (ack_in),

        .rx_data_latched(rx_data_latched),
        .ctrl_busy      (ctrl_busy),
        .ctrl_done      (ctrl_done),
        .ack_ok         (ack_ok),
        .ack_error      (i2c_ack_error)
    );

    // ------------------------------------------------------------
    // 실제 I2C Master IP
    // ------------------------------------------------------------
    i2c_master_top u_i2c_master_top (
        .clk(clk),
        .rst(rst),

        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),

        .tx_data(cmd_tx_data),
        .rx_data(i2c_rx_data),

        .ack_in (ack_in),
        .ack_out(i2c_ack_out),

        .busy(i2c_busy),
        .done(i2c_done),

        .scl(scl),
        .sda(sda)
    );

    // ------------------------------------------------------------
    // Wrapper output
    // ------------------------------------------------------------
    assign rx_data = rx_data_latched;
    assign busy    = ctrl_busy;
    assign done    = ctrl_done;

endmodule



module i2c_cmd_controller #(
    parameter logic [6:0] SLAVE_ADDR = 7'h12
) (
    input logic clk,
    input logic rst,

    input logic       start_pulse,
    input logic [7:0] master_tx_sw,

    // i2c_master_top status
    input logic       i2c_busy,
    input logic       i2c_done,
    input logic       i2c_ack_out,  // ACK=0, NACK=1
    input logic [7:0] i2c_rx_data,

    // i2c_master_top command
    output logic       cmd_start,
    output logic       cmd_write,
    output logic       cmd_read,
    output logic       cmd_stop,
    output logic [7:0] tx_data,
    output logic       ack_in,

    // demo/status output
    output logic [7:0] rx_data_latched,
    output logic       ctrl_busy,
    output logic       ctrl_done,
    output logic       ack_ok,
    output logic       ack_error
);

    typedef enum logic [2:0] {
        IDLE,
        ISSUE,
        WAIT_DONE,
        CHECK,
        DONE
    } state_e;

    typedef enum logic [2:0] {
        SEQ_START_W = 3'd0,
        SEQ_ADDR_W  = 3'd1,
        SEQ_DATA_W  = 3'd2,
        SEQ_STOP_W  = 3'd3,
        SEQ_START_R = 3'd4,
        SEQ_ADDR_R  = 3'd5,
        SEQ_READ    = 3'd6,
        SEQ_STOP_R  = 3'd7
    } seq_e;

    state_e state, next_state;
    seq_e seq_idx, next_seq_idx;

    localparam logic [7:0] ADDR_W = {SLAVE_ADDR, 1'b0};  // 8'h24
    localparam logic [7:0] ADDR_R = {SLAVE_ADDR, 1'b1};  // 8'h25

    // ACK를 확인해야 하는 단계
    logic need_ack_check;
    assign need_ack_check =
        (seq_idx == SEQ_ADDR_W) ||
        (seq_idx == SEQ_DATA_W) ||
        (seq_idx == SEQ_ADDR_R);

    // ------------------------------------------------------------
    // Sequential
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= IDLE;
            seq_idx         <= SEQ_START_W;
            rx_data_latched <= 8'd0;
            ctrl_done       <= 1'b0;
            ack_ok          <= 1'b0;
            ack_error       <= 1'b0;
        end else begin
            state     <= next_state;
            seq_idx   <= next_seq_idx;
            ctrl_done <= 1'b0;

            // transaction 시작 시 상태 초기화
            if (state == IDLE && start_pulse) begin
                ack_ok    <= 1'b1;
                ack_error <= 1'b0;
            end

            // ACK check
            if (state == CHECK && need_ack_check) begin
                if (i2c_ack_out == 1'b1) begin
                    ack_ok    <= 1'b0;
                    ack_error <= 1'b1;
                end
            end

            // READ 완료 시 데이터 latch
            if (state == WAIT_DONE && seq_idx == SEQ_READ && i2c_done) begin
                rx_data_latched <= i2c_rx_data;
            end

            if (state == DONE) begin
                ctrl_done <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------
    // Next state
    // ------------------------------------------------------------
    always_comb begin
        next_state   = state;
        next_seq_idx = seq_idx;

        case (state)

            IDLE: begin
                next_seq_idx = SEQ_START_W;
                if (start_pulse) begin
                    next_state = ISSUE;
                end
            end

            ISSUE: begin
                next_state = WAIT_DONE;
            end

            WAIT_DONE: begin
                if (i2c_done) begin
                    next_state = CHECK;
                end
            end

            CHECK: begin
                if (seq_idx == SEQ_STOP_R) begin
                    next_state = DONE;
                end else begin
                    next_seq_idx = seq_e'(seq_idx + 3'd1);
                    next_state   = ISSUE;
                end
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state   = IDLE;
                next_seq_idx = SEQ_START_W;
            end

        endcase
    end

    // ------------------------------------------------------------
    // Command output
    // ISSUE 상태에서만 1clk pulse 발생
    // ------------------------------------------------------------
    always_comb begin
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read = 1'b0;
        cmd_stop = 1'b0;
        tx_data = 8'd0;

        // 1byte read 후 종료하므로 NACK=1
        ack_in = 1'b1;

        if (state == ISSUE) begin
            case (seq_idx)

                SEQ_START_W: begin
                    cmd_start = 1'b1;
                end

                SEQ_ADDR_W: begin
                    cmd_write = 1'b1;
                    tx_data   = ADDR_W;
                end

                SEQ_DATA_W: begin
                    cmd_write = 1'b1;
                    tx_data   = master_tx_sw;
                end

                SEQ_STOP_W: begin
                    cmd_stop = 1'b1;
                end

                SEQ_START_R: begin
                    cmd_start = 1'b1;
                end

                SEQ_ADDR_R: begin
                    cmd_write = 1'b1;
                    tx_data   = ADDR_R;
                end

                SEQ_READ: begin
                    cmd_read = 1'b1;
                    ack_in   = 1'b1;  // 마지막 1byte라 NACK
                end

                SEQ_STOP_R: begin
                    cmd_stop = 1'b1;
                end

                default: begin
                end

            endcase
        end
    end

    assign ctrl_busy = (state != IDLE) && (state != DONE);

endmodule
