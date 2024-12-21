module instruction_rom (
    input [7:0] address,    
    output reg [31:0] data   
);
    reg [7:0] instruction_bytes [0:1023];  
    reg [31:0] instruction_memory [0:255]; 
    integer i;

    initial begin
        $readmemh("/home/mark/Documents/workspace/Out-of-Order-CPU/trace/final.txt", instruction_bytes);
        for (i = 0; i < 256; i = i + 1) begin
            instruction_memory[i] = {
              	instruction_bytes[4*i+3],    // Most significant byte (MSB)
                instruction_bytes[4*i+2],  // Third byte
                instruction_bytes[4*i+1],  // Second byte
                instruction_bytes[4*i+0]  // Least significant byte (LSB)
            };
        end
    end

    always @(*) begin
        data = instruction_memory[address]; 
    end
endmodule
