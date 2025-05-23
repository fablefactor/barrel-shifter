```systemverilog
// This file (bs_max_shift_sequence.sv) will be included within bs_test_pkg.sv.

class bs_max_shift_sequence #(
  parameter DATA_WIDTH = 32
) extends uvm_sequence #(bs_transaction#(DATA_WIDTH));

  `uvm_object_param_utils(bs_max_shift_sequence#(DATA_WIDTH))

  int num_transactions = 10; 

  function new(string name = "bs_max_shift_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bs_transaction#(DATA_WIDTH) m_req;
    // Calculate the max shift value based on DATA_WIDTH.
    // This should match the upper bound of shift_amount, which is DATA_WIDTH-1.
    // If DATA_WIDTH is 1, shift_amount is 1 bit and max shift is 0 (due to transaction constraint).
    // If DATA_WIDTH is > 1, max shift is DATA_WIDTH - 1.
    // The transaction's SA_WIDTH can hold up to DATA_WIDTH-1.
    type(m_req.shift_amount) target_max_shift; // Get the type of shift_amount for proper width

    if (DATA_WIDTH == 1) begin
      // For DATA_WIDTH=1, transaction constraint c_sa_for_data_width_1 forces shift_amount == 0.
      // So, "max shift" in this context is also 0.
      target_max_shift = 0;
    end else if (DATA_WIDTH > 1) begin
      target_max_shift = DATA_WIDTH - 1;
    end else begin // DATA_WIDTH = 0 or negative (invalid, defensive)
      target_max_shift = 0; 
      `uvm_warning(get_type_name(), $sformatf("DATA_WIDTH is %0d, which is invalid. Setting target_max_shift to 0.", DATA_WIDTH))
    end
    
    if (num_transactions <= 0) begin
      `uvm_warning(get_type_name(), $sformatf("num_transactions is %0d, sequence will not send any items.", num_transactions))
      return;
    end

    `uvm_info(get_type_name(), $sformatf("Starting max_shift_sequence: generating %0d transactions (shift_amount=%0d).", num_transactions, target_max_shift), UVM_MEDIUM)

    for (int i = 0; i < num_transactions; i++) begin
      `uvm_create(m_req)
      start_item(m_req);
      if (!m_req.randomize() with { shift_amount == target_max_shift; }) begin 
        `uvm_error(get_type_name(), $sformatf("Failed to randomize transaction with shift_amount == %0d", target_max_shift))
      end else begin
        `uvm_info(get_type_name(), $sformatf("Sent max_shift transaction %0d/%0d: %s", i+1, num_transactions, m_req.convert2string()), UVM_HIGH)
      end
      finish_item(m_req);
    end
    `uvm_info(get_type_name(), $sformatf("Finished max_shift_sequence after %0d transactions.", num_transactions), UVM_MEDIUM)
  endtask

endclass
```
