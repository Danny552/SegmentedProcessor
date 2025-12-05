module immediate_generator(
    input  logic [31:0] instr,     // full instruction
    input  logic [2:0]  imm_src,   // instruction type code
    output logic [31:0] imm        // 32-bit sign-extended immediate
);

/*
  imm_src codes:
  000 -> I-type (arithmetic/logical)
  001 -> I-type (load instructions)
  010 -> S-type (store: SB, SH, SW)
  011 -> B-Type (compare)
  100 -> U-Type
  101 -> J-Type
*/

always_comb begin
    case (imm_src)
        // I-type (ADDI, ANDI, ORI, etc.)
        3'b000: imm = {{20{instr[31]}}, instr[31:20]};
        
        // I-type (loads: LB, LH, LW, LBU, LHU)
        3'b001: imm = {{20{instr[31]}}, instr[31:20]};
        
        // S-type (stores: SB, SH, SW)
        3'b010: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
		  
		  // B-Type
		  3'b011: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
		  
		  // U-Type
		  3'b100: imm = {instr[31:12], 12'b0};
		  
		  // J-Type
		  3'b101: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

        
        default: imm = 32'b0;
    endcase
end
endmodule
