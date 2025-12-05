module alu(
    input wire [31:0] A, B,
    input wire [3:0]  AluOp,
    output reg [31:0] AluResult
);

/* ALU control operations
   0000 -> + add
   0001 -> - sub
   0010 -> ^ xor
   0011 -> & and
   0100 -> | or
   0101 -> << logical shift left
   0110 -> >> logical shift right
   0111 -> >>> arithmetic shift right
   1000 -> (rs1 < rs2) ? 1 : 0   Set Less Than (signed)
   1001 -> (rs1 < rs2) ? 1 : 0   Set Less Than (unsigned)
*/

always @(*) begin
    case (AluOp)
        4'b0000: AluResult = A + B;
        4'b0001: AluResult = A - B;
        4'b0010: AluResult = A ^ B;
        4'b0011: AluResult = A & B;
        4'b0100: AluResult = A | B;
        4'b0101: AluResult = A << B[4:0];
        4'b0110: AluResult = A >> B[4:0];
        4'b0111: AluResult = $signed(A) >>> B[4:0];
        4'b1000: AluResult = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
        4'b1001: AluResult = (A < B) ? 32'b1 : 32'b0;
		  4'b1111: AluResult = B;
    endcase

end

endmodule
