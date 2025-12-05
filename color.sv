 module vga_monitor(
    // --- VGA Control ---
    input  logic        clock,             // 50 MHz clock
    input  logic        reset,             // reset signal

    // --- Pipeline Stage Inputs ---

    // IF Stage
    input  logic [31:0] if_pc,
    input  logic [31:0] if_instr,

    // ID Stage
    input  logic [31:0] id_pc,
    input  logic [31:0] id_instr,
    input  logic [31:0] id_reg1,
    input  logic [31:0] id_reg2,
    input  logic [31:0] id_imm,

    // EX Stage
    input  logic [31:0] ex_pc,
    input  logic [31:0] ex_alu_result,
    input  logic [2:0]  ex_brOp,
    input  logic        ex_taken,

    // MEM Stage
    input  logic [31:0] mem_pc,
    input  logic [31:0] mem_data_read,
    input  logic        mem_memWrite,

    // WB Stage
    input  logic [31:0] wb_pc,
    input  logic [31:0] wb_data,
    input  logic [4:0]  wb_rd_addr,
    input  logic        wb_regWrite,
    input  logic        ebreak_s,

    // --- Pipeline-Specific Debug Inputs ---
    input  logic        hazard_stall, // 0 = STALL, 1 = NO STALL
    input  logic [1:0]  forward_a,
    input  logic [1:0]  forward_b,

    // --- Memory Debug Inputs ---
    input  logic [7:0]  mem [0:127],
    input  logic [31:0] regs_debug [31:0],

    // --- Instruction Memory Debug Interface ---
    output logic [6:0]  inst_mem_debug_addr,
    input  logic [31:0] inst_mem_debug_data,

    // --- VGA Outputs ---
    output logic [7:0]  vga_red,
    output logic [7:0]  vga_green,
    output logic [7:0]  vga_blue,
    output logic        vga_hsync,
    output logic        vga_vsync,
    output logic        vga_clock
);

    // --- Internal VGA Signals ---
    wire [10:0] x;
    wire [9:0]  y;
    wire        videoOn, vgaclk, pixel_on;
    wire [7:0]  current_ascii;
    wire [3:0]  row_in_char;
    wire [2:0]  col_in_char;

    // --- VGA Sub-module Instantiations ---
    clock1280x800 vgaclock(.clock50(clock), .reset(reset), .vgaclk(vgaclk));
    assign vga_clock = vgaclk;

    vga_controller_1280x800 ctrl(
        .clk(vgaclk),
        .reset(reset),
        .video_on(videoOn),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .hcount(x),
        .vcount(y)
    );

    font_renderer font_inst (
        .clk(vgaclk),
        .ascii_code(current_ascii),
        .row_in_char(row_in_char),
        .col_in_char(col_in_char),
        .pixel_on(pixel_on)
    );

    // --- Display Configuration ---
    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    localparam CHARS_PER_LINE = 20;
    localparam LINES_PER_COL = 40;
    localparam LINE_SPACING = 20;
    localparam TEXT_START_X_COL0 = 240;
    localparam TEXT_START_X_COL1 = 420;
    localparam TEXT_START_X_COL2 = 600;
    localparam TEXT_START_X_COL3 = 780;
    localparam TEXT_START_Y = 40;

    // --- Text Buffer Memory ---
    reg [7:0] text [0:LINES_PER_COL-1][0:CHARS_PER_LINE-1];
    reg [7:0] text2[0:LINES_PER_COL-1][0:CHARS_PER_LINE-1];
    reg [7:0] text3[0:LINES_PER_COL-1][0:CHARS_PER_LINE-1];
    reg [7:0] text4[0:LINES_PER_COL-1][0:CHARS_PER_LINE-1];

    // --- Helper Function ---
    function [7:0] num_to_ascii;
        input [3:0] n;
        num_to_ascii = (n < 10) ? (8'd48 + n) : (8'd65 + n - 10);
    endfunction

    // --- Instruction Memory Display Logic ---
    reg [4:0] imem_display_addr = 0;
    reg [4:0] addr_to_display = 0;
    assign inst_mem_debug_addr = {2'b00, imem_display_addr};

    // --- Screen Content Generation Logic ---
    // This block populates the text buffers with data from the pipeline stages.
    always @(posedge vgaclk) begin
        integer i, base;
        byte b0, b1, b2, b3;
        logic [31:0] imem_word;


        // fetch
        text[0][0]="F"; text[0][2]="E"; text[0][3]="T"; text[0][5]="C"; text[0][6]="H"; text[0][7]=":";
        text[1][0]="P"; text[1][1]="C"; text[1][2]=":";
        text[1][4]=num_to_ascii(if_pc[15:12]); text[1][5]=num_to_ascii(if_pc[11:8]); text[1][6]=num_to_ascii(if_pc[7:4]); text[1][7]=num_to_ascii(if_pc[3:0]);
        text[2][0]="I"; text[2][1]="N"; text[2][2]=":";
        text[2][4]=num_to_ascii(if_instr[31:28]); text[2][5]=num_to_ascii(if_instr[27:24]); text[2][6]=num_to_ascii(if_instr[23:20]); text[2][7]=num_to_ascii(if_instr[19:16]); text[2][8]="_";
        text[2][9]=num_to_ascii(if_instr[15:12]); text[2][10]=num_to_ascii(if_instr[11:8]); text[2][11]=num_to_ascii(if_instr[7:4]); text[2][12]=num_to_ascii(if_instr[3:0]);

        // Instruction decode
        text[4][0]="="; text[4][2]="I"; text[4][3]="D"; text[4][5]="S"; text[4][6]="T"; text[4][7]="G"; text[4][9]="=";
        text[5][0]="P"; text[5][1]="C"; text[5][2]=":"; text[5][4]=num_to_ascii(id_pc[7:4]); text[5][5]=num_to_ascii(id_pc[3:0]);
        text[6][0]="R"; text[6][1]="1"; text[6][2]=":"; text[6][4]=num_to_ascii(id_reg1[7:4]); text[6][5]=num_to_ascii(id_reg1[3:0]);
        text[6][7]="R"; text[6][8]="2"; text[6][9]=":"; text[6][11]=num_to_ascii(id_reg2[7:4]); text[6][12]=num_to_ascii(id_reg2[3:0]);

        // Show STALL or IMM value
        if (hazard_stall == 0) begin
           text[7][0]=" "; text[7][1]=" "; text[7][2]="*"; text[7][3]="*"; text[7][4]="S"; text[7][5]="T"; text[7][6]="A"; text[7][7]="L"; text[7][8]="L"; text[7][9]="*"; text[7][10]="*";
        end else begin
           text[7][0]="I"; text[7][1]="M"; text[7][2]=":";
           text[7][4]=num_to_ascii(id_imm[15:12]); text[7][5]=num_to_ascii(id_imm[11:8]);
           text[7][6]=num_to_ascii(id_imm[7:4]);   text[7][7]=num_to_ascii(id_imm[3:0]);
        end

        // --- EX Stage ---
        text[9][0]="="; text[9][2]="E"; text[9][3]="X"; text[9][5]="S"; text[9][6]="T"; text[9][7]="G"; text[9][9]="=";
        text[10][0]="P"; text[10][1]="C"; text[10][2]=":"; text[10][4]=num_to_ascii(ex_pc[7:4]); text[10][5]=num_to_ascii(ex_pc[3:0]);
        text[11][0]="A"; text[11][1]="L"; text[11][2]="U"; text[11][3]=":";
        text[11][5]=num_to_ascii(ex_alu_result[31:28]); text[11][6]=num_to_ascii(ex_alu_result[27:24]);
        text[11][7]=num_to_ascii(ex_alu_result[23:20]); text[11][8]=num_to_ascii(ex_alu_result[19:16]); text[11][9]="_";
        text[11][10]=num_to_ascii(ex_alu_result[15:12]); text[11][11]=num_to_ascii(ex_alu_result[11:8]);
        text[11][12]=num_to_ascii(ex_alu_result[7:4]);   text[11][13]=num_to_ascii(ex_alu_result[3:0]);

        // Forwarding info
        text[13][0]="F"; text[13][1]="A"; text[13][2]=":"; text[13][3]=num_to_ascii({2'b00, forward_a});
        text[13][5]="F"; text[13][6]="B"; text[13][7]=":"; text[13][8]=num_to_ascii({2'b00, forward_b});

        // --- MEM Stage ---
        text[14][0]="="; text[14][2]="M"; text[14][3]="E"; text[14][4]="M"; text[14][6]="S"; text[14][7]="T"; text[14][9]="=";
        text[15][0]="P"; text[15][1]="C"; text[15][2]=":"; text[15][4]=num_to_ascii(mem_pc[7:4]); text[15][5]=num_to_ascii(mem_pc[3:0]);
        text[16][0]="R"; text[16][1]="D"; text[16][2]=":"; text[16][4]=num_to_ascii(mem_data_read[7:4]); text[16][5]=num_to_ascii(mem_data_read[3:0]);
        text[16][7]="W"; text[16][8]="R"; text[16][9]=":"; text[16][10]=num_to_ascii({3'b000, mem_memWrite});

        // --- WB Stage ---
        text[18][0]="="; text[18][2]="W"; text[18][3]="B"; text[18][5]="S"; text[18][6]="T"; text[18][7]="G"; text[18][9]="=";
        text[19][0]="P"; text[19][1]="C"; text[19][2]=":"; text[19][4]=num_to_ascii(wb_pc[7:4]); text[19][5]=num_to_ascii(wb_pc[3:0]);
        text[20][0]="D"; text[20][1]="A"; text[20][2]="T"; text[20][3]=":";
        text[20][5]=num_to_ascii(wb_data[31:28]); text[20][6]=num_to_ascii(wb_data[27:24]); text[20][7]=num_to_ascii(wb_data[23:20]); text[20][8]=num_to_ascii(wb_data[19:16]); text[20][9]="_";
        text[20][10]=num_to_ascii(wb_data[15:12]); text[20][11]=num_to_ascii(wb_data[11:8]); text[20][12]=num_to_ascii(wb_data[7:4]); text[20][13]=num_to_ascii(wb_data[3:0]);
        text[21][0]="R"; text[21][1]="D"; text[21][2]=":"; text[21][4]="x"; text[21][5]=num_to_ascii({3'b000, wb_rd_addr[4]}); text[21][6]=num_to_ascii(wb_rd_addr[3:0]);
        text[23][0]="H"; text[23][1]="A"; text[23][2]="L"; text[23][3]="T"; text[23][4]=":"; text[23][6]=num_to_ascii({3'b000, ebreak_s});

        // =========================================================
        // COLUMN 1: DATA MEMORY
        // =========================================================
        text2[0][0]="D"; text2[0][1]="M"; text2[0][2]="E"; text2[0][3]="M";
        for(i=0; i<16; i++) begin
            base = i*4; b0=mem[base]; b1=mem[base+1]; b2=mem[base+2]; b3=mem[base+3];
            text2[i+1][0]=num_to_ascii(base[7:4]); text2[i+1][1]=num_to_ascii(base[3:0]); text2[i+1][2]=":"; text2[i+1][3]=" ";
            text2[i+1][4]=num_to_ascii(b3[7:4]); text2[i+1][5]=num_to_ascii(b3[3:0]);
            text2[i+1][6]=num_to_ascii(b2[7:4]); text2[i+1][7]=num_to_ascii(b2[3:0]);
            text2[i+1][8]=num_to_ascii(b1[7:4]); text2[i+1][9]=num_to_ascii(b1[3:0]);
            text2[i+1][10]=num_to_ascii(b0[7:4]); text2[i+1][11]=num_to_ascii(b0[3:0]);
        end

        // =========================================================
        // COLUMN 2: REGISTER FILE
        // =========================================================
        text3[0][0]="R"; text3[0][1]="E"; text3[0][2]="G"; text3[0][3]="S";
        for(i=0; i<32; i++) begin
            text3[i+1][0]="x"; text3[i+1][1]=num_to_ascii(i[4:4]); text3[i+1][2]=num_to_ascii(i[3:0]); text3[i+1][3]=":"; text3[i+1][4]=" ";
            text3[i+1][5]=num_to_ascii(regs_debug[i][31:28]); text3[i+1][6]=num_to_ascii(regs_debug[i][27:24]);
            text3[i+1][7]=num_to_ascii(regs_debug[i][23:20]); text3[i+1][8]=num_to_ascii(regs_debug[i][19:16]); text3[i+1][9]="_";
            text3[i+1][10]=num_to_ascii(regs_debug[i][15:12]); text3[i+1][11]=num_to_ascii(regs_debug[i][11:8]);
            text3[i+1][12]=num_to_ascii(regs_debug[i][7:4]); text3[i+1][13]=num_to_ascii(regs_debug[i][3:0]);
        end

        // =========================================================
        // COLUMN 3: INSTRUCTION MEMORY
        // =========================================================
        text4[0][0]="I"; text4[0][1]="M"; text4[0][2]="E"; text4[0][3]="M";
        imem_word = inst_mem_debug_data; // Get data from the debug port
        base = addr_to_display * 4;      // Address calculated in the previous cycle

        text4[addr_to_display+1][0]="0"; text4[addr_to_display+1][1]="x";
        text4[addr_to_display+1][2]=num_to_ascii(base[7:4]); text4[addr_to_display+1][3]=num_to_ascii(base[3:0]);
        text4[addr_to_display+1][4]=":"; text4[addr_to_display+1][5]=" ";
        text4[addr_to_display+1][6]=num_to_ascii(imem_word[31:28]); text4[addr_to_display+1][7]=num_to_ascii(imem_word[27:24]);
        text4[addr_to_display+1][8]=num_to_ascii(imem_word[23:20]); text4[addr_to_display+1][9]=num_to_ascii(imem_word[19:16]); text4[addr_to_display+1][10]="_";
        text4[addr_to_display+1][11]=num_to_ascii(imem_word[15:12]); text4[addr_to_display+1][12]=num_to_ascii(imem_word[11:8]);
        text4[addr_to_display+1][13]=num_to_ascii(imem_word[7:4]); text4[addr_to_display+1][14]=num_to_ascii(imem_word[3:0]);

        // Cycle through instruction memory addresses for display
        addr_to_display <= imem_display_addr;
        if(imem_display_addr == 31) imem_display_addr <= 0;
        else imem_display_addr <= imem_display_addr + 1;
    end

    // --- Pixel Rendering Logic ---
    // Wires to determine which character to display
    wire [6:0] char_col_idx = inside_text_col0 ? (x-TEXT_START_X_COL0)/CHAR_W : inside_text_col1 ? (x-TEXT_START_X_COL1)/CHAR_W : inside_text_col2 ? (x-TEXT_START_X_COL2)/CHAR_W : (x-TEXT_START_X_COL3)/CHAR_W;
    wire [5:0] line_num_idx = (y-TEXT_START_Y)/LINE_SPACING;
    wire inside_text_col0 = (x>=TEXT_START_X_COL0 && x<TEXT_START_X_COL0+CHARS_PER_LINE*CHAR_W && y>=TEXT_START_Y && y<TEXT_START_Y+LINES_PER_COL*LINE_SPACING);
    wire inside_text_col1 = (x>=TEXT_START_X_COL1 && x<TEXT_START_X_COL1+CHARS_PER_LINE*CHAR_W && y>=TEXT_START_Y && y<TEXT_START_Y+LINES_PER_COL*LINE_SPACING);
    wire inside_text_col2 = (x>=TEXT_START_X_COL2 && x<TEXT_START_X_COL2+CHARS_PER_LINE*CHAR_W && y>=TEXT_START_Y && y<TEXT_START_Y+LINES_PER_COL*LINE_SPACING);
    wire inside_text_col3 = (x>=TEXT_START_X_COL3 && x<TEXT_START_X_COL3+CHARS_PER_LINE*CHAR_W && y>=TEXT_START_Y && y<TEXT_START_Y+LINES_PER_COL*LINE_SPACING);
    wire inside_any_text = inside_text_col0 || inside_text_col1 || inside_text_col2 || inside_text_col3;
assign current_ascii = inside_text_col0 ? text[line_num_idx][char_col_idx] : 
                      inside_text_col1 ? text2[line_num_idx][char_col_idx] : 
                      inside_text_col2 ? text3[line_num_idx][char_col_idx] : 
                      inside_text_col3 ? text4[line_num_idx][char_col_idx] : 
                      8'd32;
    assign row_in_char = (y-TEXT_START_Y-line_num_idx*LINE_SPACING)%CHAR_H;
    assign col_in_char = inside_text_col0 ? ((x-TEXT_START_X_COL0)%CHAR_W) : inside_text_col1 ? ((x-TEXT_START_X_COL1)%CHAR_W) : inside_text_col2 ? ((x-TEXT_START_X_COL2)%CHAR_W) : ((x-TEXT_START_X_COL3)%CHAR_W);
    wire line_is_valid = (line_num_idx <= 32);
    wire [4:0] y_in_line = (y-TEXT_START_Y)%LINE_SPACING;
    wire is_in_text_gap = (y_in_line >= CHAR_H);

    // Combinational block to set pixel color
    always @(*) begin
        if (~videoOn) {vga_red,vga_green,vga_blue} = 24'h000000; // Black outside visible area
        else if (~line_is_valid || is_in_text_gap) {vga_red,vga_green,vga_blue} = 24'h001020; // dark blue
        else if (inside_any_text && pixel_on) {vga_red,vga_green,vga_blue} = 24'h913E61; // magenta
        else {vga_red,vga_green,vga_blue} = 24'h001020; // dark blue
    end

endmodule

// ============================================================
// Included Sub-modules (identical in both original files)
// ============================================================

module clock1280x800(clock50, reset, vgaclk);
    input  clock50;
    input  reset;
    output vgaclk;

    vgaClock clk(
        .ref_clk_clk(clock50),
        .ref_reset_reset(reset),        // Correct: Connect main reset to the PLL's reset input
        // .reset_source_reset(reset), // REMOVE THIS LINE
        .vga_clk_clk(vgaclk)
    );
endmodule

module vga_controller_1280x800 (
    input  clk,
    input  reset,
    output wire hsync,
    output wire vsync,
    output reg [10:0] hcount,
    output reg [9:0]  vcount,
    output video_on
);

    parameter H_VISIBLE = 1280;
    parameter H_FP      = 48;
    parameter H_SYNC    = 32;
    parameter H_BP      = 80;
    parameter H_TOTAL   = H_VISIBLE + H_FP + H_SYNC + H_BP;

    parameter V_VISIBLE = 800;
    parameter V_FP      = 3;
    parameter V_SYNC    = 6;
    parameter V_BP      = 22;
    parameter V_TOTAL   = V_VISIBLE + V_FP + V_SYNC + V_BP;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hcount <= 0;
            vcount <= 0;
        end else begin
            if (hcount == H_TOTAL - 1) begin
                hcount <= 0;
                if (vcount == V_TOTAL - 1)
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
            end else begin
                hcount <= hcount + 1;
            end
        end
    end

    assign hsync = (hcount >= H_VISIBLE + H_FP) && (hcount < H_VISIBLE + H_FP + H_SYNC);
    assign vsync = (vcount >= V_VISIBLE + V_FP) && (vcount < V_VISIBLE + V_FP + V_SYNC);
    assign video_on = (hcount < H_VISIBLE) && (vcount < V_VISIBLE);
endmodule