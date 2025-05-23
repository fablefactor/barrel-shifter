```systemverilog
// This file (bs_random_test.sv) will be included within bs_test_pkg.sv.
// It assumes barrel_shifter_base_test, bs_env, and bs_random_stimulus_sequence types
// are available via prior includes in the package.

class bs_random_test extends barrel_shifter_base_test;
  `uvm_component_utils(bs_random_test)

  // Generic environment handle.
  // The actual environment created will be bs_env#(cfg_dut_data_width, cfg_effective_latency)
  uvm_env m_env; 

  // Configuration for the number of transactions this test will run.
  // Can be overridden by uvm_config_db#(int)::set(this, "num_sequence_transactions", <value>);
  int num_sequence_transactions = 100; 

  function new(string name = "bs_random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string current_test_name = get_full_name();
    `uvm_info(get_type_name(), $sformatf("[%s] Build phase starting.", current_test_name), UVM_MEDIUM)

    // Call base class's build_phase. This is crucial as it reads dut_data_width
    // and dut_num_stages from uvm_config_db (or uses defaults) and populates:
    // - this.cfg_dut_data_width
    // - this.cfg_dut_num_stages
    // - this.cfg_effective_latency
    super.build_phase(phase); 

    // Get configuration specific to this random test for num_sequence_transactions
    if (!uvm_config_db#(int)::get(this, "", "num_sequence_transactions", num_sequence_transactions)) {
      `uvm_info(get_type_name(), $sformatf("[%s] 'num_sequence_transactions' not set via uvm_config_db. Using default: %0d.", current_test_name, num_sequence_transactions), UVM_MEDIUM)
    }

    if (num_sequence_transactions <= 0) begin
      `uvm_warning(get_type_name(), $sformatf("[%s] 'num_sequence_transactions' (%0d) is invalid. Setting to 1.", current_test_name, num_sequence_transactions))
      num_sequence_transactions = 1;
    end

    // Create the environment, specifically typed with parameters from base class configuration.
    // cfg_dut_data_width and cfg_effective_latency are available from the base class after super.build_phase().
    m_env = bs_env#(cfg_dut_data_width, cfg_effective_latency)::type_id::create("env", this);
    if (m_env == null) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Environment creation failed for bs_env #(%0d, %0d).", current_test_name, cfg_dut_data_width, cfg_effective_latency))
    end
    `uvm_info(get_type_name(), $sformatf("[%s] Successfully created bs_env #(%0d, %0d).", current_test_name, cfg_dut_data_width, cfg_effective_latency), UVM_MEDIUM);
    
    `uvm_info(get_type_name(), $sformatf("[%s] Build phase finished.", current_test_name), UVM_MEDIUM)
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Local, correctly-typed handle for the environment.
    // Parameters come from the base class's configuration properties.
    bs_env #(cfg_dut_data_width, cfg_effective_latency) typed_env_h; 
    bs_random_stimulus_sequence#(cfg_dut_data_width) seq;
    string current_test_name = get_full_name();

    phase.raise_objection(this, {current_test_name, " starting run_phase"});
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase starting. Will run %0d transactions.", current_test_name, num_sequence_transactions), UVM_MEDIUM)

    // Safely cast the generic m_env (type uvm_env) to the specifically parameterized bs_env type.
    // This is necessary to access its specific members like 'agent' with correct typing.
    if (!$cast(typed_env_h, m_env)) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to cast generic m_env to specific bs_env #(%0d,%0d) type.", current_test_name, cfg_dut_data_width, cfg_effective_latency))
      // No objection was raised by this task yet if fatal happens here, but good practice:
      // phase.drop_objection(this, {current_test_name, " ending due to cast failure"}); 
      return; // Exit if cast fails.
    end

    // Create and start the random stimulus sequence
    // Parameterize sequence with cfg_dut_data_width from base class.
    seq = bs_random_stimulus_sequence#(cfg_dut_data_width)::type_id::create("seq");
    if (seq == null) begin
       `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to create bs_random_stimulus_sequence.", current_test_name))
       // No objection raised by this task yet if fatal happens here.
       return;
    end
    
    seq.num_transactions = this.num_sequence_transactions;
    
    if (typed_env_h.agent == null || typed_env_h.agent.sequencer == null) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Environment's agent or sequencer handle is null. Cannot start sequence.", current_test_name))
      // No objection raised by this task yet.
      return;
    end
    
    `uvm_info(get_type_name(), $sformatf("[%s] Starting sequence '%s' on sequencer: %s", current_test_name, seq.get_name(), typed_env_h.agent.sequencer.get_full_name()), UVM_HIGH);
    seq.start(typed_env_h.agent.sequencer);
    
    // Add a delay that scales with the number of transactions and latency.
    // This is a fallback timeout; UVM objections from sequence/driver/monitor should ideally manage simulation time.
    // Ensure factors are uint to prevent overflow in calculation if num_transactions is very large.
    #(uint'(num_sequence_transactions) * uint'(cfg_effective_latency) * 20ns + 500ns); 
    
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase finishing.", current_test_name), UVM_MEDIUM)
    phase.drop_objection(this, {current_test_name, " finishing run_phase"});
  endtask

endclass
```
