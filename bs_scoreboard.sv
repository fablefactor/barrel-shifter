import uvm_pkg::*;
`include "uvm_macros.svh"

// Assuming bs_transaction.sv is available and compiled.
// No forward typedef needed for parameterized types like bs_transaction#(DATA_WIDTH).

class bs_scoreboard #(
    parameter DATA_WIDTH = 32
) extends uvm_scoreboard;

    // Factory registration
    `uvm_component_param_utils(bs_scoreboard#(DATA_WIDTH))

    // Analysis implementation port to receive transactions from the monitor
    uvm_analysis_imp #(bs_transaction#(DATA_WIDTH), bs_scoreboard#(DATA_WIDTH)) item_analysis_export;

    // Counters for tracking passed and failed transactions
    protected int m_passed_items;
    protected int m_failed_items;

    // Constructor
    function new(string name = "bs_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        // Create the analysis export
        item_analysis_export = new("item_analysis_export", this);
        // Initialize counters
        m_passed_items = 0;
        m_failed_items = 0;
    endfunction : new

    // write method: Called when a transaction is received via item_analysis_export
    virtual function void write(bs_transaction#(DATA_WIDTH) trans);
        if (trans == null) begin
            `uvm_warning(get_type_name(), "Received null transaction in write method.")
            return;
        end

        `uvm_info(get_type_name(), 
                  $sformatf("Comparing transaction: DataIn=0x%h, ShiftAmt=0x%h, Actual DO=0x%h, Expected DO=0x%h", 
                            trans.data_in, trans.shift_amount, trans.data_out, trans.expected_data_out), 
                  UVM_HIGH) // UVM_HIGH for potentially verbose per-transaction comparison details

        // Compare actual DUT output (trans.data_out) with expected output (trans.expected_data_out)
        // trans.expected_data_out should have been calculated by bs_transaction::post_randomize
        // when the transaction was created by a sequence.
        // trans.data_out should have been populated by the monitor with the actual DUT output.
        if (trans.data_out == trans.expected_data_out) begin
            `uvm_info(get_type_name(), 
                      $sformatf("PASSED: Transaction details: %s", trans.convert2string()), 
                      UVM_MEDIUM) // UVM_MEDIUM for passed transaction details
            m_passed_items++;
        end else begin
            `uvm_error(get_type_name(), 
                       $sformatf("FAILED: Actual DO: 0x%h != Expected DO: 0x%h. Transaction: %s", 
                                 trans.data_out, trans.expected_data_out, trans.convert2string()))
            m_failed_items++;
        end
    endfunction : write

    // report_phase: Summarize scoreboard results at the end of the test
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "---------------------------------------------------", UVM_LOW);
        `uvm_info(get_type_name(), "               Scoreboard Final Report             ", UVM_LOW);
        `uvm_info(get_type_name(), "---------------------------------------------------", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("Transactions Processed: %0d", m_passed_items + m_failed_items), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("PASSED items          : %0d", m_passed_items), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("FAILED items          : %0d", m_failed_items), UVM_LOW);
        `uvm_info(get_type_name(), "---------------------------------------------------", UVM_LOW);

        if (m_failed_items > 0) begin
            // The `uvm_error macro already contributes to the test failure status.
            // Additional messages can be printed if desired.
            `uvm_info(get_type_name(), "NOTE: Test has FAILED due to scoreboard mismatches.", UVM_LOW)
        end else if ((m_passed_items + m_failed_items) == 0) begin
             `uvm_warning(get_type_name(), "No transactions were processed by the scoreboard.")
        end else begin
            `uvm_info(get_type_name(), "NOTE: Test has PASSED scoreboard checks.", UVM_LOW)
        end
        `uvm_info(get_type_name(), "---------------------------------------------------", UVM_LOW);
    endfunction : report_phase

endclass : bs_scoreboard
