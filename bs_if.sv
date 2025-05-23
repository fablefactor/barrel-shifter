interface bs_if #(parameter DATA_WIDTH = 32) (input logic clk);

  // DUT Signals
  logic reset_n;
  logic [DATA_WIDTH-1:0] data_in;

  // Ensure shift_amount is at least 1 bit wide (e.g., [0:0]) as per subtask suggestion.
  // If DATA_WIDTH = 1, $clog2(1) = 0. Then SA_CALC_WIDTH = 1. shift_amount is logic [0:0].
  // If DATA_WIDTH > 1, $clog2(DATA_WIDTH) > 0. Then SA_CALC_WIDTH = $clog2(DATA_WIDTH).
  localparam SA_CALC_WIDTH = ($clog2(DATA_WIDTH) > 0) ? $clog2(DATA_WIDTH) : 1;
  logic [SA_CALC_WIDTH-1:0] shift_amount;

  logic [DATA_WIDTH-1:0] data_out;

  // Clocking block for Testbench components
  // Synchronizes signal sampling and driving to the clock edge.
  clocking tb_cb @(posedge clk);
    default input #1step output #1; // Default sampling and driving skews

    // Signals driven by the Testbench
    output reset_n;
    output data_in;
    output shift_amount;

    // Signals sampled by the Testbench
    input  data_out;
  endclocking : tb_cb

  // Modport for the Testbench (UVM components)
  // Provides access to the clocking block and asynchronous signals like reset
  modport tb_mp (
    clocking tb_cb, // Provides synchronized access to signals in tb_cb
    output reset_n   // Explicitly list reset_n if it needs to be driven asynchronously by TB
                     // or if preferred for clarity, even if part of cb.
  );

  // Modport for the DUT (Device Under Test)
  // Defines how the DUT connects to the interface signals
  modport dut_mp (
    input clk,
    input reset_n,
    input data_in,
    input shift_amount, // This will be logic [SA_CALC_WIDTH-1:0]
    output data_out
  );

endinterface : bs_if
