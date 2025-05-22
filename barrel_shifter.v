```verilog
module barrel_shifter #(
    parameter DATA_WIDTH = 32,
    parameter NUM_STAGES = 1
) (
    input clk,
    input reset_n,
    input [DATA_WIDTH-1:0] data_in,
    input [$clog2(DATA_WIDTH)-1:0] shift_amount, // Width is 0 if DATA_WIDTH=1
    output logic [DATA_WIDTH-1:0] data_out
);

    localparam SA_WIDTH = $clog2(DATA_WIDTH); // Shift Amount Width

    // Calculate bits of shift_amount to be handled by each stage
    // If SA_WIDTH is 0 (for DATA_WIDTH=1), BITS_PER_STAGE will be 0 if NUM_STAGES >= 1
    localparam BITS_PER_STAGE = (SA_WIDTH == 0) ? 0 : (SA_WIDTH + NUM_STAGES - 1) / NUM_STAGES;

    // Intermediate registers for pipelining
    // Stage 0 processes data_in, subsequent stages process output of previous stage.
    logic [DATA_WIDTH-1:0] stage_data [NUM_STAGES-1:0];

    // Generate blocks for single vs. pipelined stages
    generate
        if (NUM_STAGES == 0) begin : invalid_stages
            // Assign a default value or raise an error if NUM_STAGES is 0,
            // though parameters usually constrained to be > 0.
            // For simplicity, treat as 1 stage if NUM_STAGES is set to 0.
             always_ff @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    data_out <= {DATA_WIDTH{1'b0}};
                end else begin
                    if (SA_WIDTH == 0) begin // DATA_WIDTH = 1
                        data_out <= data_in;
                    end else begin
                        data_out <= (data_in << shift_amount) | (data_in >> (DATA_WIDTH - shift_amount));
                    end
                end
            end
        end else if (NUM_STAGES == 1) begin : single_stage
            // Single stage implementation (registered output)
            always_ff @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    data_out <= {DATA_WIDTH{1'b0}};
                end else begin
                    if (SA_WIDTH == 0) begin // DATA_WIDTH = 1
                        data_out <= data_in; // No shift possible
                    end else begin
                        // Rotate left
                        data_out <= (data_in << shift_amount) | (data_in >> (DATA_WIDTH - shift_amount));
                    end
                end
            end
        end else begin : pipelined_stages
            // Pipelined implementation

            // Function to get the portion of shift_amount for the current stage.
            // This is the actual value by which this stage should shift.
            function automatic [SA_WIDTH-1:0] get_stage_shift_val (input int stage_idx, input [SA_WIDTH-1:0] total_shift_amount);
                int start_bit_idx;
                int end_bit_idx;
                logic [SA_WIDTH-1:0] extracted_val;

                if (SA_WIDTH == 0 || BITS_PER_STAGE == 0) begin
                    return {SA_WIDTH{1'b0}}; // No shift if data width is 1 or no bits per stage
                end

                start_bit_idx = stage_idx * BITS_PER_STAGE;

                // If this stage is beyond the bits of total_shift_amount, it shifts by 0
                if (start_bit_idx >= SA_WIDTH) begin
                    return {SA_WIDTH{1'b0}};
                end

                end_bit_idx = start_bit_idx + BITS_PER_STAGE - 1;
                if (end_bit_idx >= SA_WIDTH) begin
                    end_bit_idx = SA_WIDTH - 1;
                end
                
                // Extract the relevant bits from total_shift_amount
                // e.g. total_shift_amount = 5'b10110 (22), stage_idx=0, BITS_PER_STAGE=3.
                // start_bit_idx = 0, end_bit_idx = 2. We need total_shift_amount[2:0] = 3'b110 (6)
                extracted_val = total_shift_amount[end_bit_idx : start_bit_idx];
                return extracted_val;
            endfunction

            always_ff @(posedge clk or negedge reset_n) begin : pipeline_logic
                if (!reset_n) begin
                    for (int j = 0; j < NUM_STAGES; j++) begin
                        stage_data[j] <= {DATA_WIDTH{1'b0}};
                    end
                    data_out <= {DATA_WIDTH{1'b0}};
                end else begin
                    logic [DATA_WIDTH-1:0] current_data_in;
                    logic [SA_WIDTH-1:0] current_stage_actual_shift;

                    // Stage 0
                    current_data_in = data_in;
                    if (SA_WIDTH == 0) begin // DATA_WIDTH = 1
                        current_stage_actual_shift = {SA_WIDTH{1'b0}}; // Effectively no shift
                        stage_data[0] <= current_data_in;
                    end else begin
                        current_stage_actual_shift = get_stage_shift_val(0, shift_amount);
                        // Perform rotation for this stage
                        stage_data[0] <= (current_data_in << current_stage_actual_shift) | (current_data_in >> (DATA_WIDTH - current_stage_actual_shift));
                    end

                    // Subsequent stages
                    for (int j = 1; j < NUM_STAGES; j++) begin
                        current_data_in = stage_data[j-1];
                        if (SA_WIDTH == 0) begin // Should not be strictly necessary here if stage_data[0] is set correctly
                             current_stage_actual_shift = {SA_WIDTH{1'b0}};
                             stage_data[j] <= current_data_in;
                        end else begin
                            current_stage_actual_shift = get_stage_shift_val(j, shift_amount);
                            // Perform rotation for this stage
                            stage_data[j] <= (current_data_in << current_stage_actual_shift) | (current_data_in >> (DATA_WIDTH - current_stage_actual_shift));
                        end
                    end
                    data_out <= stage_data[NUM_STAGES-1];
                end
            end
        end
    endgenerate

endmodule
```
