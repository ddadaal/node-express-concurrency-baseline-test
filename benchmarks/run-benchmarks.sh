#!/bin/bash

# Make this script executable:
# chmod +x run-benchmarks.sh

# Ensure proxy and target servers are running before benchmarking

# Directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_URL="http://localhost:5000"
TARGET_URL="http://localhost:5001"

# Check if test run name is provided
TEST_RUN_NAME=${1:-"run_$(date +%Y%m%d_%H%M%S)"}
echo "Test run name: $TEST_RUN_NAME"

# Validate that wrk is installed
if ! command -v wrk &> /dev/null; then
  echo "Error: wrk is not installed. Please install wrk first."
  echo "On Ubuntu: apt install wrk"
  echo "On macOS: brew install wrk"
  exit 1
fi

# Validate that mpstat (for CPU monitoring) is installed
if ! command -v mpstat &> /dev/null; then
  echo "Warning: mpstat is not installed. CPU monitoring will be disabled."
  echo "On Ubuntu: apt install sysstat"
  echo "On macOS: brew install sysstat"
  HAS_MPSTAT=false
else
  HAS_MPSTAT=true
fi

# Create a directory for results
RESULTS_DIR="$SCRIPT_DIR/results/$TEST_RUN_NAME"
mkdir -p "$RESULTS_DIR"

# Function to start CPU monitoring
start_cpu_monitoring() {
  if [ "$HAS_MPSTAT" = true ]; then
    echo "Starting CPU monitoring (per core)..."
    # -P ALL tells mpstat to show all individual cores
    mpstat -P ALL 1 > "$RESULTS_DIR/cpu_stats_$1.txt" &
    MPSTAT_PID=$!
    echo "CPU monitoring started with PID: $MPSTAT_PID"
  fi
}

# Function to stop CPU monitoring
stop_cpu_monitoring() {
  if [ "$HAS_MPSTAT" = true ] && [ -n "$MPSTAT_PID" ]; then
    echo "Stopping CPU monitoring..."
    kill $MPSTAT_PID
    echo "Per-core CPU statistics saved to $RESULTS_DIR/cpu_stats_$1.txt"
  fi
}

# Check if servers are running
if ! curl -s "$PROXY_URL" > /dev/null; then
  echo "Error: Proxy server at $PROXY_URL is not reachable."
  echo "Please start the servers using: pnpm dev"
  exit 1
fi

if ! curl -s "$TARGET_URL" > /dev/null; then
  echo "Error: Target server at $TARGET_URL is not reachable."
  echo "Please start both servers before running benchmarks."
  exit 1
fi

echo "=== Starting benchmark tests ==="
echo

# Parameters for benchmarks
# -c: Connections to keep open
# -d: Duration of the test in seconds
# -t: Number of threads to use
# -s: LUA script file

# Create markdown file for results
MARKDOWN_FILE="$RESULTS_DIR/benchmark_summary.md"
> "$MARKDOWN_FILE" # Clear the markdown file

# Initialize markdown report structure
echo "# Benchmark Results Summary - $TEST_RUN_NAME" > "$MARKDOWN_FILE"
echo "" >> "$MARKDOWN_FILE"
echo "## Test Environment" >> "$MARKDOWN_FILE"
echo "" >> "$MARKDOWN_FILE"
echo "* Test Run: $TEST_RUN_NAME" >> "$MARKDOWN_FILE"
echo "* Date: $(date)" >> "$MARKDOWN_FILE"
echo "* Target Server: $TARGET_URL" >> "$MARKDOWN_FILE"
echo "* Proxy Server: $PROXY_URL" >> "$MARKDOWN_FILE"
echo "" >> "$MARKDOWN_FILE"

echo "## Results Table" >> "$MARKDOWN_FILE"
echo "" >> "$MARKDOWN_FILE"
echo "| Server | Connections | Requests/sec | Avg Latency | Max Latency | Total Requests | Timeouts | Timeout % | Total Errors | Error % |" >> "$MARKDOWN_FILE"
echo "|--------|-------------|--------------|-------------|-------------|----------------|----------|-----------|--------------|---------|" >> "$MARKDOWN_FILE"

# Function to run benchmark with specific connection count
run_benchmark() {
    local url=$1
    local connections=$2
    local server_name=$3
    local result_file="$RESULTS_DIR/${server_name}_${connections}conn.txt"
    
    echo "Running GET benchmark on $server_name (10 seconds, $connections connections, 6 threads)"
    echo "Monitoring per-core CPU usage during benchmark..."
    start_cpu_monitoring "${server_name}_${connections}conn"
    wrk -c$connections -d10s -t6 --timeout 5s -s "$SCRIPT_DIR/get-benchmark.lua" "$url" | tee "$result_file"
    stop_cpu_monitoring "${server_name}_${connections}conn"
    echo
    
    # Extract key metrics for summary
    local rps=$(grep "Requests/sec:" "$result_file" | awk '{print $2}')
    local latency_avg=$(grep "Latency" "$result_file" | awk '{print $2}')
    local latency_max=$(grep "Latency" "$result_file" | awk '{print $4}')
    
    # Extract total requests, timeouts, and errors
    local total_requests=$(grep "requests in" "$result_file" | awk '{print $1}')
    # Check if there are timeout and error lines
    local timeouts=$(grep "Socket errors:" "$result_file" | grep -o "timeout [0-9]*" | awk '{print $2}' || echo "0")
    local errors=$(grep "Socket errors:" "$result_file" | grep -o "connect [0-9]*" | awk '{print $2}' || echo "0")
    local read_errors=$(grep "Socket errors:" "$result_file" | grep -o "read [0-9]*" | awk '{print $2}' || echo "0")
    local write_errors=$(grep "Socket errors:" "$result_file" | grep -o "write [0-9]*" | awk '{print $2}' || echo "0")
    
    # If any values are empty, set them to 0
    timeouts=${timeouts:-0}
    errors=${errors:-0}
    read_errors=${read_errors:-0}
    write_errors=${write_errors:-0}
    
    # Calculate total errors and ratios (with protection against division by zero)
    local total_errors=$((errors + timeouts + read_errors + write_errors))
    
    # Calculate ratios with 2 decimal places
    local timeout_ratio=0
    local error_ratio=0
    if [ "$total_requests" -gt 0 ]; then
        timeout_ratio=$(awk "BEGIN {printf \"%.2f\", ($timeouts/$total_requests)*100}")
        error_ratio=$(awk "BEGIN {printf \"%.2f\", ($total_errors/$total_requests)*100}")
    fi
    
    # Write directly to markdown file
    echo "| $server_name | $connections | $rps | $latency_avg | $latency_max | $total_requests | $timeouts | $timeout_ratio% | $total_errors | $error_ratio% |" >> "$MARKDOWN_FILE"
}

# Run benchmarks with different connection counts
CONNECTION_COUNTS=(50 100 150 200 500 1000 2000 5000 10000 20000)

# Run benchmarks for target server first, then proxy server
for url in "$TARGET_URL" "$PROXY_URL"; do
    # Extract only the port number from the URL
    server_name=$(echo "$url" | awk -F: '{print $NF}')
    for conn in "${CONNECTION_COUNTS[@]}"; do
        run_benchmark "$url" "$conn" "$server_name"
    done
done

echo "=== Benchmarking completed ==="
echo

echo "" >> "$MARKDOWN_FILE"
echo "Detailed results are available in the \`$RESULTS_DIR\` directory." >> "$MARKDOWN_FILE"

echo "=== Summary of Results ==="
echo
echo "Test Run: $TEST_RUN_NAME"
echo "Detailed results are available in the $RESULTS_DIR directory"
echo "CPU usage statistics are available in the cpu_stats_*.txt files"
echo "Markdown report saved to $MARKDOWN_FILE"

# Display the markdown report
echo
echo "=== Markdown Report ==="
cat "$MARKDOWN_FILE"

# Print all data under the results directory
echo
echo "=== Contents of Results Directory ==="
echo "Listing all files in $RESULTS_DIR:"
ls -la "$RESULTS_DIR"
echo
echo "=== File Contents in Results Directory ==="
for file in "$RESULTS_DIR"/*; do
    if [ -f "$file" ]; then
        echo "=== Content of $(basename "$file") ==="
        cat "$file"
        echo
        echo "==================================="
        echo
    fi
done
