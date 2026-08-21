`timescale 1ns / 1ps

module APB_Master (
    // BUS Global Signal
    input logic PCLK,
    input logic PRESET,

    // SoC Internal Signal with CPU
    input  logic [31:0] Addr,
    input  logic [31:0] WDATA,
    input  logic        R_REQ,
    input  logic        W_REQ,
    output logic [31:0] RDATA,
    output logic        READY,

    // APB Interface signal
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic        PENABLE,
    output logic        PWRITE,
    output logic        PSEL0,
    output logic        PSEL1,
    output logic        PSEL2,
    output logic        PSEL3,
    output logic        PSEL4,
    input  logic        PREADY0,
    input  logic        PREADY1,
    input  logic        PREADY2,
    input  logic        PREADY3,
    input  logic        PREADY4,
    input  logic [31:0] PRDATA0,
    input  logic [31:0] PRDATA1,
    input  logic [31:0] PRDATA2,
    input  logic [31:0] PRDATA3,
    input  logic [31:0] PRDATA4
);

  logic [2:0] mux_sel;

  // FSM
  typedef enum {
    IDLE,
    SETUP,
    ACCESS
  } apb_state_e;

  apb_state_e c_state, n_state;

  // FSM Register
  always_ff @(posedge PCLK, posedge PRESET) begin
    if (PRESET) begin
      c_state <= IDLE;
    end else begin
      c_state <= n_state;
    end
  end

  always_comb begin
    n_state = c_state;
    PADDR   = 0;
    PWDATA  = 0;
    PENABLE = 0;
    PWRITE  = 0;
    case (c_state)
      IDLE: begin
        if (W_REQ | R_REQ) begin
          n_state = SETUP;
        end
      end
      SETUP: begin
        PADDR = Addr;
        if (W_REQ) begin
          PWDATA = WDATA;
          PWRITE = 1'b1;
        end else begin
          PWDATA = 32'd0;
          PWRITE = 1'b0;
        end
        PENABLE = 0;
        n_state = ACCESS;
      end
      ACCESS: begin
        PADDR = Addr;
        if (W_REQ) begin
          PWDATA = WDATA;
          PWRITE = 1'b1;
        end else begin
          PWDATA = 32'd0;
          PWRITE = 1'b0;
        end
        PENABLE = 1;
        if (READY) begin
          // Holding (to be continue)
          // if (W_REQ | R_REQ) begin
          //     n_state=SETUP;
          // end
          n_state = IDLE;
        end
      end
    endcase
  end

  address_decoder U_ADDR_DECODER (.*);

  apb_mux U_APB_MUX (
      .sel(mux_sel),
      .*
  );


endmodule


module address_decoder (
    input  logic [31:0] Addr,
    output logic        PSEL0,
    output logic        PSEL1,
    output logic        PSEL2,
    output logic        PSEL3,
    output logic        PSEL4,
    output logic [ 2:0] mux_sel
);

  always_comb begin
    PSEL0   = 0;
    PSEL1   = 0;
    PSEL2   = 0;
    PSEL3   = 0;
    PSEL4   = 0;
    mux_sel = 3'b000;
    case (Addr[31:28])
      4'h0001: begin
        PSEL0   = 1'b1;  // RAM
        mux_sel = 3'b000;
      end
      4'h0002: begin
        case (Addr[15:12])
          4'h0: begin
            PSEL1   = 1'b1;  // GPO
            mux_sel = 3'b001;
          end
          4'h1: begin
            PSEL2   = 1'b1;  // GPI
            mux_sel = 3'b010;
          end
          4'h2: begin
            PSEL3   = 1'b1;  // GPIO
            mux_sel = 3'b011;
          end
          4'h3: begin
            PSEL4   = 1'b1;  // reserve
            mux_sel = 3'b100;
          end
        endcase
      end
    endcase
  end
endmodule

module apb_mux (
    input  logic [ 2:0] sel,
    input  logic [31:0] PRDATA0,
    input  logic [31:0] PRDATA1,
    input  logic [31:0] PRDATA2,
    input  logic [31:0] PRDATA3,
    input  logic [31:0] PRDATA4,
    input  logic        PREADY0,
    input  logic        PREADY1,
    input  logic        PREADY2,
    input  logic        PREADY3,
    input  logic        PREADY4,
    output logic [31:0] RDATA,
    output logic        READY
);

  always_comb begin
    RDATA = 0;
    READY = 1'b0;
    case (sel)
      3'b000: begin
        RDATA = PRDATA0;
        READY = PREADY0;
      end
      3'b001: begin
        RDATA = PRDATA1;
        READY = PREADY1;
      end
      3'b010: begin
        RDATA = PRDATA2;
        READY = PREADY2;
      end
      3'b011: begin
        RDATA = PRDATA3;
        READY = PREADY3;
      end
      3'b100: begin
        RDATA = PRDATA4;
        READY = PREADY4;
      end
    endcase
  end


endmodule
