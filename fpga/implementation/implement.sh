# FPGA Implementation Script
# Automated implementation flow for GEMM accelerator

#!/bin/bash

# Configuration
PROJECT_NAME="gemm_accelerator"
TOP_MODULE="gemm_accelerator_top"
TARGET_DEVICE="xc7z020-clg400-1"
SYNTH_TOOL="vivado"  # or "quartus"

# Directories
RTL_DIR="../rtl"
TB_DIR="../testbench"
CONSTRAINTS_DIR="../fpga/constraints"
RESULTS_DIR="../results"

# Create results directory
mkdir -p $RESULTS_DIR

echo "Starting FPGA implementation for $PROJECT_NAME"
echo "Target device: $TARGET_DEVICE"
echo "Synthesis tool: $SYNTH_TOOL"

# Function to run Vivado
run_vivado() {
    echo "Running Vivado synthesis and implementation..."
    
    # Create Vivado project
    vivado -mode batch -source synthesize.tcl -log vivado_synth.log
    
    # Check if synthesis succeeded
    if [ $? -eq 0 ]; then
        echo "Synthesis completed successfully"
        
        # Copy reports
        cp vivado_project/vivado_project.runs/impl_1/utilization_report.txt $RESULTS_DIR/
        cp vivado_project/vivado_project.runs/impl_1/timing_report.txt $RESULTS_DIR/
        cp vivado_project/vivado_project.runs/impl_1/power_report.txt $RESULTS_DIR/
        
        # Copy bitstream
        cp vivado_project/vivado_project.runs/impl_1/*.bit $RESULTS_DIR/
        
        echo "Implementation completed successfully"
    else
        echo "Synthesis failed - check vivado_synth.log"
        exit 1
    fi
}

# Function to run Quartus
run_quartus() {
    echo "Running Quartus synthesis and implementation..."
    
    # Run Quartus
    quartus_sh --flow compile $PROJECT_NAME
    
    # Check if compilation succeeded
    if [ $? -eq 0 ]; then
        echo "Compilation completed successfully"
        
        # Copy reports
        cp output_files/*.rpt $RESULTS_DIR/
        
        # Copy programming file
        cp output_files/*.sof $RESULTS_DIR/
        
        echo "Implementation completed successfully"
    else
        echo "Compilation failed - check compilation log"
        exit 1
    fi
}

# Function to run simulation
run_simulation() {
    echo "Running simulation..."
    
    if [ "$SYNTH_TOOL" = "vivado" ]; then
        # Run Vivado simulation
        vivado -mode batch -source simulate.tcl -log vivado_sim.log
        
        if [ $? -eq 0 ]; then
            echo "Simulation completed successfully"
            cp vivado_sim.log $RESULTS_DIR/
        else
            echo "Simulation failed - check vivado_sim.log"
        fi
    fi
}

# Function to generate reports
generate_reports() {
    echo "Generating implementation reports..."
    
    # Resource utilization
    echo "=== Resource Utilization ===" > $RESULTS_DIR/summary_report.txt
    if [ -f $RESULTS_DIR/utilization_report.txt ]; then
        grep -A 20 "Utilization by Hierarchy" $RESULTS_DIR/utilization_report.txt >> $RESULTS_DIR/summary_report.txt
    fi
    
    # Timing summary
    echo "" >> $RESULTS_DIR/summary_report.txt
    echo "=== Timing Summary ===" >> $RESULTS_DIR/summary_report.txt
    if [ -f $RESULTS_DIR/timing_report.txt ]; then
        grep -A 10 "Design Timing Summary" $RESULTS_DIR/timing_report.txt >> $RESULTS_DIR/summary_report.txt
    fi
    
    # Power summary
    echo "" >> $RESULTS_DIR/summary_report.txt
    echo "=== Power Summary ===" >> $RESULTS_DIR/summary_report.txt
    if [ -f $RESULTS_DIR/power_report.txt ]; then
        grep -A 10 "Power Summary" $RESULTS_DIR/power_report.txt >> $RESULTS_DIR/summary_report.txt
    fi
    
    echo "Reports generated in $RESULTS_DIR/"
}

# Function to run timing analysis
run_timing_analysis() {
    echo "Running timing analysis..."
    
    # Extract critical path information
    if [ -f $RESULTS_DIR/timing_report.txt ]; then
        echo "=== Critical Path Analysis ===" > $RESULTS_DIR/timing_analysis.txt
        grep -A 5 "Critical Path" $RESULTS_DIR/timing_report.txt >> $RESULTS_DIR/timing_analysis.txt
        
        # Extract setup/hold violations
        echo "" >> $RESULTS_DIR/timing_analysis.txt
        echo "=== Timing Violations ===" >> $RESULTS_DIR/timing_analysis.txt
        grep -i "violation" $RESULTS_DIR/timing_report.txt >> $RESULTS_DIR/timing_analysis.txt
    fi
}

# Function to run power analysis
run_power_analysis() {
    echo "Running power analysis..."
    
    if [ -f $RESULTS_DIR/power_report.txt ]; then
        echo "=== Power Analysis ===" > $RESULTS_DIR/power_analysis.txt
        grep -A 10 "Total On-Chip Power" $RESULTS_DIR/power_report.txt >> $RESULTS_DIR/power_analysis.txt
        
        # Extract power breakdown
        echo "" >> $RESULTS_DIR/power_analysis.txt
        echo "=== Power Breakdown ===" >> $RESULTS_DIR/power_analysis.txt
        grep -A 20 "Power Breakdown" $RESULTS_DIR/power_report.txt >> $RESULTS_DIR/power_analysis.txt
    fi
}

# Main execution
case $SYNTH_TOOL in
    "vivado")
        run_vivado
        ;;
    "quartus")
        run_quartus
        ;;
    *)
        echo "Unknown synthesis tool: $SYNTH_TOOL"
        exit 1
        ;;
esac

# Run additional analysis
run_simulation
run_timing_analysis
run_power_analysis
generate_reports

echo "FPGA implementation completed successfully!"
echo "Results available in $RESULTS_DIR/"

# Display summary
if [ -f $RESULTS_DIR/summary_report.txt ]; then
    echo ""
    echo "=== Implementation Summary ==="
    cat $RESULTS_DIR/summary_report.txt
fi
