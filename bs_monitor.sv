```systemverilog
import uvm_pkg::*;
`include "uvm_macros.svh"

// Assumes bs_transaction.sv and bs_if.sv are available through compilation order or package.

class bs_monitor #(
    parameter DATA_WIDTH = 32,
    parameter int NUM_STAGES = 1 // Represents effective DUT latency (should be >= 1)
) extends uvm_monitor;

    `uvm_component_param_utils(bs_monitor#(DATA_WIDTH, NUM_STAGES))

    // Virtual interface to access DUT signals
    virtual bs_if#(DATA_WIDTH) vif;

    // Analysis port to broadcast collected transactions to scoreboard
    uvm_analysis_port #(bs_transaction#(DATA_WIDTH)) item_collected_port;

    // Internal queue to model DUT pipeline latency for inputs
    // It stores transactions containing data_in and shift_amount that have entered the DUT.
    local bs_transaction#(DATA_WIDTH) input_pipeline[$];

    // Effective latency this monitor instance will use.
    int actual_monitor_latency;

    // Constructor
    function new(string name = "bs_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction : new

    // Build phase: Configure latency
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (this.NUM_STAGES < 1) begin
            // This case should ideally not be hit if base_test configures NUM_STAGES >= 1 for monitor
            `uvm_warning(get_type_name(), $sformatf("Monitor's NUM_STAGES parameter is %0d, which is < 1. Effective latency will be set to 1.", this.NUM_STAGES))
            actual_monitor_latency = 1;
        end else begin // Corrected typo: ELDS_PER_STAGE to else
            actual_monitor_latency = this.NUM_STAGES;
        end
        `uvm_info(get_type_name(), $sformatf("Monitor configured for effective latency = %0d cycles.", actual_monitor_latency), UVM_LOW)
    endfunction : build_phase

    // Connect phase: Get the virtual interface
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (!uvm_config_db#(virtual bs_if#(DATA_WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", $sformatf("Virtual interface must be set for %s.vif", get_full_name()))
        end
    endfunction : connect_phase

    // Run phase: Observe DUT signals and publish transactions
    virtual task run_phase(uvm_phase phase);
        bs_transaction#(DATA_WIDTH) current_inputs_capture_tr; // To capture current inputs
        bs_transaction#(DATA_WIDTH) transaction_to_publish;    // To hold the transaction popped from queue

        // Wait for reset to de-assert initially before starting collection.
        // This ensures that vif is valid and reset sequence has completed.
        // Wait for reset_n to be high at a positive clock edge.
        @(posedge vif.clk iff vif.reset_n === 1'b1);
        // Optional: Add a few cycle delays if DUT reset propagation is slow or other stabilization needed.
        // repeat(2) @(vif.tb_cb); 

        `uvm_info(get_type_name(), "Monitoring started after reset.", UVM_MEDIUM)

        forever begin
            @(vif.tb_cb); // Synchronize to DUT clock edge (via clocking block)

            // If reset becomes active during operation, clear the pipeline and wait.
            if (vif.reset_n == 0) begin
                input_pipeline.delete(); // Clear any pending items
                `uvm_info(get_type_name(), "Reset active. Flushing monitor pipeline and waiting for reset de-assertion.", UVM_MEDIUM);
                @(posedge vif.clk iff vif.reset_n === 1'b1); // Wait until reset is gone
                // repeat(2) @(vif.tb_cb); // Optional delay post-reset
                `uvm_info(get_type_name(), "Reset de-asserted. Resuming monitoring.", UVM_MEDIUM);
                continue; // Skip this cycle's processing
            end

            // 1. Capture current input values (data_in, shift_amount)
            current_inputs_capture_tr = bs_transaction#(DATA_WIDTH)::type_id::create("monitor_input_capture_tr");
            current_inputs_capture_tr.data_in = vif.tb_cb.data_in;
            current_inputs_capture_tr.shift_amount = vif.tb_cb.shift_amount;
            
            // Call post_randomize to calculate expected_data_out based on these inputs.
            // This is useful if convert2string prints it or for early debug.
            // The scoreboard will be the ultimate verifier of expected vs. actual.
            current_inputs_capture_tr.post_randomize();

            // 2. Store this captured input transaction in our delay pipeline
            input_pipeline.push_back(current_inputs_capture_tr);

            // 3. If enough input transactions have been enqueued to cover the DUT's latency,
            //    then the oldest input transaction in our pipeline now has its corresponding output
            //    available at the DUT's output.
            if (input_pipeline.size() > actual_monitor_latency) {
                // Retrieve the oldest input transaction (which entered the DUT 'actual_monitor_latency' cycles ago)
                transaction_to_publish = input_pipeline.pop_front(); 
                
                // Assign the currently observed DUT output to this past transaction
                transaction_to_publish.data_out = vif.tb_cb.data_out;

                `uvm_info(get_type_name(), $sformatf("Collected transaction: %s", transaction_to_publish.convert2string()), UVM_FULL);
                item_collected_port.write(transaction_to_publish);
            }
        end
    endtask : run_phase

endclass : bs_monitor
```
