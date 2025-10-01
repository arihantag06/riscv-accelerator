# Build and Test Instructions

## Prerequisites

### Software Requirements
- **Verilog Simulator**: ModelSim/QuestaSim or Verilator
- **FPGA Tools**: Xilinx Vivado or Intel Quartus
- **C Compiler**: GCC with RISC-V toolchain
- **Python**: Python 3.6+ for benchmarking scripts
- **Make**: GNU Make for build automation

### Hardware Requirements
- **FPGA Board**: Xilinx Zynq-7000 or Intel Cyclone V
- **Debug Tools**: ChipScope Pro or SignalTap
- **Power Measurement**: Power analyzer
- **Oscilloscope**: For timing verification

## Build Instructions

### 1. RTL Simulation Build

```bash
# Navigate to project root
cd BTECH-PROJECT

# Create build directory
mkdir -p build/simulation
cd build/simulation

# Run simulation (ModelSim)
make -f ../../testbench/Makefile sim

# Run simulation (Verilator)
make -f ../../testbench/Makefile verilator

# Run specific testbench
make -f ../../testbench/Makefile test_mac_array
make -f ../../testbench/Makefile test_scratchpad
make -f ../../testbench/Makefile test_dma
make -f ../../testbench/Makefile test_riscv_interface
```

### 2. FPGA Implementation Build

```bash
# Navigate to FPGA directory
cd fpga/implementation

# Run implementation (Vivado)
./implement.sh

# Run implementation (Quartus)
./implement.sh quartus

# Check results
ls -la ../results/
```

### 3. Software Build

```bash
# Navigate to software directory
cd software

# Build driver
cd driver
make clean
make

# Build TensorFlow Lite integration
cd ../tflite_integration
make clean
make

# Build benchmarks
cd ../benchmarks
make clean
make
```

## Test Instructions

### 1. Unit Tests

```bash
# Run MAC array tests
cd testbench/unit_tests
make test_mac_array
./mac_array_tb

# Run scratchpad tests
make test_scratchpad
./scratchpad_tb

# Run DMA tests
make test_dma
./dma_tb

# Run RISC-V interface tests
make test_riscv_interface
./riscv_interface_tb
```

### 2. Integration Tests

```bash
# Run integration tests
cd testbench/integration_tests
make test_integration
./integration_tb

# Run software oracle
cd ../software_oracle
make
./software_oracle
```

### 3. Performance Tests

```bash
# Run benchmarking suite
cd software/benchmarks
./run_benchmarks.sh

# Check results
cat results/performance/summary.txt
```

### 4. AI Model Tests

```bash
# Test MNIST model
cd models/mnist
make test_mnist
./mnist_test

# Test CIFAR-10 model
cd ../cifar10
make test_cifar10
./cifar10_test

# Test keyword spotting model
cd ../keyword_spotting
make test_keyword
./keyword_test
```

## Verification Commands

### 1. Coverage Analysis

```bash
# Run coverage analysis
cd testbench
make coverage

# View coverage report
firefox coverage_report.html
```

### 2. Timing Analysis

```bash
# Run timing analysis
cd fpga/implementation
make timing_analysis

# View timing report
cat results/timing_analysis.txt
```

### 3. Power Analysis

```bash
# Run power analysis
cd fpga/implementation
make power_analysis

# View power report
cat results/power_analysis.txt
```

## Debug Instructions

### 1. RTL Debugging

```bash
# Run simulation with waveforms
cd testbench
make sim_debug

# Open waveform viewer
vsim -view waveform.wlf
```

### 2. FPGA Debugging

```bash
# Program FPGA
cd fpga/implementation
make program_fpga

# Open debug tools
make open_debug
```

### 3. Software Debugging

```bash
# Debug driver
cd software/driver
gdb ./gemm_accel_driver

# Debug benchmarks
cd ../benchmarks
gdb ./benchmark_suite
```

## Performance Measurement

### 1. Latency Measurement

```bash
# Measure latency
cd software/benchmarks
./measure_latency.sh

# View results
cat results/latency_measurements.txt
```

### 2. Throughput Measurement

```bash
# Measure throughput
cd software/benchmarks
./measure_throughput.sh

# View results
cat results/throughput_measurements.txt
```

### 3. Power Measurement

```bash
# Measure power
cd fpga/implementation
./measure_power.sh

# View results
cat results/power_measurements.txt
```

## Troubleshooting

### Common Issues

#### 1. Simulation Issues
- **Problem**: Simulation fails to start
- **Solution**: Check simulator installation and license
- **Command**: `which vsim` or `which verilator`

#### 2. Synthesis Issues
- **Problem**: Synthesis fails
- **Solution**: Check constraints and RTL syntax
- **Command**: `make clean && make`

#### 3. Implementation Issues
- **Problem**: Implementation fails
- **Solution**: Check timing constraints and device selection
- **Command**: `make timing_analysis`

#### 4. Software Issues
- **Problem**: Compilation fails
- **Solution**: Check toolchain installation
- **Command**: `riscv64-unknown-elf-gcc --version`

### Debug Tips

#### 1. RTL Debugging
- Use waveform viewer to trace signals
- Add debug prints in testbenches
- Check assertion failures

#### 2. FPGA Debugging
- Use ChipScope for hardware debugging
- Check timing constraints
- Verify clock domains

#### 3. Software Debugging
- Use GDB for step-by-step debugging
- Add printf statements for tracing
- Check memory alignment

## Performance Optimization

### 1. RTL Optimization
- Optimize critical paths
- Reduce resource usage
- Improve timing closure

### 2. Software Optimization
- Optimize memory access patterns
- Use compiler optimizations
- Profile and optimize hotspots

### 3. System Optimization
- Optimize data flow
- Reduce memory bandwidth
- Improve cache utilization

## Quality Assurance

### 1. Code Review
- Review RTL code for best practices
- Check software code quality
- Verify documentation

### 2. Testing
- Run all test suites
- Verify coverage metrics
- Check performance targets

### 3. Validation
- Validate against requirements
- Check against specifications
- Verify compliance

## Conclusion

This build and test guide provides comprehensive instructions for building, testing, and debugging the RISC-V GEMM Accelerator project. Follow these instructions carefully to ensure successful project completion.
