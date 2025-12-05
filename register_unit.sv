module register_unit (
    input  logic         clk,
    input  logic         rst_n,          // Active-low asynchronous reset
    input  logic         write_enable,   // Write enable for register file
    input  logic [4:0]   rs1,            // Source register 1 index
    input  logic [4:0]   rs2,            // Source register 2 index
    input  logic [4:0]   rd,             // Destination register index
    input  logic [31:0]  write_data,     // Data to write into rd
    output logic [31:0]  read_data1,     // Data from rs1
    output logic [31:0]  read_data2,     // Data from rs2
    output logic [31:0]  regs_debug [31:0] // Debug output of all registers
);

    // Declare 32 registers of 32 bits
    logic [31:0] regs [31:0];

    // Expose register file for debug purposes
    assign regs_debug = regs;

    // Read data, ensure x0 (regs[0]) always reads as 0
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    // Asynchronous active-low reset, synchronous write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to 0
            for (int i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
        end else begin
            // Normal operation: write to register if enabled, except x0
            if (write_enable && (rd != 5'd0)) begin
                regs[rd] <= write_data;
            end
        end
    end

endmodule
