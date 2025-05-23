// This file (bs_min_stages_test.sv) will be included within bs_test_pkg.sv.

class bs_min_stages_test extends barrel_shifter_base_test;
  `uvm_component_utils(bs_min_stages_test)

  uvm_env m_env; // Generic handle for the environment

  // Test-specific parameters
  local static const int THIS_TEST_DATA_WIDTH = 32; // Using a default width
  local static const int THIS_TEST_NUM_STAGES = 0;  // DUT parameter for min pipelining
  int num_sequence_transactions = 75;

  function new(string name = "bs_min_stages_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string current_test_name = get_full_name();
    // Set DUT parameters for this min_stages test
    uvm_config_db#(int)::set(this, "", "dut_data_width", THIS_TEST_DATA_WIDTH);
    uvm_config_db#(int)::set(this, "", "dut_num_stages", THIS_TEST_NUM_STAGES);

    super.build_phase(phase); // Base class reads config. cfg_effective_latency will be 1.

    if (!uvm_config_db#(int)::get(this, "", "num_sequence_transactions", num_sequence_transactions)) begin
      `uvm_info(get_type_name(), $sformatf("[%s] 'num_sequence_transactions' not set, using default %0d", current_test_name, num_sequence_transactions), UVM_MEDIUM)
    end
    if (num_sequence_transactions <= 0) begin
        `uvm_warning(get_type_name(), $sformatf("[%s] num_sequence_transactions (%0d) invalid, setting to 1.",current_test_name, num_sequence_transactions));
        num_sequence_transactions = 1;
    end
    
    // cfg_dut_data_width will be THIS_TEST_DATA_WIDTH
    // cfg_effective_latency will be 1 (derived from THIS_TEST_NUM_STAGES = 0)
    m_env = bs_env#(cfg_dut_data_width, cfg_effective_latency)::type_id::create("env", this);
    if (m_env == null) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Env creation failed for bs_env #(%0d, %0d).", current_test_name, cfg_dut_data_width, cfg_effective_latency))
    end
    `uvm_info(get_type_name(), $sformatf("[%s] Created bs_env #(%0d, %0d) for min stages (DUT NUM_STAGES=%0d) test. Effective latency for monitor is %0d.", 
              current_test_name, cfg_dut_data_width, cfg_effective_latency, THIS_TEST_NUM_STAGES, cfg_effective_latency), UVM_MEDIUM);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // Use cfg_effective_latency which is correctly calculated by base class.
    // For THIS_TEST_NUM_STAGES = 0, cfg_effective_latency will be 1.
    bs_env #(THIS_TEST_DATA_WIDTH, cfg_effective_latency) typed_env_h; 
    bs_random_stimulus_sequence#(THIS_TEST_DATA_WIDTH) seq;
    string current_test_name = get_full_name();

    phase.raise_objection(this, {current_test_name, " starting run_phase"});
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase starting. DATA_WIDTH=%0d, DUT_NUM_STAGES=%0d (Effective Latency=%0d). Transactions=%0d.", 
              current_test_name, THIS_TEST_DATA_WIDTH, THIS_TEST_NUM_STAGES, cfg_effective_latency, num_sequence_transactions), UVM_MEDIUM)

    if (!$cast(typed_env_h, m_env)) {
      `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to cast m_env to bs_env #(%0d,%0d).", current_test_name, THIS_TEST_DATA_WIDTH, cfg_effective_latency))
      phase.drop_objection(this, {current_test_name, " ending due to cast failure"});
      return;
    }

    seq = bs_random_stimulus_sequence#(THIS_TEST_DATA_WIDTH)::type_id::create("seq");
    if (seq == null) begin // Added begin/end for fatal block
       `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to create sequence.", current_test_name));
       phase.drop_objection(this, {current_test_name, " ending due to sequence creation failure"});
       return;
    end
    
    seq.num_transactions = this.num_sequence_transactions;

    if (typed_env_h.agent == null || typed_env_h.agent.sequencer == null) begin // Added begin/end for fatal block
      `uvm_fatal(get_type_name(), $sformatf("[%s] Agent or sequencer is null.", current_test_name));
      phase.drop_objection(this, {current_test_name, " ending due to null agent/sequencer"});
      return;
    end
    
    seq.start(typed_env_h.agent.sequencer);
    
    #(uint'(num_sequence_transactions) * uint'(cfg_effective_latency) * 20ns + 500ns); 
    
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase finishing.", current_test_name), UVM_MEDIUM)
    phase.drop_objection(this, {current_test_name, " finishing run_phase"});
  endtask

endclass
