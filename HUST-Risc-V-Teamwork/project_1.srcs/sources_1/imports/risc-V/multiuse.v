//4
module mux4(out, in0, in1, in2, in3, sel);
	parameter WIDTH = 32;
	output reg [WIDTH-1:0] out;
    input [WIDTH-1:0] in0, in1,in2,in3;
	input[1:0] sel;
    always @ (in0,in1,in2,in3,sel) begin
		case(sel)
			2'b00: out=in0;
			2'b01: out=in1;
			2'b10: out=in2;
			2'b11: out=in3;
		endcase
	end
endmodule

//2
module mux2(out, in0, in1, sel) ;
	parameter WIDTH = 32;
	output [WIDTH-1:0] out;
    input [WIDTH-1:0] in0, in1;
	input sel;
	assign out = sel == 0?in0:in1 ;
endmodule

//8
module mux8(out, in0,in1,in2,in3,in4,in5,in6,in7,sel) ;
	parameter WIDTH = 32;
	output reg [WIDTH-1:0] out;
    input [WIDTH-1:0] in0,in1,in2,in3,in4,in5,in6,in7;
	input [2:0]sel;
	 always @ (in0,in1,in2,in3,in4,in5,in6,in7,sel) begin
		case(sel)
			3'b000: out=in0;
			3'b001: out=in1;
			3'b010: out=in2;
			3'b011: out=in3;
			3'b100: out=in4;
			3'b101: out=in5;
			3'b110: out=in6;
			3'b111: out=in7;
		endcase
	end
endmodule