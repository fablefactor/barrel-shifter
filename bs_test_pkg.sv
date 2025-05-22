```systemverilog
package bs_test_pkg;

  // Import UVM package and include UVM macros
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Include all UVM component files for the barrel shifter testbench.
  // The order is important to ensure dependencies are met during compilation.

  // 1. Transaction definition (base data item)
  `include "bs_transaction.sv"

  // 2. Sequencer (generates transactions)
  //    Depends on: bs_transaction
  `include "bs_sequencer.sv"

  // 3. Driver (drives transactions to DUT, needs interface)
  //    Depends on: bs_transaction
  //    Note: bs_if.sv (interface) is compiled separately, not part of this UVM package.
  `include "bs_driver.sv"

  // 4. Monitor (observes DUT behavior, needs interface)
  //    Depends on: bs_transaction
  //    Note: bs_if.sv (interface) is compiled separately.
  `include "bs_monitor.sv"

  // 5. Agent (contains sequencer, driver, monitor)
  //    Depends on: bs_sequencer, bs_driver, bs_monitor
  `include "bs_agent.sv"

  // 6. Scoreboard (checks transactions)
  //    Depends on: bs_transaction
  `include "bs_scoreboard.sv"

  // 7. Environment (contains agent, scoreboard)
  //    Depends on: bs_agent, bs_scoreboard
  `include "bs_env.sv"

  // Test classes (e.g., base_test, specific tests) would typically be included here as well,
  // or in a separate file that is also included by this package or compiled alongside.
  // For example:
  // `include "bs_base_test.sv"
  // `include "bs_smoke_test.sv"
  // etc.

endpackage : bs_test_pkg
```
