// This file (bs_random_stimulus_sequence.sv) will be included within bs_test_pkg.sv.
// It assumes bs_transaction type is available via prior include in the package.

class bs_random_stimulus_sequence #(
  parameter DATA_WIDTH = 32
) extends uvm_sequence #(bs_transaction#(DATA_WIDTH));

  `uvm_object_param_utils(bs_random_stimulus_sequence#(DATA_WIDTH))

  // Configuration: Number of transactions to generate
  // This can be set by the test using uvm_config_db or direct assignment
  // before starting the sequence. For direct assignment, it shouldn't be rand.
  // If it were to be randomized by a parent sequence, it should be `rand int num_transactions;`
  int num_transactions = 10; 

  function new(string name = "bs_random_stimulus_sequence");
    super.new(name);
  endfunction

  virtual task body();
    // Transaction handle; uvm_do will create an object if m_req is null,
    // or use the existing object if m_req is already created (not typical for uvm_do).
    // Declaring it here ensures a new object per `uvm_do` iteration if not using `uvm_do_on_thy_object`.
    bs_transaction#(DATA_WIDTH) m_req; 
    
    if (num_transactions <= 0) begin
      `uvm_warning(get_type_name(), $sformatf("num_transactions is %0d, sequence will not send any items.", num_transactions))
      return;
    end

    `uvm_info(get_type_name(), $sformatf("Starting random stimulus sequence: generating %0d transactions.", num_transactions), UVM_MEDIUM)

    // Loop to generate and send the specified number of transactions
    repeat (num_transactions) begin
      // `uvm_do(m_req)`:
      // 1. Creates m_req (if null, or uses existing if pre-created - less common for simple uvm_do).
      //    To ensure a fresh transaction object for each iteration when m_req is a class member,
      //    one might set m_req = null before `uvm_do` or use `uvm_do_with` on a new item.
      //    When m_req is a local var as here, `uvm_do` typically creates a new one each time.
      //    More explicitly, `m_req = bs_transaction#(DATA_WIDTH)::type_id::create("m_req");`
      //    could precede the start_item/randomize/finish_item block if not using `uvm_do`.
      // 2. Calls start_item(m_req)
      // 3. Randomizes m_req
      // 4. Calls finish_item(m_req)
      `uvm_do(m_req) 
      
      // Example of explicit control with logging:
      // begin
      //   `uvm_create(m_req); // Factory create
      //   start_item(m_req);
      //   if (!m_req.randomize()) begin
      //     `uvm_error(get_type_name(), "Failed to randomize transaction")
      //   end else begin
      //      `uvm_info(get_type_name(), 
      //                $sformatf("Generated and sending transaction (%0d/%0d): %s", 
      //                          // Need a loop counter 'i' for this specific logging
      //                          // For example, if using a for loop: i+1, num_transactions,
      //                          m_req.convert2string()), 
      //                UVM_HIGH) // UVM_HIGH for potentially verbose per-transaction details
      //   end
      //   finish_item(m_req);
      // end
    end
    `uvm_info(get_type_name(), $sformatf("Finished random stimulus sequence after %0d transactions.", num_transactions), UVM_MEDIUM)
  endtask : body

endclass : bs_random_stimulus_sequence
