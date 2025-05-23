import uvm_pkg::*;
`include "uvm_macros.svh"

class bs_transaction #(parameter DATA_WIDTH = 32) extends uvm_sequence_item;

  // Calculate SA_WIDTH consistent with bs_if.sv
  // If DATA_WIDTH = 1, $clog2(1) = 0. Then SA_WIDTH = 1. shift_amount is logic [0:0].
  // If DATA_WIDTH > 1, $clog2(DATA_WIDTH) > 0. Then SA_WIDTH = $clog2(DATA_WIDTH).
  localparam SA_WIDTH = ($clog2(DATA_WIDTH) > 0) ? $clog2(DATA_WIDTH) : 1;

  // Data Fields
  rand logic [DATA_WIDTH-1:0] data_in;
  rand logic [SA_WIDTH-1:0]   shift_amount;
  logic [DATA_WIDTH-1:0]      data_out;          // Actual data from DUT, captured by monitor
  logic [DATA_WIDTH-1:0]      expected_data_out; // Expected data, calculated in post_randomize

  // UVM Object Utilities
  `uvm_object_param_utils_begin(bs_transaction#(DATA_WIDTH))
    `uvm_field_int(data_in, UVM_ALL_ON)
    `uvm_field_int(shift_amount, UVM_ALL_ON)
    `uvm_field_int(data_out, UVM_ALL_ON | UVM_NOCOMPARE) // Captured by monitor, not for direct comparison here
    `uvm_field_int(expected_data_out, UVM_ALL_ON)      // Calculated, used for comparison by scoreboard
  `uvm_object_utils_end

  // Constraints
  // If DATA_WIDTH is 1, shift_amount must be 0.
  // SA_WIDTH will be 1, so shift_amount is [0:0].
  constraint c_sa_for_data_width_1 {
    if (DATA_WIDTH == 1) {
      shift_amount == 0;
    }
  }

  // shift_amount should be less than DATA_WIDTH.
  // This is important if DATA_WIDTH is not a power of 2.
  // E.g. DATA_WIDTH=30, $clog2(30)=5, SA_WIDTH=5, shift_amount is [4:0], max val 31.
  // Constraint ensures shift_amount is within [0, DATA_WIDTH-1].
  constraint c_sa_value_range {
    if (DATA_WIDTH > 1) { // For DATA_WIDTH=1, c_sa_for_data_width_1 handles it.
      shift_amount < DATA_WIDTH;
    }
  }

  // Constructor
  function new(string name = "bs_transaction");
    super.new(name);
  endfunction : new

  // post_randomize: Calculate expected_data_out
  function void post_randomize();
    if (DATA_WIDTH == 0) begin // Should not happen with valid DATA_WIDTH
      expected_data_out = {DATA_WIDTH{1'bx}}; // Or '0
    end else if (DATA_WIDTH == 1) begin
      // For DATA_WIDTH=1, shift_amount is constrained to 0.
      // sa_eff will be 0.
      // (data_in << 0) | (data_in >> (1-0)) = data_in | (data_in[0] >> 1) = data_in | 0 = data_in
      expected_data_out = data_in;
    end else begin
      // shift_amount is constrained to be < DATA_WIDTH.
      // The rotate left expression: (data_in << sa) | (data_in >> (WIDTH - sa))
      // This works correctly for sa = 0 as well: (din << 0) | (din >> WIDTH) = din | 0 = din.
      expected_data_out = (data_in << shift_amount) | (data_in >> (DATA_WIDTH - shift_amount));
    end
  endfunction : post_randomize

  // do_copy: Custom implementation not strictly needed if using `uvm_field_* macros correctly,
  // but often provided for clarity or if there's custom logic beyond simple field copy.
  // The macros handle copying of registered fields.
  // For this exercise, we'll rely on the macros for copy.
  // If a custom one was needed:
  // virtual function void do_copy (uvm_object rhs);
  //   bs_transaction #(DATA_WIDTH) rhs_;
  //   if (!$cast(rhs_, rhs)) begin
  //     `uvm_fatal(get_name(), $sformatf("Illegal cast in do_copy: %s", rhs.get_type_name()))
  //     return;
  //   end
  //   super.do_copy(rhs);
  //   this.data_in = rhs_.data_in;
  //   this.shift_amount = rhs_.shift_amount;
  //   this.data_out = rhs_.data_out;
  //   this.expected_data_out = rhs_.expected_data_out;
  // endfunction : do_copy

  // do_compare: Similarly, `uvm_field_* macros with UVM_COMPARE flag (default) handle comparison.
  // Fields with UVM_NOCOMPARE are skipped.
  // We rely on macros.
  // If a custom one was needed:
  // virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
  //   bs_transaction #(DATA_WIDTH) rhs_;
  //   bit result;
  //   if (!$cast(rhs_, rhs)) begin
  //     `uvm_fatal(get_name(), $sformatf("Illegal cast in do_compare: %s", rhs.get_type_name()))
  //     return 0;
  //   end
  //   result = super.do_compare(rhs, comparer);
  //   result &= comparer.compare_field_int("data_in", this.data_in, rhs_.data_in, DATA_WIDTH);
  //   result &= comparer.compare_field_int("shift_amount", this.shift_amount, rhs_.shift_amount, SA_WIDTH);
  //   // data_out is not compared (UVM_NOCOMPARE)
  //   result &= comparer.compare_field_int("expected_data_out", this.expected_data_out, rhs_.expected_data_out, DATA_WIDTH);
  //   return result;
  // endfunction : do_compare

  // convert2string: `uvm_field_* macros also build the string for printing.
  // We rely on macros.
  // If a custom one was needed:
  // function string convert2string();
  //   string s;
  //   s = super.convert2string();
  //   $sformat(s, "%s\n  data_in           : %0h (%0d)", s, data_in, data_in);
  //   $sformat(s, "%s\n  shift_amount      : %0h (%0d)", s, shift_amount, shift_amount);
  //   $sformat(s, "%s\n  data_out          : %0h (%0d)", s, data_out, data_out);
  //   $sformat(s, "%s\n  expected_data_out : %0h (%0d)", s, expected_data_out, expected_data_out);
  //   return s;
  // endfunction : convert2string

endclass : bs_transaction
