module ForwardUnit (
    input  logic [4:0] ID_EX_rs1,
    input  logic [4:0] ID_EX_rs2,
    input  logic [4:0] EX_MEM_rd,
    input  logic       EX_MEM_regWrite,
    input  logic [4:0] MEM_WB_rd,
    input  logic       MEM_WB_regWrite,
    
    output logic [1:0] ForwardA,
    output logic [1:0] ForwardB
);

    always_comb begin
        ForwardA = 2'b00;
        
        if (EX_MEM_regWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs1)) begin
            ForwardA = 2'b10;
        end
        else if (MEM_WB_regWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs1)) begin
            ForwardA = 2'b01;
        end

        ForwardB = 2'b00;
        
        if (EX_MEM_regWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2)) begin
            ForwardB = 2'b10;
        end
        else if (MEM_WB_regWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs2)) begin
            ForwardB = 2'b01;
        end
    end
endmodule