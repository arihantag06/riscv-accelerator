// Scratchpad SRAM with Double Buffering
// 32KB total (16KB per buffer) with configurable access patterns

module scratchpad_sram #(
    parameter BUFFER_SIZE = 16384,    // 16KB per buffer
    parameter DATA_WIDTH = 256,        // 256-bit data width
    parameter ADDR_WIDTH = 14,         // 14 bits for 16KB
    parameter NUM_BUFFERS = 2          // Double buffering
)(
    input wire clk,
    input wire rst_n,
    
    // Buffer control
    input wire buffer_select,          // 0=buffer0, 1=buffer1
    input wire buffer_swap,            // Swap active buffer
    
    // Read interface
    input wire rd_en,
    input wire [ADDR_WIDTH-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] rd_data,
    output reg rd_valid,
    
    // Write interface
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] wr_data,
    output reg wr_ready,
    
    // DMA interface
    input wire dma_rd_en,
    input wire [ADDR_WIDTH-1:0] dma_rd_addr,
    output reg [DATA_WIDTH-1:0] dma_rd_data,
    output reg dma_rd_valid,
    
    input wire dma_wr_en,
    input wire [ADDR_WIDTH-1:0] dma_wr_addr,
    input wire [DATA_WIDTH-1:0] dma_wr_data,
    output reg dma_wr_ready
);

    // Memory arrays for both buffers
    reg [DATA_WIDTH-1:0] buffer0 [0:BUFFER_SIZE-1];
    reg [DATA_WIDTH-1:0] buffer1 [0:BUFFER_SIZE-1];
    
    // Buffer selection logic
    wire [DATA_WIDTH-1:0] buffer0_rd_data, buffer1_rd_data;
    wire [DATA_WIDTH-1:0] buffer0_wr_data, buffer1_wr_data;
    
    // Read data multiplexing
    assign buffer0_rd_data = buffer0[rd_addr];
    assign buffer1_rd_data = buffer1[rd_addr];
    
    // Write data demultiplexing
    assign buffer0_wr_data = wr_data;
    assign buffer1_wr_data = wr_data;
    
    // Read operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data <= 0;
            rd_valid <= 0;
            dma_rd_data <= 0;
            dma_rd_valid <= 0;
        end else begin
            // Regular read
            if (rd_en) begin
                rd_data <= buffer_select ? buffer1_rd_data : buffer0_rd_data;
                rd_valid <= 1;
            end else begin
                rd_valid <= 0;
            end
            
            // DMA read
            if (dma_rd_en) begin
                dma_rd_data <= buffer_select ? buffer1[dma_rd_addr] : buffer0[dma_rd_addr];
                dma_rd_valid <= 1;
            end else begin
                dma_rd_valid <= 0;
            end
        end
    end
    
    // Write operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ready <= 1;
            dma_wr_ready <= 1;
        end else begin
            // Regular write
            if (wr_en) begin
                if (buffer_select) begin
                    buffer1[wr_addr] <= wr_data;
                end else begin
                    buffer0[wr_addr] <= wr_data;
                end
                wr_ready <= 1;
            end else begin
                wr_ready <= 1;
            end
            
            // DMA write
            if (dma_wr_en) begin
                if (buffer_select) begin
                    buffer1[dma_wr_addr] <= dma_wr_data;
                end else begin
                    buffer0[dma_wr_addr] <= dma_wr_data;
                end
                dma_wr_ready <= 1;
            end else begin
                dma_wr_ready <= 1;
            end
        end
    end
    
    // Buffer swap logic
    reg [1:0] swap_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            swap_state <= 0;
        end else if (buffer_swap) begin
            swap_state <= swap_state + 1;
        end
    end

endmodule

// Matrix Access Controller
// Handles matrix tile access patterns for efficient MAC array feeding

module matrix_access_controller #(
    parameter TILE_SIZE = 8,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 14
)(
    input wire clk,
    input wire rst_n,
    
    // Control signals
    input wire start,
    input wire [15:0] m_dim, k_dim, n_dim,
    input wire [15:0] stride_a, stride_b, stride_c,
    
    // Matrix pointers
    input wire [31:0] matrix_a_base,
    input wire [31:0] matrix_b_base,
    input wire [31:0] matrix_c_base,
    
    // Scratchpad interface
    output reg scratchpad_wr_en,
    output reg [ADDR_WIDTH-1:0] scratchpad_wr_addr,
    output reg [255:0] scratchpad_wr_data,
    input wire scratchpad_wr_ready,
    
    output reg scratchpad_rd_en,
    output reg [ADDR_WIDTH-1:0] scratchpad_rd_addr,
    input wire [255:0] scratchpad_rd_data,
    input wire scratchpad_rd_valid,
    
    // MAC array interface
    output reg mac_enable,
    output reg [TILE_SIZE*DATA_WIDTH-1:0] mac_a_row,
    output reg [TILE_SIZE*DATA_WIDTH-1:0] mac_b_col,
    
    // Status
    output reg done,
    output reg [2:0] state
);

    // State machine
    localparam IDLE = 3'b000;
    localparam LOAD_A = 3'b001;
    localparam LOAD_B = 3'b010;
    localparam COMPUTE = 3'b011;
    localparam STORE_C = 3'b100;
    localparam DONE_ST = 3'b101;
    
    // Internal counters
    reg [15:0] tile_m, tile_k, tile_n;
    reg [15:0] elem_i, elem_j, elem_k;
    reg [31:0] addr_a, addr_b, addr_c;
    
    // Tile addressing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tile_m <= 0;
            tile_k <= 0;
            tile_n <= 0;
            elem_i <= 0;
            elem_j <= 0;
            elem_k <= 0;
            addr_a <= 0;
            addr_b <= 0;
            addr_c <= 0;
            scratchpad_wr_en <= 0;
            scratchpad_rd_en <= 0;
            mac_enable <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= LOAD_A;
                        tile_m <= 0;
                        tile_k <= 0;
                        tile_n <= 0;
                        done <= 0;
                    end
                end
                
                LOAD_A: begin
                    // Load matrix A tile
                    addr_a <= matrix_a_base + (tile_m * stride_a + elem_i) * DATA_WIDTH/8;
                    scratchpad_wr_addr <= elem_i;
                    scratchpad_wr_data <= {32{8'h00}}; // Placeholder
                    scratchpad_wr_en <= 1;
                    
                    if (elem_i == TILE_SIZE - 1) begin
                        state <= LOAD_B;
                        elem_i <= 0;
                    end else begin
                        elem_i <= elem_i + 1;
                    end
                end
                
                LOAD_B: begin
                    // Load matrix B tile
                    addr_b <= matrix_b_base + (elem_j * stride_b + tile_n) * DATA_WIDTH/8;
                    scratchpad_wr_addr <= TILE_SIZE + elem_j;
                    scratchpad_wr_data <= {32{8'h00}}; // Placeholder
                    scratchpad_wr_en <= 1;
                    
                    if (elem_j == TILE_SIZE - 1) begin
                        state <= COMPUTE;
                        elem_j <= 0;
                    end else begin
                        elem_j <= elem_j + 1;
                    end
                end
                
                COMPUTE: begin
                    // Feed MAC array
                    scratchpad_rd_addr <= elem_i;
                    scratchpad_rd_en <= 1;
                    mac_a_row <= scratchpad_rd_data[TILE_SIZE*DATA_WIDTH-1:0];
                    
                    scratchpad_rd_addr <= TILE_SIZE + elem_j;
                    mac_b_col <= scratchpad_rd_data[TILE_SIZE*DATA_WIDTH-1:0];
                    
                    mac_enable <= 1;
                    
                    if (elem_k == TILE_SIZE - 1) begin
                        state <= STORE_C;
                        elem_k <= 0;
                    end else begin
                        elem_k <= elem_k + 1;
                    end
                end
                
                STORE_C: begin
                    // Store result tile
                    addr_c <= matrix_c_base + (tile_m * stride_c + tile_n) * DATA_WIDTH/8;
                    scratchpad_wr_addr <= 2 * TILE_SIZE + elem_i;
                    scratchpad_wr_data <= {32{8'h00}}; // Placeholder
                    scratchpad_wr_en <= 1;
                    
                    if (elem_i == TILE_SIZE - 1) begin
                        if (tile_n == (n_dim/TILE_SIZE) - 1) begin
                            if (tile_m == (m_dim/TILE_SIZE) - 1) begin
                                state <= DONE_ST;
                            end else begin
                                state <= LOAD_A;
                                tile_m <= tile_m + 1;
                                tile_n <= 0;
                            end
                        end else begin
                            state <= LOAD_B;
                            tile_n <= tile_n + 1;
                        end
                        elem_i <= 0;
                    end else begin
                        elem_i <= elem_i + 1;
                    end
                end
                
                DONE_ST: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
