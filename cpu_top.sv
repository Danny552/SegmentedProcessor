module cpu_top (
    // =====================
    // System & Control Inputs
    // =====================
    input  logic clk,             // Step clock (manual or slow clock)
    input  logic rst_n,           // Active-low reset button
    input  logic vga_rst_n,       // Active-low VGA reset
    input  logic vga_clock_in,    // 50 MHz VGA clock input

    // =====================
    // User I/O for Debug Display
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
    // 2. Clock Logic
    // =====================
    logic cpu_clk;
    assign cpu_clk = (sw3) ? vga_clock_in : clk;

    // =====================
    // 3. Pipeline Signals
    // =====================
    // IF Stage
    logic [31:0] if_pc_current, if_pc_next, if_pc_plus_4, if_instr;
    logic pc_write_enable, if_id_write_enable, if_flush;
    
    // ID Stage
    logic [31:0] id_pc, id_instr, id_pc_plus_4, id_reg1_data, id_reg2_data, id_imm;
    logic [4:0] id_rs1, id_rs2, id_rd;
    logic [3:0] id_alu_op;
    logic id_reg_write, id_mem_read, id_mem_write, id_alu_src_b, id_alu_src_a;
    logic [1:0] id_mem_to_reg;
    logic [2:0] id_brOp, id_imm_src;
    logic id_is_branch, id_is_jal, id_is_jalr, id_ebreak;
    logic hazard_mux_sel, id_flush;

    // EX Stage
    logic id_ex_reg_write, id_ex_mem_read, id_ex_mem_write;
    logic [1:0] id_ex_mem_to_reg;
    logic [3:0] id_ex_alu_op;
    logic id_ex_alu_src_b, id_ex_alu_src_a;
    logic id_ex_is_branch, id_ex_is_jal, id_ex_is_jalr, id_ex_ebreak;
    logic [2:0] id_ex_brOp;

    logic [31:0] ex_pc, ex_reg1, ex_reg2, ex_imm, ex_pc_plus_4;
    logic [4:0] ex_rs1, ex_rs2, ex_rd;
    logic [3:0] ex_alu_op;
    logic ex_reg_write, ex_mem_read, ex_mem_write, ex_alu_src_b, ex_alu_src_a;
    logic [1:0] ex_mem_to_reg;
    logic ex_is_branch, ex_is_jal, ex_is_jalr, ex_ebreak;
    logic [2:0] ex_brOp;
    logic [31:0] ex_forwarded_a, ex_forwarded_b, ex_alu_in_a, ex_alu_in_b, ex_alu_result;
    logic [1:0] forward_a_sel, forward_b_sel;
    logic ex_branch_taken;
    logic [31:0] ex_branch_target;
    logic pc_src;

    // MEM Stage
    logic [31:0] mem_alu_result, mem_write_data, mem_pc_plus_4;
    logic [4:0] mem_rd;
    logic mem_reg_write, mem_mem_read, mem_mem_write;
    logic [1:0] mem_mem_to_reg;
    logic [31:0] mem_read_data;
    logic mem_ebreak;

    // WB Stage
    logic [31:0] wb_read_data, wb_alu_result, wb_pc_plus_4, wb_final_data;
    logic [4:0] wb_rd;
    logic wb_reg_write;
    logic [1:0] wb_mem_to_reg;
    logic wb_ebreak;

    // Debug memory/register arrays
    logic [7:0]   mem_debug [0:127];
    logic [31:0]  regs_debug [0:31];
    logic [6:0]   imem_debug_addr;
    logic [31:0]  imem_debug_data;

    // =====================
    // 4. Pipeline Enable Logic
    // =====================
    logic pipe_en;
    assign pipe_en = !wb_ebreak; 

    // =====================
    // 5. IF Stage
    // =====================
    always_comb begin
        // If there's a ebreak in ID, freeze locally to not lose PC
        if (id_ebreak) if_pc_next = if_pc_current; 
        else if (pc_src) if_pc_next = ex_branch_target;
        else if_pc_next = if_pc_plus_4;
    end

    pc u_pc (
        .clk(cpu_clk), .rst_n(rst_n), 
        // PC freezes if there's a Hazard (pc_write_enable) OR if there's EBREAK (pipe_en)
        .en(pc_write_enable & pipe_en), 
        .next_pc(if_pc_next), .address(if_pc_current)
    );
    assign if_pc_plus_4 = if_pc_current + 4;

    instruction_memory u_imem (
        .addr(if_pc_current), .instr(if_instr),
        .debug_addr(imem_debug_addr), .debug_data(imem_debug_data)
    );

     InFe_InDe u_if_id_reg (
        .clk(cpu_clk), .rst_n(rst_n), 
        // Register freezes if there's a Hazard OR if there's EBREAK
        .en(if_id_write_enable & pipe_en), 
        .clr(if_flush), .pc_in(if_pc_current), .instr_in(if_instr),
        .pc_out(id_pc), .instr_out(id_instr)
    );
    assign if_flush = pc_src; assign id_flush = pc_src; 

    // =====================
    // 6. ID Stage
    // =====================
    assign id_rs1 = id_instr[19:15]; 
    assign id_rs2 = id_instr[24:20]; 
    assign id_rd = id_instr[11:7]; 
    assign id_pc_plus_4 = id_pc + 4;

    HazardUnit u_hazard_unit (
        .IF_ID_rs1(id_rs1), .IF_ID_rs2(id_rs2), .ID_EX_rd(ex_rd), .ID_EX_MemRead(ex_mem_read),
        .PC_Write(pc_write_enable), .IF_ID_Write(if_id_write_enable), .Control_Mux(hazard_mux_sel)
    );

    control_unit u_dec (
        .instr(id_instr), .regWrite(id_reg_write), .MemToReg(id_mem_to_reg), .MemRead(id_mem_read), .MemWrite(id_mem_write),
        .AluOp(id_alu_op), .aluB_src(id_alu_src_b), .aluA_src(id_alu_src_a), .imm_src(id_imm_src), .brOp(id_brOp),
        .branch(id_is_branch), .is_jalr(id_is_jalr), .is_jal(id_is_jal), .ebreak(id_ebreak)
    );

    register_unit u_regs (
        .clk(cpu_clk), .rst_n(rst_n), .rs1(id_rs1), .rs2(id_rs2), .rd(wb_rd), .write_data(wb_final_data), .write_enable(wb_reg_write),
        .read_data1(id_reg1_data), .read_data2(id_reg2_data), .regs_debug(regs_debug)
    );

    immediate_generator u_imm (.instr(id_instr), .imm_src(id_imm_src), .imm(id_imm));

    assign id_ex_reg_write = hazard_mux_sel ? id_reg_write : 0;
    assign id_ex_mem_write = hazard_mux_sel ? id_mem_write : 0;
    assign id_ex_mem_read = hazard_mux_sel ? id_mem_read : 0;
    assign id_ex_is_branch = hazard_mux_sel ? id_is_branch : 0;
    assign id_ex_is_jal = hazard_mux_sel ? id_is_jal : 0;
    assign id_ex_is_jalr = hazard_mux_sel ? id_is_jalr : 0;
    assign id_ex_mem_to_reg = id_mem_to_reg; 
    assign id_ex_alu_op = id_alu_op;
    assign id_ex_alu_src_b = id_alu_src_b; 
    assign id_ex_alu_src_a = id_alu_src_a;
    assign id_ex_brOp = id_brOp; 
    assign id_ex_ebreak = id_ebreak;

    InDe_EX u_id_ex (
        .clk(cpu_clk), .rst_n(rst_n), .clr(id_flush),
        .en(pipe_en), // Freeze
        .regWrite_in(id_ex_reg_write), .MemToReg_in(id_ex_mem_to_reg), .MemRead_in(id_ex_mem_read), .MemWrite_in(id_ex_mem_write),
        .aluOp_in(id_ex_alu_op), .aluB_src_in(id_ex_alu_src_b), .aluA_src_in(id_ex_alu_src_a),
        .brOp_in(id_ex_brOp), .is_branch_in(id_ex_is_branch), .is_jal_in(id_ex_is_jal), .is_jalr_in(id_ex_is_jalr), .ebreak_in(id_ex_ebreak),
        .pc_in(id_pc), .reg1_in(id_reg1_data), .reg2_in(id_reg2_data), .imm_in(id_imm), .rs1_in(id_rs1), .rs2_in(id_rs2), .rd_in(id_rd),
        .regWrite_out(ex_reg_write), .MemToReg_out(ex_mem_to_reg), .MemRead_out(ex_mem_read), .MemWrite_out(ex_mem_write),
        .aluOp_out(ex_alu_op), .aluB_src_out(ex_alu_src_b), .aluA_src_out(ex_alu_src_a),
        .brOp_out(ex_brOp), .is_branch_out(ex_is_branch), .is_jal_out(ex_is_jal), .is_jalr_out(ex_is_jalr), .ebreak_out(ex_ebreak),
        .pc_out(ex_pc), .reg1_out(ex_reg1), .reg2_out(ex_reg2), .imm_out(ex_imm), .rs1_out(ex_rs1), .rs2_out(ex_rs2), .rd_out(ex_rd)
    );

    // =====================
    // 7. EX Stage
    // =====================
    ForwardUnit u_forwarding (
        .ID_EX_rs1(ex_rs1), .ID_EX_rs2(ex_rs2), .EX_MEM_rd(mem_rd), .EX_MEM_regWrite(mem_reg_write),
        .MEM_WB_rd(wb_rd), .MEM_WB_regWrite(wb_reg_write), .ForwardA(forward_a_sel), .ForwardB(forward_b_sel)
    );

    always_comb begin
        case(forward_a_sel) 
            2'b00: ex_forwarded_a = ex_reg1; 
            2'b10: ex_forwarded_a = mem_alu_result; 
            2'b01: ex_forwarded_a = wb_final_data; 
            default: ex_forwarded_a = ex_reg1; 
        endcase
        case(forward_b_sel) 
            2'b00: ex_forwarded_b = ex_reg2; 
            2'b10: ex_forwarded_b = mem_alu_result; 
            2'b01: ex_forwarded_b = wb_final_data; 
            default: ex_forwarded_b = ex_reg2; 
        endcase
    end

    assign ex_alu_in_a = (ex_alu_src_a) ? ex_pc : ex_forwarded_a;
    assign ex_alu_in_b = (ex_alu_src_b) ? ex_imm : ex_forwarded_b;

    alu u_alu (.A(ex_alu_in_a), .B(ex_alu_in_b), .AluOp(ex_alu_op), .AluResult(ex_alu_result));
    branch_unit u_branch (.brOp(ex_brOp), .rs1(ex_forwarded_a), .rs2(ex_forwarded_b), .pc(ex_pc), .imm_branch(ex_imm), .branch_taken(ex_branch_taken), .branch_target(ex_branch_target));

    logic jump_jalr_taken; 
    assign jump_jalr_taken = ex_is_jalr;
    always_comb begin
        if (ex_is_jalr) pc_src = 1'b1;
        else if ((ex_branch_taken & ex_is_branch) | ex_is_jal) pc_src = 1'b1;
        else pc_src = 1'b0;
    end

EX_MEM u_ex_mem (
    .clk(cpu_clk), 
    .rst_n(rst_n),
    .en(pipe_en), // Freeze
    .regWrite_in(ex_reg_write), 
    .MemToReg_in(ex_mem_to_reg), 
    .MemRead_in(ex_mem_read), 
    .MemWrite_in(ex_mem_write),
    .alu_result_in(ex_alu_result), 
    .mem_write_data_in(ex_forwarded_b), 
    .rd_in(ex_rd), 
    .pc_plus_4_in(ex_pc + 4), 
    .ebreak_in(ex_ebreak),
    .regWrite_out(mem_reg_write), 
    .MemToReg_out(mem_mem_to_reg), 
    .MemRead_out(mem_mem_read), 
    .MemWrite_out(mem_mem_write),
    .alu_result_out(mem_alu_result), 
    .mem_write_data_out(mem_write_data), 
    .rd_out(mem_rd), 
    .pc_plus_4_out(mem_pc_plus_4), 
    .ebreak_out(mem_ebreak)
);

    // =====================
    // 8. MEM Stage
    // =====================
    data_memory u_mem (.clk(cpu_clk), .MemRead(mem_mem_read), .MemWrite(mem_mem_write), .funct3(3'b010), .addr(mem_alu_result), .write_data(mem_write_data), .read_data(mem_read_data), .mem_debug(mem_debug));

     MEM_WrBa  u_mem_wb (
        .clk(cpu_clk), .rst_n(rst_n),
        .en(pipe_en), // Freeze
        .regWrite_in(mem_reg_write), .MemToReg_in(mem_mem_to_reg),
        .mem_data_in(mem_read_data), .alu_result_in(mem_alu_result), .rd_in(mem_rd), .pc_plus_4_in(mem_pc_plus_4), .ebreak_in(mem_ebreak),
        .regWrite_out(wb_reg_write), .MemToReg_out(wb_mem_to_reg),
        .mem_data_out(wb_read_data), .alu_result_out(wb_alu_result), .rd_out(wb_rd), .pc_plus_4_out(wb_pc_plus_4), .ebreak_out(wb_ebreak)
    );

    // =====================
    // 9. WB Stage
    // =====================
    mux_mem u_mux_wb (.alu_result(wb_alu_result), .mem_data(wb_read_data), .pc_next(wb_pc_plus_4), .MemToReg(wb_mem_to_reg), .write_back(wb_final_data));

    // =====================
    // 10. Debug Display Logic
    // =====================
    logic [2:0] display_sel;
    assign display_sel = {sw2, sw1, sw0}; // combine switches into selector

    logic [31:0] debug_data;

    always_comb begin
        case (display_sel)
            3'b000: debug_data = id_instr;      // Instruction from ID stage
            3'b001: debug_data = ex_alu_result;  // ALU result from EX stage
            3'b010: debug_data = mem_read_data;  // Memory read data from MEM stage
            3'b100: debug_data = wb_final_data;  // Writeback data from WB stage
            default: debug_data = 32'b0;
        endcase
    end

    assign leds = {pc_write_enable, hazard_mux_sel, pc_src, id_ex_is_jalr, 
                   (forward_a_sel != 0), (forward_b_sel != 0), 2'b00, wb_ebreak};

    hex7seg seg_display0 (.val(debug_data[3:0]),   .display(seg0));
    hex7seg seg_display1 (.val(debug_data[7:4]),   .display(seg1));
    hex7seg seg_display2 (.val(debug_data[11:8]),  .display(seg2));
    hex7seg seg_display3 (.val(debug_data[15:12]), .display(seg3));

    // =====================
    // 11. VGA Debug Monitor
    // =====================
// In your top_level module
vga_monitor vga_monitor (
    .clock(vga_clock_in),
    .reset(vgarst),

    // CPU debug signals (from pipeline stages)
    .if_pc(if_pc_current),
    .if_instr(if_instr),
    .id_pc(id_pc),
    .id_instr(id_instr),
    .id_reg1(id_reg1_data),
    .id_reg2(id_reg2_data),
    .id_imm(id_imm),
    .hazard_stall(hazard_mux_sel), // Note: hazard_mux_sel is 0 on stall, 1 on no-stall. This matches the logic.
    .ex_pc(ex_pc),
    .ex_alu_result(ex_alu_result),
    .ex_brOp(ex_brOp),
    .ex_taken(pc_src),
    .forward_a(forward_a_sel),
    .forward_b(forward_b_sel),
    .mem_pc(mem_pc_plus_4 - 4), // Assuming mem_pc_plus_4 holds PC+4
    .mem_data_read(mem_read_data),
    .mem_memWrite(mem_mem_write),
    .wb_pc(wb_pc_plus_4 - 4),   // Assuming wb_pc_plus_4 holds PC+4
    .wb_data(wb_final_data),
    .wb_rd_addr(wb_rd),
    .wb_regWrite(wb_reg_write),
    .ebreak_s(wb_ebreak),

    // Memory and register debug signals
    .mem(mem_debug),
    .regs_debug(regs_debug),
    .inst_mem_debug_addr(imem_debug_addr_wire),
    .inst_mem_debug_data(imem_debug_data_wire),

    // VGA outputs
    .vga_red(VGA_R),
    .vga_green(VGA_G),
    .vga_blue(VGA_B),
    .vga_hsync(VGA_HS),
    .vga_vsync(VGA_VS),
    .vga_clock(VGA_CLK)
);

endmodule