`timescale 1ns / 1ps
module ALU(
    input[31:0] x,y,
    input[3:0] ALU_op,
    output [31:0] ALU_result,
    output equal,
    output greater,less
    );
assign equal=(x==y);
assign less=((ALU_result==1)&((ALU_op==4'b1011)|(ALU_op==4'b1100)))?1:0;
assign greater=~less;
assign ALU_result = (ALU_op == 4'b0000)? x<<y[4:0]:
                    (ALU_op == 4'b0001)? $signed($signed(x)>>>y[4:0]):
                    (ALU_op == 4'b0010)? x>>y[4:0]:
                    (ALU_op == 4'b0011)? x*y[31:0]:
                    (ALU_op == 4'b0100)? x/y:
                    (ALU_op == 4'b0101)? x+y:
                    (ALU_op == 4'b0110)? x-y:
                    (ALU_op == 4'b0111)? x&y:
                    (ALU_op == 4'b1000)? x|y:
                    (ALU_op == 4'b1001)? x^y:
                    (ALU_op == 4'b1010)? ~(x|y):
                    (ALU_op == 4'b1011)? ($signed(x)<$signed(y))?1:0:
                    (ALU_op == 4'b1100)? ((x<y)?1:0):
                    32'b0;
endmodule
