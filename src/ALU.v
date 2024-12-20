module ALU(
    input [31:0] A,             // Operand 1
    input [31:0] B,             // Operand 2 (can be rs2 or immediate)
    input [3:0] ALUControl,     // ALU control signal
    output reg [31:0] Result,   // Result of the ALU operation
    output Zero                 // Zero flag (1 if Result is 0)
);

    // Assign the Zero flag based on the Result
    assign Zero = (Result == 32'b0);

    // ALU Operation based on ALUControl
    always @(*) begin
        case (ALUControl)
            4'b0010: Result = A + B;       // Addition
            4'b0110: Result = A - B;       // Subtraction
            4'b0001: Result = A | B;       // Bitwise OR
            4'b0011: Result = A ^ B;       // Bitwise XOR
            4'b0111: Result = A >>> B[4:0]; // Arithmetic Shift Right
			4'b1000: Result = B;
            default: Result = 32'b0;       // Default case (invalid operation)
        endcase
    end
endmodule