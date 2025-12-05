module control_unit( // Control Unit (Instruction Decoder)
    input  logic [31:0] instr,   // 32-bit instruction
    output logic [3:0]  AluOp,   // ALU operation code
    output logic        regWrite, // Register write enable
    output logic [4:0]  rs1, rs2, rd, // Source and destination register indices
    output logic [2:0]  imm_src,  // Immediate type selector
    output logic        aluB_src, // ALU B input source (0=rs2, 1=immediate)
    output logic        MemRead,  // Memory read enable
    output logic        MemWrite, // Memory write enable
    output logic        MemToReg  // Select data from memory to write to register
);

    // Extracted fields from instruction
    logic [6:0] opcode;  // opcode field
    logic [2:0] funct3;  // funct3 field
    logic [6:0] funct7;  // funct7 field

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    always_comb begin
        // Default values to prevent latches
        regWrite = 0;
        AluOp    = 4'b0000;
        imm_src  = 3'b000;
        aluB_src = 0;
        MemRead  = 0;
        MemWrite = 0;
        MemToReg = 0;

        // Decode based on opcode
        case (opcode)
            7'b0110011: begin  // R-type instructions
                regWrite = 1;
                aluB_src = 0; // Use rs2 as ALU input B
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: AluOp = 4'b0000; // ADD
                    {7'b0100000, 3'b000}: AluOp = 4'b0001; // SUB
                    {7'b0000000, 3'b111}: AluOp = 4'b0011; // AND
                    {7'b0000000, 3'b110}: AluOp = 4'b0100; // OR
                    {7'b0000000, 3'b100}: AluOp = 4'b0010; // XOR
                    {7'b0000000, 3'b001}: AluOp = 4'b0101; // SLL
                    {7'b0000000, 3'b101}: AluOp = 4'b0110; // SRL
                    {7'b0100000, 3'b101}: AluOp = 4'b0111; // SRA
                    {7'b0000000, 3'b010}: AluOp = 4'b1000; // SLT
                    {7'b0000000, 3'b011}: AluOp = 4'b1001; // SLTU
                endcase
            end

            7'b0010011: begin  // I-type arithmetic instructions
                regWrite = 1;
                imm_src  = 3'b000; 
                aluB_src = 1; // Use immediate as ALU input B
                case(funct3)
                    3'b000: AluOp = 4'b0000; // ADDI
                    3'b100: AluOp = 4'b0010; // XORI
                    3'b110: AluOp = 4'b0100; // ORI
                    3'b111: AluOp = 4'b0011; // ANDI
                    3'b001: AluOp = 4'b0101; // SLLI
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            AluOp = 4'b0110; // SRLI
                        else if (funct7 == 7'b0100000)
                            AluOp = 4'b0111; // SRAI
                    end
                    3'b010: AluOp = 4'b1000; // SLTI
                    3'b011: AluOp = 4'b1001; // SLTIU
                endcase
            end

            7'b0000011: begin  // I-type load instructions
                regWrite = 1;
                imm_src  = 3'b001; // Load immediate offset
                aluB_src = 1;      // Use immediate for ALU
                AluOp    = 4'b0000; // ADD to calculate address
                MemRead  = 1;
                MemWrite = 0;
                MemToReg = 1;       // Write memory data to register
            end
		  
            7'b0100011: begin // S-type store instructions
                regWrite = 0;        // Does not write to registers
                MemWrite = 1;        // Enable memory write
                aluB_src = 1;        // Use immediate for ALU B
                imm_src  = 3'b010;   // S-type immediate
                AluOp    = 4'b0000;  // ADD to calculate memory address
            end

            default: begin
                // Keep default values
            end
        endcase
    end

endmodule
