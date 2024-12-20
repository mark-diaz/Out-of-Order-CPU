module pipeline_buffer #(parameter WIDTH = 32) (
    input clk,
    input reset_n,
	input stall,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            data_out <= {WIDTH{1'b0}};
		else if(stall) begin
			data_out <= data_out;
		end
        else begin
            data_out <= data_in;
        end
    end

endmodule