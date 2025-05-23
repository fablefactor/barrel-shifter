import uvm_pkg::*;
`include "uvm_macros.svh"

// Assume bs_agent.sv and bs_scoreboard.sv are available and compiled.

class bs_env #(
    parameter DATA_WIDTH = 32,
    parameter int NUM_STAGES = 1 // Represents DUT latency, passed to agent
) extends uvm_env;

    // Factory registration
    `uvm_component_param_utils(bs_env#(DATA_WIDTH, NUM_STAGES))

    // Component handles
    bs_agent #(DATA_WIDTH, NUM_STAGES) agent;
    bs_scoreboard #(DATA_WIDTH) scoreboard; // Scoreboard does not need NUM_STAGES directly,
                                          // as monitor handles latency compensation.

    // Constructor
    function new(string name = "bs_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // build_phase: Create environment components
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create the agent instance.
        // The agent is parameterized with DATA_WIDTH and NUM_STAGES.
        // NUM_STAGES is used by the agent to parameterize its monitor for DUT latency.
        agent = bs_agent#(DATA_WIDTH, NUM_STAGES)::type_id::create("agent", this);
        if (agent == null) begin
            `uvm_fatal(get_type_name(), "Failed to create agent component")
        end

        // Create the scoreboard instance.
        // The scoreboard is parameterized with DATA_WIDTH only.
        scoreboard = bs_scoreboard#(DATA_WIDTH)::type_id::create("scoreboard", this);
        if (scoreboard == null) begin
            `uvm_fatal(get_type_name(), "Failed to create scoreboard component")
        end

        // Note: Agent's active/passive state (is_active) is typically configured by the test
        // using uvm_config_db targeting the agent's path (e.g., "uvm_test_top.env.agent.is_active").
        // The uvm_agent base class build_phase already handles retrieving this value.
    endfunction : build_phase

    // connect_phase: Connect components within the environment
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect the agent's analysis port to the scoreboard's analysis export.
        // Ensure components and their ports exist before attempting to connect.
        if (agent != null && scoreboard != null) begin
            if (agent.agent_ap != null && scoreboard.item_analysis_export != null) begin
                agent.agent_ap.connect(scoreboard.item_analysis_export);
            end else begin
                if (agent.agent_ap == null) begin
                    `uvm_error(get_type_name(), "Agent's analysis port (agent_ap) is null. Cannot connect to scoreboard.")
                end
                if (scoreboard.item_analysis_export == null) begin
                    `uvm_error(get_type_name(), "Scoreboard's analysis export (item_analysis_export) is null. Cannot connect agent.")
                end
            end
        end else begin
            if (agent == null) begin
                `uvm_error(get_type_name(), "Agent instance is null. Cannot connect to scoreboard.")
            end
            if (scoreboard == null) begin
                `uvm_error(get_type_name(), "Scoreboard instance is null. Cannot connect agent.")
            end
        end
    endfunction : connect_phase

endclass : bs_env
