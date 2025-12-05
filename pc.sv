module pc(
  input wire clk,            // Physical button (clock)
  input wire rst_n,          // Active-low reset
  input logic en,
  output reg [31:0] address, // Current address
  output reg [31:0] next_pc  // Next program counter value
);

  // Next PC calculation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      address  <= 32'b0;      // Reset: go back to 0
      next_pc  <= 32'b0;
    end else if (en) begin
      next_pc  <= address + 32'd4; // Calculate next_pc
      address  <= address + 32'd4; // Load the new value into address
    end
  end

endmodule
