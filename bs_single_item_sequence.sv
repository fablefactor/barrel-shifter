```systemverilog
// This file (bs_single_item_sequence.sv) will be included within bs_test_pkg.sv.
// It assumes bs_transaction type is available via prior include in the package.

class bs_single_item_sequence #(
  parameter DATA_WIDTH = 32
) extends uvm_sequence #(bs_transaction#(DATA_WIDTH));

  `uvm_object_param_utils(bs_single_item_sequence#(DATA_WIDTH))

  // Optional: Add knobs to the sequence that can be set by the test
  // For example:
  // rand logic [DATA_WIDTH-1:0] fixed_data_in;
  // localparam SA_WIDTH = ($clog2(DATA_WIDTH)>0?$clog2(DATA_WIDTH):1);
  // rand logic [SA_WIDTH-1:0] fixed_shift_amount;
  // constraint use_fixed_values_cons { 
  //   solve fixed_data_in before data_in; // Example of solving order
  //   if (use_fixed_knobs) { // Assuming a 'use_fixed_knobs' boolean control
  //     data_in == fixed_data_in;
  //     shift_amount == fixed_shift_amount;
  //   }
  // }
  // For a truly *generic* single item sequence, these are not needed.
  // Tests can extend this sequence or use `uvm_do_with` for specific constraints.

  function new(string name = "bs_single_item_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bs_transaction#(DATA_WIDTH) m_req; // Local handle for the transaction
    
    `uvm_info(get_type_name(), "Starting single item sequence body.", UVM_MEDIUM)

    // Create the transaction object using the UVM macro.
    // This handles factory registration if m_req was declared as a class member
    // and randomization is done on it. For local var, it's just object creation.
    // For sequences, `uvm_do*` macros often handle this, but direct creation is also fine.
    // `uvm_create(m_req)` is typically used when m_req is a class field of type uvm_object (or derived).
    // For a local variable, direct construction is common:
    // m_req = bs_transaction#(DATA_WIDTH)::type_id::create("m_req");
    // However, the pattern `uvm_create(m_req)` followed by `start_item/finish_item` is also acceptable
    // and encourages use of factory for the transaction if it has one.
    // Let's stick to the provided example's `uvm_create`.
    `uvm_create(m_req) // This will create m_req using the factory.

    // Start the item, indicating that m_req is ready to be processed by the driver.
    // The call to start_item() is blocking if the sequencer's arbitration queue is full.
    start_item(m_req); 

    // Randomize the transaction.
    if (!m_req.randomize()) begin
      `uvm_error(get_type_name(), "Failed to randomize transaction in bs_single_item_sequence.")
    end else begin
      `uvm_info(get_type_name(), $sformatf("Generated transaction: %s", m_req.convert2string()), UVM_HIGH)
      // UVM_HIGH is suitable for detailed transaction info that might be verbose.
    end

    // Finish the item, indicating that the driver has processed the transaction.
    // This call is blocking until the driver calls item_done().
    finish_item(m_req);

    `uvm_info(get_type_name(), "Finished single item sequence body.", UVM_MEDIUM)
  endtask : body

endclass : bs_single_item_sequence
```
