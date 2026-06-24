`timescale 1ns / 1ps

module i2c_slave_top #(
    parameter logic [6:0] SLAVE_ADDR = 7'h12
) (
    input logic clk,
    input logic rst,

    input logic scl,
    inout wire  sda,

    input logic [7:0] tx_data,  // read 시 master에게 보낼 데이터

    output logic [7:0] rx_data,  // write 시 master에게 받은 데이터
    output logic       rx_done,
    output logic       tx_done,

    output logic addr_match,
    output logic rw_mode,     // 0: write, 1: read
    output logic master_ack,  // read 후 master ACK/NACK, ACK=0, NACK=1
    output logic busy
);

    logic sda_i;
    logic sda_drive_low;

    assign sda_i = sda;

    // I2C open-drain
    // sda_drive_low = 1 : SDA를 Low로 당김
    // sda_drive_low = 0 : SDA release
    assign sda   = sda_drive_low ? 1'b0 : 1'bz;

    i2c_slave_simple #(
        .SLAVE_ADDR(SLAVE_ADDR)
    ) u_i2c_slave_simple (
        .clk(clk),
        .rst(rst),

        .scl          (scl),
        .sda_i        (sda_i),
        .sda_drive_low(sda_drive_low),

        .tx_data(tx_data),

        .rx_data(rx_data),
        .rx_done(rx_done),
        .tx_done(tx_done),

        .addr_match(addr_match),
        .rw_mode   (rw_mode),
        .master_ack(master_ack),
        .busy      (busy)
    );

endmodule


module i2c_slave_simple #(
    parameter logic [6:0] SLAVE_ADDR = 7'h12
) (
    input logic clk,
    input logic rst,

    input  logic scl,
    input  logic sda_i,
    output logic sda_drive_low,

    input logic [7:0] tx_data,

    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       tx_done,

    output logic addr_match,
    output logic rw_mode,
    output logic master_ack,
    output logic busy
);

    typedef enum logic [3:0] {
        IDLE,

        ADDR,
        ADDR_ACK_WAIT_FALL,
        ADDR_ACK_HOLD,

        WRITE_DATA,
        WRITE_DATA_ACK_WAIT_FALL,
        WRITE_DATA_ACK_HOLD,

        READ_DATA,
        READ_MASTER_ACK
    } i2c_slave_state_e;

    i2c_slave_state_e c_state, n_state;

    // 외부 SCL/SDA 동기화
    logic [2:0] c_scl_sync, n_scl_sync;
    logic [2:0] c_sda_sync, n_sda_sync;

    logic scl_rise;
    logic scl_fall;
    logic start_cond;
    logic stop_cond;
    logic sda_sample;

    // shift / count
    logic [7:0] c_shift_reg, n_shift_reg;
    logic [7:0] c_tx_shift_reg, n_tx_shift_reg;
    logic [2:0] c_bit_cnt, n_bit_cnt;

    // outputs
    logic [7:0] c_rx_data, n_rx_data;
    logic c_rx_done, n_rx_done;
    logic c_tx_done, n_tx_done;

    logic c_addr_match, n_addr_match;
    logic c_addr_ok, n_addr_ok;
    logic c_rw_mode, n_rw_mode;
    logic c_master_ack, n_master_ack;
    logic c_busy, n_busy;

    logic c_sda_drive_low, n_sda_drive_low;

    logic [7:0] sample_byte;

    assign scl_rise      = (c_scl_sync[2:1] == 2'b01);
    assign scl_fall      = (c_scl_sync[2:1] == 2'b10);

    // START: SCL High에서 SDA 1 -> 0
    // STOP : SCL High에서 SDA 0 -> 1
    assign start_cond    = (c_sda_sync[2:1] == 2'b10) && (c_scl_sync[1] == 1'b1);
    assign stop_cond     = (c_sda_sync[2:1] == 2'b01) && (c_scl_sync[1] == 1'b1);

    assign sda_sample    = c_sda_sync[1];
    assign sample_byte   = {c_shift_reg[6:0], sda_sample};

    assign rx_data       = c_rx_data;
    assign rx_done       = c_rx_done;
    assign tx_done       = c_tx_done;

    assign addr_match    = c_addr_match;
    assign rw_mode       = c_rw_mode;
    assign master_ack    = c_master_ack;
    assign busy          = c_busy;

    assign sda_drive_low = c_sda_drive_low;

    always_comb begin
        n_state         = c_state;

        // synchronizer next
        n_scl_sync      = {c_scl_sync[1:0], scl};
        n_sda_sync      = {c_sda_sync[1:0], sda_i};

        n_shift_reg     = c_shift_reg;
        n_tx_shift_reg  = c_tx_shift_reg;
        n_bit_cnt       = c_bit_cnt;

        n_rx_data       = c_rx_data;
        n_rx_done       = 1'b0;
        n_tx_done       = 1'b0;

        n_addr_match    = c_addr_match;
        n_addr_ok       = c_addr_ok;
        n_rw_mode       = c_rw_mode;
        n_master_ack    = c_master_ack;
        n_busy          = c_busy;

        n_sda_drive_low = c_sda_drive_low;

        // STOP은 어느 상태에서든 버스 종료
        if (stop_cond) begin
            n_state         = IDLE;
            n_shift_reg     = 8'd0;
            n_tx_shift_reg  = 8'd0;
            n_bit_cnt       = 3'd0;

            n_addr_match    = 1'b0;
            n_addr_ok       = 1'b0;
            n_rw_mode       = 1'b0;
            n_busy          = 1'b0;

            n_sda_drive_low = 1'b0;  // release
        end  // START 또는 repeated START
        else if (start_cond) begin
            n_state         = ADDR;
            n_shift_reg     = 8'd0;
            n_tx_shift_reg  = 8'd0;
            n_bit_cnt       = 3'd0;

            n_addr_match    = 1'b0;
            n_addr_ok       = 1'b0;
            n_rw_mode       = 1'b0;
            n_busy          = 1'b1;

            n_sda_drive_low = 1'b0;  // release
        end else begin
            case (c_state)

                IDLE: begin
                    n_busy          = 1'b0;
                    n_sda_drive_low = 1'b0;
                end

                // 1. Address byte 수신
                ADDR: begin
                    if (scl_rise) begin
                        n_shift_reg = sample_byte;

                        if (c_bit_cnt == 3'd7) begin
                            n_bit_cnt = 3'd0;

                            // sample_byte[7:1] = address
                            // sample_byte[0]   = R/W, 0: write, 1: read
                            if (sample_byte[7:1] == SLAVE_ADDR) begin
                                n_addr_ok    = 1'b1;
                                n_addr_match = 1'b1;
                                n_rw_mode    = sample_byte[0];
                            end else begin
                                n_addr_ok    = 1'b0;
                                n_addr_match = 1'b0;
                                n_rw_mode    = sample_byte[0];
                            end

                            n_state = ADDR_ACK_WAIT_FALL;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1'b1;
                        end
                    end
                end

                // 2. Address ACK 준비
                ADDR_ACK_WAIT_FALL: begin
                    // 8번째 address bit 이후 SCL falling에서 ACK 준비
                    if (scl_fall) begin
                        if (c_addr_ok) begin
                            n_sda_drive_low = 1'b1;  // ACK = SDA Low
                        end else begin
                            n_sda_drive_low = 1'b0;  // NACK = release
                        end

                        n_state = ADDR_ACK_HOLD;
                    end
                end

                // 3. Address ACK 유지 후 write/read 분기
                ADDR_ACK_HOLD: begin
                    // 9번째 ACK clock이 끝나는 falling edge에서 release
                    if (scl_fall) begin
                        n_sda_drive_low = 1'b0;
                        n_shift_reg     = 8'd0;
                        n_bit_cnt       = 3'd0;

                        if (!c_addr_ok) begin
                            n_state = IDLE;
                            n_busy  = 1'b0;
                        end else if (c_rw_mode == 1'b0) begin
                            // Write transaction
                            n_state = WRITE_DATA;
                        end else begin
                            // Read transaction
                            n_tx_shift_reg = tx_data;

                            // 첫 bit를 다음 SCL rising 전에 준비
                            // tx bit가 0이면 drive low, 1이면 release
                            n_sda_drive_low = ~tx_data[7];

                            n_state = READ_DATA;
                        end
                    end
                end

                // 4. Write data byte 수신
                WRITE_DATA: begin
                    if (scl_rise) begin
                        n_shift_reg = sample_byte;

                        if (c_bit_cnt == 3'd7) begin
                            n_bit_cnt = 3'd0;
                            n_rx_data = sample_byte;
                            n_rx_done = 1'b1;
                            n_state   = WRITE_DATA_ACK_WAIT_FALL;
                        end else begin
                            n_bit_cnt = c_bit_cnt + 1'b1;
                        end
                    end
                end

                // 5. Write data ACK 준비
                WRITE_DATA_ACK_WAIT_FALL: begin
                    if (scl_fall) begin
                        n_sda_drive_low = 1'b1;  // ACK
                        n_state         = WRITE_DATA_ACK_HOLD;
                    end
                end

                // 6. Write data ACK 유지 후 다음 byte 대기
                WRITE_DATA_ACK_HOLD: begin
                    if (scl_fall) begin
                        n_sda_drive_low = 1'b0;  // release
                        n_shift_reg     = 8'd0;
                        n_bit_cnt       = 3'd0;

                        // STOP 전까지 다음 data byte도 받을 수 있음
                        n_state         = WRITE_DATA;
                    end
                end

                // 7. Read data byte 송신
                READ_DATA: begin
                    // Slave는 이미 SDA에 현재 bit를 올려둔 상태
                    // Master가 SCL High에서 sample한 뒤,
                    // SCL falling에서 다음 bit를 준비한다.
                    if (scl_fall) begin
                        if (c_bit_cnt == 3'd7) begin
                            // bit0까지 전송 완료.
                            // 다음 9번째 clock은 Master ACK/NACK이므로 SDA release
                            n_bit_cnt       = 3'd0;
                            n_sda_drive_low = 1'b0;  // release
                            n_tx_done       = 1'b1;
                            n_state         = READ_MASTER_ACK;
                        end else begin
                            // 다음 bit 준비
                            n_tx_shift_reg  = {c_tx_shift_reg[6:0], 1'b0};
                            n_bit_cnt       = c_bit_cnt + 1'b1;

                            // shift 후 다음 bit는 기존 c_tx_shift_reg[6]
                            n_sda_drive_low = ~c_tx_shift_reg[6];
                        end
                    end
                end

                // 8. Read 후 Master ACK/NACK 확인
                READ_MASTER_ACK: begin
                    // 9번째 clock에서 Master가 ACK/NACK을 SDA에 출력
                    // ACK=0이면 계속 읽기, NACK=1이면 종료 대기
                    if (scl_rise) begin
                        n_master_ack = sda_sample;

                        if (sda_sample == 1'b0) begin
                            // Master ACK: 다음 byte 전송 가능
                            // 여기서는 단순히 같은 tx_data를 다시 전송하도록 구성
                            n_tx_shift_reg  = tx_data;
                            n_bit_cnt       = 3'd0;
                            n_sda_drive_low = ~tx_data[7];
                            n_state         = READ_DATA;
                        end else begin
                            // Master NACK: 더 이상 read 안 함
                            n_sda_drive_low = 1'b0;
                            n_state         = IDLE;
                            n_busy          = 1'b0;
                        end
                    end
                end

                default: begin
                    n_state         = IDLE;
                    n_sda_drive_low = 1'b0;
                end

            endcase
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;

            c_scl_sync      <= 3'b111;
            c_sda_sync      <= 3'b111;

            c_shift_reg     <= 8'd0;
            c_tx_shift_reg  <= 8'd0;
            c_bit_cnt       <= 3'd0;

            c_rx_data       <= 8'd0;
            c_rx_done       <= 1'b0;
            c_tx_done       <= 1'b0;

            c_addr_match    <= 1'b0;
            c_addr_ok       <= 1'b0;
            c_rw_mode       <= 1'b0;
            c_master_ack    <= 1'b1;
            c_busy          <= 1'b0;

            c_sda_drive_low <= 1'b0;
        end else begin
            c_state         <= n_state;

            c_scl_sync      <= n_scl_sync;
            c_sda_sync      <= n_sda_sync;

            c_shift_reg     <= n_shift_reg;
            c_tx_shift_reg  <= n_tx_shift_reg;
            c_bit_cnt       <= n_bit_cnt;

            c_rx_data       <= n_rx_data;
            c_rx_done       <= n_rx_done;
            c_tx_done       <= n_tx_done;

            c_addr_match    <= n_addr_match;
            c_addr_ok       <= n_addr_ok;
            c_rw_mode       <= n_rw_mode;
            c_master_ack    <= n_master_ack;
            c_busy          <= n_busy;

            c_sda_drive_low <= n_sda_drive_low;
        end
    end

endmodule
