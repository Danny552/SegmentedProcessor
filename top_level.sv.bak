module top_level(
  input wire clk,
  input wire rst_n,
  output wire [6:0] display,
  output wire [9:0] leds
);

  // Instantiate the pc module
  wire [31:0] next_pc;
  wire [31:0] address;

  pc pc_inst(
    .clk(clk),
    .rst_n(rst_n),
    .next_pc(next_pc),
    .address(address)
  );

  hex7seg display0(
    .val(address[3:0]),
    .display(display)
  );

  assign leds = 10'b1010101010;
endmodule 
