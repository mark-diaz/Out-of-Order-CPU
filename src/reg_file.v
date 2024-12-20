module reg_file(
    input clk,
    input reset_n,
    input [4:0] rs1,         // Read register 1
    input [4:0] rs2,         // Read register 2
    input [4:0] rd1,         // Write register 1
    input [31:0] rd1_data,   // Data to write for retire 1
    input regWrite1,         // Write enable signal for retire 1
    input [4:0] rd2,         // Write register 2
    input [31:0] rd2_data,   // Data to write for retire 2
    input regWrite2,         // Write enable signal for retire 2
    output [31:0] rs1_data, // Data output for rs1
    output [31:0] rs2_data  // Data output for rs2
);

    // 32 registers, 32-bits wide
    reg [31:0] registers [0:31];

    // Read register data: Combinational
    assign rs1_data = (rs1 == 5'b00000) ? 32'b0 : registers[rs1]; // x0 is always 0
    assign rs2_data = (rs2 == 5'b00000) ? 32'b0 : registers[rs2]; // x0 is always 0

    integer i;
    // Write register data: Sequential
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] = 32'd0;
            end
        end
        else begin
            // Handle write for retire 1
            if (regWrite1 && (rd1 != 5'b00000)) begin
                registers[rd1] <= rd1_data; 
            end
            // Handle write for retire 2
            if (regWrite2 && (rd2 != 5'b00000)) begin
                registers[rd2] <= rd2_data; 
            end
        end
    end

endmodule
