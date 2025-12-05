module pc(
  input wire clk,
  input wire rst_n,
  input wire [31:0] next_pc,
  output reg [31:0] address  
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      address <= 32'b0;
    else
      address <= next_pc;
  end
endmodule
