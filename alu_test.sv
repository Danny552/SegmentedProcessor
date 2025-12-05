module top_alu_test (
    input  logic        clk,       // si lo quieres usar
    input  logic [9:0]  sw,        // switches de la FPGA
    output logic [9:0]  leds,      // LEDs de la FPGA
    output logic [6:0]  display0,  // displays
    output logic [6:0]  display1
);

    // Entradas de la ALU
    logic [3:0] alu_op;     // operación de la ALU (ej: 0000=add, 0001=sub, etc.)
    logic [31:0] a, b;
    logic [31:0] result;

    // Mapear switches a entradas
    assign alu_op = sw[3:0];      // switches 0-3 = código de operación
    assign a      = {28'b0, sw[7:4]}; // switches 4-7 = operando A (4 bits)
    assign b      = {28'b0, sw[9:8], 2'b0}; // switches 8-9 = parte de operando B

    // Instanciar ALU
    alu alu_inst (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result)
    );

    // Mostrar resultado en LEDs
    assign leds = result[9:0]; // los 10 bits menos significativos

    // Mostrar el resultado en displays hex
    hex7seg disp0 (.val(result[3:0]),  .display(display0));
    hex7seg disp1 (.val(result[7:4]),  .display(display1));

endmodule
