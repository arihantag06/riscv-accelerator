# Architecture Specification

## Overview
The Energy-Efficient RISC-V Matrix Multiplication Accelerator is designed to offload GEMM operations from the main RISC-V processor, providing significant speedup for AI inference workloads while maintaining programmability.

## System Architecture

### Core Components

#### 1. MAC Array
- **Configuration**: 8x8 array of multiply-accumulate units
- **Data Types**: Supports int8 and int16 precision
- **Pipeline Depth**: 3-stage pipeline for optimal throughput
- **Accumulation**: 32-bit accumulation with saturation

#### 2. Scratchpad SRAM
- **Size**: 32KB total (16KB per buffer)
- **Organization**: Double-buffered for continuous operation
- **Access Pattern**: Optimized for matrix tile access
- **Bandwidth**: 256 bits per cycle

#### 3. DMA Engine
- **Function**: Manages data movement between main memory and scratchpad
- **Features**: 
  - Programmable stride support
  - Burst transfer optimization
  - Interrupt-driven completion signaling

#### 4. RISC-V Interface
- **Custom Instruction**: Single `matmul` instruction for GEMM invocation
- **Memory-Mapped Registers**: Control and status interface
- **Address Space**: 0x40000000 - 0x40000FFF

## Dataflow Design

### Matrix Blocking Strategy
- **Tile Size**: 8x8 matrices for optimal MAC array utilization
- **Memory Layout**: Row-major ordering for efficient access
- **Stride Handling**: Configurable stride support for various matrix layouts

### Pipeline Organization
```
Input Buffer → MAC Array → Accumulation → Output Buffer
     ↓              ↓           ↓            ↓
   DMA Read    → Pipeline → Saturation → DMA Write
```

## Interface Specification

### Custom Instruction Format
```
matmul rd, rs1, rs2
- rd: Destination register (accumulation result)
- rs1: Source register 1 (matrix A pointer)
- rs2: Source register 2 (matrix B pointer)
```

### Memory-Mapped Registers
| Address | Name | Function |
|---------|------|----------|
| 0x40000000 | CTRL | Control register |
| 0x40000004 | STATUS | Status register |
| 0x40000008 | MATRIX_A_ADDR | Matrix A base address |
| 0x4000000C | MATRIX_B_ADDR | Matrix B base address |
| 0x40000010 | MATRIX_C_ADDR | Matrix C base address |
| 0x40000014 | M_DIM | M dimension |
| 0x40000018 | K_DIM | K dimension |
| 0x4000001C | N_DIM | N dimension |
| 0x40000020 | DATA_TYPE | Data type (0=int8, 1=int16) |

## Performance Targets
- **Throughput**: >100 GOPS for int8 operations
- **Latency**: <1000 cycles for 8x8x8 GEMM
- **Power**: <100mW active power consumption
- **Area**: <50K LUTs on FPGA

## Verification Strategy
1. Unit-level verification for each component
2. Integration testing with software oracle
3. End-to-end testing with real AI models
4. Performance benchmarking against baseline
