# AI Model Benchmarking Script
# Automated benchmarking for multiple AI models

#!/bin/bash

# Configuration
BENCHMARK_DIR="software/benchmarks"
RESULTS_DIR="results/performance"
MODELS_DIR="models"

# Create results directory
mkdir -p $RESULTS_DIR

echo "AI Model Benchmarking Suite"
echo "============================"

# Function to benchmark MNIST
benchmark_mnist() {
    echo "Benchmarking MNIST model..."
    
    # Compile benchmark
    gcc -o mnist_benchmark $BENCHMARK_DIR/benchmark_suite.c \
        $BENCHMARK_DIR/mnist_model.c \
        $BENCHMARK_DIR/gemm_accel_driver.c \
        -lm -O2
    
    if [ $? -eq 0 ]; then
        # Run benchmark
        ./mnist_benchmark > $RESULTS_DIR/mnist_results.txt 2>&1
        
        if [ $? -eq 0 ]; then
            echo "MNIST benchmark completed successfully"
        else
            echo "MNIST benchmark failed"
        fi
    else
        echo "MNIST benchmark compilation failed"
    fi
}

# Function to benchmark CIFAR-10
benchmark_cifar10() {
    echo "Benchmarking CIFAR-10 model..."
    
    # Compile benchmark
    gcc -o cifar10_benchmark $BENCHMARK_DIR/benchmark_suite.c \
        $BENCHMARK_DIR/cifar10_model.c \
        $BENCHMARK_DIR/gemm_accel_driver.c \
        -lm -O2
    
    if [ $? -eq 0 ]; then
        # Run benchmark
        ./cifar10_benchmark > $RESULTS_DIR/cifar10_results.txt 2>&1
        
        if [ $? -eq 0 ]; then
            echo "CIFAR-10 benchmark completed successfully"
        else
            echo "CIFAR-10 benchmark failed"
        fi
    else
        echo "CIFAR-10 benchmark compilation failed"
    fi
}

# Function to benchmark Keyword Spotting
benchmark_keyword() {
    echo "Benchmarking Keyword Spotting model..."
    
    # Compile benchmark
    gcc -o keyword_benchmark $BENCHMARK_DIR/benchmark_suite.c \
        $BENCHMARK_DIR/keyword_model.c \
        $BENCHMARK_DIR/gemm_accel_driver.c \
        -lm -O2
    
    if [ $? -eq 0 ]; then
        # Run benchmark
        ./keyword_benchmark > $RESULTS_DIR/keyword_results.txt 2>&1
        
        if [ $? -eq 0 ]; then
            echo "Keyword Spotting benchmark completed successfully"
        else
            echo "Keyword Spotting benchmark failed"
        fi
    else
        echo "Keyword Spotting benchmark compilation failed"
    fi
}

# Function to run comprehensive benchmark
run_comprehensive_benchmark() {
    echo "Running comprehensive benchmark suite..."
    
    # Compile comprehensive benchmark
    gcc -o comprehensive_benchmark $BENCHMARK_DIR/benchmark_suite.c \
        $BENCHMARK_DIR/gemm_accel_driver.c \
        -lm -O2
    
    if [ $? -eq 0 ]; then
        # Run comprehensive benchmark
        ./comprehensive_benchmark > $RESULTS_DIR/comprehensive_results.txt 2>&1
        
        if [ $? -eq 0 ]; then
            echo "Comprehensive benchmark completed successfully"
        else
            echo "Comprehensive benchmark failed"
        fi
    else
        echo "Comprehensive benchmark compilation failed"
    fi
}

# Function to analyze results
analyze_results() {
    echo "Analyzing benchmark results..."
    
    # Create summary report
    echo "AI Model Benchmarking Summary" > $RESULTS_DIR/summary.txt
    echo "=============================" >> $RESULTS_DIR/summary.txt
    echo "" >> $RESULTS_DIR/summary.txt
    
    # Analyze each model
    for model in mnist cifar10 keyword; do
        if [ -f $RESULTS_DIR/${model}_results.txt ]; then
            echo "=== $model Results ===" >> $RESULTS_DIR/summary.txt
            grep -E "(Latency|Throughput|Accuracy|Status)" $RESULTS_DIR/${model}_results.txt >> $RESULTS_DIR/summary.txt
            echo "" >> $RESULTS_DIR/summary.txt
        fi
    done
    
    # Performance comparison
    echo "=== Performance Comparison ===" >> $RESULTS_DIR/summary.txt
    echo "Model          Latency(ms)  Throughput(GOPS)  Accuracy(%)  Status" >> $RESULTS_DIR/summary.txt
    echo "---------------------------------------------------------------" >> $RESULTS_DIR/summary.txt
    
    for model in mnist cifar10 keyword; do
        if [ -f $RESULTS_DIR/${model}_results.txt ]; then
            # Extract key metrics
            latency=$(grep "Latency:" $RESULTS_DIR/${model}_results.txt | awk '{print $2}')
            throughput=$(grep "Throughput:" $RESULTS_DIR/${model}_results.txt | awk '{print $2}')
            accuracy=$(grep "Accuracy:" $RESULTS_DIR/${model}_results.txt | awk '{print $2}')
            status=$(grep "Status:" $RESULTS_DIR/${model}_results.txt | awk '{print $2}')
            
            printf "%-15s %-12s %-16s %-12s %s\n" \
                   "$model" "$latency" "$throughput" "$accuracy" "$status" >> $RESULTS_DIR/summary.txt
        fi
    done
    
    echo "Results analysis completed"
}

# Function to generate performance plots
generate_plots() {
    echo "Generating performance plots..."
    
    # Create Python script for plotting
    cat > $RESULTS_DIR/generate_plots.py << 'EOF'
import matplotlib.pyplot as plt
import numpy as np

# Read results and create plots
models = ['MNIST', 'CIFAR-10', 'Keyword Spotting']
latencies = [2.5, 15.2, 8.7]  # Placeholder data
throughputs = [45.2, 28.1, 38.9]  # Placeholder data
accuracies = [97.5, 87.2, 92.1]  # Placeholder data

# Create subplots
fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(12, 10))

# Latency comparison
ax1.bar(models, latencies, color='skyblue')
ax1.set_title('Inference Latency')
ax1.set_ylabel('Latency (ms)')
ax1.tick_params(axis='x', rotation=45)

# Throughput comparison
ax2.bar(models, throughputs, color='lightgreen')
ax2.set_title('Throughput')
ax2.set_ylabel('Throughput (GOPS)')
ax2.tick_params(axis='x', rotation=45)

# Accuracy comparison
ax3.bar(models, accuracies, color='lightcoral')
ax3.set_title('Model Accuracy')
ax3.set_ylabel('Accuracy (%)')
ax3.tick_params(axis='x', rotation=45)

# Energy efficiency
efficiency = [t/l for t, l in zip(throughputs, latencies)]
ax4.bar(models, efficiency, color='gold')
ax4.set_title('Energy Efficiency')
ax4.set_ylabel('GOPS/ms')
ax4.tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('performance_comparison.png', dpi=300, bbox_inches='tight')
plt.close()

print("Performance plots generated successfully")
EOF
    
    # Run Python script
    python3 $RESULTS_DIR/generate_plots.py
    
    if [ $? -eq 0 ]; then
        echo "Performance plots generated successfully"
    else
        echo "Failed to generate performance plots"
    fi
}

# Function to run power analysis
run_power_analysis() {
    echo "Running power analysis..."
    
    # Create power analysis script
    cat > $RESULTS_DIR/power_analysis.py << 'EOF'
import matplotlib.pyplot as plt
import numpy as np

# Power consumption data (placeholder)
models = ['MNIST', 'CIFAR-10', 'Keyword Spotting']
power_active = [85, 95, 88]  # mW
power_idle = [15, 15, 15]    # mW
energy_per_inference = [0.21, 1.45, 0.77]  # mJ

# Create power analysis plots
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

# Power consumption
x = np.arange(len(models))
width = 0.35

ax1.bar(x - width/2, power_active, width, label='Active Power', color='red')
ax1.bar(x + width/2, power_idle, width, label='Idle Power', color='blue')
ax1.set_title('Power Consumption')
ax1.set_ylabel('Power (mW)')
ax1.set_xticks(x)
ax1.set_xticklabels(models)
ax1.legend()
ax1.tick_params(axis='x', rotation=45)

# Energy per inference
ax2.bar(models, energy_per_inference, color='green')
ax2.set_title('Energy per Inference')
ax2.set_ylabel('Energy (mJ)')
ax2.tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('power_analysis.png', dpi=300, bbox_inches='tight')
plt.close()

print("Power analysis completed")
EOF
    
    # Run power analysis
    python3 $RESULTS_DIR/power_analysis.py
    
    if [ $? -eq 0 ]; then
        echo "Power analysis completed successfully"
    else
        echo "Failed to run power analysis"
    fi
}

# Main execution
echo "Starting AI model benchmarking..."

# Run individual benchmarks
benchmark_mnist
benchmark_cifar10
benchmark_keyword

# Run comprehensive benchmark
run_comprehensive_benchmark

# Analyze results
analyze_results

# Generate plots
generate_plots

# Run power analysis
run_power_analysis

echo "Benchmarking suite completed successfully!"
echo "Results available in $RESULTS_DIR/"

# Display summary
if [ -f $RESULTS_DIR/summary.txt ]; then
    echo ""
    echo "=== Benchmarking Summary ==="
    cat $RESULTS_DIR/summary.txt
fi

# Cleanup
rm -f mnist_benchmark cifar10_benchmark keyword_benchmark comprehensive_benchmark
