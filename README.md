```markdown
# Pipelined Barrel Shifter with UVM Testbench

## 1. Project Overview

This project implements a synthesizable, pipelined Verilog barrel shifter module capable of performing rotate left operations. The data bus width and the number of pipeline stages are parameterized. 
A comprehensive UVM (Universal Verification Methodology) testbench is provided to verify the shifter's functionality across various configurations and scenarios. The testbench includes a suite of tests and can be run using the provided Makefile with Synopsys VCS.

## 2. Barrel Shifter RTL (`barrel_shifter.v`)

The core of the design is the `barrel_shifter` Verilog module.

*   **Functionality**: Performs a rotate left operation on the input data.
*   **Parameters**:
    *   `DATA_WIDTH`: Specifies the width of the `data_in` and `data_out` buses. The default value in the top-level testbench (`tb_top.sv`) is 32. The corrected RTL module robustly handles `DATA_WIDTH=1`.
    *   `NUM_STAGES`: Defines the number of physical pipeline stages used to implement the barrel shifting logic. A value of `0` is treated by the RTL as equivalent to `1` stage. The default value in `tb_top.sv` is 1. The corrected RTL uses these stages to pipeline a series of logical shift-by-power-of-2 operations.
*   **Ports**:
    *   `input logic clk`: Clock signal.
    *   `input logic reset_n`: Active-low asynchronous reset.
    *   `input logic [DATA_WIDTH-1:0] data_in`: Data to be rotated.
    *   `input logic [(($clog2(DATA_WIDTH) > 0) ? $clog2(DATA_WIDTH) : 1)-1:0] shift_amount`: Number of bit positions to rotate left by. Width is correctly calculated to be at least 1.
    *   `output logic [DATA_WIDTH-1:0] data_out`: Rotated data output.
*   **Synthesizability**: The module is written using synthesizable Verilog constructs. The pipelined design with distributed logical operations is more resource-aware than cascading full shifters.

## 3. UVM Testbench Environment

A robust UVM environment is provided to verify the `barrel_shifter` DUT.

*   **Key Components**:
    *   `bs_transaction.sv`: Defines the transaction item, including input data, shift amount, actual output, and calculated expected output (handles `DATA_WIDTH=1` correctly).
    *   `bs_if.sv`: SystemVerilog interface connecting the DUT to the testbench (with robust `shift_amount` width).
    *   `bs_sequencer.sv`: Generates sequences of transactions.
    *   `bs_driver.sv`: Drives transactions to the DUT.
    *   `bs_monitor.sv`: Observes DUT signals, captures transactions, and correctly accounts for pipeline latency using its `NUM_STAGES` parameter (which is the effective latency).
    *   `bs_agent.sv`: Encapsulates the sequencer, driver, and monitor.
    *   `bs_scoreboard.sv`: Compares actual DUT outputs against expected outputs.
    *   `bs_env.sv`: Instantiates the agent and scoreboard.
    *   `bs_test_pkg.sv`: SystemVerilog package including all UVM classes.
    *   `tb_top.sv`: Top-level module instantiating DUT, interface, clock/reset, and starting UVM tests. Passes DUT hardware parameters (`P_DATA_WIDTH`, `P_NUM_STAGES`) to UVM via `uvm_config_db`.

*   **Testbench Configuration & Parameterization Focus**:
    *   The `barrel_shifter_base_test` retrieves `dut_data_width` and `dut_num_stages` (from `tb_top.sv` via `uvm_config_db`). It calculates `cfg_effective_latency = (dut_num_stages == 0) ? 1 : dut_num_stages;`.
    *   Derived tests (e.g., `bs_random_test`, `bs_narrow_width_test`) use these `cfg_` values to instantiate a specifically parameterized `bs_env #(cfg_dut_data_width, cfg_effective_latency)`.
    *   This ensures the UVM environment (especially the monitor and transaction generation) correctly adapts to the DUT configuration defined at the `tb_top.sv` level or overridden for a specific test run via Makefile variables (`DATA_WIDTH`, `NUM_STAGES` for `run_test`).
    *   Tests like `bs_narrow_width_test` demonstrate forcing specific parameters by setting them in `uvm_config_db` before the base test reads them.

*   **Implemented Test Cases**:
    *   `barrel_shifter_base_test`: Base for common configuration.
    *   `bs_smoke_test`: Default DUT params, few random transactions.
    *   `bs_random_test`: Configurable random transactions, adapts to `uvm_config_db` for DUT params.
    *   `bs_narrow_width_test`: UVM configured for `DATA_WIDTH=8, NUM_STAGES=1`.
    *   `bs_wide_width_test`: UVM configured for `DATA_WIDTH=128, NUM_STAGES=4`.
    *   `bs_min_stages_test`: UVM configured for `DATA_WIDTH=32, NUM_STAGES=0` (latency 1).
    *   `bs_max_stages_test`: UVM configured for `DATA_WIDTH=32, NUM_STAGES=5`.
    *   `bs_zero_shift_test`, `bs_full_rotate_test`, `bs_max_shift_test`: Test specific shift values.

## 4. Makefile Flow

A `Makefile` simplifies compilation and simulation using Synopsys VCS.

*   **Prerequisites**: Synopsys VCS installed.
*   **Targets**:
    *   `make help`: Displays detailed help on targets and variables.
    *   `make compile` (or `make`): Compiles DUT (with `tb_top.sv` defaults: `P_DATA_WIDTH=32, P_NUM_STAGES=1`) and testbench. Log: `compile.log`.
    *   `make run_test TESTNAME=<test> [DATA_WIDTH=<w>] [NUM_STAGES=<s>] [NUM_TRANS=<n>] [EXTRA_SIM_OPTS="<opts>"]`: Runs a specific test.
        *   `DATA_WIDTH`, `NUM_STAGES` set UVM config for expected DUT params. Scoreboard flags mismatches with compiled DUT.
        *   `NUM_TRANS` sets transaction counts for relevant tests.
        *   Log: `run_<test>_DW<w>_NS<s>_NT<n>.log`.
    *   `make run_all_tests`: Cleans, recompiles (default DUT), and runs a predefined test suite.
    *   `make clean`: Removes generated files.

## 5. Directory Structure

*   `barrel_shifter.v`: Verilog DUT module.
*   `bs_if.sv`: SystemVerilog interface for the DUT.
*   `tb_top.sv`: Top-level SystemVerilog testbench module.
*   `bs_test_pkg.sv`: UVM package including all UVM components, sequences, and tests.
    *   (Includes: `bs_transaction.sv`, `bs_sequencer.sv`, `bs_driver.sv`, `bs_monitor.sv`, `bs_agent.sv`, `bs_scoreboard.sv`, `bs_env.sv`)
    *   (Includes: `bs_single_item_sequence.sv`, `bs_random_stimulus_sequence.sv`, etc.)
    *   (Includes: `base_test.sv`, `bs_smoke_test.sv`, `bs_random_test.sv`, etc.)
*   `Makefile`: For compiling and running simulations.
*   `README.md`: This file (or `PROJECT_README.md` if this creation is successful).
```
