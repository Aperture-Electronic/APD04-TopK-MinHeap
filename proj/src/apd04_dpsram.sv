// System verilog source file
// Dual port SRAM for APD04 Top-K Min-Heap Sorter

module apd04_dpsram
#(
    parameter  type T          = logic,
    parameter       WORDS      = 128,
    localparam      ADDR_WIDTH = $clog2(WORDS)
)
(
    input       logic                    clk,

    input       T                        a_din,
    output      T                        a_dout,
    input       logic                    a_wen,
    input             [ADDR_WIDTH - 1:0] a_waddr,
    input             [ADDR_WIDTH - 1:0] a_raddr,

    input       T                        b_din,
    output      T                        b_dout,
    input       logic                    b_wen,
    input             [ADDR_WIDTH - 1:0] b_waddr,
    input             [ADDR_WIDTH - 1:0] b_raddr
);

// RAM block
T ram [WORDS];

always_ff @(posedge clk) begin : ram_porta
    if (a_wen) begin
        ram[a_waddr] <= a_din;
    end

    a_dout <= ram[a_raddr];
end : ram_porta

always_ff @(posedge clk) begin : ram_portb
    if (b_wen) begin
        ram[b_waddr] <= b_din;
    end

    b_dout <= ram[b_raddr];
end : ram_portb

endmodule : apd04_dpsram
