```systemverilog
import uvm_pkg::*;
`include "uvm_macros.svh"

// Assuming bs_transaction.sv is compiled before this file,
// or included if part of a package compilation unit.
// No forward typedef needed for parameterized types like bs_transaction#(DATA_WIDTH).

// Class definition for the sequencer
// This sequencer will generate and send bs_transaction items.
class bs_sequencer #(
    parameter DATA_WIDTH = 32
) extends uvm_sequencer #(bs_transaction#(DATA_WIDTH));

    // Factory registration macro
    `uvm_component_param_utils(bs_sequencer#(DATA_WIDTH))

    // Constructor
    function new(string name = "bs_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

endclass : bs_sequencer
```
