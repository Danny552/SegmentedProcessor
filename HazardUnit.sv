module HazardUnit (
    input  logic [4:0] IF_ID_rs1,
    input  logic [4:0] IF_ID_rs2,
    input  logic [4:0] ID_EX_rd,
    input  logic       ID_EX_MemRead,
    
    output logic       PC_Write,      
    output logic       IF_ID_Write,   
    output logic       Control_Mux
);

    always_comb begin
        if (ID_EX_MemRead && ((ID_EX_rd == IF_ID_rs1) || (ID_EX_rd == IF_ID_rs2))) begin
            PC_Write    = 0; 
            IF_ID_Write = 0; 
            Control_Mux = 0;
        end else begin
            PC_Write    = 1;
            IF_ID_Write = 1;
            Control_Mux = 1;
        end
    end
endmodule