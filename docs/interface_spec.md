# RISC-V Interface Specification

## Custom Instruction Extension

### Instruction Encoding
The custom instruction follows RISC-V custom-0 opcode space:
```
31-25: funct7 (custom)
24-20: rs2
19-15: rs1
14-12: funct3 (000)
11-7:  rd
6-0:   opcode (0001011 - custom-0)
```

### Instruction Semantics
```assembly
matmul rd, rs1, rs2
```
- **rd**: Destination register for result pointer
- **rs1**: Source register containing matrix A configuration pointer
- **rs2**: Source register containing matrix B configuration pointer

### Configuration Structure
```c
typedef struct {
    uint32_t matrix_a_addr;    // Base address of matrix A
    uint32_t matrix_b_addr;    // Base address of matrix B
    uint32_t matrix_c_addr;    // Base address of matrix C (output)
    uint16_t m_dim;           // M dimension
    uint16_t k_dim;           // K dimension
    uint16_t n_dim;           // N dimension
    uint8_t  data_type;       // 0=int8, 1=int16
    uint8_t  reserved;        // Padding
} matmul_config_t;
```

## Memory-Mapped Register Interface

### Register Map
| Offset | Name | Width | Access | Description |
|--------|------|-------|--------|-------------|
| 0x000 | CTRL | 32 | R/W | Control register |
| 0x004 | STATUS | 32 | R | Status register |
| 0x008 | MATRIX_A_ADDR | 32 | R/W | Matrix A base address |
| 0x00C | MATRIX_B_ADDR | 32 | R/W | Matrix B base address |
| 0x010 | MATRIX_C_ADDR | 32 | R/W | Matrix C base address |
| 0x014 | M_DIM | 16 | R/W | M dimension |
| 0x018 | K_DIM | 16 | R/W | K dimension |
| 0x01C | N_DIM | 16 | R/W | N dimension |
| 0x020 | DATA_TYPE | 8 | R/W | Data type (0=int8, 1=int16) |
| 0x024 | STRIDE_A | 16 | R/W | Stride for matrix A |
| 0x028 | STRIDE_B | 16 | R/W | Stride for matrix B |
| 0x02C | STRIDE_C | 16 | R/W | Stride for matrix C |

### Control Register (CTRL)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | START | Start GEMM operation |
| 1 | RESET | Reset accelerator |
| 2 | IRQ_EN | Enable interrupt on completion |
| 3-7 | Reserved | Reserved for future use |

### Status Register (STATUS)
| Bit | Name | Description |
|-----|------|-------------|
| 0 | BUSY | Accelerator is busy |
| 1 | DONE | Operation completed |
| 2 | ERROR | Error occurred |
| 3-7 | Reserved | Reserved for future use |

## Software Interface

### C API Functions
```c
// Initialize accelerator
int matmul_accel_init(void);

// Configure and start GEMM operation
int matmul_accel_start(const matmul_config_t* config);

// Wait for completion
int matmul_accel_wait(void);

// Check status
int matmul_accel_status(void);

// Reset accelerator
void matmul_accel_reset(void);
```

### Usage Example
```c
#include "matmul_accel.h"

int main() {
    matmul_config_t config = {
        .matrix_a_addr = 0x80000000,
        .matrix_b_addr = 0x80001000,
        .matrix_c_addr = 0x80002000,
        .m_dim = 32,
        .k_dim = 32,
        .n_dim = 32,
        .data_type = 0  // int8
    };
    
    matmul_accel_init();
    matmul_accel_start(&config);
    matmul_accel_wait();
    
    return 0;
}
```

## Interrupt Handling
- **IRQ Number**: 7 (configurable)
- **Trigger**: Completion of GEMM operation
- **Handler**: User-defined completion callback

## Error Handling
- **Invalid dimensions**: Returns error if dimensions exceed limits
- **Memory alignment**: Ensures proper alignment for DMA transfers
- **Timeout**: Implements watchdog timer for stuck operations
