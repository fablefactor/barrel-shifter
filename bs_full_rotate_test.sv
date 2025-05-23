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
    string current_test_name = get_full_name();
    uvm_sequence seq_h; // Generic handle for the sequence to be started
    bs_full_rotate_sequence#(cfg_dut_data_width) actual_full_rotate_seq;

    uvm_component temp_agent_comp;
    uvm_component temp_seqr_comp;
    uvm_sequencer_base seqr_to_start_on; // Generic sequencer handle for seq_h.start()

    phase.raise_objection(this, {current_test_name, " starting run_phase"});
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase starting. Transactions=%0d.", 
              current_test_name, num_full_rotate_transactions), UVM_MEDIUM)

    // Sequence Creation and Configuration
    actual_full_rotate_seq = bs_full_rotate_sequence#(cfg_dut_data_width)::type_id::create("seq");
    if (actual_full_rotate_seq == null) begin
       `uvm_fatal(get_type_name(), $sformatf("[%s] Failed to create bs_full_rotate_sequence.", current_test_name))
       phase.drop_objection(this, {current_test_name, " ending due to sequence creation failure"});
       return;
    end
    actual_full_rotate_seq.num_transactions = this.num_full_rotate_transactions;
    if (!$cast(seq_h, actual_full_rotate_seq)) begin
        `uvm_fatal(get_type_name(), $sformatf("Failed to cast actual_full_rotate_seq to uvm_sequence for starting. Type is %s", actual_full_rotate_seq.get_type_name()));
        phase.drop_objection(this, {current_test_name, " ending due to sequence cast failure"});
        return;
    end

    // Getting the Sequencer Handle
    if (m_env == null) begin
        `uvm_fatal(get_type_name(), $sformatf("[%s] m_env handle is null. Cannot get sequencer.", current_test_name));
        phase.drop_objection(this, {current_test_name, " ending due to null m_env"});
        return;
    end
    temp_agent_comp = m_env.get_child("agent");
    if (temp_agent_comp == null) begin
        `uvm_fatal(get_type_name(), $sformatf("[%s] Agent component not found under m_env. Path: %s", current_test_name, m_env.get_full_name()));
        phase.drop_objection(this, {current_test_name, " ending due to null agent component"});
        return;
    end
    temp_seqr_comp = temp_agent_comp.get_child("sequencer");
    if (temp_seqr_comp == null) begin
        `uvm_fatal(get_type_name(), $sformatf("[%s] Sequencer component not found under agent. Path: %s", current_test_name, temp_agent_comp.get_full_name()));
        phase.drop_objection(this, {current_test_name, " ending due to null sequencer component"});
        return;
    end
    if (!$cast(seqr_to_start_on, temp_seqr_comp)) begin
        `uvm_fatal(get_type_name(), $sformatf("Failed to cast sequencer component (%s) to uvm_sequencer_base. Path: %s", temp_seqr_comp.get_type_name(), temp_seqr_comp.get_full_name()));
        phase.drop_objection(this, {current_test_name, " ending due to sequencer cast failure"});
        return;
    end
    
    seq_h.start(seqr_to_start_on);
    
    #(uint'(num_full_rotate_transactions) * uint'(cfg_effective_latency) * 20ns + 500ns); 
    
    `uvm_info(get_type_name(), $sformatf("[%s] Run phase finishing.", current_test_name), UVM_MEDIUM)
    phase.drop_objection(this, {current_test_name, " finishing run_phase"});
  endtask

endclass
