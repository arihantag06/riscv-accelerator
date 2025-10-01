// GEMM Accelerator Driver Implementation
// Low-level hardware interface for RISC-V GEMM accelerator

#include "gemm_accel_driver.h"
#include <stdio.h>
#include <string.h>

// Memory-mapped register access macros
#define REG_READ(addr)          (*(volatile uint32_t*)(addr))
#define REG_WRITE(addr, val)   (*(volatile uint32_t*)(addr) = (val))

// Global variables
static bool driver_initialized = false;
static uint32_t cycle_count_start = 0;

// Initialize the GEMM accelerator
int gemm_accel_init(void) {
    if (driver_initialized) {
        return 0; // Already initialized
    }
    
    // Reset the accelerator
    gemm_accel_reset();
    
    // Wait for reset to complete
    while (gemm_accel_is_busy()) {
        // Wait
    }
    
    driver_initialized = true;
    printf("GEMM Accelerator initialized\n");
    return 0;
}

// Start GEMM operation with given configuration
int gemm_accel_start(const gemm_config_t* config) {
    if (!driver_initialized) {
        printf("ERROR: Driver not initialized\n");
        return -1;
    }
    
    if (config == NULL) {
        printf("ERROR: NULL configuration\n");
        return -1;
    }
    
    // Check if accelerator is busy
    if (gemm_accel_is_busy()) {
        printf("ERROR: Accelerator is busy\n");
        return -1;
    }
    
    // Validate configuration
    if (config->m_dim == 0 || config->k_dim == 0 || config->n_dim == 0) {
        printf("ERROR: Invalid dimensions\n");
        return -1;
    }
    
    if (config->data_type > GEMM_DATA_TYPE_INT16) {
        printf("ERROR: Invalid data type\n");
        return -1;
    }
    
    // Configure registers
    REG_WRITE(GEMM_MATRIX_A_ADDR_REG, config->matrix_a_addr);
    REG_WRITE(GEMM_MATRIX_B_ADDR_REG, config->matrix_b_addr);
    REG_WRITE(GEMM_MATRIX_C_ADDR_REG, config->matrix_c_addr);
    REG_WRITE(GEMM_M_DIM_REG, config->m_dim);
    REG_WRITE(GEMM_K_DIM_REG, config->k_dim);
    REG_WRITE(GEMM_N_DIM_REG, config->n_dim);
    REG_WRITE(GEMM_DATA_TYPE_REG, config->data_type);
    REG_WRITE(GEMM_STRIDE_A_REG, config->stride_a);
    REG_WRITE(GEMM_STRIDE_B_REG, config->stride_b);
    REG_WRITE(GEMM_STRIDE_C_REG, config->stride_c);
    
    // Start operation
    REG_WRITE(GEMM_CTRL_REG, GEMM_CTRL_START);
    
    // Record start time for performance measurement
    cycle_count_start = gemm_accel_get_cycle_count();
    
    printf("GEMM operation started: %dx%dx%d, type=%s\n", 
           config->m_dim, config->k_dim, config->n_dim,
           config->data_type == GEMM_DATA_TYPE_INT8 ? "int8" : "int16");
    
    return 0;
}

// Wait for GEMM operation to complete
int gemm_accel_wait(void) {
    if (!driver_initialized) {
        printf("ERROR: Driver not initialized\n");
        return -1;
    }
    
    // Wait for completion
    while (gemm_accel_is_busy()) {
        // Polling wait - could be replaced with interrupt-driven wait
    }
    
    // Check for errors
    if (gemm_accel_has_error()) {
        printf("ERROR: GEMM operation failed\n");
        return -1;
    }
    
    // Calculate performance metrics
    uint32_t cycle_count_end = gemm_accel_get_cycle_count();
    uint32_t total_cycles = cycle_count_end - cycle_count_start;
    
    printf("GEMM operation completed in %d cycles\n", total_cycles);
    
    return 0;
}

// Check accelerator status
int gemm_accel_status(void) {
    if (!driver_initialized) {
        return -1;
    }
    
    uint32_t status = REG_READ(GEMM_STATUS_REG);
    
    if (status & GEMM_STATUS_ERROR) {
        return -1; // Error
    } else if (status & GEMM_STATUS_DONE) {
        return 1; // Done
    } else if (status & GEMM_STATUS_BUSY) {
        return 0; // Busy
    } else {
        return 2; // Idle
    }
}

// Reset the accelerator
void gemm_accel_reset(void) {
    REG_WRITE(GEMM_CTRL_REG, GEMM_CTRL_RESET);
    
    // Wait for reset to complete
    while (gemm_accel_is_busy()) {
        // Wait
    }
    
    printf("GEMM Accelerator reset\n");
}

// Check if accelerator is busy
bool gemm_accel_is_busy(void) {
    return (REG_READ(GEMM_STATUS_REG) & GEMM_STATUS_BUSY) != 0;
}

// Check if accelerator is done
bool gemm_accel_is_done(void) {
    return (REG_READ(GEMM_STATUS_REG) & GEMM_STATUS_DONE) != 0;
}

// Check if accelerator has error
bool gemm_accel_has_error(void) {
    return (REG_READ(GEMM_STATUS_REG) & GEMM_STATUS_ERROR) != 0;
}

// Set interrupt enable
void gemm_accel_set_interrupt_enable(bool enable) {
    uint32_t ctrl = REG_READ(GEMM_CTRL_REG);
    if (enable) {
        ctrl |= GEMM_CTRL_IRQ_EN;
    } else {
        ctrl &= ~GEMM_CTRL_IRQ_EN;
    }
    REG_WRITE(GEMM_CTRL_REG, ctrl);
}

// Get cycle count (placeholder - would read from cycle counter register)
uint32_t gemm_accel_get_cycle_count(void) {
    // This would typically read from a cycle counter register
    // For now, return a placeholder value
    static uint32_t cycle_count = 0;
    cycle_count += 100; // Simulate cycle counting
    return cycle_count;
}

// Helper function to create configuration
gemm_config_t gemm_create_config(
    uint32_t matrix_a_addr,
    uint32_t matrix_b_addr,
    uint32_t matrix_c_addr,
    uint16_t m_dim,
    uint16_t k_dim,
    uint16_t n_dim,
    uint8_t data_type,
    uint16_t stride_a,
    uint16_t stride_b,
    uint16_t stride_c
) {
    gemm_config_t config;
    config.matrix_a_addr = matrix_a_addr;
    config.matrix_b_addr = matrix_b_addr;
    config.matrix_c_addr = matrix_c_addr;
    config.m_dim = m_dim;
    config.k_dim = k_dim;
    config.n_dim = n_dim;
    config.data_type = data_type;
    config.stride_a = stride_a;
    config.stride_b = stride_b;
    config.stride_c = stride_c;
    return config;
}

// Example usage function
int gemm_example(void) {
    // Initialize accelerator
    if (gemm_accel_init() != 0) {
        return -1;
    }
    
    // Create test matrices (placeholder addresses)
    uint32_t matrix_a_addr = 0x80000000;
    uint32_t matrix_b_addr = 0x80001000;
    uint32_t matrix_c_addr = 0x80002000;
    
    // Create configuration for 8x8x8 int8 GEMM
    gemm_config_t config = gemm_create_config(
        matrix_a_addr, matrix_b_addr, matrix_c_addr,
        8, 8, 8,                    // M, K, N dimensions
        GEMM_DATA_TYPE_INT8,        // int8 data type
        8, 8, 8                     // strides
    );
    
    // Start and wait for completion
    if (gemm_accel_start(&config) != 0) {
        return -1;
    }
    
    if (gemm_accel_wait() != 0) {
        return -1;
    }
    
    printf("GEMM example completed successfully\n");
    return 0;
}
