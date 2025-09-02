#!/usr/bin/env python3
"""
Python implementation of run_simulation_all.sh
Tests all arithmetic modules with configurable widths and pipeline stages
Generates comprehensive HTML reports of test results
"""

import os
import sys
import time
import datetime
import subprocess
import re
import argparse
from pathlib import Path
import shutil
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, List, Tuple, Optional


class ModuleTest:
    """Class to manage testing a single module with specific configuration"""
    def __init__(self, module_id: int, width: int, pipe_stages: int, log_dir: str):
        self.module_id = module_id
        self.width = width
        self.pipe_stages = pipe_stages
        self.log_dir = log_dir
        self.config_dir = f"{log_dir}/w{width}_p{pipe_stages}"
        self.log_file = f"{self.config_dir}/module_{module_id}.log"
        self.duration = 0
        self.status = "UNKNOWN"
        self.config_key = f"{width}_{pipe_stages}"
        
        # Ensure log directory exists
        os.makedirs(self.config_dir, exist_ok=True)
    
    def run_test(self) -> bool:
        """Run compilation and simulation for this module"""
        start_time = time.time()
        print(f"Testing module {self.module_id}...", end=" ", flush=True)
        
        # Compile with Verilator
        with open(self.log_file, "w") as log:
            compile_result = subprocess.run([
                "verilator", "--binary", "--timing", "--assert", "--autoflush", "-j", "2", "-sv",
                "-Wno-CASEINCOMPLETE", "-Wno-REALCVT", "-Wno-SELRANGE", "-Wno-TIMESCALEMOD",
                "-Wno-UNSIGNED", "-Wno-WIDTH", "-CFLAGS", "-O1", "-Wno-fatal",
                "--trace-structs", "--trace-params", "--trace-fst",
                "-top", "tb_pipelined_arithmetic",
                "-o", f"sim_w{self.width}_p{self.pipe_stages}_m{self.module_id}.exe",
                f"+define+SIMULATION",
                f"+define+MODULE_ID={self.module_id}",
                f"+define+WIDTH={self.width}",
                f"+define+PIPE_STAGES={self.pipe_stages}",
                "arithmetic_modules.sv", "pipelined_arithmetic.sv", "tb_pipelined_arithmetic.sv"
            ], stdout=log, stderr=log)
            
            if compile_result.returncode != 0:
                print("COMPILE FAILED")
                self.status = "COMPILE FAILED"
                self.duration = time.time() - start_time
                return False
            
            # Run simulation
            sim_result = subprocess.run(
                [f"./obj_dir/sim_w{self.width}_p{self.pipe_stages}_m{self.module_id}.exe"],
                stdout=log, stderr=log
            )
            
        # Check for pass/fail
        self.duration = time.time() - start_time
        with open(self.log_file, "r") as log:
            log_content = log.read()
            if "TEST PASSED" in log_content:
                print(f"PASSED ({self.duration:.1f}s)")
                self.status = "PASSED"
                return True
            else:
                print(f"FAILED ({self.duration:.1f}s)")
                self.status = "FAILED"
                return False


class ConfigurationTest:
    """Class to manage testing all modules for a specific configuration"""
    def __init__(self, width: int, pipe_stages: int, total_modules: int, log_dir: str):
        self.width = width
        self.pipe_stages = pipe_stages
        self.total_modules = total_modules
        self.log_dir = log_dir
        self.config_dir = f"{log_dir}/w{width}_p{pipe_stages}"
        self.config_key = f"{width}_{pipe_stages}"
        self.passed = 0
        self.failed = 0
        self.duration = 0
        self.module_tests: List[ModuleTest] = []
        
        # Create config directory
        os.makedirs(self.config_dir, exist_ok=True)
        
    def run(self) -> Tuple[int, int, float]:
        """Run tests for all modules with this configuration"""
        print("--------------------------------------------------------------------")
        print(f"Testing configuration: WIDTH={self.width}, PIPE_STAGES={self.pipe_stages}")
        print("--------------------------------------------------------------------")
        
        start_time = time.time()
        
        # Test each module
        for module_id in range(1, self.total_modules + 1):
            test = ModuleTest(module_id, self.width, self.pipe_stages, self.log_dir)
            self.module_tests.append(test)
            success = test.run_test()
            if success:
                self.passed += 1
            else:
                self.failed += 1
        
        self.duration = time.time() - start_time
        
        # Print configuration summary
        self._print_summary()
        
        # Generate HTML report for this configuration
        self._generate_html_report()
        
        return self.passed, self.failed, self.duration
    
    def _print_summary(self):
        """Print summary table for this configuration"""
        print()
        print(f"Configuration Summary: WIDTH={self.width}, PIPE_STAGES={self.pipe_stages}")
        print("-----------------------------------------------------------------------")
        print(f"{'MODULE':<8} | {'STATUS':<15} | {'TIME (sec)':<10}")
        print("-----------------------------------------------------------------------")
        
        for test in self.module_tests:
            print(f"Module {test.module_id:<2} | {test.status:<15} | {test.duration:<10.1f}")
        
        print("-----------------------------------------------------------------------")
        print(f"{'TOTAL':<8} | {f'{self.passed} passed, {self.failed} failed':<15} | {self.duration:<10.1f} seconds")
        print("-----------------------------------------------------------------------")
        print()
    
    def _generate_html_report(self):
        """Generate HTML report for this configuration"""
        html_file = f"{self.config_dir}/report.html"
        
        with open(html_file, "w") as f:
            f.write(f"""<!DOCTYPE html>
<html>
<head>
    <title>Test Report: WIDTH={self.width}, PIPE_STAGES={self.pipe_stages}</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th, td {{ padding: 8px; text-align: left; border: 1px solid #ddd; }}
        th {{ background-color: #f2f2f2; }}
        tr.passed td:nth-child(2) {{ color: green; font-weight: bold; }}
        tr.failed td:nth-child(2) {{ color: red; font-weight: bold; }}
        tr.summary {{ font-weight: bold; background-color: #f2f2f2; }}
        .summary-box {{ 
            padding: 10px;
            margin-top: 20px;
            border-radius: 5px;
            text-align: center;
            font-weight: bold;
        }}
        .success {{ background-color: #dff0d8; color: #3c763d; }}
        .failure {{ background-color: #f2dede; color: #a94442; }}
    </style>
</head>
<body>
    <h1>Test Report: WIDTH={self.width}, PIPE_STAGES={self.pipe_stages}</h1>
    <p><strong>Date:</strong> {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
    
    <h2>Results</h2>
    <table>
        <tr>
            <th>Module</th>
            <th>Status</th>
            <th>Log File</th>
        </tr>
""")
            
            # Add rows for each module
            for test in self.module_tests:
                status_class = "passed" if test.status == "PASSED" else "failed"
                log_filename = f"module_{test.module_id}.log"
                
                f.write(f"""        <tr class="{status_class}">
            <td>Module {test.module_id}</td>
            <td>{test.status}</td>
            <td><a href="{log_filename}" target="_blank">View Log</a></td>
        </tr>
""")
            
            # Add summary row
            f.write(f"""        <tr class="summary">
            <td>TOTAL</td>
            <td>{self.passed} passed, {self.failed} failed</td>
            <td>{self.duration:.1f} seconds</td>
        </tr>
    </table>
""")
            
            # Add summary box
            if self.failed == 0:
                f.write("""    <div class="summary-box success">
        ALL TESTS PASSED! 🎉
    </div>
""")
            else:
                f.write(f"""    <div class="summary-box failure">
        SOME TESTS FAILED! ❌ ({self.failed} out of {self.total_modules})
    </div>
""")
            
            # Add navigation link and close HTML
            f.write("""    <p><a href="../dashboard.html">Back to Dashboard</a></p>
</body>
</html>
""")


class TestSuite:
    """Main class to run all tests for multiple configurations"""
    def __init__(self, widths: List[int], pipe_stages: List[int], total_modules: int):
        self.widths = widths
        self.pipe_stages = pipe_stages
        self.total_modules = total_modules
        self.timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        self.log_dir = f"simulation_logs_{self.timestamp}"
        self.config_results: Dict[str, Dict[str, int]] = {}
        self.total_tests = 0
        self.total_passed = 0
        self.total_failed = 0
        self.total_duration = 0
        
        # Create log directory
        os.makedirs(self.log_dir, exist_ok=True)
    
    def run(self):
        """Run all configurations"""
        start_time = time.time()
        
        # Print header
        print("=======================================================================")
        print(f"Running tests for all {self.total_modules} arithmetic modules")
        print(f"Testing {len(self.widths)} WIDTH values: {self.widths}")
        print(f"Testing {len(self.pipe_stages)} PIPE_STAGES values: {self.pipe_stages}")
        print("=======================================================================")
        print()
        
        # Test all configurations
        for width in self.widths:
            for pipe_stages in self.pipe_stages:
                config = ConfigurationTest(width, pipe_stages, self.total_modules, self.log_dir)
                passed, failed, duration = config.run()
                
                config_key = f"{width}_{pipe_stages}"
                self.config_results[config_key] = {
                    "width": width,
                    "pipe_stages": pipe_stages,
                    "passed": passed,
                    "failed": failed,
                    "duration": duration
                }
                
                self.total_tests += self.total_modules
                self.total_passed += passed
                self.total_failed += failed
        
        self.total_duration = time.time() - start_time
        
        # Print final summary
        self._print_summary()
        
        # Generate dashboard HTML
        self._generate_dashboard()
        
        # Create a symbolic link to the latest run
        try:
            if os.path.exists("latest_results"):
                os.remove("latest_results")
            os.symlink(self.log_dir, "latest_results")
        except Exception as e:
            print(f"Warning: Could not create symbolic link: {e}")
        
        print()
        print("Test suite completed!")
        print(f"Dashboard HTML report generated: {self.log_dir}/dashboard.html")
        print("View the report at: latest_results/dashboard.html")
    
    def _print_summary(self):
        """Print final summary table"""
        print("=======================================================================")
        print("                    FINAL TEST SUMMARY")
        print("=======================================================================")
        print(f"Total configurations tested: {len(self.widths)}x{len(self.pipe_stages)} = {len(self.widths) * len(self.pipe_stages)}")
        print(f"Total modules tested: {self.total_tests}")
        print(f"Total tests passed: {self.total_passed}")
        print(f"Total tests failed: {self.total_failed}")
        print(f"Total time: {self.total_duration:.1f} seconds")
        print("=======================================================================")
    
    def _generate_dashboard(self):
        """Generate HTML dashboard with all results"""
        html_file = f"{self.log_dir}/dashboard.html"
        
        with open(html_file, "w") as f:
            f.write(f"""<!DOCTYPE html>
<html>
<head>
    <title>Pipeline Arithmetic Module Test Dashboard</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        table {{ border-collapse: collapse; width: 100%; margin-bottom: 20px; }}
        th, td {{ padding: 8px; text-align: left; border: 1px solid #ddd; }}
        th {{ background-color: #f2f2f2; }}
        .dashboard-title {{ text-align: center; margin-bottom: 20px; }}
        .summary {{ background-color: #f9f9f9; padding: 15px; margin-bottom: 20px; border-radius: 5px; }}
        .config-table {{ margin-top: 30px; }}
        .passed {{ color: green; font-weight: bold; }}
        .failed {{ color: red; font-weight: bold; }}
        .highlight {{ background-color: #ffffd0; }}
        .summary-box {{ 
            padding: 10px;
            margin-top: 20px;
            border-radius: 5px;
            text-align: center;
            font-weight: bold;
        }}
        .success {{ background-color: #dff0d8; color: #3c763d; }}
        .failure {{ background-color: #f2dede; color: #a94442; }}
    </style>
</head>
<body>
    <h1 class="dashboard-title">Pipeline Arithmetic Module Test Dashboard</h1>
    
    <div class="summary">
        <h2>Overall Summary</h2>
        <p><strong>Date:</strong> {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
        <p><strong>Configurations Tested:</strong> {len(self.widths)}x{len(self.pipe_stages)} = {len(self.widths) * len(self.pipe_stages)}</p>
        <p><strong>Total Tests:</strong> {self.total_tests}</p>
        <p><strong>Tests Passed:</strong> <span class="passed">{self.total_passed}</span></p>
        <p><strong>Tests Failed:</strong> <span class="failed">{self.total_failed}</span></p>
        <p><strong>Total Runtime:</strong> {self.total_duration:.1f} seconds</p>
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
""")
            
            # Add rows for each configuration
            for width in self.widths:
                for pipe_stages in self.pipe_stages:
                    config_key = f"{width}_{pipe_stages}"
                    if config_key in self.config_results:
                        result = self.config_results[config_key]
                        row_class = "highlight" if result["failed"] > 0 else ""
                        
                        f.write(f"""        <tr class="{row_class}">
            <td>{width}</td>
            <td>{pipe_stages}</td>
            <td class="passed">{result["passed"]}</td>
            <td class="failed">{result["failed"]}</td>
            <td>{result["duration"]:.1f}</td>
            <td><a href="w{width}_p{pipe_stages}/report.html">View Details</a></td>
        </tr>
""")
            
            # Add heat map section
            f.write("""    </table>
    
    <h2>Heat Map: Pass Rate by Configuration</h2>
    <table class="config-table">
        <tr>
            <th>Width / Pipeline Stages</th>
""")
            
            # Add column headers (pipeline stages)
            for pipe_stages in self.pipe_stages:
                f.write(f"            <th>{pipe_stages}</th>\n")
            
            f.write("        </tr>\n")
            
            # Add rows for each width with heat map cells
            for width in self.widths:
                f.write(f"        <tr>\n            <td>{width}</td>\n")
                
                for pipe_stages in self.pipe_stages:
                    config_key = f"{width}_{pipe_stages}"
                    if config_key in self.config_results:
                        result = self.config_results[config_key]
                        passed = result["passed"]
                        total = passed + result["failed"]
                        pass_rate = int((passed * 100) / total) if total > 0 else 0
                        
                        # Calculate background color based on pass rate (green to red gradient)
                        r = max(0, min(255, 255 - pass_rate * 2))
                        g = max(0, min(255, 55 + pass_rate * 2))
                        b = 50
                        
                        f.write(f'            <td style="background-color: rgb({r}, {g}, {b}); color: white; text-align: center;">{pass_rate}%</td>\n')
                    else:
                        f.write('            <td>N/A</td>\n')
                
                f.write("        </tr>\n")
            
            # Add summary box and close HTML
            summary_class = "success" if self.total_failed == 0 else "failure"
            summary_text = "ALL TESTS PASSED! 🎉" if self.total_failed == 0 else f"SOME TESTS FAILED! ❌ ({self.total_failed} out of {self.total_tests})"
            
            f.write(f"""    </table>
    
    <div class="summary-box {summary_class}">
        {summary_text}
    </div>
</body>
</html>
""")


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="Run SystemVerilog module tests with multiple configurations"
    )
    parser.add_argument("--widths", type=str, default="8,16",
                        help="Comma-separated list of WIDTH values to test (default: 8,16)")
    parser.add_argument("--pipe-stages", type=str, default="2,3,4",
                        help="Comma-separated list of PIPE_STAGES values to test (default: 2,3,4)")
    parser.add_argument("--modules", type=int, default=25,
                        help="Number of modules to test (default: 25)")
    return parser.parse_args()


def main():
    """Main function"""
    args = parse_arguments()
    
    # Parse width and pipe_stages lists
    try:
        widths = [int(w) for w in args.widths.split(",")]
        pipe_stages = [int(p) for p in args.pipe_stages.split(",")]
    except ValueError:
        print("Error: WIDTH and PIPE_STAGES must be comma-separated integers")
        sys.exit(1)
    
    # Validate arguments
    if not widths:
        print("Error: At least one WIDTH value must be specified")
        sys.exit(1)
    if not pipe_stages:
        print("Error: At least one PIPE_STAGES value must be specified")
        sys.exit(1)
    if args.modules < 1:
        print("Error: MODULES must be at least 1")
        sys.exit(1)
    
    # Run test suite
    test_suite = TestSuite(widths, pipe_stages, args.modules)
    test_suite.run()


if __name__ == "__main__":
    main()
