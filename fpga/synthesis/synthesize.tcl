# FPGA Synthesis Script for GEMM Accelerator
# Supports Xilinx Vivado and Intel Quartus

# Set project parameters
set PROJECT_NAME "gemm_accelerator"
set TOP_MODULE "gemm_accelerator_top"
set TARGET_DEVICE "xc7z020-clg400-1"  # Zynq-7000 for Vivado
# set TARGET_DEVICE "5CSXFC6D6F31C6"  # Cyclone V for Quartus

# Source file list
set RTL_FILES {
    "../rtl/mac_array/mac_array.v"
    "../rtl/scratchpad/scratchpad_sram.v"
    "../rtl/dma/dma_engine.v"
    "../rtl/interface/riscv_interface.v"
    "../rtl/top/gemm_accelerator_top.v"
}

# Testbench files
set TB_FILES {
    "../testbench/unit_tests/mac_array_tb.v"
}

# Constraints file
set CONSTRAINTS_FILE "constraints.xdc"

# Create project
if {[string match "*vivado*" [file tail [info nameofexecutable]]]} {
    # Vivado synthesis
    create_project $PROJECT_NAME ./vivado_project -part $TARGET_DEVICE -force
    
    # Add source files
    add_files -norecurse $RTL_FILES
    add_files -fileset sim_1 -norecurse $TB_FILES
    
    # Add constraints
    if {[file exists $CONSTRAINTS_FILE]} {
        add_files -fileset constrs_1 -norecurse $CONSTRAINTS_FILE
    }
    
    # Set top module
    set_property top $TOP_MODULE [current_fileset]
    
    # Synthesis settings
    set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
    
    # Launch synthesis
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    
    # Launch implementation
    launch_runs impl_1 -jobs 4
    wait_on_run impl_1
    
    # Generate bitstream
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    
    # Report results
    open_run impl_1
    report_utilization -file utilization_report.txt
    report_timing -file timing_report.txt
    report_power -file power_report.txt
    
} elseif {[string match "*quartus*" [file tail [info nameofexecutable]]]} {
    # Quartus synthesis
    project_new $PROJECT_NAME -overwrite
    
    # Set device
    set_global_assignment -name FAMILY "Cyclone V"
    set_global_assignment -name DEVICE $TARGET_DEVICE
    
    # Add source files
    foreach file $RTL_FILES {
        set_global_assignment -name VERILOG_FILE $file
    }
    
    # Add constraints
    if {[file exists "constraints.qsf"]} {
        source constraints.qsf
    }
    
    # Set top module
    set_global_assignment -name TOP_LEVEL_ENTITY $TOP_MODULE
    
    # Compile project
    load_package flow
    execute_flow -compile
    
    # Report results
    load_package report
    load_report
    make_all_pins_report
    make_all_summary
}

puts "FPGA synthesis completed for $PROJECT_NAME"
