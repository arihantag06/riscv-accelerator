// TensorFlow Lite Micro Integration
// Custom kernel implementation for GEMM accelerator

#ifndef TFLITE_GEMM_KERNEL_H
#define TFLITE_GEMM_KERNEL_H

#include "tensorflow/lite/micro/kernels/kernel_util.h"
#include "tensorflow/lite/micro/micro_log.h"
#include "tensorflow/lite/micro/micro_utils.h"
#include "gemm_accel_driver.h"

// TensorFlow Lite Micro context
namespace tflite {
namespace ops {
namespace micro {

// Custom GEMM kernel registration
TfLiteRegistration* Register_CUSTOM_GEMM();

// GEMM kernel implementation
TfLiteStatus EvalCustomGemm(TfLiteContext* context, TfLiteNode* node);

} // namespace micro
} // namespace ops
} // namespace tflite

// Helper functions for TensorFlow Lite integration
namespace tflite {
namespace gemm_accel {

// Convert TfLiteTensor to accelerator configuration
gemm_config_t ConvertToAccelConfig(
    const TfLiteTensor* input_a,
    const TfLiteTensor* input_b,
    const TfLiteTensor* output,
    const TfLiteGemmParams* params
);

// Validate tensor dimensions and types
TfLiteStatus ValidateTensors(
    const TfLiteTensor* input_a,
    const TfLiteTensor* input_b,
    const TfLiteTensor* output
);

// Calculate performance metrics
void CalculatePerformanceMetrics(
    int m, int k, int n,
    uint32_t cycles,
    float* gops,
    float* efficiency
);

} // namespace gemm_accel
} // namespace tflite

#endif // TFLITE_GEMM_KERNEL_H
