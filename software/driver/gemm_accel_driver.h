// GEMM Accelerator Driver
// Low-level hardware interface for RISC-V GEMM accelerator

#ifndef GEMM_ACCEL_DRIVER_H
#define GEMM_ACCEL_DRIVER_H

#include <stdint.h>
#include <stdbool.h>

// Register definitions
#define GEMM_ACCEL_BASE_ADDR    0x40000000
#define GEMM_CTRL_REG           (GEMM_ACCEL_BASE_ADDR + 0x00)
#define GEMM_STATUS_REG         (GEMM_ACCEL_BASE_ADDR + 0x04)
#define GEMM_MATRIX_A_ADDR_REG  (GEMM_ACCEL_BASE_ADDR + 0x08)
#define GEMM_MATRIX_B_ADDR_REG  (GEMM_ACCEL_BASE_ADDR + 0x0C)
#define GEMM_MATRIX_C_ADDR_REG  (GEMM_ACCEL_BASE_ADDR + 0x10)
#define GEMM_M_DIM_REG          (GEMM_ACCEL_BASE_ADDR + 0x14)
#define GEMM_K_DIM_REG          (GEMM_ACCEL_BASE_ADDR + 0x18)
#define GEMM_N_DIM_REG          (GEMM_ACCEL_BASE_ADDR + 0x1C)
#define GEMM_DATA_TYPE_REG      (GEMM_ACCEL_BASE_ADDR + 0x20)
#define GEMM_STRIDE_A_REG       (GEMM_ACCEL_BASE_ADDR + 0x24)
#define GEMM_STRIDE_B_REG       (GEMM_ACCEL_BASE_ADDR + 0x28)
#define GEMM_STRIDE_C_REG       (GEMM_ACCEL_BASE_ADDR + 0x2C)

// Control register bits
#define GEMM_CTRL_START         (1 << 0)
#define GEMM_CTRL_RESET         (1 << 1)
#define GEMM_CTRL_IRQ_EN        (1 << 2)

// Status register bits
#define GEMM_STATUS_BUSY        (1 << 0)
#define GEMM_STATUS_DONE        (1 << 1)
#define GEMM_STATUS_ERROR       (1 << 2)

// Data types
#define GEMM_DATA_TYPE_INT8     0
#define GEMM_DATA_TYPE_INT16    1

// Configuration structure
typedef struct {
    uint32_t matrix_a_addr;
    uint32_t matrix_b_addr;
    uint32_t matrix_c_addr;
    uint16_t m_dim;
    uint16_t k_dim;
    uint16_t n_dim;
    uint8_t  data_type;
    uint16_t stride_a;
    uint16_t stride_b;
    uint16_t stride_c;
} gemm_config_t;

// Function prototypes
int gemm_accel_init(void);
int gemm_accel_start(const gemm_config_t* config);
int gemm_accel_wait(void);
int gemm_accel_status(void);
void gemm_accel_reset(void);
bool gemm_accel_is_busy(void);
bool gemm_accel_is_done(void);
bool gemm_accel_has_error(void);

// Utility functions
void gemm_accel_set_interrupt_enable(bool enable);
uint32_t gemm_accel_get_cycle_count(void);

#endif // GEMM_ACCEL_DRIVER_H
