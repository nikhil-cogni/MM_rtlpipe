#!/bin/bash
# Script to run all 25 pipelined arithmetic modules across multiple configurations
# and tabulate results with dashboard summary

# Default configuration parameters (can be overridden with command line arguments)
WIDTHS=(8 16 )  # Multiple data widths to test
PIPE_STAGES_LIST=(2 3 4)  # Multiple pipeline stages to test
TOTAL_MODULES=25

# Process command line arguments
if [ $# -ge 1 ]; then
    # Parse WIDTH argument: either single value or comma-separated list
    IFS=',' read -ra WIDTHS <<< "$1"
fi

if [ $# -ge 2 ]; then
    # Parse PIPE_STAGES argument: either single value or comma-separated list
    IFS=',' read -ra PIPE_STAGES_LIST <<< "$2"
fi

if [ $# -ge 3 ]; then
    # Optional parameter for number of modules to test
    TOTAL_MODULES=$3
fi

# Create timestamp for this run
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Create a log directory with timestamp
LOG_DIR="simulation_logs_${TIMESTAMP}"
mkdir -p $LOG_DIR

# Initialize 2D arrays to store results for all configurations
# We'll use string encoding to simulate multidimensional arrays
declare -A config_results_passed
declare -A config_results_failed
declare -A config_results_time

# Print header
echo "======================================================================="
echo "Running tests for all $TOTAL_MODULES arithmetic modules"
echo "Testing ${#WIDTHS[@]} WIDTH values: ${WIDTHS[*]}"
echo "Testing ${#PIPE_STAGES_LIST[@]} PIPE_STAGES values: ${PIPE_STAGES_LIST[*]}"
echo "======================================================================="
echo ""

# Function to extract runtime from log file
extract_runtime() {
    # Extract runtime using grep and awk (looks for simulation time in the log)
    grep -o "simulation time: [0-9.]* s" "$1" | awk '{print $3}'
}

# Function to check if a test passed
check_test_passed() {
    grep -q "TEST PASSED" "$1"
    return $?
}

# Function to run tests for a specific configuration
run_tests_for_config() {
    local width=$1
    local pipe_stages=$2
    local config_dir="${LOG_DIR}/w${width}_p${pipe_stages}"
    local config_key="${width}_${pipe_stages}"
    local passed=0
    local failed=0
    local start_config_time=$(date +%s)
    
    mkdir -p "$config_dir"
    
    echo "--------------------------------------------------------------------"
    echo "Testing configuration: WIDTH=$width, PIPE_STAGES=$pipe_stages"
    echo "--------------------------------------------------------------------"
    
    # Initialize per-module results arrays for this configuration
    declare -a results_status
    declare -a results_time
    
    # Run tests for all modules with this configuration
    for module in $(seq 1 $TOTAL_MODULES); do
        log_file="${config_dir}/module_${module}.log"
        
        echo -n "Testing module $module... "
        
        # Record start time for this module
        start_time=$(date +%s)
        
        # Run the simulation for this module
        verilator --binary --timing --assert --autoflush -j 2 -sv \
            -Wno-CASEINCOMPLETE -Wno-REALCVT -Wno-SELRANGE -Wno-TIMESCALEMOD \
            -Wno-UNSIGNED -Wno-WIDTH -CFLAGS -O1 -Wno-fatal \
            --trace-structs --trace-params --trace-fst \
            -top tb_pipelined_arithmetic \
            -o "sim_w${width}_p${pipe_stages}_m${module}.exe" \
            +define+SIMULATION +define+MODULE_ID=${module} +define+WIDTH=${width} +define+PIPE_STAGES=${pipe_stages} \
            arithmetic_modules.sv pipelined_arithmetic.sv tb_pipelined_arithmetic.sv > "${log_file}" 2>&1
        
        # Check if compilation succeeded
        if [ $? -ne 0 ]; then
            echo "COMPILE FAILED"
            results_status[$module]="COMPILE FAILED"
            failed=$((failed+1))
            continue
        fi
        
        # Run the simulation
        ./obj_dir/sim_w${width}_p${pipe_stages}_m${module}.exe >> "${log_file}" 2>&1
        
        # Record end time and calculate duration
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        results_time[$module]=$duration
        
        # Check if the test passed
        if check_test_passed "${log_file}"; then
            echo "PASSED (${duration}s)"
            results_status[$module]="PASSED"
            passed=$((passed+1))
        else
            echo "FAILED (${duration}s)"
            results_status[$module]="FAILED"
            failed=$((failed+1))
        fi
    done
    
    # Calculate total duration for this configuration
    local end_config_time=$(date +%s)
    local config_duration=$((end_config_time - start_config_time))
    
    # Store configuration results
    config_results_passed["$config_key"]=$passed
    config_results_failed["$config_key"]=$failed
    config_results_time["$config_key"]=$config_duration
    
    # Generate summary table for this configuration
    echo ""
    echo "Configuration Summary: WIDTH=$width, PIPE_STAGES=$pipe_stages"
    echo "-----------------------------------------------------------------------"
    printf "%-8s | %-15s | %-10s\n" "MODULE" "STATUS" "TIME (sec)"
    echo "-----------------------------------------------------------------------"
    
    # Print results for each module
    for module in $(seq 1 $TOTAL_MODULES); do
        printf "%-8s | %-15s | %-10s\n" "Module $module" "${results_status[$module]}" "${results_time[$module]}"
    done
    
    # Print summary footer for this configuration
    echo "-----------------------------------------------------------------------"
    printf "%-8s | %-15s | %-10s\n" "TOTAL" "$passed passed, $failed failed" "$config_duration seconds"
    echo "-----------------------------------------------------------------------"
    echo ""
    
    # Generate HTML report for this configuration
    generate_config_html "$width" "$pipe_stages" "$passed" "$failed" "$config_duration" "$config_dir"
    
    # Return results
    echo "${passed},${failed},${config_duration}"
}

# Function to generate HTML report for a specific configuration
generate_config_html() {
    local width=$1
    local pipe_stages=$2
    local passed=$3
    local failed=$4
    local duration=$5
    local config_dir=$6
    local config_html="${config_dir}/report.html"
    
    cat > "$config_html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test Report: WIDTH=$width, PIPE_STAGES=$pipe_stages</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        tr.passed td:nth-child(2) { color: green; font-weight: bold; }
        tr.failed td:nth-child(2) { color: red; font-weight: bold; }
        tr.summary { font-weight: bold; background-color: #f2f2f2; }
        .summary-box { 
            padding: 10px;
            margin-top: 20px;
            border-radius: 5px;
            text-align: center;
            font-weight: bold;
        }
        .success { background-color: #dff0d8; color: #3c763d; }
        .failure { background-color: #f2dede; color: #a94442; }
    </style>
</head>
<body>
    <h1>Test Report: WIDTH=$width, PIPE_STAGES=$pipe_stages</h1>
    <p><strong>Date:</strong> $(date)</p>
    
    <h2>Results</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Status</th>
            <th>Log File</th>
        </tr>
EOF
    
    # Add rows for each module
    for module in $(seq 1 $TOTAL_MODULES); do
        log_file="module_${module}.log"
        status="UNKNOWN"
        status_class="failed"
        
        if grep -q "TEST PASSED" "${config_dir}/${log_file}" 2>/dev/null; then
            status="PASSED"
            status_class="passed"
        elif grep -q "COMPILE FAILED\|TEST FAILED" "${config_dir}/${log_file}" 2>/dev/null; then
            status="FAILED"
        fi
        
        cat >> "$config_html" << EOF
        <tr class="$status_class">
            <td>Module $module</td>
            <td>$status</td>
            <td><a href="$log_file" target="_blank">View Log</a></td>
        </tr>
EOF
    done
    
    # Add summary row
    cat >> "$config_html" << EOF
        <tr class="summary">
            <td>TOTAL</td>
            <td>$passed passed, $failed failed</td>
            <td>$duration seconds</td>
        </tr>
    </table>
EOF
    
    # Add summary box
    if [ $failed -eq 0 ]; then
        cat >> "$config_html" << EOF
    <div class="summary-box success">
        ALL TESTS PASSED! 🎉
    </div>
EOF
    else
        cat >> "$config_html" << EOF
    <div class="summary-box failure">
        SOME TESTS FAILED! ❌ ($failed out of $TOTAL_MODULES)
    </div>
EOF
    fi
    
    # Close HTML file
    cat >> "$config_html" << EOF
    <p><a href="../dashboard.html">Back to Dashboard</a></p>
</body>
</html>
EOF
}

# Start time for entire test suite
start_time_all=$(date +%s)

# Track global statistics
total_tests=0
total_passed=0
total_failed=0

# Run tests for all configurations
for width in "${WIDTHS[@]}"; do
    for pipe_stages in "${PIPE_STAGES_LIST[@]}"; do
        config_key="${width}_${pipe_stages}"
        
        # Run tests for this configuration and get results
        IFS=',' read -r passed failed duration <<< $(run_tests_for_config "$width" "$pipe_stages")
        
        # Update global statistics
        total_tests=$((total_tests + TOTAL_MODULES))
        total_passed=$((total_passed + passed))
        total_failed=$((total_failed + failed))
    done
done

# Calculate total duration for all configurations
end_time_all=$(date +%s)
total_duration=$((end_time_all - start_time_all))

# Print final summary
echo "======================================================================="
echo "                    FINAL TEST SUMMARY"
echo "======================================================================="
echo "Total configurations tested: ${#WIDTHS[@]}x${#PIPE_STAGES_LIST[@]} = $((${#WIDTHS[@]} * ${#PIPE_STAGES_LIST[@]}))"
echo "Total modules tested: $total_tests"
echo "Total tests passed: $total_passed"
echo "Total tests failed: $total_failed"
echo "Total time: $total_duration seconds"
echo "======================================================================="

# Generate main HTML dashboard
cat > "${LOG_DIR}/dashboard.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Pipeline Arithmetic Module Test Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .dashboard-title { text-align: center; margin-bottom: 20px; }
        .summary { background-color: #f9f9f9; padding: 15px; margin-bottom: 20px; border-radius: 5px; }
        .config-table { margin-top: 30px; }
        .passed { color: green; font-weight: bold; }
        .failed { color: red; font-weight: bold; }
        .highlight { background-color: #ffffd0; }
        .summary-box { 
            padding: 10px;
            margin-top: 20px;
            border-radius: 5px;
            text-align: center;
            font-weight: bold;
        }
        .success { background-color: #dff0d8; color: #3c763d; }
        .failure { background-color: #f2dede; color: #a94442; }
    </style>
</head>
<body>
    <h1 class="dashboard-title">Pipeline Arithmetic Module Test Dashboard</h1>
    
    <div class="summary">
        <h2>Overall Summary</h2>
        <p><strong>Date:</strong> $(date)</p>
        <p><strong>Configurations Tested:</strong> ${#WIDTHS[@]}x${#PIPE_STAGES_LIST[@]} = $((${#WIDTHS[@]} * ${#PIPE_STAGES_LIST[@]}))</p>
        <p><strong>Total Tests:</strong> $total_tests</p>
        <p><strong>Tests Passed:</strong> <span class="passed">$total_passed</span></p>
        <p><strong>Tests Failed:</strong> <span class="failed">$total_failed</span></p>
        <p><strong>Total Runtime:</strong> $total_duration seconds</p>
    </div>
    
    <h2>Configuration Results</h2>
    <table class="config-table">
        <tr>
            <th>Width</th>
            <th>Pipeline Stages</th>
            <th>Pass</th>
            <th>Fail</th>
            <th>Time (sec)</th>
            <th>Actions</th>
        </tr>
EOF

# Add rows for each configuration
for width in "${WIDTHS[@]}"; do
    for pipe_stages in "${PIPE_STAGES_LIST[@]}"; do
        config_key="${width}_${pipe_stages}"
        passed=${config_results_passed["$config_key"]}
        failed=${config_results_failed["$config_key"]}
        duration=${config_results_time["$config_key"]}
        
        # Determine if this configuration had any failures
        row_class=""
        if [ "$failed" -gt 0 ]; then
            row_class="highlight"
        fi
        
        cat >> "${LOG_DIR}/dashboard.html" << EOF
        <tr class="$row_class">
            <td>$width</td>
            <td>$pipe_stages</td>
            <td class="passed">$passed</td>
            <td class="failed">$failed</td>
            <td>$duration</td>
            <td><a href="w${width}_p${pipe_stages}/report.html">View Details</a></td>
        </tr>
EOF
    done
done

# Complete dashboard HTML
cat >> "${LOG_DIR}/dashboard.html" << EOF
    </table>
    
    <h2>Heat Map: Pass Rate by Configuration</h2>
    <table class="config-table">
        <tr>
            <th>Width / Pipeline Stages</th>
EOF

# Add column headers (pipeline stages)
for pipe_stages in "${PIPE_STAGES_LIST[@]}"; do
    echo "<th>$pipe_stages</th>" >> "${LOG_DIR}/dashboard.html"
done

echo "</tr>" >> "${LOG_DIR}/dashboard.html"

# Add rows for each width with heat map cells
for width in "${WIDTHS[@]}"; do
    echo "<tr><td>$width</td>" >> "${LOG_DIR}/dashboard.html"
    
    for pipe_stages in "${PIPE_STAGES_LIST[@]}"; do
        config_key="${width}_${pipe_stages}"
        passed=${config_results_passed["$config_key"]}
        total=$((passed + ${config_results_failed["$config_key"]}))
        pass_rate=$(( (passed * 100) / total ))
        
        # Calculate background color based on pass rate (green to red gradient)
        r=$((255 - pass_rate * 2))
        g=$((55 + pass_rate * 2))
        b=50
        if [ $r -lt 0 ]; then r=0; fi
        if [ $r -gt 255 ]; then r=255; fi
        if [ $g -lt 0 ]; then g=0; fi
        if [ $g -gt 255 ]; then g=255; fi
        
        echo "<td style='background-color: rgb($r, $g, $b); color: white; text-align: center;'>$pass_rate%</td>" >> "${LOG_DIR}/dashboard.html"
    done
    
    echo "</tr>" >> "${LOG_DIR}/dashboard.html"
done

# Close the dashboard HTML
cat >> "${LOG_DIR}/dashboard.html" << EOF
    </table>
    
    <div class="summary-box $([ $total_failed -eq 0 ] && echo 'success' || echo 'failure')">
        $([ $total_failed -eq 0 ] && echo 'ALL TESTS PASSED! 🎉' || echo "SOME TESTS FAILED! ❌ ($total_failed out of $total_tests)")
    </div>
</body>
</html>
EOF

# Create a symbolic link to the latest run
rm -f latest_results
ln -s "$LOG_DIR" latest_results

echo ""
echo "Test suite completed!"
echo "Dashboard HTML report generated: ${LOG_DIR}/dashboard.html"
echo "View the report at: latest_results/dashboard.html"
