// System verilog source file
// APD04 Top-K Min-Heap Sorter
module apd04_topk_minheap
#(
    parameter DATA_WIDTH = 32,
    parameter TOP_K      = 128
)
(
    // Clock and reset
    input  logic                    clk,
    input  logic                    aresetn,

    // Data input interface
    input  logic [DATA_WIDTH - 1:0] s_axis_din_tdata,
    input  logic                    s_axis_din_tvalid,
    input  logic                    s_axis_din_tlast,
    output logic                    s_axis_din_tready,

    // Data output interface
    output logic [DATA_WIDTH - 1:0] m_axis_dout_tdata,
    output logic                    m_axis_dout_tvalid,
    output logic                    m_axis_dout_tlast
);

localparam                                 HEAP_ADDR_WIDTH        = $clog2(TOP_K);
localparam                                 HEAP_PTR_WIDTH         = HEAP_ADDR_WIDTH + 2;

typedef logic [DATA_WIDTH - 1:0] payload_t;
typedef logic [HEAP_ADDR_WIDTH - 1:0] heap_addr_t;
typedef logic [HEAP_PTR_WIDTH - 1:0] heap_ptr_t;

typedef enum logic [2:0]
{
    STATE_CLEAR,
    STATE_HEAP_NOTFULL,
    STATE_SIFT_UP,
    STATE_HEAP_FULL,
    STATE_SIFT_DN,
    STATE_OUTPUT
} state_e;

state_e                                    state;
logic                                      din_valid;
heap_ptr_t                                 heap_ptr;

logic                                      last_data_flag;

// Compare and swap addresses
heap_addr_t                                cmp_rd_a_addr;
heap_addr_t                                cmp_rd_b_addr;
heap_addr_t                                swap_wb_a_addr;
heap_addr_t                                swap_wb_b_addr;
logic                                      swap_valid;
logic                                      swap_at_full;
heap_ptr_t                                 left_leaf_addr;
heap_ptr_t                                 right_leaf_addr;
logic                                      nxt_left_leaf_ovfl;
logic                                      nxt_right_leaf_ovfl;
logic                                      right_leaf_ovfl;

// Swap data cache
payload_t                                  swap_data_cache;

// Comparation unit
payload_t                                  cmp_lchild;
logic                                      lchild_less_rchild;
logic                                      swap_execute;
payload_t                                  minimum_leaf;
heap_addr_t                                minimum_leaf_addr;
heap_addr_t                                minimum_leaf_addr_safe;

// Heap top cache
payload_t                                  heap_top_cache;

// Heap top compare unit
logic                                      din_gt_heap_top;

// 2-stage sift
logic                                      sift_stage;

// Sift down compare
logic                                      sift_dn_din_swap;
heap_addr_t                                sift_dn_last_swap_addr;
logic                                      sift_dn_cmp_inv;

// To DPRAM
heap_addr_t                                heap_pa_waddr;
heap_addr_t                                heap_pb_waddr;
payload_t                                  heap_pa_wdata;
payload_t                                  heap_pb_wdata;
logic                                      heap_pa_wen;
logic                                      heap_pb_wen;
heap_addr_t                                heap_pa_raddr;
heap_addr_t                                heap_pb_raddr;
payload_t                                  heap_pa_rdata;
payload_t                                  heap_pb_rdata;

assign din_valid                  = s_axis_din_tvalid && s_axis_din_tready;

// Comparator
assign lchild_less_rchild         = cmp_lchild < heap_pb_rdata;
assign din_gt_heap_top            = s_axis_din_tdata > heap_top_cache;

// Do swap when:
//  1. Allow the swapping in SIFT_UP or SIFT_DN state (swap_valid = 1)
//  2. The compare result is LEFT < RIGHT (lchild_less_rchild = 1)
//     NOTE: In SIFT_UP, L = h[cur_ptr],  R = h[parent]  , with sift_dn_cmp_inv always 0
//           In SIFT_DN, L = h[samllest], R = h[cur]     , when sift_dn_cmp_inv = 0
//                       L = h[cur]     , R = h[smallest], when sift_dn_cmp_inv = 1
assign swap_execute               = swap_valid && (lchild_less_rchild ^ sift_dn_cmp_inv);

// Get the minimum leaf of the tree and compare with the input data
// If it's less than the input data, do swap
assign minimum_leaf_addr          = ((lchild_less_rchild) ? cmp_rd_a_addr : cmp_rd_b_addr);
assign swap_at_full               = (minimum_leaf < swap_data_cache);

// Leaf address (next)
assign left_leaf_addr             = {minimum_leaf_addr, 1'b0} + 'd1;
assign right_leaf_addr            = {minimum_leaf_addr, 1'b0} + 'd2;
assign nxt_left_leaf_ovfl         = left_leaf_addr > (TOP_K - 1);
assign nxt_right_leaf_ovfl        = right_leaf_addr > (TOP_K - 1);

// Safe minimum leaf (no overflow)
assign minimum_leaf_addr_safe     = right_leaf_ovfl ? cmp_rd_a_addr : minimum_leaf_addr;
assign minimum_leaf               = right_leaf_ovfl ? heap_pa_rdata :
    (((lchild_less_rchild) ? heap_pa_rdata : heap_pb_rdata));

// Connect output data to RAM
assign m_axis_dout_tdata          = heap_pa_rdata;

always_ff @(posedge clk, negedge aresetn) begin
    if (!aresetn) begin
        state                  <= STATE_CLEAR;

        // Block the input interfaces @reset
        s_axis_din_tready      <= '0;

        // Reset output interfaces
        m_axis_dout_tvalid     <= '0;

        // Reset the heap counter
        heap_ptr               <= '0;

        // Reset the heap address
        cmp_rd_a_addr          <= '0;
        cmp_rd_b_addr          <= '0;

        // Reset swap control
        swap_valid             <= '0;

        // Clear the swap data
        swap_data_cache        <= '0;

        // Reset the sift down unit
        sift_dn_din_swap       <= '0;
        sift_dn_last_swap_addr <= '0;
        sift_dn_cmp_inv        <= '0;
        sift_stage             <= '0;
        right_leaf_ovfl        <= '0;

        // Reset the last data flag
        last_data_flag         <= '0;

        // Reset the output interface
        m_axis_dout_tvalid     <= '0;
        m_axis_dout_tlast      <= '0;
    end
    else begin
        case (state)
            STATE_CLEAR: begin
                m_axis_dout_tvalid <= '0;
                m_axis_dout_tlast  <= '0;

                // Clear the heap
                if (heap_ptr == (TOP_K / 2)) begin
                    state                  <= STATE_HEAP_NOTFULL;
                    s_axis_din_tready      <= '1;
                    heap_ptr               <= '0;
                end
                else begin
                    heap_ptr               <= heap_ptr + 'd1;
                    s_axis_din_tready      <= '0;
                end
            end
            STATE_HEAP_NOTFULL: begin
                if (din_valid) begin
                    // Count the input data
                    heap_ptr               <= heap_ptr + 'd1;

                    // Enter the sift up procdure excluding the first data
                    if (heap_ptr != '0) begin
                        // Current compare source is
                        // L = input data    -> h[cur_ptr]
                        // R = prepared data -> h[(cur_ptr - 1) >> 1]

                        // Allow swap
                        swap_valid                          <= '1;

                        // Cache the input data for swap
                        swap_data_cache                     <= s_axis_din_tdata;

                        // Prepare for next compare
                        cmp_rd_a_addr                       <= (heap_ptr - 1) >> 1;                // next SIFT IDX = cur PARENT
                        cmp_rd_b_addr                       <= (((heap_ptr - 1) >> 1) - 1) >> 1;   // next PARENT

                        // Entering sift up
                        state                               <= STATE_SIFT_UP;

                        s_axis_din_tready                   <= '0;

                        // Mark the last data
                        if (s_axis_din_tlast) begin
                            last_data_flag     <= '1;
                        end
                    end
                    else begin
                        // Only one data in the stream, exit
                        if (s_axis_din_tlast) begin
                            state              <= STATE_OUTPUT;
                        end
                        else begin
                            // Prepare for next compare
                            // PARENT = (nextPTR - 1) >> 1 = (curPTR + 1 - 1) >> 1
                            //        = (curPTR) >> 1
                            cmp_rd_a_addr      <= heap_ptr + 'd1;   // SIFT IDX (next)
                            cmp_rd_b_addr      <= heap_ptr >> 1;    // PARENT (next)
                        end
                    end
                end
            end
            STATE_SIFT_UP: begin
                if (swap_execute) begin
                    // If execute the swap, update the iteration index and parent
                    cmp_rd_a_addr          <= cmp_rd_b_addr;                // SIFT IDX
                    cmp_rd_b_addr          <= (cmp_rd_b_addr - 'd1) >> 1;   // PARENT
                end
                else begin
                    // If do not execute the swap, then exit
                    swap_valid             <= '0;

                    // If last data flagged, go to output
                    if (last_data_flag) begin
                        heap_ptr                            <= '0;
                        state                               <= STATE_OUTPUT;
                    end

                    // The heap is full, entering the HEAP_FULL state
                    if (heap_ptr == TOP_K) begin
                        // Prepare for R/L compare
                        cmp_rd_a_addr                       <= 'd1;
                        cmp_rd_b_addr                       <= 'd2;

                        state                               <= STATE_HEAP_FULL;
                    end
                    else begin
                        // Prepare for next compare
                        cmp_rd_a_addr                       <= heap_ptr[$bits(heap_addr_t) - 1:0]; // SIFT IDX
                        cmp_rd_b_addr                       <= (heap_ptr - 1) >> 1;                // PARENT

                        state                               <= STATE_HEAP_NOTFULL;
                    end

                    // Let the interface continue to receive data
                    s_axis_din_tready      <= '1;
                end
            end
            STATE_HEAP_FULL : begin
                if (din_valid) begin
                    if (din_gt_heap_top) begin
                        // Cache the input data for swap
                        swap_data_cache                     <= s_axis_din_tdata;

                        // Do sift down procdure
                        state                               <= STATE_SIFT_DN;

                        // Reset the 2-stage sift down unit
                        sift_dn_din_swap                    <= '1;
                        sift_stage                          <= '0;
                        right_leaf_ovfl                     <= '0;

                        s_axis_din_tready                   <= '0;

                        // Mark the last data
                        if (s_axis_din_tlast) begin
                            last_data_flag     <= '1;
                        end
                    end
                    else begin
                        // Ignore the value
                        if (s_axis_din_tlast) begin
                            state              <= STATE_OUTPUT;
                            heap_ptr           <= '0;
                        end
                    end
                end
            end
            STATE_SIFT_DN: begin
                if (!sift_stage) begin
                    // Stage I: Direct/swap write the new data into the heap
                    // Switch stage
                    sift_stage             <= ~sift_stage;

                    // Clear the flag of swap from input data
                    sift_dn_din_swap       <= '0;

                    // Set the pointer overflow flag
                    if (!sift_dn_din_swap) begin
                        right_leaf_ovfl                     <= nxt_right_leaf_ovfl;
                    end
                    else begin
                        right_leaf_ovfl                     <= '0;
                    end

                    // Record the leaf address
                    if (!nxt_left_leaf_ovfl)  cmp_rd_a_addr <= left_leaf_addr[$bits(heap_addr_t) - 1:0];
                    if (!nxt_right_leaf_ovfl) cmp_rd_b_addr <= right_leaf_addr[$bits(heap_addr_t) - 1:0];

                    // Record the last swap address
                    sift_dn_last_swap_addr <= minimum_leaf_addr_safe;

                    // No swap of left leaf overflow
                    if (!swap_at_full || nxt_left_leaf_ovfl) begin
                        if (last_data_flag) begin
                            heap_ptr           <= '0;
                            state              <= STATE_OUTPUT;
                        end
                        else begin
                            // Prepare for R/L compare
                            cmp_rd_a_addr      <= 'd1;
                            cmp_rd_b_addr      <= 'd2;

                            // Re-enable the data receive
                            s_axis_din_tready  <= '1;

                            state              <= STATE_HEAP_FULL;
                        end
                    end
                end
                else begin
                    sift_stage             <= ~sift_stage;
                end
            end
            STATE_OUTPUT : begin
                m_axis_dout_tlast  <= (heap_ptr == (TOP_K - 1));
                m_axis_dout_tvalid <= '1;

                if (heap_ptr == (TOP_K - 1)) begin
                    state                  <=  STATE_CLEAR;
                end
                else begin
                    heap_ptr               <= heap_ptr + 'd1;
                end
            end
        endcase
    end
end

// Heap top cache
always_ff @(posedge clk, negedge aresetn) begin : heap_top_cache_mgmt
    if (!aresetn) begin
        heap_top_cache <= '0;
    end
    else begin
        if (heap_pa_wen && (heap_pa_waddr == '0)) begin
            heap_top_cache <= heap_pa_wdata;
        end

        if (heap_pb_wen && (heap_pb_waddr == '0)) begin
            heap_top_cache <= heap_pb_wdata;
        end
    end
end : heap_top_cache_mgmt

// Heap swap address
always_ff @(posedge clk, negedge aresetn) begin : heap_swap_addr_sfr
    if (!aresetn) begin
        swap_wb_a_addr <= '0;
        swap_wb_b_addr <= '0;
    end
    else begin
        swap_wb_a_addr <= cmp_rd_a_addr;
        swap_wb_b_addr <= cmp_rd_b_addr;
    end
end : heap_swap_addr_sfr

// Comparator source selection
always_comb begin : cmp_src_sel
    case (state)
        STATE_SIFT_UP : begin
            cmp_lchild = swap_data_cache; // Swap cache
        end
        STATE_SIFT_DN: begin
            cmp_lchild = heap_pa_rdata;   // Left node
        end
        default: begin
            cmp_lchild = '0;
        end
    endcase
end : cmp_src_sel

// Heap control selection
always_comb begin : heap_ctrl_sel
    case (state)
        STATE_CLEAR: begin
            heap_pa_wdata = '0;
            heap_pa_waddr = {1'b0, heap_ptr[$bits(heap_addr_t) - 2:0]};
            heap_pa_wen   = '1;
            heap_pa_raddr = '0;

            heap_pb_wdata = '0;
            heap_pb_waddr = {1'b1, heap_ptr[$bits(heap_addr_t) - 2:0]};
            heap_pb_wen   = '1;
            heap_pb_raddr = '0;
        end
        STATE_HEAP_NOTFULL : begin
            heap_pa_wdata = s_axis_din_tdata;
            heap_pa_waddr = heap_ptr[$bits(heap_addr_t) - 1:0];
            heap_pa_wen   = din_valid;
            heap_pa_raddr = cmp_rd_a_addr;

            heap_pb_wdata = '0;
            heap_pb_waddr = '0;
            heap_pb_wen   = '0;
            heap_pb_raddr = (heap_ptr - 1) >> 1;
        end
        STATE_SIFT_UP : begin
            heap_pa_wdata = heap_pb_rdata;
            heap_pa_waddr = swap_wb_a_addr;
            heap_pa_wen   = swap_execute;
            heap_pa_raddr = cmp_rd_a_addr;

            heap_pb_wdata = swap_data_cache;
            heap_pb_waddr = swap_wb_b_addr;
            heap_pb_wen   = swap_execute;
            heap_pb_raddr = cmp_rd_b_addr;
        end
        STATE_HEAP_FULL: begin
            heap_pa_wdata = '0;
            heap_pa_waddr = '0;
            heap_pa_wen   = '0;
            heap_pa_raddr = cmp_rd_a_addr;

            heap_pb_wdata = '0;
            heap_pb_waddr = '0;
            heap_pb_wen   = '0;
            heap_pb_raddr = cmp_rd_b_addr;
        end
        STATE_SIFT_DN: begin
            if (!sift_stage) begin
                heap_pa_wdata = swap_at_full ? minimum_leaf : swap_data_cache;
                heap_pa_wen   = swap_at_full || sift_dn_din_swap;
                heap_pa_raddr = left_leaf_addr[$bits(heap_addr_t) - 1:0];

                heap_pb_wdata = swap_data_cache;
                heap_pb_wen   = swap_at_full;
                heap_pb_raddr = right_leaf_addr[$bits(heap_addr_t) - 1:0];

                if (sift_dn_din_swap) begin
                    heap_pa_waddr = '0;
                    heap_pb_waddr = lchild_less_rchild ? 'd1 : 'd2;
                end
                else begin
                    heap_pa_waddr = sift_dn_last_swap_addr;
                    heap_pb_waddr = minimum_leaf_addr_safe;
                end
            end
            else begin
                heap_pa_wdata = '0;
                heap_pa_waddr = '0;
                heap_pa_wen   = '0;
                heap_pa_raddr = cmp_rd_a_addr;

                heap_pb_wdata = '0;
                heap_pb_waddr = '0;
                heap_pb_wen   = '0;
                heap_pb_raddr = cmp_rd_b_addr;
            end
        end
        STATE_OUTPUT : begin
            heap_pa_wdata = '0;
            heap_pa_waddr = '0;
            heap_pa_wen   = '0;
            heap_pa_raddr = heap_ptr[$bits(heap_addr_t) - 1:0];

            heap_pb_wdata = '0;
            heap_pb_waddr = '0;
            heap_pb_wen   = '0;
            heap_pb_raddr = '0;
        end
        default: begin
            heap_pa_wdata = '0;
            heap_pa_waddr = '0;
            heap_pa_wen   = '0;
            heap_pa_raddr = '0;

            heap_pb_wdata = '0;
            heap_pb_waddr = '0;
            heap_pb_wen   = '0;
            heap_pb_raddr = '0;
        end
    endcase
end : heap_ctrl_sel

// Heap DPSRAM
apd04_dpsram #(
    .WORDS(TOP_K    ),
    .T    (payload_t)
)
heap_dpsram (
    .clk    (clk          ),
    .a_din  (heap_pa_wdata),
    .a_dout (heap_pa_rdata),
    .a_wen  (heap_pa_wen  ),
    .a_waddr(heap_pa_waddr),
    .a_raddr(heap_pa_raddr),
    .b_din  (heap_pb_wdata),
    .b_dout (heap_pb_rdata),
    .b_wen  (heap_pb_wen  ),
    .b_waddr(heap_pb_waddr),
    .b_raddr(heap_pb_raddr)
);

endmodule : apd04_topk_minheap

