`timescale 1ns / 1ps

module axi4_lite_master (
    input logic ACLK,
    input logic ARESET_n,

    // AW channel
    output logic [31:0] AWADDR,
    output logic        AWVALID,
    input  logic        AWREADY,

    // W channel
    output logic [31:0] WDATA,
    output logic        WVALID,
    input  logic        WREADY,

    // B channel
    input  logic [1:0] BRESP,
    input  logic       BVALID,
    output logic       BREADY,

    // AR channel
    output logic [31:0] ARADDR,
    output logic        ARVALID,
    input  logic        AREADY,   // 나중에 ARREADY로 이름 바꾸는 것 추천

    // R channel
    input  logic [31:0] RDATA,
    input  logic        RVALID,
    output logic        RREADY,
    input  logic [ 1:0] RRESP,

    // internal signals
    input  logic        transfer,
    output logic        ready,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic        write
);

    localparam logic [1:0] RESP_OKAY = 2'b00;

    logic [31:0] addr_r;
    logic [31:0] wdata_r;

    logic aw_done;
    logic w_done;
    logic b_done;

    logic aw_fire;
    logic w_fire;
    logic b_fire;

    assign aw_fire = AWVALID && AWREADY;
    assign w_fire  = WVALID && WREADY;
    assign b_fire  = BVALID && BREADY;

    logic start_write;
    logic start_read;
    logic ar_fire;
    logic r_fire;

    assign start_write = transfer && write && ready;
    assign start_read  = transfer && !write && ready;
    assign ar_fire     = ARVALID && AREADY;
    assign r_fire      = RVALID && RREADY;

    // =========================================================
    // Host request latch
    // =========================================================
    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            addr_r  <= 32'd0;
            wdata_r <= 32'd0;
        end else begin
            if (start_write || start_read) begin
                addr_r  <= addr;
            end
            if (start_write) begin
                wdata_r <= wdata;
            end
        end
    end

    // =========================================================
    // AW Channel FSM
    // =========================================================
    typedef enum logic {
        AW_IDLE,
        AW_VALID
    } aw_state_e;

    aw_state_e c_aw_state, n_aw_state;

    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            c_aw_state <= AW_IDLE;
        end else begin
            c_aw_state <= n_aw_state;
        end
    end

    always_comb begin
        n_aw_state = c_aw_state;
        AWADDR     = addr_r;
        AWVALID    = 1'b0;

        case (c_aw_state)
            AW_IDLE: begin
                if (start_write) begin
                    n_aw_state = AW_VALID;
                end
            end

            AW_VALID: begin
                AWADDR  = addr_r;
                AWVALID = 1'b1;

                if (aw_fire) begin
                    n_aw_state = AW_IDLE;
                end
            end

            default: begin
                n_aw_state = AW_IDLE;
            end
        endcase
    end

    // =========================================================
    // W Channel FSM
    // =========================================================
    typedef enum logic {
        W_IDLE,
        W_VALID
    } w_state_e;

    w_state_e c_w_state, n_w_state;

    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            c_w_state <= W_IDLE;
        end else begin
            c_w_state <= n_w_state;
        end
    end

    always_comb begin
        n_w_state = c_w_state;
        WDATA     = wdata_r;
        WVALID    = 1'b0;

        case (c_w_state)
            W_IDLE: begin
                if (start_write) begin
                    n_w_state = W_VALID;
                end
            end

            W_VALID: begin
                WDATA  = wdata_r;
                WVALID = 1'b1;

                if (w_fire) begin
                    n_w_state = W_IDLE;
                end
            end

            default: begin
                n_w_state = W_IDLE;
            end
        endcase
    end

    // =========================================================
    // B Channel FSM
    // =========================================================
    typedef enum logic {
        B_IDLE,
        B_READY
    } b_state_e;

    b_state_e c_b_state, n_b_state;

    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            c_b_state <= B_IDLE;
        end else begin
            c_b_state <= n_b_state;
        end
    end

    always_comb begin
        n_b_state = c_b_state;
        BREADY    = 1'b0;

        case (c_b_state)
            B_IDLE: begin
                // AW와 W를 보낸 뒤 response 받을 준비
                if (aw_done && w_done) begin
                    n_b_state = B_READY;
                end
            end

            B_READY: begin
                BREADY = 1'b1;

                if (b_fire) begin
                    n_b_state = B_IDLE;
                end
            end

            default: begin
                n_b_state = B_IDLE;
            end
        endcase
    end

    // =========================================================
    // Done tracking
    // =========================================================
    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
            b_done  <= 1'b0;
        end else begin
            b_done <= 1'b0;

            if (start_write) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
                b_done  <= 1'b0;
            end

            if (aw_fire) begin
                aw_done <= 1'b1;
            end

            if (w_fire) begin
                w_done <= 1'b1;
            end

            if (b_fire) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
                b_done  <= 1'b1;
            end
        end
    end




    // =========================================================
    // Read channel
    // =========================================================

    // =========================================================
    // AR Channel FSM
    // =========================================================
    typedef enum logic {
        AR_IDLE,
        AR_VALID
    } ar_state_e;

    ar_state_e c_ar_state, n_ar_state;

    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            c_ar_state <= AR_IDLE;
        end else begin
            c_ar_state <= n_ar_state;
        end
    end

    always_comb begin
        n_ar_state = c_ar_state;
        ARADDR     = addr_r;
        ARVALID    = 1'b0;

        case (c_ar_state)
            AR_IDLE: begin
                if (start_read) begin
                    n_ar_state = AR_VALID;
                end
            end

            AR_VALID: begin
                ARADDR  = addr_r;
                ARVALID = 1'b1;

                if (ar_fire) begin
                    n_ar_state = AR_IDLE;
                end
            end

            default: begin
                n_ar_state = AR_IDLE;
            end
        endcase
    end

    // =========================================================
    // R Channel FSM
    // =========================================================
    typedef enum logic {
        R_IDLE,
        R_READY
    } r_state_e;

    r_state_e c_r_state, n_r_state;

    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            c_r_state <= R_IDLE;
        end else begin
            c_r_state <= n_r_state;
        end
    end

    always_comb begin
        n_r_state = c_r_state;
        RREADY    = 1'b0;

        case (c_r_state)
            R_IDLE: begin
                RREADY = 1'b0;
                // AR 주소 전송이 끝난 뒤 read data 받을 준비
                if (ar_fire) begin
                    n_r_state = R_READY;
                end
            end

            R_READY: begin
                // Master가 read data 받을 준비 완료
                RREADY = 1'b1;

                // Slave가 RVALID를 올리면 read data transfer 완료
                if (r_fire) begin
                    n_r_state = R_IDLE;
                end
            end

            default: begin
                RREADY = 1'b0;
                n_r_state = R_IDLE;
            end
        endcase
    end

    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            rdata <= 32'd0;
        end else if (r_fire) begin
            rdata <= RDATA;
        end
    end

    // =========================================================
    // Host ready
    // =========================================================
    always_comb begin
        // 기본 의미:
        // ready = 새로운 write/read 요청을 받을 수 있음
        ready = (c_aw_state == AW_IDLE) &&
                (c_w_state  == W_IDLE)  &&
                (c_b_state  == B_IDLE)  &&
                (!aw_done) &&
                (!w_done)  &&
                (c_ar_state == AR_IDLE) &&
                (c_r_state  == R_IDLE);
    end

endmodule
