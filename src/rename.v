module rename (
    input clk,
    input reset_n,
    input issue_valid,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
	input retire_valid1,
	input isStore,
	input [5:0] retire_phys_reg1,
	input retire_valid2,
	input [5:0] retire_phys_reg2,
	output reg [5:0] phys_rd,
	output reg [5:0] phys_rs1,
	output reg [5:0] phys_rs2,
	output reg [5:0] old_phys_rd,
	output reg [4:0] arch_reg,
	output free_list_empty,
	output reg rename_valid
);
	parameter NUM_PHYS_REGS = 64;
	parameter NUM_ARCH_REGS = 32;
	parameter DEFAULT_PHYS_REG = 6'd0;
	parameter DEFAULT_ARCH_REG = 5'd0;


	reg [NUM_PHYS_REGS-1:0] free_list;
    reg [5:0] rename_alias_table [31:0];
	reg [5:0] prev_rd;
	reg prev_issue_valid;

	wire prev_retire_valid1;
	wire prev_retire_valid2;
	wire [5:0] prev_retire_phys_reg1;
	wire [5:0] prev_retire_phys_reg2;
	reg reg_found;
    integer i;

	assign free_list_empty = (issue_valid && !reg_found && !isStore) ? 1'b1 : 1'b0;

	// Assignments for retirement logic
	assign prev_retire_phys_reg1 = retire_valid1 ? retire_phys_reg1 : prev_retire_phys_reg1;
	assign prev_retire_valid1 = retire_valid1 ? retire_valid1 : 1'b0;
	assign prev_retire_phys_reg2 = retire_valid2 ? retire_phys_reg2 : prev_retire_phys_reg2;
	assign prev_retire_valid2 = retire_valid2 ? retire_valid2 : 1'b0;
	 
    // Combinational logic for renaming
    always @(*) begin

		reg_found = 1'b0;
		phys_rd = DEFAULT_PHYS_REG;
		rename_valid = 0;
		phys_rs1 = DEFAULT_PHYS_REG;
		phys_rs2 = DEFAULT_PHYS_REG;
		old_phys_rd = DEFAULT_PHYS_REG;
		arch_reg = DEFAULT_ARCH_REG;
		
		if (issue_valid)begin
			phys_rd = DEFAULT_PHYS_REG;

			// Store do not have destination regs
			if(isStore) begin
				phys_rd = DEFAULT_PHYS_REG;
				arch_reg = DEFAULT_ARCH_REG;
			end 
			else begin
				for(i = 0; i < NUM_PHYS_REGS; i = i + 1) begin
					if (free_list[i] && reg_found == 1'b0) begin
						phys_rd = i[5:0];
						reg_found = 1'b1;
					end
				end
			end

			if(reg_found || isStore) begin
				
				rename_valid = 1'b1;
				phys_rs1 = rename_alias_table[rs1]; 
				phys_rs2 = rename_alias_table[rs2];
			
				if(!isStore) begin
					old_phys_rd = rename_alias_table[rd];
					arch_reg = rd;
				end
			end 
		end
    end

    // Sequential logic for state updates only
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
			free_list <= {{NUM_PHYS_REGS-32{1'b1}}, {32{1'b0}}};
            for (i = 0; i < 32; i = i + 1) begin
				rename_alias_table[i] <= i;
            end
			prev_rd <= 6'b000000;
        end
        else begin
			prev_rd <= rd;
			prev_issue_valid<=issue_valid;
				
            // Update state based on the combinationally computed phys_rd
            if(prev_issue_valid && !free_list_empty&& !isStore) begin
                free_list[phys_rd] <= 1'b0;
               	rename_alias_table[rd] <= phys_rd;
            end
            // update free list on retire
            if(prev_retire_valid1) begin
                free_list[prev_retire_phys_reg1] <= 1'b1;
            end
			if(prev_retire_valid2) begin
                free_list[prev_retire_phys_reg2] <= 1'b1;				 
            end
        end
	end

endmodule