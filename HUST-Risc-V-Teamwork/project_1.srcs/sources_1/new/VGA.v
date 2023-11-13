`timescale 1ns / 1ps

module vga_display (
           input clk ,  //65MHz 
           input [11: 0] vdata ,
           
           output [11:0] vaddr_x,
           output [10:0] vaddr_y,
           
           output reg h_sync, v_sync,
           output reg [11:0] vga  
       );

localparam h_active_pixels = 1024 ;
localparam h_front_porch = 24 ;
localparam h_sync_width = 136 ;
localparam h_back_porch = 160 ;
localparam h_total_piexls = (h_active_pixels + h_front_porch + h_back_porch + h_sync_width);

localparam v_active_pixels = 768 ;
localparam v_front_porch = 3 ;
localparam v_sync_width = 6 ;
localparam v_back_porch = 29 ;
localparam v_total_piexls = (v_active_pixels + v_front_porch + v_back_porch + v_sync_width);

reg [11: 0] x_counter;
reg [10: 0] y_counter;

initial begin
    x_counter=0;
    y_counter=0;
end

always @(posedge clk)

    if (x_counter == h_total_piexls-1)
        x_counter <= 0;
    else
        x_counter <= x_counter + 1;

always @(posedge clk)
    if (x_counter == h_total_piexls-1)
    begin
        if (y_counter == v_total_piexls-1)
            y_counter <= 0;
        else
            y_counter <= y_counter + 1;
    end
    
always @(posedge clk)
  begin
     h_sync <= (x_counter >= h_sync_width + h_back_porch && x_counter < h_active_pixels + h_sync_width + h_back_porch);
     v_sync <= (y_counter >= v_sync_width + v_back_porch && y_counter < v_active_pixels + v_sync_width + v_back_porch);
  end

always @(posedge clk)
  begin
    if (h_sync && v_sync)
      begin
        vga <= vdata;
      end
    else vga <= 12'h000;
  end

assign vaddr_x = (h_sync)?(x_counter - h_sync_width - h_back_porch + 1):11'h7ff;
assign vaddr_y = (v_sync)?(y_counter - v_sync_width - v_back_porch ):10'h3ff;
endmodule



