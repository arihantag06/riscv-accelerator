// TensorFlow Lite Micro Integration Implementation
// Custom kernel implementation for GEMM accelerator

#include "tflite_gemm_kernel.h"
#include "tensorflow/lite/kernels/internal/common.h"
#include "tensorflow/lite/kernels/internal/quantization_util.h"
#include "tensorflow/lite/kernels/internal/tensor_ctypes.h"
#include "tensorflow/lite/kernels/internal/types.h"
#include "tensorflow/lite/kernels/kernel_util.h"
#include "tensorflow/lite/micro/kernels/kernel_util.h"
#include "tensorflow/lite/micro/micro_log.h"
#include "tensorflow/lite/micro/micro_utils.h"

namespace tflite {
namespace ops {
namespace micro {

// Custom GEMM kernel implementation
TfLiteStatus EvalCustomGemm(TfLiteContext* context, TfLiteNode* node) {
    const TfLiteTensor* input_a = GetInput(context, node, 0);
    const TfLiteTensor* input_b = GetInput(context, node, 1);
    TfLiteTensor* output = GetOutput(context, node, 0);
    
    // Validate tensors
    TfLiteStatus status = gemm_accel::ValidateTensors(input_a, input_b, output);
    if (status != kTfLiteOk) {
        MicroPrintf("Tensor validation failed");
        return status;
    }
    
    // Get tensor dimensions
    const RuntimeShape& input_a_shape = GetTensorShape(input_a);
    const RuntimeShape& input_b_shape = GetTensorShape(input_b);
    const RuntimeShape& output_shape = GetTensorShape(output);
    
    int m = input_a_shape.Dims(0);
    int k = input_a_shape.Dims(1);
    int n = input_b_shape.Dims(1);
    
    MicroPrintf("GEMM dimensions: %dx%dx%d", m, k, n);
    
    // Convert to accelerator configuration
    gemm_config_t config = gemm_accel::ConvertToAccelConfig(
        input_a, input_b, output, nullptr
    );
    
    // Initialize accelerator if not already done
    static bool accel_initialized = false;
    if (!accel_initialized) {
        if (gemm_accel_init() != 0) {
            MicroPrintf("Failed to initialize GEMM accelerator");
            return kTfLiteError;
        }
        accel_initialized = true;
    }
    
    // Start GEMM operation
    if (gemm_accel_start(&config) != 0) {
        MicroPrintf("Failed to start GEMM operation");
        return kTfLiteError;
    }
    
    // Wait for completion
    if (gemm_accel_wait() != 0) {
        MicroPrintf("GEMM operation failed");
        return kTfLiteError;
    }
    
    MicroPrintf("GEMM operation completed successfully");
    return kTfLiteOk;
}

// Register custom GEMM kernel
TfLiteRegistration* Register_CUSTOM_GEMM() {
    static TfLiteRegistration r = {
        nullptr,  // init
        nullptr,  // free
        nullptr,  // prepare
        EvalCustomGemm,  // invoke
    };
    return &r;
}

} // namespace micro
} // namespace ops

namespace gemm_accel {

// Convert TfLiteTensor to accelerator configuration
gemm_config_t ConvertToAccelConfig(
    const TfLiteTensor* input_a,
    const TfLiteTensor* input_b,
    const TfLiteTensor* output,
    const TfLiteGemmParams* params
) {
    gemm_config_t config;
    
    // Set matrix addresses (assuming contiguous memory layout)
    config.matrix_a_addr = (uint32_t)input_a->data.data;
    config.matrix_b_addr = (uint32_t)input_b->data.data;
    config.matrix_c_addr = (uint32_t)output->data.data;
    
    // Set dimensions
    const RuntimeShape& input_a_shape = GetTensorShape(input_a);
    const RuntimeShape& input_b_shape = GetTensorShape(input_b);
    
    config.m_dim = input_a_shape.Dims(0);
    config.k_dim = input_a_shape.Dims(1);
    config.n_dim = input_b_shape.Dims(1);
    
    // Set data type based on tensor type
    if (input_a->type == kTfLiteInt8) {
        config.data_type = GEMM_DATA_TYPE_INT8;
    } else if (input_a->type == kTfLiteInt16) {
        config.data_type = GEMM_DATA_TYPE_INT16;
    } else {
        config.data_type = GEMM_DATA_TYPE_INT8; // Default
    }
    
    // Set strides (assuming row-major layout)
    config.stride_a = config.k_dim;
    config.stride_b = config.n_dim;
    config.stride_c = config.n_dim;
    
    return config;
}

// Validate tensor dimensions and types
TfLiteStatus ValidateTensors(
    const TfLiteTensor* input_a,
    const TfLiteTensor* input_b,
    const TfLiteTensor* output
) {
    // Check for null pointers
    if (input_a == nullptr || input_b == nullptr || output == nullptr) {
        return kTfLiteError;
    }
    
    // Check tensor types
    if (input_a->type != input_b->type) {
        MicroPrintf("Input tensor types must match");
        return kTfLiteError;
    }
    
    if (input_a->type != kTfLiteInt8 && input_a->type != kTfLiteInt16) {
        MicroPrintf("Unsupported tensor type: %d", input_a->type);
        return kTfLiteError;
    }
    
    // Check dimensions
    const RuntimeShape& input_a_shape = GetTensorShape(input_a);
    const RuntimeShape& input_b_shape = GetTensorShape(input_b);
    const RuntimeShape& output_shape = GetTensorShape(output);
    
    if (input_a_shape.DimensionsCount() != 2) {
        MicroPrintf("Input A must be 2D tensor");
        return kTfLiteError;
    }
    
    if (input_b_shape.DimensionsCount() != 2) {
        MicroPrintf("Input B must be 2D tensor");
        return kTfLiteError;
    }
    
    if (output_shape.DimensionsCount() != 2) {
        MicroPrintf("Output must be 2D tensor");
        return kTfLiteError;
    }
    
    // Check dimension compatibility
    int m = input_a_shape.Dims(0);
    int k_a = input_a_shape.Dims(1);
    int k_b = input_b_shape.Dims(0);
    int n = input_b_shape.Dims(1);
    
    if (k_a != k_b) {
        MicroPrintf("Inner dimensions must match: %d != %d", k_a, k_b);
        return kTfLiteError;
    }
    
    // Check output dimensions
    if (output_shape.Dims(0) != m || output_shape.Dims(1) != n) {
        MicroPrintf("Output dimensions mismatch");
        return kTfLiteError;
    }
    
    return kTfLiteOk;
}

// Calculate performance metrics
void CalculatePerformanceMetrics(
    int m, int k, int n,
    uint32_t cycles,
    float* gops,
    float* efficiency
) {
    // Calculate operations (2 * M * K * N for multiply-add)
    float operations = 2.0f * m * k * n;
    
    // Calculate GOPS
    *gops = operations / (cycles * 1e-9f);
    
    // Calculate efficiency (assuming 100 MHz clock)
    float theoretical_max_gops = 100.0f; // 100 GOPS theoretical max
    *efficiency = (*gops / theoretical_max_gops) * 100.0f;
}

} // namespace gemm_accel
} // namespace tflite

// C interface for TensorFlow Lite Micro
extern "C" {

// Register custom GEMM kernel
TfLiteRegistration* Register_CUSTOM_GEMM() {
    return tflite::ops::micro::Register_CUSTOM_GEMM();
}

// Initialize GEMM accelerator
int tflite_gemm_accel_init(void) {
    return gemm_accel_init();
}

// Get performance metrics
void tflite_gemm_get_performance_metrics(
    int m, int k, int n,
    uint32_t cycles,
    float* gops,
    float* efficiency
) {
    tflite::gemm_accel::CalculatePerformanceMetrics(m, k, n, cycles, gops, efficiency);
}

} // extern "C"
