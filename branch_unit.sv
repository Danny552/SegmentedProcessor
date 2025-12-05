module branch_unit(
    input  logic [2:0]  brOp,       // From control unit
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    input  logic [31:0] pc,
    input  logic [31:0] imm_branch, // Imm
    output logic branch_taken,
    output logic [31:0] branch_target // Where
);

/*
br control aop 
000 -> beq 
001 -> bne 
100 -> blt 
101 -> bge 
110 -> bltu 
111 -> bgeu 
*/

    // comparador
    always_comb begin
        case(brOp)
            3'b000: branch_taken = (rs1 == rs2);                    // BEQ
            3'b001: branch_taken = (rs1 != rs2);                    // BNE
            3'b100: branch_taken = ($signed(rs1) < $signed(rs2));   // BLT
            3'b101: branch_taken = ($signed(rs1) >= $signed(rs2));  // BGE
            3'b110: branch_taken = (rs1 < rs2);                     // BLTU
            3'b111: branch_taken = (rs1 >= rs2);                    // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    assign branch_target = pc + imm_branch;

endmodule
