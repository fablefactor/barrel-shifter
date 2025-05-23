# Makefile for Barrel Shifter UVM Testbench

# --- Variables ---
SHELL = /bin/bash
VCS = vcs
SIMV = ./simv
RM = rm -rf

# Source Files
DUT_FILES = barrel_shifter.v
IF_FILES = bs_if.sv
TB_TOP_FILES = tb_top.sv
# UVM package includes all other .sv files for the testbench
UVM_PKG_FILES = bs_test_pkg.sv 

# All SV files for compilation. Order matters for packages.
VERILOG_SOURCES = $(DUT_FILES)
# bs_test_pkg.sv includes other .sv files. tb_top needs bs_test_pkg and bs_if.
SV_SOURCES = $(IF_FILES) $(UVM_PKG_FILES) $(TB_TOP_FILES) 

# VCS Compile Options
# -lca for UVM/SystemVerilog link-time checks and optimizations.
# -kdb for interactive debugging database (optional, good for Verdi).
VCS_OPTS = -sverilog -ntb_opts uvm-1.2 -debug_acc+all -timescale=1ns/1ps -lca -kdb
VCS_COMPILE_LOG = compile.log

# Simulation Run Options
SIMV_OPTS_COMMON = +UVM_VERBOSITY=UVM_LOW
# Any other common runtime options can be added here.

# Default values for run_test if not provided by user from command line
# Example: make run_test TESTNAME=my_test DATA_WIDTH=64 NUM_STAGES=0 NUM_TRANS=50
TESTNAME ?= bs_smoke_test
DATA_WIDTH ?= 32 # For UVM config db, should ideally match compiled DUT for meaningful results
NUM_STAGES ?= 1  # For UVM config db (0-N for DUT parameter, becomes latency 1 to N for monitor)
NUM_TRANS ?= 20  # Default number of transactions for tests that use it
EXTRA_SIM_OPTS ?= "" # For additional user-defined sim options

help:
	@echo ""
	@echo "Barrel Shifter UVM Testbench Makefile Help"
	@echo "--------------------------------------------"
	@echo "Available targets:"
	@echo "  make all           : Compiles the DUT and testbench (default)."
	@echo "  make compile       : Compiles the DUT and testbench."
	@echo "  make run_test      : Runs a specific test."
	@echo "                       Variables to set:"
	@echo "                         TESTNAME=<test_name>  (Default: bs_smoke_test)"
	@echo "                         DATA_WIDTH=<value>    (Default: 32, for UVM config)"
	@echo "                         NUM_STAGES=<value>    (Default: 1, for UVM config)"
	@echo "                         NUM_TRANS=<value>     (Default: 20, for UVM config for num transactions in tests)"
	@echo "                         EXTRA_SIM_OPTS="<opts>" (Optional: e.g., +UVM_VERBOSITY=UVM_HIGH)"
	@echo "                       Example: make run_test TESTNAME=bs_random_test DATA_WIDTH=64 NUM_STAGES=0 NUM_TRANS=100"
	@echo "  make run_all_tests : Cleans, recompiles, and runs a predefined suite of tests."
	@echo "  make clean         : Removes generated simulation files, logs, and databases."
	@echo "  make docs          : Placeholder for documentation generation."
	@echo "  make help          : Shows this help message."
	@echo ""
	@echo "Note on DUT Parameters (P_DATA_WIDTH, P_NUM_STAGES in tb_top.sv):"
	@echo "  The 'compile' target uses the default values set in 'tb_top.sv' (currently 32-bit, 1-stage)."
	@echo "  The DATA_WIDTH and NUM_STAGES variables for 'run_test' configure the UVM environment's expectation"
	@echo "  of the DUT. If these differ from the compiled DUT parameters, the scoreboard should detect issues."
	@echo ""

# --- Targets ---
.PHONY: all compile run_test run_all_tests clean docs help

all: compile

compile:
	@echo "Compiling DUT and Testbench (DUT: P_DATA_WIDTH=32, P_NUM_STAGES=1 from tb_top.sv defaults)..."
	$(VCS) $(VCS_OPTS) $(VERILOG_SOURCES) $(SV_SOURCES) -o $(SIMV) -l $(VCS_COMPILE_LOG)

run_test: compile
	@echo "Running test: $(TESTNAME) with UVM config: DATA_WIDTH=$(DATA_WIDTH), NUM_STAGES=$(NUM_STAGES), NUM_TRANS=$(NUM_TRANS)"
	@echo "Note: Actual DUT hardware compiled with P_DATA_WIDTH, P_NUM_STAGES from tb_top.sv defaults."
	$(SIMV) $(SIMV_OPTS_COMMON) \
		+UVM_TESTNAME=$(TESTNAME) \
		+uvm_set_config_int=uvm_test_top,dut_data_width,$(DATA_WIDTH) \
		+uvm_set_config_int=uvm_test_top,dut_num_stages,$(NUM_STAGES) \
		+uvm_set_config_int=uvm_test_top,num_sequence_transactions,$(NUM_TRANS) \
		+uvm_set_config_int=uvm_test_top,num_zero_shift_transactions,$(NUM_TRANS) \
		+uvm_set_config_int=uvm_test_top,num_full_rotate_transactions,$(NUM_TRANS) \
		+uvm_set_config_int=uvm_test_top,num_max_shift_transactions,$(NUM_TRANS) \
		+uvm_set_config_int=uvm_test_top,num_narrow_width_transactions,$(NUM_TRANS) \
		+uvm_set_config_int=uvm_test_top,num_wide_width_transactions,$(NUM_TRANS) \
		+uvm_set_config_int=uvm_test_top,num_min_stages_transactions,$(NUM_TRANS) \
		+uvm_set_config_int=uvm_test_top,num_max_stages_transactions,$(NUM_TRANS) \
		$(EXTRA_SIM_OPTS) -l run_$(TESTNAME)_DW$(DATA_WIDTH)_NS$(NUM_STAGES)_NT$(NUM_TRANS).log

run_all_tests: clean compile
	@echo "Running all specified tests..."
	@echo "Note: All tests run against DUT compiled with tb_top.sv defaults (P_DATA_WIDTH=32, P_NUM_STAGES=1)."
	@echo "Tests targeting other DUT parameters will configure UVM environment accordingly; scoreboard will catch mismatches if any."
	$(MAKE) run_test TESTNAME=bs_smoke_test DATA_WIDTH=32 NUM_STAGES=1 NUM_TRANS=5
	$(MAKE) run_test TESTNAME=bs_random_test DATA_WIDTH=32 NUM_STAGES=1 NUM_TRANS=250
	# Following tests use their internal const for DUT config, UVM config matches this.
	# The DATA_WIDTH/NUM_STAGES passed to run_test here are for UVM config consistency.
	$(MAKE) run_test TESTNAME=bs_narrow_width_test DATA_WIDTH=8 NUM_STAGES=1 NUM_TRANS=50
	$(MAKE) run_test TESTNAME=bs_wide_width_test DATA_WIDTH=128 NUM_STAGES=4 NUM_TRANS=100
	$(MAKE) run_test TESTNAME=bs_min_stages_test DATA_WIDTH=32 NUM_STAGES=0 NUM_TRANS=75
	$(MAKE) run_test TESTNAME=bs_max_stages_test DATA_WIDTH=32 NUM_STAGES=5 NUM_TRANS=100
	$(MAKE) run_test TESTNAME=bs_zero_shift_test DATA_WIDTH=32 NUM_STAGES=1 NUM_TRANS=30
	$(MAKE) run_test TESTNAME=bs_full_rotate_test DATA_WIDTH=32 NUM_STAGES=1 NUM_TRANS=30
	$(MAKE) run_test TESTNAME=bs_max_shift_test DATA_WIDTH=32 NUM_STAGES=1 NUM_TRANS=30
	@echo "Completed all tests. Check run_*.log files for results."

clean:
	@echo "Cleaning up..."
	$(RM) $(SIMV) simv.daidir csrc ucli.key *.vdb DVEfiles verdiLog AN.DB novas.* *.log compile.log novas_dump.log *.fsdb transcript work *.bak *.elab.log default.svcf *.history .restartSim* .synopsys* inter.vpd urgReport* *.vpd
	@echo "Clean complete."

# Placeholder for documentation generation if added later
docs:
	@echo "Documentation generation target exists, but not yet implemented."
