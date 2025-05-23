import uvm_pkg::*;
`include "uvm_macros.svh"

// Forward declarations or ensure component files are compiled first.
// bs_sequencer.sv, bs_driver.sv, bs_monitor.sv, bs_transaction.sv

class bs_agent #(
    parameter DATA_WIDTH = 32,
    parameter int NUM_STAGES = 1 // NUM_STAGES for DUT latency, mainly for monitor/driver config
) extends uvm_agent;

    // Factory registration
    `uvm_component_param_utils(bs_agent#(DATA_WIDTH, NUM_STAGES))

    // Components
    // Sequencer only needs DATA_WIDTH as it deals with transactions.
    bs_sequencer #(DATA_WIDTH) sequencer;
    // Driver and Monitor might need NUM_STAGES for latency considerations.
    bs_driver    #(DATA_WIDTH, NUM_STAGES) driver;
    bs_monitor   #(DATA_WIDTH, NUM_STAGES) monitor;

    // Analysis Port for broadcasting transactions collected by the monitor
    uvm_analysis_port #(bs_transaction#(DATA_WIDTH)) agent_ap;

    // Constructor
    function new(string name = "bs_agent", uvm_component parent = null);
        super.new(name, parent);
        // Create the analysis port
        agent_ap = new("agent_ap", this);
    endfunction : new

    // build_phase: Create agent components
    virtual function void build_phase(uvm_phase phase);
        // uvm_agent's build_phase retrieves 'is_active' from config_db
        super.build_phase(phase);

        // Create the monitor instance (always created, regardless of active/passive)
        // The monitor needs DATA_WIDTH and NUM_STAGES for its operation.
        monitor = bs_monitor#(DATA_WIDTH, NUM_STAGES)::type_id::create("monitor", this);
        if (monitor == null) begin
            `uvm_fatal(get_type_name(), "Failed to create monitor component")
        end

        // Create active components (driver and sequencer) only if the agent is UVM_ACTIVE
        if (get_is_active() == UVM_ACTIVE) begin
            // Driver needs DATA_WIDTH and NUM_STAGES.
            driver = bs_driver#(DATA_WIDTH, NUM_STAGES)::type_id::create("driver", this);
            if (driver == null) begin
                `uvm_fatal(get_type_name(), "Failed to create driver component")
            end

            // Sequencer only needs DATA_WIDTH.
            sequencer = bs_sequencer#(DATA_WIDTH)::type_id::create("sequencer", this);
            if (sequencer == null) begin
                `uvm_fatal(get_type_name(), "Failed to create sequencer component")
            end
        end
    endfunction : build_phase

    // connect_phase: Connect agent components
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect the monitor's output analysis port to the agent's analysis port.
        // Ensure monitor and its port exist before connecting.
        if (monitor != null && monitor.item_collected_port != null) begin
            monitor.item_collected_port.connect(this.agent_ap);
        end else if (monitor == null) begin
            `uvm_warning(get_type_name(), "Monitor instance is null, cannot connect item_collected_port.")
        end else begin // monitor.item_collected_port is null
            `uvm_warning(get_type_name(), "Monitor's item_collected_port is null, cannot connect to agent_ap.")
        end


        // If the agent is UVM_ACTIVE, connect the driver and sequencer.
        if (get_is_active() == UVM_ACTIVE) begin
            // Ensure driver and sequencer, and their respective ports, exist before connecting.
            if (driver != null && driver.seq_item_port != null &&
                sequencer != null && sequencer.seq_item_export != null) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end else begin
                if (driver == null) `uvm_warning(get_type_name(), "Driver instance is null, cannot connect to sequencer.")
                if (sequencer == null) `uvm_warning(get_type_name(), "Sequencer instance is null, cannot connect driver.")
                // Specific port null checks could also be added if necessary
            end
        end
    endfunction : connect_phase

endclass : bs_agent
