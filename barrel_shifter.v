```verilog
module barrel_shifter #(
    parameter DATA_WIDTH = 32,
    parameter NUM_STAGES = 1 // User-defined number of physical pipeline stages
) (
    input clk,
    input reset_n,
    // Robust shift_amount port width: min 1 bit wide (for DATA_WIDTH=1, SA_WIDTH becomes 1, port is [0:0])
    input [(($clog2(DATA_WIDTH) > 0) ? $clog2(DATA_WIDTH) : 1)-1:0] shift_amount,
    input [DATA_WIDTH-1:0] data_in, // Added data_in to port list
    output logic [DATA_WIDTH-1:0] data_out
);

    // Ensure DATA_WIDTH is at least 1 for $clog2 calculations if it could be 0.
    // However, tests should ensure DATA_WIDTH > 0.
    localparam EFFECTIVE_DATA_WIDTH = (DATA_WIDTH == 0) ? 1 : DATA_WIDTH;

    // Robust SA_WIDTH: Minimum 1. For DATA_WIDTH=1, $clog2 is 0, so SA_WIDTH becomes 1.
    localparam SA_WIDTH = (($clog2(EFFECTIVE_DATA_WIDTH) > 0) ? $clog2(EFFECTIVE_DATA_WIDTH) : 1);

    // Effective number of physical pipeline stages. If user specifies 0, treat as 1.
    localparam EFF_NUM_STAGES = (NUM_STAGES == 0) ? 1 : NUM_STAGES;

    generate
        if (EFFECTIVE_DATA_WIDTH == 1) begin : gen_data_width_one
            // For DATA_WIDTH=1, shift_amount is [0:0]. RTL shift by SA[0] (0 or 1) on a single bit
            // is effectively no change for rotation. Output is simply data_in pipelined.
            logic [EFFECTIVE_DATA_WIDTH-1:0] pipe_reg_dw1 [EFF_NUM_STAGES-1:0];

            always_ff @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    for (int i = 0; i < EFF_NUM_STAGES; i++) begin
                        pipe_reg_dw1[i] <= {EFFECTIVE_DATA_WIDTH{1'b0}};
                    end
                end else begin
                    pipe_reg_dw1[0] <= data_in;
                    for (int i = 1; i < EFF_NUM_STAGES; i++) begin
                        pipe_reg_dw1[i] <= pipe_reg_dw1[i-1];
                    end
                end
            end
            assign data_out = pipe_reg_dw1[EFF_NUM_STAGES-1];

        end else begin : gen_data_width_general // DATA_WIDTH > 1
            
            // Pipeline registers for physical stages
            logic [DATA_WIDTH-1:0] pipe_reg [EFF_NUM_STAGES-1:0];
            // Combinatorial result for each physical stage's logic
            logic [DATA_WIDTH-1:0] comb_stage_output [EFF_NUM_STAGES-1:0];

            // Generate combinatorial logic for each physical stage
            genvar p_idx; // Physical stage index
            for (p_idx = 0; p_idx < EFF_NUM_STAGES; p_idx++) begin : gen_physical_stage_logic
                always_comb begin
                    logic [DATA_WIDTH-1:0] current_data_bus;
                    logic [DATA_WIDTH-1:0] result_this_physical_stage;

                    // Determine input to this physical stage's combinatorial logic
                    current_data_bus = (p_idx == 0) ? data_in : pipe_reg[p_idx-1];
                    result_this_physical_stage = current_data_bus; // Initialize with input data

                    // Determine which logical stages (bits of shift_amount) this physical stage handles.
                    // num_logical_stages is SA_WIDTH (since DATA_WIDTH > 1 here).
                    // Distribute SA_WIDTH logical operations among EFF_NUM_STAGES physical stages.
                    int ops_this_stage = (SA_WIDTH / EFF_NUM_STAGES) + ((p_idx < (SA_WIDTH % EFF_NUM_STAGES)) ? 1 : 0);
                    int start_logical_stage_idx = (p_idx * (SA_WIDTH / EFF_NUM_STAGES)) + 
                                                  ((p_idx < (SA_WIDTH % EFF_NUM_STAGES)) ? p_idx : (SA_WIDTH % EFF_NUM_STAGES));
                    
                    for (int k = 0; k < ops_this_stage; k++) begin
                        int current_logical_stage_idx = start_logical_stage_idx + k;
                        // This check should ideally not be needed if ops distribution is correct
                        if (current_logical_stage_idx < SA_WIDTH) begin 
                            if (shift_amount[current_logical_stage_idx]) begin
                                int shift_val_this_logical_stage = 1 << current_logical_stage_idx;
                                // Perform rotation
                                result_this_physical_stage = (result_this_physical_stage << shift_val_this_logical_stage) | 
                                                             (result_this_physical_stage >> (DATA_WIDTH - shift_val_this_logical_stage));
                            end
                        end
                    end
                    comb_stage_output[p_idx] = result_this_physical_stage;
                end
            end

            // Pipeline registers: Register the output of each physical stage's combinatorial logic
            always_ff @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    for (int i = 0; i < EFF_NUM_STAGES; i++) begin
                        pipe_reg[i] <= {DATA_WIDTH{1'b0}};
                    end
                end else begin
                    for (int i = 0; i < EFF_NUM_STAGES; i++) begin
                        pipe_reg[i] <= comb_stage_output[i];
                    end
                end
            end

            // Assign final output from the last pipeline stage
            assign data_out = pipe_reg[EFF_NUM_STAGES-1];

        end // end gen_data_width_general
    endgenerate
endmodule
```
