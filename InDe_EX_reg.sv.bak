module InDe_EX_reg (
    input  logic        clk, rst_n, clr,
    input  logic        en, 
    
    // Control (WB)
    input  logic        regWrite_in,
    input  logic [1:0]  MemToReg_in,
    // Control (MEM)
    input  logic        MemRead_in,
    input  logic        MemWrite_in,
    // Control (EX)
    input  logic [3:0]  aluOp_in,
    input  logic        aluB_src_in,
    input  logic        aluA_src_in,
    // Control Branch/Jump/eBreak
    input  logic [2:0]  brOp_in,
    input  logic        is_branch_in, is_jal_in, is_jalr_in, ebreak_in,
    // Data
    input  logic [31:0] pc_in,
    input  logic [31:0] reg1_in,
    input  logic [31:0] reg2_in,
    input  logic [31:0] imm_in,
    input  logic [4:0]  rs1_in,
    input  logic [4:0]  rs2_in,
    input  logic [4:0]  rd_in,
    
    // Output
    output logic        regWrite_out,
    output logic [1:0]  MemToReg_out,
    output logic        MemRead_out,
    output logic        MemWrite_out,
    output logic [3:0]  aluOp_out,
    output logic        aluB_src_out,
    output logic        aluA_src_out,
    output logic [2:0]  brOp_out,
    output logic        is_branch_out, is_jal_out, is_jalr_out, ebreak_out,
    output logic [31:0] pc_out,
    output logic [31:0] reg1_out,
    output logic [31:0] reg2_out,
    output logic [31:0] imm_out,
    output logic [4:0]  rs1_out,
    output logic [4:0]  rs2_out,
    output logic [4:0]  rd_out halt_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regWrite_out <= 0; MemToReg_out <= 0;
            MemRead_out  <= 0; MemWrite_out <= 0;
            aluOp_out    <= 0; aluB_src_out <= 0; aluA_src_out <= 0;
            brOp_out     <= 0; is_branch_out <= 0; is_jal_out <= 0; is_jalr_out <= 0; ebreak_out <= 0;
            pc_out <= 0; reg1_out <= 0; reg2_out <= 0; imm_out <= 0;
            rs1_out <= 0; rs2_out <= 0; rd_out <= 0;
        end 
        else if (en) begin
            if (clr) begin
                regWrite_out <= 0; MemToReg_out <= 0;
                MemRead_out  <= 0; MemWrite_out <= 0;
                aluOp_out    <= 0; aluB_src_out <= 0; aluA_src_out <= 0;
                brOp_out     <= 0; is_branch_out <= 0; is_jal_out <= 0; is_jalr_out <= 0; ebreak_out <= 0;
                pc_out <= 0; reg1_out <= 0; reg2_out <= 0; imm_out <= 0;
                rs1_out <= 0; rs2_out <= 0; rd_out <= 0;
            end else begin
                regWrite_out <= regWrite_in; MemToReg_out <= MemToReg_in;
                MemRead_out  <= MemRead_in;  MemWrite_out <= MemWrite_in;
                aluOp_out    <= aluOp_in;    aluB_src_out <= aluB_src_in; aluA_src_out <= aluA_src_in;
                brOp_out     <= brOp_in;     is_branch_out <= is_branch_in; is_jal_out <= is_jal_in; is_jalr_out <= is_jalr_in; ebreak_out <= ebreak_in;
                pc_out <= pc_in; reg1_out <= reg1_in; reg2_out <= reg2_in; imm_out <= imm_in;
                rs1_out <= rs1_in; rs2_out <= rs2_in; rd_out <= rd_in;
            end
        end
    end
endmodule