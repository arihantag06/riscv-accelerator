// MAC Array Module - 8x8 array of multiply-accumulate units
// Supports int8 and int16 data types with 32-bit accumulation

module mac_array #(
    parameter MAC_WIDTH = 8,           // 8x8 MAC array
    parameter DATA_WIDTH = 8,          // Input data width (8 or 16)
    parameter ACC_WIDTH = 32,         // Accumulator width
    parameter PIPELINE_DEPTH = 3      // Pipeline stages
)(
    input wire clk,
    input wire rst_n,
    
    // Control signals
    input wire enable,
    input wire data_type,             // 0=int8, 1=int16
    input wire clear_acc,             // Clear accumulators
    
    // Data inputs
    input wire [MAC_WIDTH*DATA_WIDTH-1:0] matrix_a_row,
    input wire [MAC_WIDTH*DATA_WIDTH-1:0] matrix_b_col,
    
    // Accumulator outputs
    output reg [MAC_WIDTH*MAC_WIDTH*ACC_WIDTH-1:0] accumulators,
    
    // Pipeline control
    output reg valid_out,
    output reg [2:0] pipeline_stage
);

    // Internal signals
    wire [MAC_WIDTH*MAC_WIDTH*DATA_WIDTH-1:0] mult_results;
    wire [MAC_WIDTH*MAC_WIDTH*ACC_WIDTH-1:0] add_results;
    reg [MAC_WIDTH*MAC_WIDTH*ACC_WIDTH-1:0] accum_regs;
    
    // Pipeline registers
    reg [PIPELINE_DEPTH-1:0] valid_pipe;
    reg [MAC_WIDTH*MAC_WIDTH*ACC_WIDTH-1:0] accum_pipe [PIPELINE_DEPTH-1:0];
    
    // Generate MAC units
    genvar i, j;
    generate
        for (i = 0; i < MAC_WIDTH; i = i + 1) begin : gen_mac_row
            for (j = 0; j < MAC_WIDTH; j = j + 1) begin : gen_mac_col
                // Instantiate MAC unit
                mac_unit #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) mac_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .enable(enable),
                    .data_type(data_type),
                    .clear_acc(clear_acc),
                    .a(matrix_a_row[i*DATA_WIDTH +: DATA_WIDTH]),
                    .b(matrix_b_col[j*DATA_WIDTH +: DATA_WIDTH]),
                    .accum_in(accum_regs[(i*MAC_WIDTH+j)*ACC_WIDTH +: ACC_WIDTH]),
                    .accum_out(add_results[(i*MAC_WIDTH+j)*ACC_WIDTH +: ACC_WIDTH])
                );
            end
        end
    endgenerate
    
    // Pipeline implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe <= 0;
            accum_regs <= 0;
            valid_out <= 0;
            pipeline_stage <= 0;
            for (int k = 0; k < PIPELINE_DEPTH; k++) begin
                accum_pipe[k] <= 0;
            end
        end else begin
            // Pipeline shift
            valid_pipe <= {valid_pipe[PIPELINE_DEPTH-2:0], enable};
            accum_pipe[0] <= add_results;
            for (int k = 1; k < PIPELINE_DEPTH; k++) begin
                accum_pipe[k] <= accum_pipe[k-1];
            end
            
            // Update accumulators
            if (enable) begin
                accum_regs <= add_results;
            end
            
            // Output signals
            valid_out <= valid_pipe[PIPELINE_DEPTH-1];
            accumulators <= accum_pipe[PIPELINE_DEPTH-1];
            pipeline_stage <= valid_pipe;
        end
    end

endmodule

// Individual MAC unit
module mac_unit #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire data_type,     // 0=int8, 1=int16
    input wire clear_acc,
    input wire [DATA_WIDTH-1:0] a,
    input wire [DATA_WIDTH-1:0] b,
    input wire [ACC_WIDTH-1:0] accum_in,
    output reg [ACC_WIDTH-1:0] accum_out
);

    // Internal signals
    wire [DATA_WIDTH*2-1:0] mult_result;
    wire [ACC_WIDTH-1:0] mult_extended;
    wire [ACC_WIDTH-1:0] add_result;
    wire [ACC_WIDTH-1:0] saturated_result;
    
    // Multiplication
    assign mult_result = $signed(a) * $signed(b);
    
    // Sign extension based on data type
    assign mult_extended = data_type ? 
        {{(ACC_WIDTH-32){mult_result[31]}}, mult_result} :  // int16
        {{(ACC_WIDTH-16){mult_result[15]}}, mult_result};   // int8
    
    // Addition
    assign add_result = mult_extended + accum_in;
    
    // Saturation logic
    saturation_unit #(
        .ACC_WIDTH(ACC_WIDTH)
    ) sat_inst (
        .data_in(add_result),
        .data_out(saturated_result)
    );
    
    // Register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_out <= 0;
        end else if (clear_acc) begin
            accum_out <= 0;
        end else if (enable) begin
            accum_out <= saturated_result;
        end
    end

endmodule

// Saturation unit for 32-bit accumulation
module saturation_unit #(
    parameter ACC_WIDTH = 32
)(
    input wire [ACC_WIDTH-1:0] data_in,
    output reg [ACC_WIDTH-1:0] data_out
);

    always @(*) begin
        // Check for overflow/underflow
        if (data_in[ACC_WIDTH-1:ACC_WIDTH-2] == 2'b01) begin
            // Positive overflow - saturate to max positive
            data_out = {1'b0, {(ACC_WIDTH-1){1'b1}}};
        end else if (data_in[ACC_WIDTH-1:ACC_WIDTH-2] == 2'b10) begin
            // Negative overflow - saturate to max negative
            data_out = {1'b1, {(ACC_WIDTH-1){1'b0}}};
        end else begin
            // No overflow
            data_out = data_in;
        end
    end

endmodule
