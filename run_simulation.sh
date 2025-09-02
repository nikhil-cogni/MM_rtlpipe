#!/bin/bash
# Script to compile and run the pipelined arithmetic testbench

# Parameters (you can modify these)
MODULE_ID=5
WIDTH=16
PIPE_STAGES=3

# Override with command-line arguments if provided
if [ "$1" != "" ]; then MODULE_ID=$1; fi
if [ "$2" != "" ]; then WIDTH=$2; fi
if [ "$3" != "" ]; then PIPE_STAGES=$3; fi

echo "=== Compiling with Verilator (MODULE_ID=${MODULE_ID}, WIDTH=${WIDTH}, PIPE_STAGES=${PIPE_STAGES}) ==="

# Clean old build if it exists
rm -rf obj_dir

# Run Verilator compilation
verilator --binary --timing --assert --autoflush -j 2 -sv \
  -Wno-CASEINCOMPLETE -Wno-REALCVT -Wno-SELRANGE -Wno-TIMESCALEMOD \
  -Wno-UNSIGNED -Wno-WIDTH -CFLAGS -O1 -Wno-fatal \
  --trace-structs --trace-params --trace-fst \
  -top tb_pipelined_arithmetic \
  -o sim.exe \
  +define+SIMULATION +define+MODULE_ID=${MODULE_ID} +define+WIDTH=${WIDTH} +define+PIPE_STAGES=${PIPE_STAGES} \
  arithmetic_modules.sv pipelined_arithmetic.sv tb_pipelined_arithmetic.sv

# Check if compilation succeeded
if [ $? -ne 0 ]; then
  echo "=== Compilation failed! ==="
  exit 1
fi

echo "=== Compilation successful! ==="
echo "=== Running simulation ==="

# Run the simulation
./obj_dir/sim.exe

# Check simulation exit status
if [ $? -eq 0 ]; then
  echo "=== Simulation completed successfully! ==="
  
  # List the generated waveform file
  if [ -f "dumpfile.fst" ]; then
    echo "=== Waveform file generated: dumpfile.fst ==="
    ls -la dumpfile.fst
  fi
else
  echo "=== Simulation failed! ==="
  exit 1
fi
