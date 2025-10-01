# Makefile for Testbench Compilation and Simulation

# Configuration
SIMULATOR = modelsim  # or verilator
TOP_MODULE = gemm_accelerator_top
RTL_DIR = ../rtl
TB_DIR = .
RESULTS_DIR = ../results

# RTL source files
RTL_FILES = \
    $(RTL_DIR)/mac_array/mac_array.v \
    $(RTL_DIR)/scratchpad/scratchpad_sram.v \
    $(RTL_DIR)/dma/dma_engine.v \
    $(RTL_DIR)/interface/riscv_interface.v \
    $(RTL_DIR)/top/gemm_accelerator_top.v

# Testbench files
TB_FILES = \
    $(TB_DIR)/unit_tests/mac_array_tb.v \
    $(TB_DIR)/unit_tests/scratchpad_tb.v \
    $(TB_DIR)/unit_tests/dma_tb.v \
    $(TB_DIR)/unit_tests/riscv_interface_tb.v \
    $(TB_DIR)/integration_tests/integration_tb.v

# Default target
all: sim

# ModelSim simulation
sim: compile_sim run_sim

compile_sim:
	@echo "Compiling RTL and testbenches..."
	vlib work
	vlog -work work $(RTL_FILES) $(TB_FILES)

run_sim:
	@echo "Running simulation..."
	vsim -c -do "run -all; quit" work.mac_array_tb
	vsim -c -do "run -all; quit" work.scratchpad_tb
	vsim -c -do "run -all; quit" work.dma_tb
	vsim -c -do "run -all; quit" work.riscv_interface_tb
	vsim -c -do "run -all; quit" work.integration_tb

# Verilator simulation
verilator: compile_verilator run_verilator

compile_verilator:
	@echo "Compiling with Verilator..."
	verilator --cc --exe --build $(RTL_FILES) $(TB_DIR)/unit_tests/mac_array_tb.v

run_verilator:
	@echo "Running Verilator simulation..."
	./obj_dir/Vmac_array_tb

# Individual test targets
test_mac_array:
	@echo "Testing MAC array..."
	vlib work
	vlog -work work $(RTL_DIR)/mac_array/mac_array.v $(TB_DIR)/unit_tests/mac_array_tb.v
	vsim -c -do "run -all; quit" work.mac_array_tb

test_scratchpad:
	@echo "Testing scratchpad..."
	vlib work
	vlog -work work $(RTL_DIR)/scratchpad/scratchpad_sram.v $(TB_DIR)/unit_tests/scratchpad_tb.v
	vsim -c -do "run -all; quit" work.scratchpad_tb

test_dma:
	@echo "Testing DMA..."
	vlib work
	vlog -work work $(RTL_DIR)/dma/dma_engine.v $(TB_DIR)/unit_tests/dma_tb.v
	vsim -c -do "run -all; quit" work.dma_tb

test_riscv_interface:
	@echo "Testing RISC-V interface..."
	vlib work
	vlog -work work $(RTL_DIR)/interface/riscv_interface.v $(TB_DIR)/unit_tests/riscv_interface_tb.v
	vsim -c -do "run -all; quit" work.riscv_interface_tb

test_integration:
	@echo "Testing integration..."
	vlib work
	vlog -work work $(RTL_FILES) $(TB_DIR)/integration_tests/integration_tb.v
	vsim -c -do "run -all; quit" work.integration_tb

# Coverage analysis
coverage:
	@echo "Running coverage analysis..."
	vlib work
	vlog -work work -cover bcesf $(RTL_FILES) $(TB_FILES)
	vsim -c -coverage -do "run -all; coverage save coverage.ucdb; quit" work.integration_tb
	vcover report -html coverage.ucdb

# Clean up
clean:
	@echo "Cleaning up..."
	rm -rf work
	rm -rf obj_dir
	rm -f *.wlf
	rm -f *.ucdb
	rm -f transcript
	rm -f vsim.wlf

# Help
help:
	@echo "Available targets:"
	@echo "  sim              - Run ModelSim simulation"
	@echo "  verilator        - Run Verilator simulation"
	@echo "  test_mac_array   - Test MAC array only"
	@echo "  test_scratchpad  - Test scratchpad only"
	@echo "  test_dma         - Test DMA only"
	@echo "  test_riscv_interface - Test RISC-V interface only"
	@echo "  test_integration - Test integration"
	@echo "  coverage         - Run coverage analysis"
	@echo "  clean            - Clean up generated files"
	@echo "  help             - Show this help"

.PHONY: all sim compile_sim run_sim verilator compile_verilator run_verilator \
        test_mac_array test_scratchpad test_dma test_riscv_interface test_integration \
        coverage clean help
