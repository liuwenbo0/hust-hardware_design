module DFlipFlop(
    input CLK,   // Clock signal
    input RST,   // Reset signal
    input d,       // Data input signal
    output reg q        // Output signal
);

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            // Clear the output signal to zero when the reset signal is high
            q <= 1'b0;
        end 
        else begin
            // On the rising edge, pass the data input signal (d) to the output signal (q)
            q <= d;
        end
    end
endmodule

module Interrupter(
    input CLK,IR,uret,
    output interrupt,LED
);
    wire D1out,D2in;
    
    assign LED = interrupt | D1out;
    assign D2in = (~uret) & ( D1out | interrupt);
    
    DFlipFlop D1(.CLK(IR),.RST(interrupt),.d(1'b1),.q(D1out));
    DFlipFlop D2(.CLK(CLK),.RST(1'b0),.d(D2in),.q(interrupt)); 
endmodule

module PriorityEncoder(
    input [4:0] inputs,    // Five-bit input signals
    output [2:0] encoded,   // Priority-encoded output
    output interr
);
    // Use priority encoding logic
    assign encoded =(inputs[4] == 1) ? 3'b100 :
                    (inputs[3] == 1) ? 3'b011 :
                    (inputs[2] == 1) ? 3'b010 :
                    (inputs[1] == 1) ? 3'b001 :
                    (inputs[0] == 1) ? 3'b000 :
                    3'b111; // Default
    assign interr = ~(inputs == 5'b00000);
endmodule


module Scheduler(IRR1,IRR2,IRR3,IRR4,IRR5,interr,uret1,uret2,uret3,uret4,uret5,uret,interrEN,CLK,interrAddr);
    input IRR1,IRR2,IRR3,IRR4,IRR5;
    input interrEN,CLK,uret;
    output interr;
    output uret1,uret2,uret3,uret4,uret5;
    output [31:0]interrAddr;
    wire [2:0]choice,uret_choice;
    wire [4:0]urettmp;    

    PriorityEncoder P(.inputs({IRR5,IRR4,IRR3,IRR2,IRR1}),.interr(interr),.encoded(choice));
    //Interrupt handler Address
    mux8 mux(.out(interrAddr), .in0(32'h0288),.in1(32'h0190),.in2(32'h0004),.in3(32'h01e0),.in4(32'h22c),.in5(32'h0),.in6(32'h0),.in7(32'h0),.sel(choice));
    register #(3) retReg(.CLK(CLK),.EN(interrEN),.Din(choice),.Dout(uret_choice),.RST(0));
    
    assign urettmp = (uret_choice == 3'b000) ? 5'b00001:
                     (uret_choice == 3'b001) ? 5'b00010:
                     (uret_choice == 3'b010) ? 5'b00100:
                     (uret_choice == 3'b011) ? 5'b01000:
                     (uret_choice == 3'b100) ? 5'b10000:
                     5'b00000;  //defualt
    assign uret1 = urettmp[0]&uret;
    assign uret2 = urettmp[1]&uret;
    assign uret3 = urettmp[2]&uret;
    assign uret4 = urettmp[3]&uret;
    assign uret5 = urettmp[4]&uret;
    
endmodule

module InterrEn(uret,CLK,interr,interrEN);
 input CLK,uret,interr;
 output interrEN;
 wire Din,Dout,EN;
 
 assign interrEN = (~Dout) & interr;
 assign Din = interrEN;
 assign EN = uret || interrEN;
 
 register #(1) IE(.CLK(CLK),.EN(EN),.Din(Din),.Dout(Dout),.RST(0));
endmodule 

module EPC(EN,Din,Dout);
    input EN;
    input [31:0] Din;
    output [31:0] Dout;
    reg [31:0] ram;         // Register
    initial ram = 0;         // Initialize the register to 0

    always @(posedge EN) begin
            ram <= Din;        // If enable signal is active, set register value to the input data
        end
    assign Dout = ram;     
endmodule