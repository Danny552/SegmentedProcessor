module instruction_memory (
    input  logic [31:0] addr,
    output logic [31:0] instr,

    input  logic [6:0]  debug_addr,
    output logic [31:0] debug_data
);

    // Internal memory: 128 words of 32 bits
    logic [31:0] memory [0:127];

    //Initial memory load from file
    initial begin
       $readmemb("program.bin", memory);
    end

    // Instruction read
    always_comb begin
        instr = memory[addr[8:2]];
    end

    // Debug read
    assign debug_data = memory[debug_addr];

endmodule
