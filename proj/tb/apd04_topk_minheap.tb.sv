// System verilog testbench file
// APD04 Top-K Min-Heap Sorter Simple Testbench
`timescale 1ns/1ps


module apd04_topk_minheap_tb;
localparam                    TCO                         = 1ns;
localparam                    CLOCK_PERIOD                = 10ns;
localparam                    RESET_PERIOD                = 25ns;
localparam                    DATA_WIDTH                  = 16;
localparam                    TOP_K                       = 128;
localparam                    DATA_N                      = 1024;

typedef logic [DATA_WIDTH - 1:0] payload_t;

logic                         clk;
logic                         aresetn;
logic      [DATA_WIDTH - 1:0] s_axis_din_tdata;
logic                         s_axis_din_tvalid;
logic                         s_axis_din_tlast;
logic                         s_axis_din_tready;
logic      [DATA_WIDTH - 1:0] m_axis_dout_tdata;
logic                         m_axis_dout_tvalid;
logic                         m_axis_dout_tlast;

apd04_topk_minheap #(
    .DATA_WIDTH(DATA_WIDTH),
    .TOP_K     (TOP_K     )
)
DUV
(
    .clk               (clk               ),
    .aresetn           (aresetn           ),
    .s_axis_din_tdata  (s_axis_din_tdata  ),
    .s_axis_din_tvalid (s_axis_din_tvalid ),
    .s_axis_din_tlast  (s_axis_din_tlast  ),
    .s_axis_din_tready (s_axis_din_tready ),
    .m_axis_dout_tdata (m_axis_dout_tdata ),
    .m_axis_dout_tvalid(m_axis_dout_tvalid),
    .m_axis_dout_tlast (m_axis_dout_tlast )
);

// Clock and reset generation
initial begin
    fork
        begin
            clk                     = 1'b0;
            forever #(CLOCK_PERIOD / 2) clk = ~clk;
        end
        begin
            aresetn                 = 1'b0;
            #(RESET_PERIOD) aresetn = 1'b1;
        end
    join
end

int                           fd;
int                           data_idx                    = 0;
payload_t                     payload_x          [DATA_N];

initial begin
    fd                 = $fopen("test_vector.txt", "w");

    for (int i = 0; i < DATA_N; i++) begin
        // Give the random number to payload array
        payload_x[i] = payload_t'($urandom());
        $fwrite(fd, "%0d\n", payload_x[i]);
    end

    $fclose(fd);

    $display("Generated %d payloads, wrote it to test_vector.txt", DATA_N);

    // Reset interface
    s_axis_din_tdata   = #TCO '0;
    s_axis_din_tvalid  = #TCO '0;
    s_axis_din_tlast   = #TCO '0;

    // Wait for the reset
    @(posedge aresetn);

    for (int i = 0; i < DATA_N; ) begin
        s_axis_din_tdata  = #TCO payload_x[i];
        s_axis_din_tlast  = #TCO (i == DATA_N - 1);
        s_axis_din_tvalid = #TCO '1;
        @(posedge clk);
        if (s_axis_din_tvalid && s_axis_din_tready) begin
            i++;
            data_idx++;
        end
    end

    s_axis_din_tvalid  = #TCO '0;
    s_axis_din_tlast   = #TCO '0;

    #1500ns $finish();
end

endmodule : apd04_topk_minheap_tb

