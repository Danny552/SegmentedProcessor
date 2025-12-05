module mux2_1( //for selecting alu source
	input logic[31:0] x,y,
	input logic select,
	output logic[31:0] r
);

assign r = select? y:x;

endmodule