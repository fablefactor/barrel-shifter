import uvm_pkg::*;
`include "uvm_macros.svh"
import bs_test_pkg::*; // Includes all our UVM components and tests

module tb_top;

  // Default DUT Parameters - these can be overridden at compile time
  localparam int P_DATA_WIDTH = 32;
  localparam int P_NUM_STAGES = 1;

  logic clk;
  logic reset_n;

  // Clock generation
  localparam time CLK_PERIOD = 10ns;
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Reset generation
  initial begin
    reset_n = 1'b0; // Assert reset
    repeat(5) @(posedge clk);
    reset_n = 1'b1; // De-assert reset
    `uvm_info("TB_TOP", "Reset de-asserted", UVM_LOW)
  end

  // Instantiate the interface
  // The interface is parameterized with P_DATA_WIDTH from tb_top
  bs_if #(P_DATA_WIDTH) dut_if(clk); 
  // Connect reset to the interface instance
  assign dut_if.reset_n = reset_n;

  // Instantiate the DUT
  // The DUT is parameterized with P_DATA_WIDTH and P_NUM_STAGES from tb_top
  barrel_shifter #(
    .DATA_WIDTH(P_DATA_WIDTH),
    .NUM_STAGES(P_NUM_STAGES)
  ) dut (
    .clk(dut_if.clk), // Use clk from interface
    .reset_n(dut_if.reset_n),
    .data_in(dut_if.data_in),
    .shift_amount(dut_if.shift_amount),
    .data_out(dut_if.data_out)
  );

  // UVM test execution
  initial begin
    `uvm_info("TB_TOP", $sformatf("Starting testbench with DUT DATA_WIDTH=%0d, NUM_STAGES=%0d", P_DATA_WIDTH, P_NUM_STAGES), UVM_LOW);

    // Set the virtual interface for UVM driver and monitor
    // These paths assume the UVM hierarchy: uvm_test_top -> env -> agent -> driver / monitor
    uvm_config_db#(virtual bs_if#(P_DATA_WIDTH))::set(null, "uvm_test_top.env.agent.driver", "vif", dut_if);
    uvm_config_db#(virtual bs_if#(P_DATA_WIDTH))::set(null, "uvm_test_top.env.agent.monitor", "vif", dut_if);

    // Set DUT parameters for the UVM base_test to retrieve.
    // This allows tests to know the DUT's compile-time configuration.
    uvm_config_db#(int)::set(null, "uvm_test_top", "dut_data_width", P_DATA_WIDTH);
    uvm_config_db#(int)::set(null, "uvm_test_top", "dut_num_stages", P_NUM_STAGES);

    // Run the UVM test specified by +UVM_TESTNAME=your_test_name on the command line
    run_test();
  end

endmodule
