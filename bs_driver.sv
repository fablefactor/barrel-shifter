```systemverilog
import uvm_pkg::*;
`include "uvm_macros.svh"

// Forward declaration or ensure bs_transaction.sv is compiled first.
// For parameterized types, direct usage is often fine if files are in correct compilation order.
// Interface bs_if will be accessed via virtual interface handle.

class bs_driver #(
    parameter DATA_WIDTH = 32,
    parameter NUM_STAGES = 1 // NUM_STAGES is included for completeness, though not directly used in this simple driver.
) extends uvm_driver #(bs_transaction#(DATA_WIDTH));

    // Factory registration
    `uvm_component_param_utils(bs_driver#(DATA_WIDTH, NUM_STAGES))

    // Virtual interface handle to connect to the DUT
    virtual bs_if#(DATA_WIDTH) vif;

    // Constructor
    function new(string name = "bs_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // connect_phase: Get the virtual interface from the configuration database
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (!uvm_config_db#(virtual bs_if#(DATA_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("Virtual interface must be set for %s.vif", get_full_name()))
        end
    endfunction : connect_phase

    // run_phase: Main task to drive transactions to the DUT
    virtual task run_phase(uvm_phase phase);
        bs_transaction#(DATA_WIDTH) req; // Transaction handle

        // Initialize DUT inputs to a known state at the beginning of the simulation.
        // This ensures inputs are not 'X' before the first transaction.
        // Reset sequence (usually in test or env) should handle reset_n.
        // Driver focuses on data/shift_amount after reset.
        fork
            begin
                // Drive initial default values using the clocking block
                // This ensures proper timing relative to the clock.
                @(vif.tb_cb); // Wait for the first clock edge if reset is synchronous, or just to align
                vif.tb_cb.data_in <= {DATA_WIDTH{1'b0}};
                // SA_CALC_WIDTH is local to bs_if, but shift_amount port on cb is correctly sized.
                vif.tb_cb.shift_amount <= '0; // Drive 0, will be correctly sized.
                @(vif.tb_cb); // Wait one cycle for these initial values to be seen/settle
            end
        join_none // Allow the main loop to start immediately if needed, or use join if these are prerequisite

        // Main loop to get and drive transactions
        forever begin
            // Get the next transaction item from the sequencer
            seq_item_port.get_next_item(req);

            `uvm_info(get_type_name(), $sformatf("Driving transaction: %s", req.convert2string()), UVM_MEDIUM)

            // Drive transaction data to the DUT inputs via the clocking block
            // The clocking block handles the timing of when these signals are driven
            // relative to the clock edge (e.g., #1 output skew).
            vif.tb_cb.data_in <= req.data_in;
            vif.tb_cb.shift_amount <= req.shift_amount;

            // Wait for one clock cycle. This allows the DUT to sample the driven values.
            // The DUT's first pipeline stage will latch these inputs on this clock edge.
            @(vif.tb_cb);

            // Signal that the transaction item has been processed by the driver.
            // No response data is sent back with item_done() in this case.
            seq_item_port.item_done();

            // Note: There is no need to explicitly "de-assert" data lines unless the
            // interface protocol requires it (e.g., using a valid signal).
            // For this shifter, inputs can remain stable or change with the next transaction.
            // The NUM_STAGES parameter doesn't affect this core driving loop, as the driver
            // is only responsible for getting new inputs to the DUT. Monitor handles latency.
        end
    endtask : run_phase

endclass : bs_driver
```
