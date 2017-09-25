`timescale 1 ns/ 1 ps
module clk_divider
#( parameter DIVISOR = 12'd868)
(
input clk_i,
input resetn_i,
output reg clk_en_o
);
reg[11:0] clk_dividor =0;

always@( posedge clk_i or negedge resetn_i)
 begin
if(!resetn_i) 
begin
clk_dividor <= 12'h0;
clk_en_o <= 1'h0;
//End of automatics
end 
else
begin
if(clk_dividor != DIVISOR)
begin
clk_dividor <= clk_dividor + 1'b1;
clk_en_o <= 1'b0;
end
else
begin
clk_dividor <= 12'h0;
clk_en_o <= 1'b1;
end
end
end
endmodule