```systemverilog
package bs_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Environment Components
  `include "bs_transaction.sv"
  `include "bs_sequencer.sv" 
  `include "bs_driver.sv"    
  `include "bs_monitor.sv"   
  `include "bs_agent.sv"     
  `include "bs_scoreboard.sv"
  `include "bs_env.sv"       

  // Sequence Classes
  `include "bs_single_item_sequence.sv"
  `include "bs_random_stimulus_sequence.sv"
  `include "bs_zero_shift_sequence.sv"
  `include "bs_full_rotate_sequence.sv"
  `include "bs_max_shift_sequence.sv"

  // Test Classes
  `include "base_test.sv" // Base test must come before tests that extend it
  `include "bs_smoke_test.sv"
  `include "bs_random_test.sv"
  `include "bs_narrow_width_test.sv"
  `include "bs_wide_width_test.sv"
  `include "bs_min_stages_test.sv"
  `include "bs_max_stages_test.sv"

endpackage
```
