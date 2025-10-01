// Software Oracle - Reference Implementation
// Provides golden reference for verification

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

// Matrix multiplication reference implementation
void matrix_multiply_int8(
    const int8_t* A, const int8_t* B, int32_t* C,
    int M, int K, int N,
    int stride_a, int stride_b, int stride_c
) {
    for (int m = 0; m < M; m++) {
        for (int n = 0; n < N; n++) {
            int32_t sum = 0;
            for (int k = 0; k < K; k++) {
                sum += (int32_t)A[m * stride_a + k] * (int32_t)B[k * stride_b + n];
            }
            C[m * stride_c + n] = sum;
        }
    }
}

void matrix_multiply_int16(
    const int16_t* A, const int16_t* B, int32_t* C,
    int M, int K, int N,
    int stride_a, int stride_b, int stride_c
) {
    for (int m = 0; m < M; m++) {
        for (int n = 0; n < N; n++) {
            int32_t sum = 0;
            for (int k = 0; k < K; k++) {
                sum += (int32_t)A[m * stride_a + k] * (int32_t)B[k * stride_b + n];
            }
            C[m * stride_c + n] = sum;
        }
    }
}

// Generate random test matrices
void generate_test_matrices_int8(int8_t* A, int8_t* B, int M, int K, int N) {
    for (int i = 0; i < M * K; i++) {
        A[i] = (int8_t)(rand() % 256 - 128);
    }
    for (int i = 0; i < K * N; i++) {
        B[i] = (int16_t)(rand() % 256 - 128);
    }
}

void generate_test_matrices_int16(int16_t* A, int16_t* B, int M, int K, int N) {
    for (int i = 0; i < M * K; i++) {
        A[i] = (int16_t)(rand() % 65536 - 32768);
    }
    for (int i = 0; i < K * N; i++) {
        B[i] = (int16_t)(rand() % 65536 - 32768);
    }
}

// Compare results
int compare_results(const int32_t* C_hw, const int32_t* C_ref, int M, int N) {
    int errors = 0;
    for (int i = 0; i < M * N; i++) {
        if (C_hw[i] != C_ref[i]) {
            printf("Error at index %d: HW=%d, REF=%d\n", i, C_hw[i], C_ref[i]);
            errors++;
        }
    }
    return errors;
}

// Test cases
typedef struct {
    int M, K, N;
    int data_type; // 0=int8, 1=int16
    char* name;
} test_case_t;

int main() {
    printf("Software Oracle for GEMM Accelerator Verification\n");
    printf("================================================\n");
    
    // Test cases
    test_case_t test_cases[] = {
        {8, 8, 8, 0, "8x8x8 int8"},
        {16, 16, 16, 0, "16x16x16 int8"},
        {32, 32, 32, 0, "32x32x32 int8"},
        {8, 8, 8, 1, "8x8x8 int16"},
        {16, 16, 16, 1, "16x16x16 int16"},
        {32, 32, 32, 1, "32x32x32 int16"},
        {64, 64, 64, 0, "64x64x64 int8"},
        {128, 128, 128, 0, "128x128x128 int8"}
    };
    
    int num_tests = sizeof(test_cases) / sizeof(test_case_t);
    int total_errors = 0;
    
    for (int t = 0; t < num_tests; t++) {
        test_case_t* tc = &test_cases[t];
        printf("\nTest %d: %s\n", t+1, tc->name);
        
        if (tc->data_type == 0) {
            // int8 test
            int8_t* A = malloc(tc->M * tc->K * sizeof(int8_t));
            int8_t* B = malloc(tc->K * tc->N * sizeof(int8_t));
            int32_t* C_hw = malloc(tc->M * tc->N * sizeof(int32_t));
            int32_t* C_ref = malloc(tc->M * tc->N * sizeof(int32_t));
            
            generate_test_matrices_int8(A, B, tc->M, tc->K, tc->N);
            
            // Reference computation
            matrix_multiply_int8(A, B, C_ref, tc->M, tc->K, tc->N, tc->K, tc->N, tc->N);
            
            // Hardware computation (placeholder - would interface with accelerator)
            memset(C_hw, 0, tc->M * tc->N * sizeof(int32_t));
            // TODO: Interface with hardware accelerator
            
            // Compare results
            int errors = compare_results(C_hw, C_ref, tc->M, tc->N);
            total_errors += errors;
            
            printf("Errors: %d\n", errors);
            
            free(A);
            free(B);
            free(C_hw);
            free(C_ref);
        } else {
            // int16 test
            int16_t* A = malloc(tc->M * tc->K * sizeof(int16_t));
            int16_t* B = malloc(tc->K * tc->N * sizeof(int16_t));
            int32_t* C_hw = malloc(tc->M * tc->N * sizeof(int32_t));
            int32_t* C_ref = malloc(tc->M * tc->N * sizeof(int32_t));
            
            generate_test_matrices_int16(A, B, tc->M, tc->K, tc->N);
            
            // Reference computation
            matrix_multiply_int16(A, B, C_ref, tc->M, tc->K, tc->N, tc->K, tc->N, tc->N);
            
            // Hardware computation (placeholder)
            memset(C_hw, 0, tc->M * tc->N * sizeof(int32_t));
            // TODO: Interface with hardware accelerator
            
            // Compare results
            int errors = compare_results(C_hw, C_ref, tc->M, tc->N);
            total_errors += errors;
            
            printf("Errors: %d\n", errors);
            
            free(A);
            free(B);
            free(C_hw);
            free(C_ref);
        }
    }
    
    printf("\n================================================\n");
    printf("Total errors: %d\n", total_errors);
    if (total_errors == 0) {
        printf("All tests PASSED!\n");
    } else {
        printf("Some tests FAILED!\n");
    }
    
    return total_errors;
}
