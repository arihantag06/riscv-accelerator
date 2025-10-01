// MAC Array Testbench
// Comprehensive testing of MAC array functionality

`timescale 1ns/1ps

module mac_array_tb;

    // Parameters
    parameter MAC_WIDTH = 8;
    parameter DATA_WIDTH = 8;
    parameter ACC_WIDTH = 32;
    parameter PIPELINE_DEPTH = 3;
    
    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Control signals
    reg enable;
    reg data_type;
    reg clear_acc;
    
    // Data inputs
    reg [MAC_WIDTH*DATA_WIDTH-1:0] matrix_a_row;
    reg [MAC_WIDTH*DATA_WIDTH-1:0] matrix_b_col;
    
    // Outputs
    wire [MAC_WIDTH*MAC_WIDTH*ACC_WIDTH-1:0] accumulators;
    wire valid_out;
    wire [2:0] pipeline_stage;
    
    // Test vectors
    reg [DATA_WIDTH-1:0] test_matrix_a [0:MAC_WIDTH-1];
    reg [DATA_WIDTH-1:0] test_matrix_b [0:MAC_WIDTH-1];
    reg [ACC_WIDTH-1:0] expected_result [0:MAC_WIDTH-1][0:MAC_WIDTH-1];
    
    // Instantiate DUT
    mac_array #(
        .MAC_WIDTH(MAC_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .PIPELINE_DEPTH(PIPELINE_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_type(data_type),
        .clear_acc(clear_acc),
        .matrix_a_row(matrix_a_row),
        .matrix_b_col(matrix_b_col),
        .accumulators(accumulators),
        .valid_out(valid_out),
        .pipeline_stage(pipeline_stage)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        $display("Starting MAC Array Testbench");
        
        // Initialize signals
        rst_n = 0;
        enable = 0;
        data_type = 0; // int8
        clear_acc = 0;
        matrix_a_row = 0;
        matrix_b_col = 0;
        
        // Reset
        #20 rst_n = 1;
        #10;
        
        // Test 1: Basic int8 multiplication
        $display("Test 1: Basic int8 multiplication");
        test_int8_basic();
        
        // Test 2: int16 multiplication
        $display("Test 2: int16 multiplication");
        test_int16_basic();
        
        // Test 3: Accumulation test
        $display("Test 3: Accumulation test");
        test_accumulation();
        
        // Test 4: Pipeline test
        $display("Test 4: Pipeline test");
        test_pipeline();
        
        // Test 5: Saturation test
        $display("Test 5: Saturation test");
        test_saturation();
        
        $display("All tests completed");
        $finish;
    end
    
    // Test 1: Basic int8 multiplication
    task test_int8_basic;
        begin
            data_type = 0; // int8
            clear_acc = 1;
            #10 clear_acc = 0;
            
            // Set test vectors
            test_matrix_a[0] = 8'd2;
            test_matrix_a[1] = 8'd3;
            test_matrix_a[2] = 8'd4;
            test_matrix_a[3] = 8'd5;
            test_matrix_a[4] = 8'd6;
            test_matrix_a[5] = 8'd7;
            test_matrix_a[6] = 8'd8;
            test_matrix_a[7] = 8'd9;
            
            test_matrix_b[0] = 8'd1;
            test_matrix_b[1] = 8'd2;
            test_matrix_b[2] = 8'd3;
            test_matrix_b[3] = 8'd4;
            test_matrix_b[4] = 8'd5;
            test_matrix_b[5] = 8'd6;
            test_matrix_b[6] = 8'd7;
            test_matrix_b[7] = 8'd8;
            
            // Pack into input vectors
            for (int i = 0; i < MAC_WIDTH; i++) begin
                matrix_a_row[i*DATA_WIDTH +: DATA_WIDTH] = test_matrix_a[i];
                matrix_b_col[i*DATA_WIDTH +: DATA_WIDTH] = test_matrix_b[i];
            end
            
            // Enable MAC array
            enable = 1;
            #10;
            
            // Wait for pipeline completion
            wait(valid_out);
            #10;
            
            // Verify results
            for (int i = 0; i < MAC_WIDTH; i++) begin
                for (int j = 0; j < MAC_WIDTH; j++) begin
                    expected_result[i][j] = $signed(test_matrix_a[i]) * $signed(test_matrix_b[j]);
                    if (accumulators[(i*MAC_WIDTH+j)*ACC_WIDTH +: ACC_WIDTH] != expected_result[i][j]) begin
                        $display("ERROR: MAC[%d][%d] = %d, expected %d", 
                                i, j, 
                                accumulators[(i*MAC_WIDTH+j)*ACC_WIDTH +: ACC_WIDTH],
                                expected_result[i][j]);
                    end else begin
                        $display("PASS: MAC[%d][%d] = %d", i, j, expected_result[i][j]);
                    end
                end
            end
            
            enable = 0;
            #20;
        end
    endtask
    
    // Test 2: int16 multiplication
    task test_int16_basic;
        begin
            data_type = 1; // int16
            clear_acc = 1;
            #10 clear_acc = 0;
            
            // Set test vectors for int16
            test_matrix_a[0] = 16'd100;
            test_matrix_a[1] = 16'd200;
            test_matrix_a[2] = 16'd300;
            test_matrix_a[3] = 16'd400;
            test_matrix_a[4] = 16'd500;
            test_matrix_a[5] = 16'd600;
            test_matrix_a[6] = 16'd700;
            test_matrix_a[7] = 16'd800;
            
            test_matrix_b[0] = 16'd10;
            test_matrix_b[1] = 16'd20;
            test_matrix_b[2] = 16'd30;
            test_matrix_b[3] = 16'd40;
            test_matrix_b[4] = 16'd50;
            test_matrix_b[5] = 16'd60;
            test_matrix_b[6] = 16'd70;
            test_matrix_b[7] = 16'd80;
            
            // Pack into input vectors
            for (int i = 0; i < MAC_WIDTH; i++) begin
                matrix_a_row[i*DATA_WIDTH +: DATA_WIDTH] = test_matrix_a[i];
                matrix_b_col[i*DATA_WIDTH +: DATA_WIDTH] = test_matrix_b[i];
            end
            
            // Enable MAC array
            enable = 1;
            #10;
            
            // Wait for pipeline completion
            wait(valid_out);
            #10;
            
            // Verify results
            for (int i = 0; i < MAC_WIDTH; i++) begin
                for (int j = 0; j < MAC_WIDTH; j++) begin
                    expected_result[i][j] = $signed(test_matrix_a[i]) * $signed(test_matrix_b[j]);
                    if (accumulators[(i*MAC_WIDTH+j)*ACC_WIDTH +: ACC_WIDTH] != expected_result[i][j]) begin
                        $display("ERROR: MAC[%d][%d] = %d, expected %d", 
                                i, j, 
                                accumulators[(i*MAC_WIDTH+j)*ACC_WIDTH +: ACC_WIDTH],
                                expected_result[i][j]);
                    end else begin
                        $display("PASS: MAC[%d][%d] = %d", i, j, expected_result[i][j]);
                    end
                end
            end
            
            enable = 0;
            #20;
        end
    endtask
    
    // Test 3: Accumulation test
    task test_accumulation;
        begin
            data_type = 0; // int8
            clear_acc = 1;
            #10 clear_acc = 0;
            
            // First multiplication
            test_matrix_a[0] = 8'd2;
            test_matrix_b[0] = 8'd3;
            matrix_a_row[0*DATA_WIDTH +: DATA_WIDTH] = test_matrix_a[0];
            matrix_b_col[0*DATA_WIDTH +: DATA_WIDTH] = test_matrix_b[0];
            
            enable = 1;
            #10;
            wait(valid_out);
            #10;
            
            // Second multiplication (should accumulate)
            test_matrix_a[0] = 8'd4;
            test_matrix_b[0] = 8'd5;
            matrix_a_row[0*DATA_WIDTH +: DATA_WIDTH] = test_matrix_a[0];
            matrix_b_col[0*DATA_WIDTH +: DATA_WIDTH] = test_matrix_b[0];
            
            #10;
            wait(valid_out);
            #10;
            
            // Verify accumulation: 2*3 + 4*5 = 6 + 20 = 26
            if (accumulators[0*ACC_WIDTH +: ACC_WIDTH] != 26) begin
                $display("ERROR: Accumulation = %d, expected 26", 
                        accumulators[0*ACC_WIDTH +: ACC_WIDTH]);
            end else begin
                $display("PASS: Accumulation = 26");
            end
            
            enable = 0;
            #20;
        end
    endtask
    
    // Test 4: Pipeline test
    task test_pipeline;
        begin
            data_type = 0; // int8
            clear_acc = 1;
            #10 clear_acc = 0;
            
            // Continuous data stream
            enable = 1;
            for (int cycle = 0; cycle < 10; cycle++) begin
                for (int i = 0; i < MAC_WIDTH; i++) begin
                    matrix_a_row[i*DATA_WIDTH +: DATA_WIDTH] = cycle + i;
                    matrix_b_col[i*DATA_WIDTH +: DATA_WIDTH] = cycle + i + 1;
                end
                #10;
            end
            
            // Wait for pipeline to drain
            for (int i = 0; i < PIPELINE_DEPTH; i++) begin
                #10;
            end
            
            enable = 0;
            #20;
            
            $display("Pipeline test completed");
        end
    endtask
    
    // Test 5: Saturation test
    task test_saturation;
        begin
            data_type = 0; // int8
            clear_acc = 1;
            #10 clear_acc = 0;
            
            // Test overflow case
            test_matrix_a[0] = 8'd127; // Max positive int8
            test_matrix_b[0] = 8'd127; // Max positive int8
            matrix_a_row[0*DATA_WIDTH +: DATA_WIDTH] = test_matrix_a[0];
            matrix_b_col[0*DATA_WIDTH +: DATA_WIDTH] = test_matrix_b[0];
            
            enable = 1;
            #10;
            wait(valid_out);
            #10;
            
            // Result should be saturated to max positive 32-bit value
            if (accumulators[0*ACC_WIDTH +: ACC_WIDTH] != 32'h7FFFFFFF) begin
                $display("ERROR: Saturation = %d, expected 0x7FFFFFFF", 
                        accumulators[0*ACC_WIDTH +: ACC_WIDTH]);
            end else begin
                $display("PASS: Saturation = 0x7FFFFFFF");
            end
            
            enable = 0;
            #20;
        end
    endtask

endmodule
