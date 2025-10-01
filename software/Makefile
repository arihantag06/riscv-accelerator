# Makefile for Software Compilation

# Configuration
CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS = -lm
TARGET_DIR = ../results

# Source directories
DRIVER_DIR = driver
TFLITE_DIR = tflite_integration
BENCHMARK_DIR = benchmarks

# Driver sources
DRIVER_SOURCES = $(DRIVER_DIR)/gemm_accel_driver.c
DRIVER_HEADERS = $(DRIVER_DIR)/gemm_accel_driver.h
DRIVER_TARGET = $(TARGET_DIR)/gemm_accel_driver

# TensorFlow Lite sources
TFLITE_SOURCES = $(TFLITE_DIR)/tflite_gemm_kernel.cpp
TFLITE_HEADERS = $(TFLITE_DIR)/tflite_gemm_kernel.h
TFLITE_TARGET = $(TARGET_DIR)/tflite_gemm_kernel

# Benchmark sources
BENCHMARK_SOURCES = $(BENCHMARK_DIR)/benchmark_suite.c
BENCHMARK_TARGET = $(TARGET_DIR)/benchmark_suite

# Default target
all: driver tflite benchmark

# Build driver
driver: $(DRIVER_TARGET)

$(DRIVER_TARGET): $(DRIVER_SOURCES) $(DRIVER_HEADERS)
	@echo "Building GEMM accelerator driver..."
	@mkdir -p $(TARGET_DIR)
	$(CC) $(CFLAGS) -o $@ $(DRIVER_SOURCES) $(LDFLAGS)

# Build TensorFlow Lite integration
tflite: $(TFLITE_TARGET)

$(TFLITE_TARGET): $(TFLITE_SOURCES) $(TFLITE_HEADERS)
	@echo "Building TensorFlow Lite integration..."
	@mkdir -p $(TARGET_DIR)
	$(CC) $(CFLAGS) -o $@ $(TFLITE_SOURCES) $(LDFLAGS)

# Build benchmark suite
benchmark: $(BENCHMARK_TARGET)

$(BENCHMARK_TARGET): $(BENCHMARK_SOURCES) $(DRIVER_SOURCES) $(DRIVER_HEADERS)
	@echo "Building benchmark suite..."
	@mkdir -p $(TARGET_DIR)
	$(CC) $(CFLAGS) -o $@ $(BENCHMARK_SOURCES) $(DRIVER_SOURCES) $(LDFLAGS)

# Test targets
test_driver: driver
	@echo "Testing driver..."
	$(DRIVER_TARGET)

test_tflite: tflite
	@echo "Testing TensorFlow Lite integration..."
	$(TFLITE_TARGET)

test_benchmark: benchmark
	@echo "Running benchmark suite..."
	$(BENCHMARK_TARGET)

# Run all tests
test: test_driver test_tflite test_benchmark

# Clean up
clean:
	@echo "Cleaning up..."
	rm -rf $(TARGET_DIR)
	rm -f *.o
	rm -f *.a

# Install dependencies
install_deps:
	@echo "Installing dependencies..."
	# Install TensorFlow Lite Micro
	pip3 install tensorflow-lite-micro
	# Install other dependencies
	pip3 install numpy matplotlib

# Run benchmarks
benchmark_mnist: benchmark
	@echo "Running MNIST benchmark..."
	cd $(BENCHMARK_DIR) && ./run_benchmarks.sh mnist

benchmark_cifar10: benchmark
	@echo "Running CIFAR-10 benchmark..."
	cd $(BENCHMARK_DIR) && ./run_benchmarks.sh cifar10

benchmark_keyword: benchmark
	@echo "Running keyword spotting benchmark..."
	cd $(BENCHMARK_DIR) && ./run_benchmarks.sh keyword

benchmark_all: benchmark
	@echo "Running all benchmarks..."
	cd $(BENCHMARK_DIR) && ./run_benchmarks.sh

# Performance analysis
analyze_performance:
	@echo "Analyzing performance..."
	cd $(BENCHMARK_DIR) && python3 analyze_performance.py

# Generate reports
report: benchmark_all analyze_performance
	@echo "Generating reports..."
	cd $(BENCHMARK_DIR) && python3 generate_reports.py

# Help
help:
	@echo "Available targets:"
	@echo "  all              - Build all software components"
	@echo "  driver           - Build GEMM accelerator driver"
	@echo "  tflite           - Build TensorFlow Lite integration"
	@echo "  benchmark        - Build benchmark suite"
	@echo "  test             - Run all tests"
	@echo "  test_driver       - Test driver only"
	@echo "  test_tflite       - Test TensorFlow Lite integration only"
	@echo "  test_benchmark    - Test benchmark suite only"
	@echo "  benchmark_mnist  - Run MNIST benchmark"
	@echo "  benchmark_cifar10 - Run CIFAR-10 benchmark"
	@echo "  benchmark_keyword - Run keyword spotting benchmark"
	@echo "  benchmark_all    - Run all benchmarks"
	@echo "  analyze_performance - Analyze performance results"
	@echo "  report            - Generate performance reports"
	@echo "  install_deps      - Install dependencies"
	@echo "  clean             - Clean up generated files"
	@echo "  help              - Show this help"

.PHONY: all driver tflite benchmark test test_driver test_tflite test_benchmark \
        benchmark_mnist benchmark_cifar10 benchmark_keyword benchmark_all \
        analyze_performance report install_deps clean help
