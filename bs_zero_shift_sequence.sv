// This file (bs_zero_shift_sequence.sv) will be included within bs_test_pkg.sv.

class bs_zero_shift_sequence #(
  parameter DATA_WIDTH = 32
) extends uvm_sequence #(bs_transaction#(DATA_WIDTH));

  `uvm_object_param_utils(bs_zero_shift_sequence#(DATA_WIDTH))

  int num_transactions = 10; 
  // Constraint for shift_amount = 0 is applied directly in randomize() call.

  function new(string name = "bs_zero_shift_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bs_transaction#(DATA_WIDTH) m_req;
    
    if (num_transactions <= 0) begin
      `uvm_warning(get_type_name(), $sformatf("num_transactions is %0d, sequence will not send any items.", num_transactions))
      return;
    end

    `uvm_info(get_type_name(), $sformatf("Starting zero_shift_sequence: generating %0d transactions.", num_transactions), UVM_MEDIUM)

    for (int i = 0; i < num_transactions; i++) begin
      `uvm_create(m_req)
      start_item(m_req);
      if (!m_req.randomize() with { shift_amount == '0; }) begin // Constrain shift_amount
        `uvm_error(get_type_name(), "Failed to randomize transaction with shift_amount == 0")
      end else begin
        `uvm_info(get_type_name(), $sformatf("Sent zero_shift transaction %0d/%0d: %s", i+1, num_transactions, m_req.convert2string()), UVM_HIGH)
      end
      finish_item(m_req);
    end
    `uvm_info(get_type_name(), $sformatf("Finished zero_shift_sequence after %0d transactions.", num_transactions), UVM_MEDIUM)
  endtask

endclass
