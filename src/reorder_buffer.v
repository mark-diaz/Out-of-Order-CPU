module reorder_buffer(
    input clk,
    input reset_n,
    
    input alloc_valid,
    input [31:0] alloc_instr_addr,
    input [5:0] alloc_dest,
    input [5:0] alloc_oldDest,
    input [4:0] alloc_archDest,
	 
    output wire alloc_ready, // Indicates if allocation is possible
    output reg [5:0] rob_entry_num,
    
    input writeback_valid1,
    input writeback_valid2,
    input writeback_valid3,
    input writeback_valid4,
    input [5:0] writeback_idx1, // Writeback ROB location
    input [31:0] writeback_value1, // Writeback ROB destination register value
    input [5:0] writeback_idx2, // Writeback ROB location
    input [31:0] writeback_value2,
    input [5:0] writeback_idx3, // Writeback ROB location
    input [31:0] writeback_value3,
    input [5:0] writeback_idx4, // Writeback ROB location
    input [31:0] writeback_value4,
    
    //rob forwarding to issue queue
    input [5:0] phys_rs1,
    input [5:0] phys_rs2,
    output reg forward_rs1_valid,
    output reg forward_rs2_valid,
    output reg [31:0] rob_forward_data_rs1,
    output reg [31:0] rob_forward_data_rs2,
    output reg commit_valid_1, // Overall commit status
    output reg commit_valid_2,
    output reg [5:0] commit_dest_1,
    output reg [5:0] free_oldDest_1,
    output reg [31:0] commit_value_1, // Ready value to write to the register file
    output reg [4:0] commit_archDest_1,
    output reg [5:0] commit_dest_2,
    output reg [5:0] free_oldDest_2,
    output reg [31:0] commit_value_2,
    output reg [4:0] commit_archDest_2,
    input commit_ready

);
    // ROB entries
    reg rob_valid[63:0];         // Valid bit for each entry
    reg [5:0] rob_dest[63:0];    // Destination register for each entry
    reg [5:0] rob_oldDest[63:0]; // Previous destination register for each entry
    reg[4:0] rob_archDest[63:0];
    reg [31:0] rob_instr_addr[63:0]; // Instruction address for each entry
    reg rob_result_ready[63:0];  // Result ready bit for each entry
    reg [31:0] rob_value[63:0];  // Value for each entry
    
    // Head and tail pointers
    reg [5:0] head, tail;
    reg prev_alloc_valid;
    reg prev_commit_ready;
    reg new_head;
    integer i;
    
    assign alloc_ready = !((tail + 1) % 64 == head);

    // Combinational commit and writeback logic
    always @(*) begin
        commit_valid_1 = 0; // Default no commit
        commit_valid_2=0;
        commit_dest_1 = 6'b111111;
        free_oldDest_1 = 6'b111111;
        commit_archDest_1=5'b11111;
        commit_archDest_2=5'b11111;
        commit_value_1 = 32'b0;
        commit_dest_2 = 6'b111111;
        free_oldDest_2 = 6'b111111;
        commit_value_2 = 32'b0;
        rob_entry_num = tail;
		  
        forward_rs1_valid = 0;
        forward_rs2_valid = 0;
        rob_forward_data_rs1 = 32'b0;
        rob_forward_data_rs2 = 32'b0;
			
        for(i = 0; i < 64;i = i + 1) begin
            if(forward_rs1_valid==1'b0 && rob_dest[i] == phys_rs1 &&rob_valid[i] && rob_result_ready[i]) begin
                forward_rs1_valid = 1'b1;
                rob_forward_data_rs1 = rob_value[i];
            end
            if(forward_rs2_valid==1'b0 && rob_dest[i] == phys_rs2 &&rob_valid[i] && rob_result_ready[i]) begin
                forward_rs2_valid = 1'b1;
                rob_forward_data_rs2 = rob_value[i];
            end
        end

        // Commit logic (up to 2)
        if (commit_ready && rob_valid[head] && rob_result_ready[head]) begin
            commit_valid_1 = 1;
            commit_dest_1 = rob_dest[head];
            free_oldDest_1 = rob_oldDest[head];
            commit_value_1 = rob_value[head];
            commit_archDest_1 = rob_archDest[head];

            // Check second instruction
            if (rob_valid[(head + 1) % 64] && rob_result_ready[(head + 1) % 64]) begin
                commit_valid_2 = 1;
                commit_dest_2 = rob_dest[(head + 1) % 64];
                free_oldDest_2 = rob_oldDest[(head + 1) % 64];
                commit_value_2 = rob_value[(head + 1) % 64];
                commit_archDest_2 = rob_archDest[(head + 1) % 64];
            end
        end
    end

    // Sequential logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Reset ROB
            for (i = 0; i < 64; i = i + 1) begin
                rob_valid[i] <= 0;
                rob_result_ready[i] <= 0;
                //rob_dest[i] <= 6'b0;
                rob_oldDest[i] <= 6'b0;
                rob_archDest[i] <= 6'b0;
                //rob_value[i] <= 32'b0;
                rob_instr_addr[i] <= 32'b0;
            end
            head <= 0;
            tail <= 0;
        end else begin
            // Allocation
				prev_alloc_valid <= alloc_valid;
				prev_commit_ready <= commit_ready;
            if (prev_alloc_valid && alloc_ready) begin
                rob_valid[tail] <= 1;
                rob_instr_addr[tail] <= alloc_instr_addr;
                rob_dest[tail] <= alloc_dest;
                rob_archDest[tail] <= alloc_archDest;
                rob_oldDest[tail] <= alloc_oldDest;
                rob_result_ready[tail] <= 0;
                tail <= (tail + 1) % 64;
            end
				
            // Writeback
            if (writeback_valid1) begin          //changing to use rob_index not dest reg could also change all of the writebacks
                if (rob_valid[writeback_idx1] ) begin
                    rob_result_ready[writeback_idx1] <= 1;
                    rob_value[writeback_idx1] <= writeback_value1;
                end
			end

            if (writeback_valid2) begin          //changing to use rob_index not dest reg could also change all of the writebacks
                if (rob_valid[writeback_idx2] ) begin
                    rob_result_ready[writeback_idx2] <= 1;
                    rob_value[writeback_idx2] <= writeback_value2;
                end
            end

            if (writeback_valid3) begin          //changing to use rob_index not dest reg could also change all of the writebacks
                if (rob_valid[writeback_idx3] ) begin
                    rob_result_ready[writeback_idx3] <= 1;
                    rob_value[writeback_idx3] <= writeback_value3;
                end
            end

            if (writeback_valid4) begin          //changing to use rob_index not dest reg could also change all of the writebacks
                if (rob_valid[writeback_idx4] ) begin
                    rob_result_ready[writeback_idx4] <= 1;
                    rob_value[writeback_idx4] <= writeback_value4;
                end
            end

            // Commit up to two instructions
            if (prev_commit_ready && rob_valid[head] && rob_result_ready[head]) begin
                rob_valid[head] <= 0;
                
                // Check and commit second instruction
                if (rob_valid[(head + 1) % 64] && rob_result_ready[(head + 1) % 64]) begin

                    rob_valid[(head + 1) % 64] <= 0;
                    head <= (((head + 1) % 64) + 1) % 64;
                end
                else begin
                    head <= (head + 1) % 64;
                end
            end
        end
    end
endmodule
