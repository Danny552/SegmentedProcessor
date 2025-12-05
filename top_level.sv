module cpu_top (
    // =====================
    // System & Control Inputs
    // =====================
    input  logic clk,             // Step clock (manual or slow clock)
    input  logic rst_n,           // Active-low reset button
    input  logic vga_rst_n,       // Active-low VGA reset
    input  logic vga_clock_in,    // 50 MHz VGA clock input

    // =====================
    // Switches, LEDs, and 7-Segment Displays
    // =====================
    input  logic sw0,
    input  logic sw1,
    input  logic sw2,
    input  logic sw3,
    output logic [6:0] seg0,
    output logic [6:0] seg1,
    output logic [6:0] seg2,
    output logic [6:0] seg3,
    output logic [9:0] leds,

    // =====================
    // VGA Outputs
    // =====================
    output logic [7:0] VGA_R,
    output logic [7:0] VGA_G,
    output logic [7:0] VGA_B,
    output logic VGA_HS,
    output logic VGA_VS,
    output logic VGA_CLK
);

    // =====================
    // 1. Reset Logic
    // =====================
    wire sys_reset = ~rst_n;      // Convert to active-high reset
    wire vga_reset = ~vga_rst_n;  // Convert VGA reset to active-high

    // =====================
    // 2. Internal CPU Signals
    // =====================
    logic [31:0] pc_current, pc_next;
    logic [31:0] instruction;
    logic [3:0]  alu_op;
    logic        reg_write_en;
    logic [4:0]  rs1, rs2, rd;
    logic [31:0] reg_data_a, reg_data_b;
    logic [31:0] alu_result;
    logic        zero_flag;

    logic [31:0] immediate;
    logic [31:0] alu_operand_b;
    logic [2:0]  imm_type;
    logic        alu_src_b_sel;
    logic        mem_read, mem_write, mem_to_reg;

    logic [31:0] mem_read_data;
    logic [31:0] writeback_data;

    // Debug memory/register arrays
    logic [7:0]  mem_debug [0:127];
    logic [31:0] regs_debug [31:0];

    logic [6:0]  imem_debug_addr;
    logic [31:0] imem_debug_data;

    // =====================
    // 3. CPU Core Components
    // =====================

    // Program Counter
    pc pc_unit (
        .clk(clk),
        .rst_n(rst_n),
        .address(pc_current),
        .next_pc(pc_next)
    );

    // Instruction Memory
    instruction_memory instr_mem (
        .addr(pc_current),
        .instr(instruction),
        .debug_addr(imem_debug_addr),
        .debug_data(imem_debug_data)
    );

    // Instruction Decoder
    decoder decoder_unit (
        .instr(instruction),
        .AluOp(alu_op),
        .regWrite(reg_write_en),
        .MemRead(mem_read),
        .MemWrite(mem_write),
        .MemToReg(mem_to_reg),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .imm_src(imm_type),
        .aluB_src(alu_src_b_sel)
    );

    // Register File
    register_file reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .write_enable(reg_write_en),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(writeback_data),
        .read_data1(reg_data_a),
        .read_data2(reg_data_b),
        .regs_debug(regs_debug)
    );

    // Immediate Generator
    immediate_generator imm_gen (
        .instr(instruction),
        .imm_src(imm_type),
        .imm(immediate)
    );

    // ALU Operand B Mux
    mux2_1 alu_src_mux (
        .x(reg_data_b),
        .y(immediate),
        .select(alu_src_b_sel),
        .r(alu_operand_b)
    );

    // ALU
    alu alu_unit (
        .A(reg_data_a),
        .B(alu_operand_b),
        .AluOp(alu_op),
        .zero(zero_flag),
        .AluResult(alu_result)
    );

    // Data Memory
    data_memory data_mem (
        .clk(clk),
        .MemRead(mem_read),
        .MemWrite(mem_write),
        .funct3(instruction[14:12]),
        .addr(alu_result),
        .write_data(reg_data_b),
        .read_data(mem_read_data),
        .mem_debug(mem_debug)
    );

    // Writeback Mux
    mux_mem wb_mux (
        .alu_result(alu_result),
        .mem_data(mem_read_data),
        .MemToReg(mem_to_reg),
        .write_back(writeback_data)
    );

    // =====================
    // 4. Debug Display Logic
    // =====================
    logic [31:0] debug_data;
    logic [2:0] display_sel = {sw2, sw1, sw0};

    always_comb begin
        case (display_sel)
            3'b000: debug_data = instruction;
            3'b001: debug_data = alu_result;
            3'b010: debug_data = mem_read_data;
            3'b100: debug_data = writeback_data;
            default: debug_data = 32'b0;
        endcase
    end

    assign leds = debug_data[9:0];

    hex7seg seg_display0 (.val(debug_data[3:0]),   .display(seg0));
    hex7seg seg_display1 (.val(debug_data[7:4]),   .display(seg1));
    hex7seg seg_display2 (.val(debug_data[11:8]),  .display(seg2));
    hex7seg seg_display3 (.val(debug_data[15:12]), .display(seg3));

    // =====================
    // 5. VGA Debug Monitor
    // =====================
    vga_debug vga_monitor (
        .clock(vga_clock_in),
        .reset(vga_reset),

        // CPU debug signals
        .pc_addr(pc_current),
        .instr(instruction),
        .alu_result(alu_result),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .reg_write(reg_write_en),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_read_data(mem_read_data),
        .write_back_data(writeback_data),
        .imm(immediate),
        .aluOp(alu_op),
        .next_pc(pc_next),
        .alu_B(alu_operand_b),
        .imm_src(imm_type),
        .mem(mem_debug),
        .regs_debug(regs_debug),
        .inst_mem_debug_addr(imem_debug_addr),
        .inst_mem_debug_data(imem_debug_data),

        // VGA outputs
        .vga_red(VGA_R),
        .vga_green(VGA_G),
        .vga_blue(VGA_B),
        .vga_hsync(VGA_HS),
        .vga_vsync(VGA_VS),
        .vga_clock(VGA_CLK)
    );

endmodule
