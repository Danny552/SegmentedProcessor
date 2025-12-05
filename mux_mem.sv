module mux_mem (// if reading from ALU or memory
    input  logic [31:0] alu_result,
    input  logic [31:0] mem_data,
    input  logic [1:0]  MemToReg,   // control: 00 = ALU, 01 = Memory, 10 = JAL Y JALR
	 input  logic [31:0] pc_next,
    output logic [31:0] write_back
);

    always_comb begin
        case(MemToReg)
            2'b00: write_back = alu_result; // Operaciones R e I
            2'b01: write_back = mem_data;   // LW
            2'b10: write_back = pc_next;  // JAL y JALR
            default: write_back = 32'b0;
        endcase
    end
endmodule
