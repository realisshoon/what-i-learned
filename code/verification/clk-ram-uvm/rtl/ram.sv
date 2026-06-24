module ram #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  we,
    input  logic [DATA_WIDTH-1:0] wdata,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] rdata
);

    localparam DEPTH = 1 << ADDR_WIDTH;
    logic [DATA_WIDTH-1:0] mem[0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= wdata;
        end else begin
            rdata <= mem[addr];
        end
    end

endmodule
