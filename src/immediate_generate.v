module immediate_generate (
    input [31:0] instruction,
    output reg [31:0] immediate
);
    // opcodes
    parameter R_TYPE = 7'b0110011;
    parameter I_TYPE = 7'b0010011;
    parameter S_TYPE = 7'b0100011;
    parameter U_TYPE = 7'b0110111;
	parameter L_TYPE = 7'b0000011;
    
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            R_TYPE: immediate[31:0] = 32'd0;
            I_TYPE: immediate = { { 20{instruction[31]} }, instruction[31:20]}; // sign-extend MSB
			L_TYPE: immediate = { { 20{instruction[31]} }, instruction[31:20]}; // sign-extend
            S_TYPE: immediate = { {20{ instruction[31]} } , instruction[31:25], instruction[11:7]}; // sign-extend MSB
            U_TYPE: immediate = { instruction[31:12], 12'd0}; // zero-extend the remaining bits
            default: immediate[31:0] = 32'd0;
        endcase
    end

endmodule