// Top-level GEMM Accelerator Integration
// Integrates all components: MAC array, scratchpad, DMA, and RISC-V interface

module gemm_accelerator_top #(
    parameter MAC_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32,
    parameter SCRATCHPAD_SIZE = 16384,
    parameter SCRATCHPAD_ADDR_WIDTH = 14,
    parameter REG_ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    
    // RISC-V CPU interface
    input wire [31:0] cpu_pc,
    input wire [31:0] cpu_instruction,
    input wire cpu_valid,
    output reg cpu_ready,
    output reg [31:0] cpu_result,
    
    // Memory-mapped register interface
    input wire reg_rd_en,
    input wire reg_wr_en,
    input wire [REG_ADDR_WIDTH-1:0] reg_addr,
    input wire [31:0] reg_wr_data,
    output reg [31:0] reg_rd_data,
    output reg reg_rd_valid,
    
    // Memory interface (AXI4-like)
    output reg mem_arvalid,
    output reg [31:0] mem_araddr,
    output reg [7:0] mem_arlen,
    output reg [2:0] mem_arsize,
    input wire mem_arready,
    
    output reg mem_rready,
    input wire mem_rvalid,
    input wire [255:0] mem_rdata,
    input wire mem_rlast,
    
    output reg mem_awvalid,
    output reg [31:0] mem_awaddr,
    output reg [7:0] mem_awlen,
    output reg [2:0] mem_awsize,
    input wire mem_awready,
    
    output reg mem_wvalid,
    output reg [255:0] mem_wdata,
    output reg mem_wlast,
    input wire mem_wready,
    
    input wire mem_bvalid,
    output reg mem_bready,
    
    // Interrupt output
    output reg irq_out
);

    // Internal signals
    wire accel_start, accel_reset, accel_irq_en;
    wire accel_busy, accel_done, accel_error;
    wire [31:0] matrix_a_addr, matrix_b_addr, matrix_c_addr;
    wire [15:0] m_dim, k_dim, n_dim;
    wire [7:0] data_type;
    wire [15:0] stride_a, stride_b, stride_c;
    
    // MAC array interface
    wire mac_enable, mac_clear_acc;
    wire [MAC_WIDTH*DATA_WIDTH-1:0] mac_a_row, mac_b_col;
    wire [MAC_WIDTH*MAC_WIDTH*ACC_WIDTH-1:0] mac_accumulators;
    wire mac_valid_out;
    wire [2:0] mac_pipeline_stage;
    
    // Scratchpad interface
    wire scratchpad_wr_en;
    wire [SCRATCHPAD_ADDR_WIDTH-1:0] scratchpad_wr_addr;
    wire [255:0] scratchpad_wr_data;
    wire scratchpad_wr_ready;
    
    wire scratchpad_rd_en;
    wire [SCRATCHPAD_ADDR_WIDTH-1:0] scratchpad_rd_addr;
    wire [255:0] scratchpad_rd_data;
    wire scratchpad_rd_valid;
    
    // DMA interface
    wire dma_start, dma_dir;
    wire [31:0] dma_mem_addr;
    wire [SCRATCHPAD_ADDR_WIDTH-1:0] dma_scratchpad_addr;
    wire [15:0] dma_transfer_len, dma_stride;
    wire dma_done, dma_busy;
    
    // Matrix access controller interface
    wire mac_controller_start;
    wire mac_controller_done;
    wire [2:0] mac_controller_state;
    
    // Instantiate RISC-V interface
    riscv_interface riscv_if_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_pc(cpu_pc),
        .cpu_instruction(cpu_instruction),
        .cpu_valid(cpu_valid),
        .cpu_ready(cpu_ready),
        .cpu_result(cpu_result),
        .reg_rd_en(reg_rd_en),
        .reg_wr_en(reg_wr_en),
        .reg_addr(reg_addr),
        .reg_wr_data(reg_wr_data),
        .reg_rd_data(reg_rd_data),
        .reg_rd_valid(reg_rd_valid),
        .accel_start(accel_start),
        .accel_reset(accel_reset),
        .accel_irq_en(accel_irq_en),
        .accel_busy(accel_busy),
        .accel_done(accel_done),
        .accel_error(accel_error),
        .matrix_a_addr(matrix_a_addr),
        .matrix_b_addr(matrix_b_addr),
        .matrix_c_addr(matrix_c_addr),
        .m_dim(m_dim),
        .k_dim(k_dim),
        .n_dim(n_dim),
        .data_type(data_type),
        .stride_a(stride_a),
        .stride_b(stride_b),
        .stride_c(stride_c),
        .irq_out(irq_out)
    );
    
    // Instantiate MAC array
    mac_array mac_array_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(mac_enable),
        .data_type(data_type),
        .clear_acc(mac_clear_acc),
        .matrix_a_row(mac_a_row),
        .matrix_b_col(mac_b_col),
        .accumulators(mac_accumulators),
        .valid_out(mac_valid_out),
        .pipeline_stage(mac_pipeline_stage)
    );
    
    // Instantiate scratchpad SRAM
    scratchpad_sram scratchpad_inst (
        .clk(clk),
        .rst_n(rst_n),
        .buffer_select(1'b0), // Single buffer for now
        .buffer_swap(1'b0),
        .rd_en(scratchpad_rd_en),
        .rd_addr(scratchpad_rd_addr),
        .rd_data(scratchpad_rd_data),
        .rd_valid(scratchpad_rd_valid),
        .wr_en(scratchpad_wr_en),
        .wr_addr(scratchpad_wr_addr),
        .wr_data(scratchpad_wr_data),
        .wr_ready(scratchpad_wr_ready),
        .dma_rd_en(dma_rd_en),
        .dma_rd_addr(dma_rd_addr),
        .dma_rd_data(dma_rd_data),
        .dma_rd_valid(dma_rd_valid),
        .dma_wr_en(dma_wr_en),
        .dma_wr_addr(dma_wr_addr),
        .dma_wr_data(dma_wr_data),
        .dma_wr_ready(dma_wr_ready)
    );
    
    // Instantiate DMA engine
    dma_engine dma_inst (
        .clk(clk),
        .rst_n(rst_n),
        .dma_start(dma_start),
        .dma_dir(dma_dir),
        .mem_addr(dma_mem_addr),
        .scratchpad_addr(dma_scratchpad_addr),
        .transfer_len(dma_transfer_len),
        .stride(dma_stride),
        .dma_done(dma_done),
        .dma_busy(dma_busy),
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
        .scratchpad_wr_en(dma_wr_en),
        .scratchpad_wr_addr(dma_wr_addr),
        .scratchpad_wr_data(dma_wr_data),
        .scratchpad_wr_ready(dma_wr_ready),
        .scratchpad_rd_en(dma_rd_en),
        .scratchpad_rd_addr(dma_rd_addr),
        .scratchpad_rd_data(dma_rd_data),
        .scratchpad_rd_valid(dma_rd_valid)
    );
    
    // Instantiate matrix access controller
    matrix_access_controller mac_controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(mac_controller_start),
        .m_dim(m_dim),
        .k_dim(k_dim),
        .n_dim(n_dim),
        .stride_a(stride_a),
        .stride_b(stride_b),
        .stride_c(stride_c),
        .matrix_a_base(matrix_a_addr),
        .matrix_b_base(matrix_b_addr),
        .matrix_c_base(matrix_c_addr),
        .scratchpad_wr_en(scratchpad_wr_en),
        .scratchpad_wr_addr(scratchpad_wr_addr),
        .scratchpad_wr_data(scratchpad_wr_data),
        .scratchpad_wr_ready(scratchpad_wr_ready),
        .scratchpad_rd_en(scratchpad_rd_en),
        .scratchpad_rd_addr(scratchpad_rd_addr),
        .scratchpad_rd_data(scratchpad_rd_data),
        .scratchpad_rd_valid(scratchpad_rd_valid),
        .mac_enable(mac_enable),
        .mac_a_row(mac_a_row),
        .mac_b_col(mac_b_col),
        .done(mac_controller_done),
        .state(mac_controller_state)
    );
    
    // Control logic
    reg [2:0] control_state;
    localparam IDLE = 3'b000;
    localparam LOAD_MATRIX_A = 3'b001;
    localparam LOAD_MATRIX_B = 3'b010;
    localparam COMPUTE = 3'b011;
    localparam STORE_MATRIX_C = 3'b100;
    localparam DONE = 3'b101;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_state <= IDLE;
            mac_controller_start <= 0;
            dma_start <= 0;
            accel_busy <= 0;
            accel_done <= 0;
            accel_error <= 0;
        end else begin
            case (control_state)
                IDLE: begin
                    if (accel_start) begin
                        control_state <= LOAD_MATRIX_A;
                        accel_busy <= 1;
                        accel_done <= 0;
                        accel_error <= 0;
                    end
                end
                
                LOAD_MATRIX_A: begin
                    // Configure DMA to load matrix A
                    dma_start <= 1;
                    dma_dir <= 0; // mem to scratchpad
                    dma_mem_addr <= matrix_a_addr;
                    dma_scratchpad_addr <= 0;
                    dma_transfer_len <= (m_dim * k_dim * DATA_WIDTH) / 256;
                    dma_stride <= stride_a;
                    
                    if (dma_done) begin
                        dma_start <= 0;
                        control_state <= LOAD_MATRIX_B;
                    end
                end
                
                LOAD_MATRIX_B: begin
                    // Configure DMA to load matrix B
                    dma_start <= 1;
                    dma_dir <= 0; // mem to scratchpad
                    dma_mem_addr <= matrix_b_addr;
                    dma_scratchpad_addr <= SCRATCHPAD_SIZE/2; // Second half
                    dma_transfer_len <= (k_dim * n_dim * DATA_WIDTH) / 256;
                    dma_stride <= stride_b;
                    
                    if (dma_done) begin
                        dma_start <= 0;
                        control_state <= COMPUTE;
                        mac_controller_start <= 1;
                    end
                end
                
                COMPUTE: begin
                    mac_controller_start <= 0;
                    if (mac_controller_done) begin
                        control_state <= STORE_MATRIX_C;
                    end
                end
                
                STORE_MATRIX_C: begin
                    // Configure DMA to store matrix C
                    dma_start <= 1;
                    dma_dir <= 1; // scratchpad to mem
                    dma_mem_addr <= matrix_c_addr;
                    dma_scratchpad_addr <= 0; // Results stored here
                    dma_transfer_len <= (m_dim * n_dim * DATA_WIDTH) / 256;
                    dma_stride <= stride_c;
                    
                    if (dma_done) begin
                        dma_start <= 0;
                        control_state <= DONE;
                    end
                end
                
                DONE: begin
                    accel_busy <= 0;
                    accel_done <= 1;
                    control_state <= IDLE;
                end
            endcase
        end
    end
    
    // MAC clear accumulator control
    assign mac_clear_acc = (control_state == COMPUTE) && (mac_controller_state == 3'b000);

endmodule
