//transform LedData to display , SEG is the display , AN is the select
module FPGADigit(LedData,CLK,SEG,AN,RST);
    input CLK;//origin clk
    input [31:0] LedData;//LedData 
    input RST;
    output [7:0] SEG;//display
    output [7:0] AN;//select
    
    wire CLK_N;//new clk
    wire [3:0] Led;//display data
    wire [2:0] count;//clk count
   
    //use 
    divider #(5000) div(.clk(CLK),.clk_N(CLK_N));//new clk
    
    counter cot(.clk(CLK_N),.out(count),.halt(1'b0),.RST(RST));//clk counter , T=8

    decoder3_8 decoder(.num(count),.sel(AN));//select one digital pipe

    display_sel sel(.num(count), .dig(LedData), .code(Led));//  LedData sel

    pattern SEG7_0(.code(Led),.patt(SEG));
endmodule

module divider (clk, clk_N); //clk divider
    input           clk;
    output reg      clk_N;
    parameter      N = 50_000_000;
    reg [31:0]      counter;
        initial begin;
            counter <= 32'h0;
            clk_N <= 1'b0;
        end
    always @(posedge clk)  begin
        if(counter>=N) begin
            clk_N <= ~clk_N;
            counter <= 32'h0;
        end
        else
            counter <= counter + 1;
    end
endmodule

module counter(clk, out,halt,RST);
	input clk,halt,RST;                    
	output reg [2:0] out;             
    initial out=0;
	always @(posedge clk)  begin
	    if(RST) out<=0;
        else if(out<3'b111) 
           begin
            if(~halt)  out<=out+1'b1;
           end
        else 
           begin
            out<=0;
           end
	end                           
endmodule

module decoder3_8(num, sel);//3-8 decoder , generate sel , high electric level active
	input [2: 0] num;       
	output reg [7:0] sel;
    always@(num) begin
        case (num[2:0])
		3'b000:sel=~8'b00000001;
		3'b001:sel=~8'b00000010;
		3'b010:sel=~8'b00000100;
		3'b011:sel=~8'b00001000;
		3'b100:sel=~8'b00010000;
		3'b101:sel=~8'b00100000;
		3'b110:sel=~8'b01000000;
		3'b111:sel=~8'b10000000;
        endcase
	end                    
endmodule

module display_sel(num, dig, code);
    input   [2: 0]    num;
    input   [31:0]    dig;
    output reg [3:0]  code;
    always @* begin
        case(num)
            3'd0: code = dig[3:0];
            3'd1: code = dig[7:4];
            3'd2: code = dig[11:8];
            3'd3: code = dig[15:12];
            3'd4: code = dig[19:16];
            3'd5: code = dig[23:20];
            3'd6: code = dig[27:24];
            3'd7: code = dig[31:28];
            default: code = 4'h0;
        endcase
    end
endmodule

module pattern(code, patt);//binary to display
	input [3: 0] code;       
	output reg [7:0] patt;      
    always@(code) begin
        case (code[3:0])
	        4'b0000:patt=8'b11000000;
            4'b0001:patt=8'b11111001;
            4'b0010:patt=8'b10100100;
            4'b0011:patt=8'b10110000;
            4'b0100:patt=8'b10011001;
            4'b0101:patt=8'b10010010;
            4'b0110:patt=8'b10000010;
            4'b0111:patt=8'b11111000;
            4'b1000:patt=8'b10000000;
            4'b1001:patt=8'b10011000;
            4'b1010:patt=8'b10001000;
            4'b1011:patt=8'b10000011;
            4'b1100:patt=8'b11000110;
            4'b1101:patt=8'b10100001;
            4'b1110:patt=8'b10000110;
            4'b1111:patt=8'b10001110;
        endcase
	end                       
endmodule