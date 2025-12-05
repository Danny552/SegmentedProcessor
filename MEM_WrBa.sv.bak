module MEM_WrBa (
    input  logic        clk, rst_n,
    input  logic        en,
	 
    // Control (WB)
    input  logic        regWrite_in,
    input  logic [1:0]  MemToReg_in,
    
    // Data
    input  logic [31:0] mem_data_in,
    input  logic [31:0] alu_result_in,
    input  logic [4:0]  rd_in,
    input  logic [31:0] pc_plus_4_in,
    input  logic        halt_in,
    
    // output
    output logic        regWrite_out,
    output logic [1:0]  MemToReg_out,
    
    output logic [31:0] mem_data_out,
    output logic [31:0] alu_result_out,
    output logic [4:0]  rd_out,
    output logic [31:0] pc_plus_4_out,
    output logic        halt_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            regWrite_out <= 0; MemToReg_out <= 0;
            mem_data_out <= 0; alu_result_out <= 0; rd_out <= 0;
            pc_plus_4_out <= 0; halt_out <= 0;
        end else if (en) begin
            regWrite_out <= regWrite_in; MemToReg_out <= MemToReg_in;
            mem_data_out <= mem_data_in; alu_result_out <= alu_result_in; rd_out <= rd_in;
            pc_plus_4_out <= pc_plus_4_in; halt_out <= halt_in;
        end
    end
endmodule