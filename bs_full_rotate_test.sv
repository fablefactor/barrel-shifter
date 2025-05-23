// This file (bs_full_rotate_test.sv) will be included within bs_test_pkg.sv.

class bs_full_rotate_test extends barrel_shifter_base_test;
  `uvm_component_utils(bs_full_rotate_test)

  uvm_env m_env; // Generic handle for the environment
  int num_full_rotate_transactions = 20; // Default for this test

  function new(string name = "bs_full_rotate_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    string current_test_name = get_full_name();
    super.build_phase(phase); // Reads DUT config into base class's cfg_ members

    if (!uvm_config_db#(int)::get(this, "", "num_full_rotate_transactions", num_full_rotate_transactions)) begin
      `uvm_info(get_type_name(), $sformatf("[%s] 'num_full_rotate_transactions' not set, using default %0d", current_test_name, num_full_rotate_transactions), UVM_MEDIUM)
    end
    if (num_full_rotate_transactions <= 0) begin
        `uvm_warning(get_type_name(), $sformatf("[%s] num_full_rotate_transactions (%0d) invalid, setting to 1.",current_test_name, num_full_rotate_transactions));
        num_full_rotate_transactions = 1;
    end

    m_env = bs_env#(cfg_dut_data_width, cfg_effective_latency)::type_id::create("env", this);
    if (m_env == null) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Env creation failed for bs_env #(%0d, %0d).", current_test_name, cfg_dut_data_width, cfg_effective_latency))
    end
    `uvm_info(get_type_name(), $sformatf("[%s] Created bs_env #(%0d, %0d) for full_rotate test.", current_test_name, cfg_dut_data_width, cfg_effective_latency), UVM_MEDIUM);
  endfunction

  virtual task run_phase(uvm_phase phase);
    bs_env #(cfg_dut_data_width, cfg_effective_latency) typed_env_h; 
    bs_full_rotate_sequence#(cfg_dut_data_width) seq;
    string current_test_name = get_full_name();

    phase.raise_objection(this, {current_test_name, " starting run_phase"});
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase starting. Transactions=%0d.", 
              current_test_name, num_full_rotate_transactions), UVM_MEDIUM)

    if (!$cast(typed_env_h, m_env)) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to cast m_env to bs_env #(%0d,%0d).", current_test_name, cfg_dut_data_width, cfg_effective_latency));
      phase.drop_objection(this, {current_test_name, " ending due to cast failure"});
      return;
    end

    seq = bs_full_rotate_sequence#(cfg_dut_data_width)::type_id::create("seq");
    if (seq == null) begin
        `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to create bs_full_rotate_sequence.", current_test_name));
        phase.drop_objection(this, {current_test_name, " ending due to sequence creation failure"});
        return;
    end
    
    seq.num_transactions = this.num_full_rotate_transactions;

    if (typed_env_h.agent == null || typed_env_h.agent.sequencer == null) begin
      `uvm_fatal(get_type_name(), $sformatf("[%s] Agent or sequencer is null.", current_test_name));
      phase.drop_objection(this, {current_test_name, " ending due to null agent/sequencer"});
      return;
    end
    
    seq.start(typed_env_h.agent.sequencer);
    
    #(uint'(num_full_rotate_transactions) * uint'(cfg_effective_latency) * 20ns + 500ns); 
    
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase finishing.", current_test_name), UVM_MEDIUM)
    phase.drop_objection(this, {current_test_name, " finishing run_phase"});
  endtask

endclass
