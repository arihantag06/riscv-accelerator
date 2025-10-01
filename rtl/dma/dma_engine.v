// DMA Engine for efficient data movement
// Handles transfers between main memory and scratchpad

module dma_engine #(
    parameter DATA_WIDTH = 256,        // 256-bit data width
    parameter ADDR_WIDTH = 32,         // 32-bit address space
    parameter SCRATCHPAD_ADDR_WIDTH = 14,
    parameter MAX_BURST_LEN = 16       // Maximum burst length
)(
    input wire clk,
    input wire rst_n,
    
    // Control interface
    input wire dma_start,
    input wire dma_dir,                // 0=mem_to_scratchpad, 1=scratchpad_to_mem
    input wire [ADDR_WIDTH-1:0] mem_addr,
    input wire [SCRATCHPAD_ADDR_WIDTH-1:0] scratchpad_addr,
    input wire [15:0] transfer_len,    // Number of 256-bit words
    input wire [15:0] stride,         // Stride for non-contiguous access
    output reg dma_done,
    output reg dma_busy,
    
    // Memory interface (AXI4-like)
    output reg mem_arvalid,
    output reg [ADDR_WIDTH-1:0] mem_araddr,
    output reg [7:0] mem_arlen,
    output reg [2:0] mem_arsize,
    input wire mem_arready,
    
    output reg mem_rready,
    input wire mem_rvalid,
    input wire [DATA_WIDTH-1:0] mem_rdata,
    input wire mem_rlast,
    
    output reg mem_awvalid,
    output reg [ADDR_WIDTH-1:0] mem_awaddr,
    output reg [7:0] mem_awlen,
    output reg [2:0] mem_awsize,
    input wire mem_awready,
    
    output reg mem_wvalid,
    output reg [DATA_WIDTH-1:0] mem_wdata,
    output reg mem_wlast,
    input wire mem_wready,
    
    input wire mem_bvalid,
    output reg mem_bready,
    
    // Scratchpad interface
    output reg scratchpad_wr_en,
    output reg [SCRATCHPAD_ADDR_WIDTH-1:0] scratchpad_wr_addr,
    output reg [DATA_WIDTH-1:0] scratchpad_wr_data,
    input wire scratchpad_wr_ready,
    
    output reg scratchpad_rd_en,
    output reg [SCRATCHPAD_ADDR_WIDTH-1:0] scratchpad_rd_addr,
    input wire [DATA_WIDTH-1:0] scratchpad_rd_data,
    input wire scratchpad_rd_valid
);

    // State machine
    localparam IDLE = 3'b000;
    localparam READ_REQ = 3'b001;
    localparam READ_DATA = 3'b010;
    localparam WRITE_REQ = 3'b011;
    localparam WRITE_DATA = 3'b100;
    localparam DONE = 3'b101;
    
    // Internal signals
    reg [2:0] state;
    reg [15:0] transfer_count;
    reg [ADDR_WIDTH-1:0] current_mem_addr;
    reg [SCRATCHPAD_ADDR_WIDTH-1:0] current_scratchpad_addr;
    reg [7:0] burst_len;
    
    // Burst length calculation
    always @(*) begin
        if (transfer_len - transfer_count >= MAX_BURST_LEN) begin
            burst_len = MAX_BURST_LEN - 1; // AXI uses len-1
        end else begin
            burst_len = (transfer_len - transfer_count) - 1;
        end
    end
    
    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            transfer_count <= 0;
            current_mem_addr <= 0;
            current_scratchpad_addr <= 0;
            dma_done <= 0;
            dma_busy <= 0;
            
            // Memory interface
            mem_arvalid <= 0;
            mem_araddr <= 0;
            mem_arlen <= 0;
            mem_arsize <= 3'b101; // 256-bit = 32 bytes
            mem_rready <= 0;
            mem_awvalid <= 0;
            mem_awaddr <= 0;
            mem_awlen <= 0;
            mem_awsize <= 3'b101;
            mem_wvalid <= 0;
            mem_wdata <= 0;
            mem_wlast <= 0;
            mem_bready <= 0;
            
            // Scratchpad interface
            scratchpad_wr_en <= 0;
            scratchpad_wr_addr <= 0;
            scratchpad_wr_data <= 0;
            scratchpad_rd_en <= 0;
            scratchpad_rd_addr <= 0;
        end else begin
            case (state)
                IDLE: begin
                    dma_done <= 0;
                    dma_busy <= 0;
                    transfer_count <= 0;
                    
                    if (dma_start) begin
                        state <= dma_dir ? WRITE_REQ : READ_REQ;
                        current_mem_addr <= mem_addr;
                        current_scratchpad_addr <= scratchpad_addr;
                        dma_busy <= 1;
                    end
                end
                
                READ_REQ: begin
                    mem_arvalid <= 1;
                    mem_araddr <= current_mem_addr;
                    mem_arlen <= burst_len;
                    
                    if (mem_arready) begin
                        mem_arvalid <= 0;
                        state <= READ_DATA;
                        mem_rready <= 1;
                    end
                end
                
                READ_DATA: begin
                    if (mem_rvalid && mem_rready) begin
                        // Write to scratchpad
                        scratchpad_wr_en <= 1;
                        scratchpad_wr_addr <= current_scratchpad_addr;
                        scratchpad_wr_data <= mem_rdata;
                        
                        // Update addresses
                        current_mem_addr <= current_mem_addr + 32; // 256-bit = 32 bytes
                        current_scratchpad_addr <= current_scratchpad_addr + 1;
                        transfer_count <= transfer_count + 1;
                        
                        if (mem_rlast || transfer_count == transfer_len - 1) begin
                            mem_rready <= 0;
                            scratchpad_wr_en <= 0;
                            state <= DONE;
                        end
                    end
                end
                
                WRITE_REQ: begin
                    mem_awvalid <= 1;
                    mem_awaddr <= current_mem_addr;
                    mem_awlen <= burst_len;
                    
                    if (mem_awready) begin
                        mem_awvalid <= 0;
                        state <= WRITE_DATA;
                        mem_wvalid <= 1;
                        mem_bready <= 1;
                    end
                end
                
                WRITE_DATA: begin
                    if (mem_wready) begin
                        // Read from scratchpad
                        scratchpad_rd_en <= 1;
                        scratchpad_rd_addr <= current_scratchpad_addr;
                        mem_wdata <= scratchpad_rd_data;
                        
                        // Update addresses
                        current_mem_addr <= current_mem_addr + 32;
                        current_scratchpad_addr <= current_scratchpad_addr + 1;
                        transfer_count <= transfer_count + 1;
                        
                        if (transfer_count == transfer_len - 1) begin
                            mem_wlast <= 1;
                        end
                        
                        if (mem_wlast) begin
                            mem_wvalid <= 0;
                            mem_wlast <= 0;
                            scratchpad_rd_en <= 0;
                            
                            if (mem_bvalid) begin
                                mem_bready <= 0;
                                state <= DONE;
                            end
                        end
                    end
                end
                
                DONE: begin
                    dma_done <= 1;
                    dma_busy <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

// DMA Controller - manages multiple DMA operations
module dma_controller #(
    parameter NUM_CHANNELS = 4,
    parameter DATA_WIDTH = 256,
    parameter ADDR_WIDTH = 32,
    parameter SCRATCHPAD_ADDR_WIDTH = 14
)(
    input wire clk,
    input wire rst_n,
    
    // Channel control
    input wire [NUM_CHANNELS-1:0] channel_start,
    input wire [NUM_CHANNELS-1:0] channel_dir,
    input wire [NUM_CHANNELS*ADDR_WIDTH-1:0] channel_mem_addr,
    input wire [NUM_CHANNELS*SCRATCHPAD_ADDR_WIDTH-1:0] channel_scratchpad_addr,
    input wire [NUM_CHANNELS*16-1:0] channel_transfer_len,
    input wire [NUM_CHANNELS*16-1:0] channel_stride,
    output wire [NUM_CHANNELS-1:0] channel_done,
    output wire [NUM_CHANNELS-1:0] channel_busy,
    
    // Memory interface
    output reg mem_arvalid,
    output reg [ADDR_WIDTH-1:0] mem_araddr,
    output reg [7:0] mem_arlen,
    output reg [2:0] mem_arsize,
    input wire mem_arready,
    
    output reg mem_rready,
    input wire mem_rvalid,
    input wire [DATA_WIDTH-1:0] mem_rdata,
    input wire mem_rlast,
    
    output reg mem_awvalid,
    output reg [ADDR_WIDTH-1:0] mem_awaddr,
    output reg [7:0] mem_awlen,
    output reg [2:0] mem_awsize,
    input wire mem_awready,
    
    output reg mem_wvalid,
    output reg [DATA_WIDTH-1:0] mem_wdata,
    output reg mem_wlast,
    input wire mem_wready,
    
    input wire mem_bvalid,
    output reg mem_bready,
    
    // Scratchpad interface
    output reg scratchpad_wr_en,
    output reg [SCRATCHPAD_ADDR_WIDTH-1:0] scratchpad_wr_addr,
    output reg [DATA_WIDTH-1:0] scratchpad_wr_data,
    input wire scratchpad_wr_ready,
    
    output reg scratchpad_rd_en,
    output reg [SCRATCHPAD_ADDR_WIDTH-1:0] scratchpad_rd_addr,
    input wire [DATA_WIDTH-1:0] scratchpad_rd_data,
    input wire scratchpad_rd_valid
);

    // Channel arbitration
    reg [2:0] active_channel;
    reg [NUM_CHANNELS-1:0] channel_request;
    wire [NUM_CHANNELS-1:0] channel_grant;
    
    // Round-robin arbiter
    round_robin_arbiter #(
        .NUM_REQUESTS(NUM_CHANNELS)
    ) arbiter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .requests(channel_request),
        .grant(channel_grant)
    );
    
    // Channel multiplexing
    wire [ADDR_WIDTH-1:0] selected_mem_addr;
    wire [SCRATCHPAD_ADDR_WIDTH-1:0] selected_scratchpad_addr;
    wire [15:0] selected_transfer_len;
    wire [15:0] selected_stride;
    wire selected_dir;
    
    // Multiplexer for channel selection
    assign selected_mem_addr = channel_mem_addr[active_channel*ADDR_WIDTH +: ADDR_WIDTH];
    assign selected_scratchpad_addr = channel_scratchpad_addr[active_channel*SCRATCHPAD_ADDR_WIDTH +: SCRATCHPAD_ADDR_WIDTH];
    assign selected_transfer_len = channel_transfer_len[active_channel*16 +: 16];
    assign selected_stride = channel_stride[active_channel*16 +: 16];
    assign selected_dir = channel_dir[active_channel];
    
    // Instantiate DMA engine
    dma_engine dma_inst (
        .clk(clk),
        .rst_n(rst_n),
        .dma_start(channel_grant[active_channel] && channel_start[active_channel]),
        .dma_dir(selected_dir),
        .mem_addr(selected_mem_addr),
        .scratchpad_addr(selected_scratchpad_addr),
        .transfer_len(selected_transfer_len),
        .stride(selected_stride),
        .dma_done(channel_done[active_channel]),
        .dma_busy(channel_busy[active_channel]),
        .mem_arvalid(mem_arvalid),
        .mem_araddr(mem_araddr),
        .mem_arlen(mem_arlen),
        .mem_arsize(mem_arsize),
        .mem_arready(mem_arready),
        .mem_rready(mem_rready),
        .mem_rvalid(mem_rvalid),
        .mem_rdata(mem_rdata),
        .mem_rlast(mem_rlast),
        .mem_awvalid(mem_awvalid),
        .mem_awaddr(mem_awaddr),
        .mem_awlen(mem_awlen),
        .mem_awsize(mem_awsize),
        .mem_awready(mem_awready),
        .mem_wvalid(mem_wvalid),
        .mem_wdata(mem_wdata),
        .mem_wlast(mem_wlast),
        .mem_wready(mem_wready),
        .mem_bvalid(mem_bvalid),
        .mem_bready(mem_bready),
        .scratchpad_wr_en(scratchpad_wr_en),
        .scratchpad_wr_addr(scratchpad_wr_addr),
        .scratchpad_wr_data(scratchpad_wr_data),
        .scratchpad_wr_ready(scratchpad_wr_ready),
        .scratchpad_rd_en(scratchpad_rd_en),
        .scratchpad_rd_addr(scratchpad_rd_addr),
        .scratchpad_rd_data(scratchpad_rd_data),
        .scratchpad_rd_valid(scratchpad_rd_valid)
    );
    
    // Channel request generation
    always @(*) begin
        channel_request = channel_start & ~channel_busy;
    end

endmodule

// Round-robin arbiter
module round_robin_arbiter #(
    parameter NUM_REQUESTS = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [NUM_REQUESTS-1:0] requests,
    output reg [NUM_REQUESTS-1:0] grant
);

    reg [NUM_REQUESTS-1:0] last_grant;
    reg [NUM_REQUESTS-1:0] grant_mask;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_grant <= 1;
            grant <= 0;
        end else begin
            // Create mask for round-robin
            grant_mask = {last_grant[NUM_REQUESTS-2:0], 1'b0};
            
            // Find next grant
            if (requests & grant_mask) begin
                grant <= requests & grant_mask;
            end else if (requests) begin
                grant <= requests & ~grant_mask;
            end else begin
                grant <= 0;
            end
            
            // Update last grant
            if (grant) begin
                last_grant <= grant;
            end
        end
    end

endmodule
