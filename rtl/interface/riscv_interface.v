// RISC-V Custom Instruction Interface
// Implements matmul instruction and memory-mapped registers

module riscv_interface #(
    parameter REG_ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
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
    input wire [DATA_WIDTH-1:0] reg_wr_data,
    output reg [DATA_WIDTH-1:0] reg_rd_data,
    output reg reg_rd_valid,
    
    // Accelerator control interface
    output reg accel_start,
    output reg accel_reset,
    output reg accel_irq_en,
    input wire accel_busy,
    input wire accel_done,
    input wire accel_error,
    
    // Matrix configuration
    output reg [31:0] matrix_a_addr,
    output reg [31:0] matrix_b_addr,
    output reg [31:0] matrix_c_addr,
    output reg [15:0] m_dim,
    output reg [15:0] k_dim,
    output reg [15:0] n_dim,
    output reg [7:0] data_type,
    output reg [15:0] stride_a,
    output reg [15:0] stride_b,
    output reg [15:0] stride_c,
    
    // Interrupt output
    output reg irq_out
);

    // Register definitions
    localparam REG_CTRL = 8'h00;
    localparam REG_STATUS = 8'h04;
    localparam REG_MATRIX_A_ADDR = 8'h08;
    localparam REG_MATRIX_B_ADDR = 8'h0C;
    localparam REG_MATRIX_C_ADDR = 8'h10;
    localparam REG_M_DIM = 8'h14;
    localparam REG_K_DIM = 8'h18;
    localparam REG_N_DIM = 8'h1C;
    localparam REG_DATA_TYPE = 8'h20;
    localparam REG_STRIDE_A = 8'h24;
    localparam REG_STRIDE_B = 8'h28;
    localparam REG_STRIDE_C = 8'h2C;
    
    // Control register bits
    localparam CTRL_START = 0;
    localparam CTRL_RESET = 1;
    localparam CTRL_IRQ_EN = 2;
    
    // Status register bits
    localparam STATUS_BUSY = 0;
    localparam STATUS_DONE = 1;
    localparam STATUS_ERROR = 2;
    
    // Internal registers
    reg [31:0] ctrl_reg;
    reg [31:0] status_reg;
    reg [31:0] matrix_a_addr_reg;
    reg [31:0] matrix_b_addr_reg;
    reg [31:0] matrix_c_addr_reg;
    reg [15:0] m_dim_reg;
    reg [15:0] k_dim_reg;
    reg [15:0] n_dim_reg;
    reg [7:0] data_type_reg;
    reg [15:0] stride_a_reg;
    reg [15:0] stride_b_reg;
    reg [15:0] stride_c_reg;
    
    // Custom instruction detection
    wire is_matmul_inst;
    wire [31:0] inst_opcode, inst_funct3, inst_funct7;
    wire [4:0] inst_rd, inst_rs1, inst_rs2;
    
    // Instruction decoding
    assign inst_opcode = cpu_instruction[6:0];
    assign inst_funct3 = cpu_instruction[14:12];
    assign inst_funct7 = cpu_instruction[31:25];
    assign inst_rd = cpu_instruction[11:7];
    assign inst_rs1 = cpu_instruction[19:15];
    assign inst_rs2 = cpu_instruction[24:20];
    
    // Detect matmul instruction (custom-0 opcode with specific funct7)
    assign is_matmul_inst = (inst_opcode == 7'b0001011) && // custom-0
                           (inst_funct3 == 3'b000) &&     // funct3 = 000
                           (inst_funct7 == 7'b0000000);   // funct7 = 0000000
    
    // Custom instruction execution
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_ready <= 0;
            cpu_result <= 0;
            accel_start <= 0;
        end else begin
            if (cpu_valid && is_matmul_inst) begin
                // Start accelerator with configuration from rs1 and rs2
                accel_start <= 1;
                cpu_result <= matrix_c_addr_reg; // Return result address
                cpu_ready <= 1;
            end else begin
                accel_start <= 0;
                cpu_ready <= 0;
            end
        end
    end
    
    // Memory-mapped register interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 0;
            matrix_a_addr_reg <= 0;
            matrix_b_addr_reg <= 0;
            matrix_c_addr_reg <= 0;
            m_dim_reg <= 0;
            k_dim_reg <= 0;
            n_dim_reg <= 0;
            data_type_reg <= 0;
            stride_a_reg <= 0;
            stride_b_reg <= 0;
            stride_c_reg <= 0;
            reg_rd_data <= 0;
            reg_rd_valid <= 0;
        end else begin
            // Write operations
            if (reg_wr_en) begin
                case (reg_addr)
                    REG_CTRL: begin
                        ctrl_reg <= reg_wr_data;
                        if (reg_wr_data[CTRL_RESET]) begin
                            // Reset accelerator
                            accel_reset <= 1;
                        end
                    end
                    REG_MATRIX_A_ADDR: matrix_a_addr_reg <= reg_wr_data;
                    REG_MATRIX_B_ADDR: matrix_b_addr_reg <= reg_wr_data;
                    REG_MATRIX_C_ADDR: matrix_c_addr_reg <= reg_wr_data;
                    REG_M_DIM: m_dim_reg <= reg_wr_data[15:0];
                    REG_K_DIM: k_dim_reg <= reg_wr_data[15:0];
                    REG_N_DIM: n_dim_reg <= reg_wr_data[15:0];
                    REG_DATA_TYPE: data_type_reg <= reg_wr_data[7:0];
                    REG_STRIDE_A: stride_a_reg <= reg_wr_data[15:0];
                    REG_STRIDE_B: stride_b_reg <= reg_wr_data[15:0];
                    REG_STRIDE_C: stride_c_reg <= reg_wr_data[15:0];
                endcase
            end
            
            // Read operations
            if (reg_rd_en) begin
                reg_rd_valid <= 1;
                case (reg_addr)
                    REG_CTRL: reg_rd_data <= ctrl_reg;
                    REG_STATUS: reg_rd_data <= status_reg;
                    REG_MATRIX_A_ADDR: reg_rd_data <= matrix_a_addr_reg;
                    REG_MATRIX_B_ADDR: reg_rd_data <= matrix_b_addr_reg;
                    REG_MATRIX_C_ADDR: reg_rd_data <= matrix_c_addr_reg;
                    REG_M_DIM: reg_rd_data <= {16'h0, m_dim_reg};
                    REG_K_DIM: reg_rd_data <= {16'h0, k_dim_reg};
                    REG_N_DIM: reg_rd_data <= {16'h0, n_dim_reg};
                    REG_DATA_TYPE: reg_rd_data <= {24'h0, data_type_reg};
                    REG_STRIDE_A: reg_rd_data <= {16'h0, stride_a_reg};
                    REG_STRIDE_B: reg_rd_data <= {16'h0, stride_b_reg};
                    REG_STRIDE_C: reg_rd_data <= {16'h0, stride_c_reg};
                    default: reg_rd_data <= 32'h0;
                endcase
            end else begin
                reg_rd_valid <= 0;
            end
        end
    end
    
    // Status register update
    always @(*) begin
        status_reg = {29'h0, accel_error, accel_done, accel_busy};
    end
    
    // Output assignments
    assign matrix_a_addr = matrix_a_addr_reg;
    assign matrix_b_addr = matrix_b_addr_reg;
    assign matrix_c_addr = matrix_c_addr_reg;
    assign m_dim = m_dim_reg;
    assign k_dim = k_dim_reg;
    assign n_dim = n_dim_reg;
    assign data_type = data_type_reg;
    assign stride_a = stride_a_reg;
    assign stride_b = stride_b_reg;
    assign stride_c = stride_c_reg;
    assign accel_irq_en = ctrl_reg[CTRL_IRQ_EN];
    
    // Interrupt generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_out <= 0;
        end else begin
            irq_out <= accel_done && ctrl_reg[CTRL_IRQ_EN];
        end
    end

endmodule

// Configuration Loader
// Loads matrix configuration from memory into accelerator registers

module config_loader #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    
    // Control interface
    input wire load_start,
    input wire [ADDR_WIDTH-1:0] config_addr,
    output reg load_done,
    
    // Memory interface
    output reg mem_rd_en,
    output reg [ADDR_WIDTH-1:0] mem_rd_addr,
    input wire [DATA_WIDTH-1:0] mem_rd_data,
    input wire mem_rd_valid,
    
    // Configuration output
    output reg [31:0] matrix_a_addr,
    output reg [31:0] matrix_b_addr,
    output reg [31:0] matrix_c_addr,
    output reg [15:0] m_dim,
    output reg [15:0] k_dim,
    output reg [15:0] n_dim,
    output reg [7:0] data_type,
    output reg [15:0] stride_a,
    output reg [15:0] stride_b,
    output reg [15:0] stride_c,
    output reg config_valid
);

    // State machine
    localparam IDLE = 3'b000;
    localparam LOAD_CONFIG = 3'b001;
    localparam DONE = 3'b010;
    
    reg [2:0] state;
    reg [2:0] config_count;
    
    // Configuration structure (8 words)
    // Word 0: matrix_a_addr
    // Word 1: matrix_b_addr  
    // Word 2: matrix_c_addr
    // Word 3: m_dim, k_dim
    // Word 4: n_dim, data_type
    // Word 5: stride_a, stride_b
    // Word 6: stride_c, reserved
    // Word 7: reserved
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            config_count <= 0;
            load_done <= 0;
            config_valid <= 0;
            mem_rd_en <= 0;
            matrix_a_addr <= 0;
            matrix_b_addr <= 0;
            matrix_c_addr <= 0;
            m_dim <= 0;
            k_dim <= 0;
            n_dim <= 0;
            data_type <= 0;
            stride_a <= 0;
            stride_b <= 0;
            stride_c <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (load_start) begin
                        state <= LOAD_CONFIG;
                        config_count <= 0;
                        mem_rd_addr <= config_addr;
                        mem_rd_en <= 1;
                        load_done <= 0;
                        config_valid <= 0;
                    end
                end
                
                LOAD_CONFIG: begin
                    if (mem_rd_valid) begin
                        case (config_count)
                            3'd0: matrix_a_addr <= mem_rd_data;
                            3'd1: matrix_b_addr <= mem_rd_data;
                            3'd2: matrix_c_addr <= mem_rd_data;
                            3'd3: begin
                                m_dim <= mem_rd_data[15:0];
                                k_dim <= mem_rd_data[31:16];
                            end
                            3'd4: begin
                                n_dim <= mem_rd_data[15:0];
                                data_type <= mem_rd_data[23:16];
                            end
                            3'd5: begin
                                stride_a <= mem_rd_data[15:0];
                                stride_b <= mem_rd_data[31:16];
                            end
                            3'd6: stride_c <= mem_rd_data[15:0];
                        endcase
                        
                        config_count <= config_count + 1;
                        mem_rd_addr <= mem_rd_addr + 4;
                        
                        if (config_count == 3'd6) begin
                            mem_rd_en <= 0;
                            state <= DONE;
                            config_valid <= 1;
                        end
                    end
                end
                
                DONE: begin
                    load_done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
