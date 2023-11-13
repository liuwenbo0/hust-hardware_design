module MEM(Addr, Din, CLK, MemWrite, sel, Dout, vaddr_x, vaddr_y, vdata);
    input [9:0] Addr;       // Address input
    input [31:0] Din;       // Data input
    input CLK, MemWrite;    // Clock signal and write enable
    input [3:0] sel;        // Data select signal
    input [11:0] vaddr_x;
    input [10:0] vaddr_y;
    output [31:0] Dout;     // Data output
    output [11:0] vdata;
    reg [31:0] RAM[2**20-1:0]; // Storage registers, size is 2^20

    always @(posedge CLK) begin
        if (MemWrite) begin
            if (sel == 4'b1111)
                RAM[Addr] <= Din;            // Perform full data write
            else if (sel == 4'b0001)
                RAM[Addr][7:0] <= Din[7:0];  // Write low-byte data
            else if (sel == 4'b0010)
                RAM[Addr][15:8] <= Din[15:8]; // Write second low-byte data
            else if (sel == 4'b0100)
                RAM[Addr][23:16] <= Din[23:16]; // Write second high-byte data
            else if (sel == 4'b1000)
                RAM[Addr][31:24] <= Din[31:24]; // Write high-byte data
        end
    end
    //addr_x/24 addr_y/24
    assign Dout = RAM[Addr]; // Data output is the stored value at the spec ified address
    assign vdata = (vaddr_x >= 11'h300)? 12'hf00 :
                   (RAM[vaddr_y/24][31-(vaddr_x/24)])? 12'haaa : 12'h000;
endmodule

module RegFile(Din, R1Adr, R2Adr, WAdr, WE, CLK, R1, R2);
    input [31:0] Din;       // Data input
    input [4:0] WAdr, R1Adr, R2Adr; // Write address, R1 address, and R2 address
    input WE, CLK;          // Write enable and clock signal
    output [31:0] R1, R2;   // R1 and R2 outputs
    reg [31:0] RAM[31:0];   // Register file, size is 32 registers

    integer i;
    initial begin
        for (i = 0; i <= 31; i = i + 1) begin
            RAM[i] = 0; // Initialize all registers to 0
        end
    end

    assign R1 = RAM[R1Adr]; // R1 output is the value at the specified address
    assign R2 = RAM[R2Adr]; // R2 output is the value at the specified address

    always @(posedge CLK) begin
        if (WE && WAdr != 0)
            RAM[WAdr] <= Din; // Perform data write (if address is not 0 and write enable is active)
    end
endmodule

module register(CLK, RST, EN, Din, Dout);
    parameter WIDTH = 32;   // Register width, default is 32 bits
    input CLK, RST, EN;     // Clock, reset, and enable signals
    input [WIDTH-1:0] Din;  // Data input
    output [WIDTH-1:0] Dout; // Data output
    reg [31:0] ram;         // Register

    initial ram = 0;         // Initialize the register to 0

    always @(posedge CLK) begin
        if (RST)
            ram <= 0;        // If reset signal is active, set register value to 0
        else if (EN)
            ram <= Din;       // If enable signal is active, set register value to the input data
        else
            ram = ram;        // Otherwise, keep the register value unchanged
    end

    assign Dout = ram;        // Data output is the register value
endmodule

module ROM(Addr, Dout);
    input [9:0] Addr;          // Address input
    output [31:0] Dout;    // Data output
    reg [31:0] rom[1023:0];   // Read-only memory, size is 1024 32-bit data
    initial begin
        $readmemh("C:\\Users\\Miles\\Desktop\\HUST-Risc-V-Teamwork\\main.txt", rom);    // Read initialization data from a file to fill the read-only memory
    end    
    assign Dout = rom[Addr];
endmodule