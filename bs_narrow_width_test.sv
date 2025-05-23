// This file (bs_narrow_width_test.sv) will be included within bs_test_pkg.sv.
// It assumes barrel_shifter_base_test, bs_env, and bs_random_stimulus_sequence types
// are available via prior includes in the package.

class bs_narrow_width_test extends barrel_shifter_base_test;
  `uvm_component_utils(bs_narrow_width_test)

  uvm_env m_env; // Generic handle for the environment

  // Test-specific parameters and configurations
  local static const int THIS_TEST_DATA_WIDTH = 8;
  local static const int THIS_TEST_NUM_STAGES = 1; // Example: fix stages for this test
  int num_sequence_transactions = 50; // Default number of transactions for this test

  function new(string name = "bs_narrow_width_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string current_test_name = get_full_name();
    `uvm_info(get_type_name(), $sformatf("[%s] Build phase starting.", current_test_name), UVM_MEDIUM)

    // Set DUT parameters specifically for this narrow-width test.
    // These values will be read by super.build_phase() from the base class.
    uvm_config_db#(int)::set(this, "", "dut_data_width", THIS_TEST_DATA_WIDTH);
    uvm_config_db#(int)::set(this, "", "dut_num_stages", THIS_TEST_NUM_STAGES);

    // Call base class's build_phase. This is crucial as it reads the above configurations
    // (and others like verbosity settings, etc.) and populates:
    // - this.cfg_dut_data_width (will be THIS_TEST_DATA_WIDTH)
    // - this.cfg_dut_num_stages (will be THIS_TEST_NUM_STAGES)
    // - this.cfg_effective_latency (derived from THIS_TEST_NUM_STAGES)
    super.build_phase(phase); 

    // Get test-specific configuration for num_sequence_transactions
    if (!uvm_config_db#(int)::get(this, "", "num_sequence_transactions", num_sequence_transactions)) begin
      `uvm_info(get_type_name(), $sformatf("[%s] 'num_sequence_transactions' not set via uvm_config_db for test. Using default: %0d.", current_test_name, num_sequence_transactions), UVM_MEDIUM)
    end
    if (num_sequence_transactions <= 0) begin
        `uvm_warning(get_type_name(), $sformatf("[%s] 'num_sequence_transactions' (%0d) is invalid for test. Setting to 1.",current_test_name, num_sequence_transactions));
        num_sequence_transactions = 1;
    end

    // Create the environment, specifically typed with parameters obtained from base class configuration.
    // cfg_dut_data_width will be THIS_TEST_DATA_WIDTH (8).
    // cfg_effective_latency will be derived from THIS_TEST_NUM_STAGES (e.g., 1 if THIS_TEST_NUM_STAGES is 1 or 0).
    m_env = bs_env#(cfg_dut_data_width, cfg_effective_latency)::type_id::create("env", this);
    if (m_env == null) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Environment creation failed for bs_env #(%0d, %0d).", current_test_name, cfg_dut_data_width, cfg_effective_latency))
    end
    `uvm_info(get_type_name(), $sformatf("[%s] Successfully created bs_env #(%0d, %0d) for narrow width test.", current_test_name, cfg_dut_data_width, cfg_effective_latency), UVM_MEDIUM);
    
    `uvm_info(get_type_name(), $sformatf("[%s] Build phase finished.", current_test_name), UVM_MEDIUM)
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Localparam for effective latency, ensuring it's based on this test's compile-time constants
    localparam TEST_SPECIFIC_EFFECTIVE_LATENCY = (THIS_TEST_NUM_STAGES == 0) ? 1 : THIS_TEST_NUM_STAGES;

    // Local handle, correctly typed to match the created environment's parameterization.
    // THIS_TEST_DATA_WIDTH is const. TEST_SPECIFIC_EFFECTIVE_LATENCY is const.
    bs_env #(THIS_TEST_DATA_WIDTH, TEST_SPECIFIC_EFFECTIVE_LATENCY) typed_env_h; 
    bs_random_stimulus_sequence#(THIS_TEST_DATA_WIDTH) seq;
    string current_test_name = get_full_name();

    phase.raise_objection(this, {current_test_name, " starting run_phase"});
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase starting. DATA_WIDTH=%0d, TEST_NUM_STAGES=%0d (Effective Latency for env/monitor=%0d). Transactions=%0d.", 
              current_test_name, THIS_TEST_DATA_WIDTH, THIS_TEST_NUM_STAGES, TEST_SPECIFIC_EFFECTIVE_LATENCY, num_sequence_transactions), UVM_MEDIUM)

    // Safely cast the generic m_env (type uvm_env) to the specifically parameterized bs_env type.
    if (!$cast(typed_env_h, m_env)) {
      `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to cast m_env to bs_env #(%0d,%0d). Object is of type %s", current_test_name, THIS_TEST_DATA_WIDTH, TEST_SPECIFIC_EFFECTIVE_LATENCY, m_env.get_type_name()))
      phase.drop_objection(this, {current_test_name, " ending due to cast failure"}); // Drop objection before exiting
      return; 
    }

    // Create and start the random stimulus sequence, parameterized with THIS_TEST_DATA_WIDTH.
    seq = bs_random_stimulus_sequence#(THIS_TEST_DATA_WIDTH)::type_id::create("seq");
    if (seq == null) {
       `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to create bs_random_stimulus_sequence.", current_test_name))
       phase.drop_objection(this, {current_test_name, " ending due to sequence creation failure"}); // Drop objection
       return;
    }
    
    seq.num_transactions = this.num_sequence_transactions;
    
    if (typed_env_h.agent == null || typed_env_h.agent.sequencer == null) {
      `uvm_fatal(get_type_name(), $sformatf("[%s] Environment's agent or sequencer handle is null. Cannot start sequence.", current_test_name))
      phase.drop_objection(this, {current_test_name, " ending due to null agent/sequencer"}); // Drop objection
      return;
    }
    
    `uvm_info(get_type_name(), $sformatf("[%s] Starting sequence '%s' on sequencer: %s", current_test_name, seq.get_name(), typed_env_h.agent.sequencer.get_full_name()), UVM_HIGH);
    seq.start(typed_env_h.agent.sequencer);
    
    // Fallback timeout delay
    #(uint'(num_sequence_transactions) * uint'(cfg_effective_latency) * 20ns + 500ns); 
    
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase finishing.", current_test_name), UVM_MEDIUM)
    phase.drop_objection(this, {current_test_name, " finishing run_phase"});
  endtask

endclass
