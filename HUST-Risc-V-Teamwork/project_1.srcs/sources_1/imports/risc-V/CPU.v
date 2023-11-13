// Single-cycle RISC-V CPU
module CPU_RISCV(
    // Inputs and Outputs
    input CLK, // Clock source on the development board (100MHz)
    input Go, // Signal for handling halt
    input RST, // Reset signal
    
    input [1:0] CLK_Sel, Display_Sel, // Clock and display mode selection
    // CLK_Sel: 00-1Hz, 01-10Hz, 10-50Hz, 11-100Hz
    // Display_Sel: 00-LedData, 01-PCData, 10-IRData, 11-Number of cycles
    output [7:0] SEG, // Seven-segment display output
    output [7:0] AN, // Seven-segment display enable
    output halt,// Halt signal
    
    input UP,DOWN,CENTER,LEFT,RIGHT, //interrupt
    output [4:0] it, // interrupt LED
    
    output h_sync,v_sync, //VGA
    output [11:0] vga
    );

    // Necessary Wires
    wire [31:0] PC_in, PC_out, PC_add_4, IR;
    wire CLK_N, PC_en, CLK_1, CLK_2, CLK_3, CLK_4;
    wire [4:0] Funct, OpCode; // Signals to the input hard-wired controller
    wire MemtoReg, MemWrite, ALU_Src, RegWrite, ecall, S_Type, BEQ, BNE, jal, jalr, uret, lui; // Output signals from the hard-wired controller
    wire [3:0] ALUOP; // Operation signals
    wire [4:0] rs1, rs2, rd, R1Adr, R2Adr; // Extracted signals for R1, R2 addresses, and write address (rd)
    wire [31:0] RDin_1, RDin , R1, R2; // RegFile input and output data   RDin 1 add support for lui
    wire [11:0] Imm_I, Imm_S, Imm_B; // Immediate values for I, S, B-type instructions
    wire [19:0] Imm_J; // Immediate value for J-type instruction
    wire [31:0] Imm_I_ex, Imm_S_ex, Imm_B_ex, Imm_J_ex, Imm ,Imm_lui; // Extended immediate values
    wire [1:0] Imm_Sel; // Immediate value selection signal
    wire B_signal, S_signal, J_signal, Jalr_signal; // Instruction signals
    wire [31:0] X, Y; // Inputs to ALU
    wire [31:0] Result1;// ALU calculation results
    wire greater_equal, lesser, equal; // ALU output signals
    wire Branch; // Jump signal
    wire [31:0] MEMout, MEMData; // Data register output and multiplexer output
    wire RDin_Sel; // RDin selection signal
    wire [31:0] Imm_shift, Branch_Adr, PC_Adr; // Immediate left shift result, branch jump address, and the first multiplexer output of PC address
    wire Ledout; // Halt signal and LedData output signal
    wire [31:0] LedData, LED_Show; // Seven-segment display output signals
    wire [3:0] MemSel, Sel1;
    wire [4:0] Sel2;    
    
    // interrupt 
    wire [31:0] next_PC,EPC_out,EPCAddr_in,InterrAddr;
    wire InterrEN,Interr;
    wire uret1,uret2,uret3,uret4,uret5,Interrupt1,Interrupt2,Interrupt3,Interrupt4,Interrupt5;
    
    //VGA
    wire [11:0] vaddr_x;//要显示的像素点的行坐标
    wire [10:0] vaddr_y;//要显示的像素点的列坐标
    wire [11:0] vdata;//要显示的像素点的rgb
    wire clk_vga;
    
    
    // Logic Implementation
    assign PC_en = Go | (~halt); // Generate PC enable signal
    assign PC_add_4 = PC_out + 4; // Generate PC + 4
    // Input signals for the hard-wired controller
    assign Funct = {IR[30], IR[25], IR[14:12]};
    assign OpCode = IR[6:2];
    // Input signals for Reg File
    assign rs1 = IR[19:15];
    assign rs2 = IR[24:20];
    assign rd = IR[11:7];
    // Immediate values for I, S, B, J-type instructions  add support for lui
    assign Imm_I = IR[31:20];
    assign Imm_S = {IR[31:25], IR[11:7]};
    assign Imm_B = {IR[31], IR[7], IR[30:25], IR[11:8]};
    assign Imm_J = {IR[31], IR[19:12], IR[20], IR[30:21]};
    assign Imm_lui = {IR[31:12],12'b000000000000};
    // Generate instruction type signals
    assign B_signal = BEQ || BNE;
    assign S_signal = S_Type;
    assign J_signal = jal;
    assign Jalr_signal = jalr;
    assign Imm_Sel = {~S_signal && (B_signal || J_signal), ~B_signal && (J_signal || S_signal)};
    // Inputs to ALU
    assign X = R1;
    // Branch jump signal
    assign Branch = (BEQ && equal) || (BNE && ~equal);
    // Generate branch jump address
    assign Branch_Adr = PC_out + Imm_shift;
    // Generate halt signal and LedData output signal
    assign halt = ecall && ~(R1 == 32'h00000022);
    assign Ledout = ecall && (R1 == 32'h00000022);
    
    // Instantiate 
    divider #(50000000) divider1(.clk(CLK), .clk_N(CLK_1)); // Generate 1Hz clock signal
    divider #(5000000) divider2(.clk(CLK), .clk_N(CLK_2)); // Generate 10Hz clock signal
    divider #(1000000) divider3(.clk(CLK), .clk_N(CLK_3)); // Generate 50Hz clock signal
    divider #(500000) divider4(.clk(CLK), .clk_N(CLK_4)); // Generate 100Hz clock signal
    mux4 #(1) mux4_2(.out(CLK_N), .in0(CLK_1), .in1(CLK_2), .in2(CLK_3), .in3(CLK_4), .sel(CLK_Sel)); // 4-way multiplexer

    mux4 #(32) mux4_3(.out(LED_Show), .in0(LedData), .in1(PC_out), .in2(IR), .in3(LedData), .sel(Display_Sel)); // 4-way multiplexer

    register #(32) PC(.CLK(CLK_N), .RST(RST), .EN(PC_en), .Din(PC_in), .Dout(PC_out)); // PC register
    ROM IR_register(.Addr(PC_out[11:2]), .Dout(IR)); // Instruction register
    hard_wire_controller controller(.Funct(Funct), .OpCode(OpCode),.IR21(IR[21]),.ALUOP(ALUOP), .MemtoReg(MemtoReg), .MemWrite(MemWrite),
        .ALU_Src(ALU_Src), .RegWrite(RegWrite), .ecall(ecall), .S_Type(S_Type), .BEQ(BEQ), .BNE(BNE),
        .jal(jal), .jalr(jalr),.uret(uret),.lui(lui)); // Hard-wired controller
    mux2 #(5) mux2_1(.out(R1Adr), .in0(rs1), .in1(5'b10001), .sel(ecall)); // 2-way multiplexer 1
    mux2 #(5) mux2_2(.out(R2Adr), .in0(rs2), .in1(5'b01010), .sel(ecall)); // 2-way multiplexer 2
    RegFile Regfile(.Din(RDin), .R1Adr(R1Adr), .R2Adr(R2Adr), .WAdr(rd), .WE(RegWrite), .CLK(CLK_N), .R1(R1), .R2(R2)); // Data register
    extender_sign #(.in_WIDTH(12), .out_WIDTH(32)) ex1(.in(Imm_I), .out(Imm_I_ex)); // Sign extension for Imm_I
    extender_sign #(.in_WIDTH(12), .out_WIDTH(32)) ex2(.in(Imm_S), .out(Imm_S_ex)); // Sign extension for Imm_S
    extender_sign #(.in_WIDTH(12), .out_WIDTH(32)) ex3(.in(Imm_B), .out(Imm_B_ex)); // Sign extension for Imm_B
    extender_sign #(.in_WIDTH(20), .out_WIDTH(32)) ex4(.in(Imm_J), .out(Imm_J_ex)); // Sign extension for Imm_J
    mux4 #(32) mux4_1(.out(Imm), .in0(Imm_I_ex), .in1(Imm_S_ex), .in2(Imm_B_ex), .in3(Imm_J_ex), .sel(Imm_Sel)); // 4-way multiplexer
    mux2 #(32) mux2_3(.out(Y), .in0(R2), .in1(Imm), .sel(ALU_Src)); // 2-way multiplexer 3
    ALU ALU(.x(X), .y(Y), .ALU_op(ALUOP), .ALU_result(Result1), .greater(greater_equal), .less(lesser), .equal(equal)); // ALU
    MEM Mem(.Addr(Result1[11:2]), .Din(R2), .CLK(CLK_N), .MemWrite(MemWrite), .sel(4'b1111), .Dout(MEMout),.vaddr_x(vaddr_x),.vaddr_y(vaddr_y),.vdata(vdata)); // Data memory
    mux2 #(32) mux2_4(.out(MEMData), .in0(Result1), .in1(MEMout), .sel(MemtoReg)); // 2-way multiplexer 4
    mux2 #(32) mux2_5(.out(RDin_1), .in0(MEMData), .in1(PC_add_4), .sel(J_signal || Jalr_signal)); // 2-way multiplexer 5
    mux2 #(32) mux2_6(.out(RDin), .in0(RDin_1), .in1(Imm_lui), .sel(lui)); // 2-way multiplexer 6
    mux2 #(32) mux2_7(.out(PC_Adr), .in0(PC_add_4), .in1(Branch_Adr), .sel(Branch || J_signal)); // 2-way multiplexer 7
    mux2 #(32) mux2_8(.out(next_PC), .in0(PC_Adr), .in1(Result1), .sel(Jalr_signal)); // 2-way multiplexer 8
    mux2 #(32) interrAddr(.out(EPCAddr_in), .in0(next_PC), .in1(InterrAddr), .sel(InterrEN)); //2-way mul for interrupt
    mux2 #(32) EPCAddr(.out(PC_in), .in0(EPCAddr_in), .in1(EPC_out), .sel(uret));    //2-way mul for epc interrupt
    log_shifter_left #(.data_WIDTH(32), .shift_WIDTH(5)) shifter(.in(Imm), .out(Imm_shift), .shiftAmount(5'b00001)); // Logical left shift
    register #(32) LED(.CLK(CLK_N), .RST(RST), .EN(Ledout), .Din(R2), .Dout(LedData)); // LedData register
    FPGADigit FPGADigit(.LedData(LED_Show), .CLK(CLK), .SEG(SEG), .AN(AN),.RST(RST)); // Seven-segment display controller
    
    //interrupt
    Interrupter Interrupter1(.CLK(CLK_N),.IR(UP),.uret(uret1),.interrupt(Interrupt1),.LED(it[0]));
    Interrupter Interrupter2(.CLK(CLK_N),.IR(LEFT),.uret(uret2),.interrupt(Interrupt2),.LED(it[1]));
    Interrupter Interrupter3(.CLK(CLK_N),.IR(CENTER),.uret(uret3),.interrupt(Interrupt3),.LED(it[2]));
    Interrupter Interrupter4(.CLK(CLK_N),.IR(RIGHT),.uret(uret4),.interrupt(Interrupt4),.LED(it[3]));
    Interrupter Interrupter5(.CLK(CLK_N),.IR(DOWN),.uret(uret5),.interrupt(Interrupt5),.LED(it[4]));
    
    EPC epc(.EN(InterrEN),.Din(next_PC),.Dout(EPC_out));
    
    Scheduler scheduler(.IRR1(Interrupt1),.IRR2(Interrupt2),.IRR3(Interrupt3),.IRR4(Interrupt4),.IRR5(Interrupt5),
    .uret1(uret1),.uret2(uret2),.uret3(uret3),.uret4(uret4),.uret5(uret5),
    .interr(Interr),.uret(uret),.interrEN(InterrEN),.CLK(CLK_N),.interrAddr(InterrAddr));
    
    InterrEn interren(.uret(uret),.CLK(CLK_N),.interr(Interr),.interrEN(InterrEN));

    //VGA
    clk_wiz_0 clk_wiz (.clk_in1(CLK),.clk_out1(clk_vga));
    vga_display vga_display(
            .clk(clk_vga),
            .vdata(vdata),//要显示的像素点的rgb
            .vaddr_x(vaddr_x),
            .vaddr_y(vaddr_y),
            .h_sync(h_sync),
            .v_sync(v_sync),
            .vga(vga)
        );
endmodule

