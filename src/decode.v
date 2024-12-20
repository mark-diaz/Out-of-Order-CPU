module decode(
    input [31:0] instruction,
    output [6:0] opcode,
    output [4:0] rd,
    output [4:0] rs1,
    output [4:0] rs2,
    output [2:0] funct3,
    output [6:0] funct7,
    output is_load,
    output is_store,
    output is_byte,
    output is_word,
    output valid_instruction
);

    // Instruction Types and Funct3 codes
    parameter OPCODE_R_TYPE = 7'b0110011; // Register-Type Instructions
    parameter OPCODE_I_TYPE = 7'b0010011; // Immediate-Type Instructions
    parameter OPCODE_S_TYPE = 7'b0100011; // Store-Type Instructions
    parameter OPCODE_U_TYPE = 7'b0110111; // Upper Immediate-Type Instructions
    parameter OPCODE_L_TYPE = 7'b0000011; // Load-Type Instructions
    parameter FUNCT3_BYTE = 3'b000;       // Byte-level operations
    parameter FUNCT3_WORD = 3'b010;       // Word-level operations

    // Decode the instruction fields
    assign opcode = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7 = instruction[31:25];

    // Decode instruction types
    assign is_load = (opcode == OPCODE_L_TYPE);
    assign is_store = (opcode == OPCODE_S_TYPE);
    assign is_byte = (funct3 == FUNCT3_BYTE) && (is_load || is_store);
    assign is_word = (funct3 == FUNCT3_WORD) && (is_load || is_store);

    // Detect valid instructions
    assign valid_instruction = (opcode == OPCODE_R_TYPE) ||  // Arithmetic
                               (opcode == OPCODE_I_TYPE) ||  // Immediate Arithmetic
                               (opcode == OPCODE_S_TYPE) ||  // Store-Type Instructions
                               (opcode == OPCODE_U_TYPE) ||  // Upper Immediate-Type Instructions
                               (opcode == OPCODE_L_TYPE);    // Load-Type Instructions
endmodule
