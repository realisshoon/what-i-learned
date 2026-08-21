`timescale 1ns / 1ps

module axi4_lite_slave (
    input logic ACLK,
    input logic ARESET_n,

    // AW channel
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,

    // W channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,

    // B channel
    output logic [1:0] BRESP,
    output logic       BVALID,
    input  logic       BREADY,

    // AR channel
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        AREADY,   // 나중에 ARREADY로 이름 바꾸는 것 추천

    // R channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

    localparam logic [1:0] RESP_OKAY = 2'b00;

    logic [31:0] slv_reg0;
    logic [31:0] slv_reg1;
    logic [31:0] slv_reg2;
    logic [31:0] slv_reg3;

    logic [31:0] addr_r;
    logic [31:0] wdata_r;

    logic        aw_done;
    logic        w_done;

    logic        aw_fire;
    logic        w_fire;
    logic        b_fire;

    logic        have_aw;
    logic        have_w;
    logic [31:0] wr_addr;
    logic [31:0] wr_data;

    assign aw_fire = AWVALID && AWREADY;
    assign w_fire  = WVALID && WREADY;
    assign b_fire  = BVALID && BREADY;

    // Slave가 현재 address/data를 받을 수 있으면 READY를 1로 둠
    assign AWREADY = (!aw_done) && (!BVALID);
    assign WREADY  = (!w_done) && (!BVALID);

    // 같은 cycle에 AW/W가 들어오는 경우까지 처리하기 위한 조합 신호
    assign have_aw = aw_done || aw_fire;
    assign have_w  = w_done || w_fire;

    assign wr_addr = aw_fire ? AWADDR : addr_r;
    assign wr_data = w_fire ? WDATA : wdata_r;

    // Write Address / Write Data / Write Response 처리
    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            slv_reg0 <= 32'd0;
            slv_reg1 <= 32'd0;
            slv_reg2 <= 32'd0;
            slv_reg3 <= 32'd0;

            addr_r   <= 32'd0;
            wdata_r  <= 32'd0;

            aw_done  <= 1'b0;
            w_done   <= 1'b0;

            BVALID   <= 1'b0;
            BRESP    <= RESP_OKAY;
        end else begin

            if (aw_fire) begin
                addr_r  <= AWADDR;
                aw_done <= 1'b1;
            end

            if (w_fire) begin
                wdata_r <= WDATA;
                w_done  <= 1'b1;
            end

            if (!BVALID && have_aw && have_w) begin
                case (wr_addr[3:2])
                    2'd0: slv_reg0 <= wr_data;
                    2'd1: slv_reg1 <= wr_data;
                    2'd2: slv_reg2 <= wr_data;
                    2'd3: slv_reg3 <= wr_data;
                    default: begin
                    end
                endcase

                BVALID  <= 1'b1;
                BRESP   <= RESP_OKAY;

                aw_done <= 1'b0;
                w_done  <= 1'b0;
            end

            if (b_fire) begin
                BVALID <= 1'b0;
                BRESP  <= RESP_OKAY;
            end
        end
    end
    // =========================================================
    // READ Transaction
    // AR channel + R channel
    // =========================================================

    logic [31:0] araddr_r;

    logic ar_fire;
    logic r_fire;

    assign ar_fire = ARVALID && AREADY;
    assign r_fire  = RVALID && RREADY;

    // RVALID가 이미 떠 있으면 새로운 AR을 받지 않음
    // 즉 read response가 pending 중이면 다음 read address를 막음
    assign AREADY  = !RVALID;

    always_ff @(posedge ACLK or negedge ARESET_n) begin
        if (!ARESET_n) begin
            araddr_r <= 32'd0;

            RDATA    <= 32'd0;
            RVALID   <= 1'b0;
            RRESP    <= RESP_OKAY;
        end else begin

            // -----------------------------
            // AR handshake 발생
            // Master가 read address를 보냄
            // Slave가 address를 받고 바로 RDATA 준비
            // -----------------------------
            if (ar_fire) begin
                araddr_r <= ARADDR;

                case (ARADDR[3:2])
                    2'd0: RDATA <= slv_reg0;
                    2'd1: RDATA <= slv_reg1;
                    2'd2: RDATA <= slv_reg2;
                    2'd3: RDATA <= slv_reg3;
                    default: RDATA <= 32'd0;
                endcase

                RVALID <= 1'b1;
                RRESP  <= RESP_OKAY;
            end

            // -----------------------------
            // R handshake 완료
            // Master가 read data를 받음
            // -----------------------------
            if (r_fire) begin
                RVALID <= 1'b0;
                RRESP  <= RESP_OKAY;
            end
        end
    end

endmodule
