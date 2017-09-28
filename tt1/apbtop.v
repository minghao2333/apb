`timescale 1 ns/ 1 ps
module apbtop
//uart_reg
(
   input         pclk,
	input         presetn,
	input[5:0]    paddr,
	input         psel,
	input         penable,
	input         pwrite,
	input[31:0]   pwdata,
	output wire[31:0]  prdata,
	
	output wire        interrupt,
	
	output wire        shoot,
	output wire       datatx,
   input	        busyn,
	input [7:0]   datarx
);


	
   
	 wire [7:0]    uart_tx_data;
	// wire          buf_empty;
	 //wire          uart_tx_data_en;
	// wire[7:0]      uart_tx_o;
	 wire[1:0]    control_data;
	 wire          uart_tx_ready;
	 //wire[7:0]     uart_tx_data;
     //wire[31:0]    prdata_o;


			
 apbslave m11
(
   .pclk(pclk),
	.presetn(presetn),
	.paddr(paddr),
	.psel(psel),
	.penable(penable),
	.pwrite(pwrite),
	.pwdata(pwdata),
	.prdata(prdata),
	.datavaild(busyn),
	.interrupt(interrupt),
	.uart_tx_ready(uart_tx_ready),
	.uart_tx_data_en(shoot),
	.prx_data(datarx),
	.control_data(control_data),
	.uart_tx_data(uart_tx_data)
);

 
  

 uart_tx u111
	 (
    .clk_i(pclk),
    .resetn_i(presetn),
	 .datain_i(uart_tx_data),
	 .shoot_i(shoot),
	 .verify(control_data),
	 .uart_tx_o(datatx),
	 .uart_busy_o(uart_tx_ready)
);

 

endmodule