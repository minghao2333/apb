module apbtop
(
   input         pclk,
	input         presetn,
	input[31:0]   haddr_i,
	input[3:0]    hsel_i,
	input         hwrite_i,
	input[31:0]   hwdata_i,
	//input         hready,
   input [31:0]  prdata_i,
	output reg    uart_tx_o1
	
	);
	 wire [3:0]   psel_o;
	 wire    penable_o;
	 wire    pwrite_o;
	 wire [31:0]   paddr_o;
	 wire [31:0]   pwdata_o;
	 wire [31:0]   hrdata_o;
    wire [31:0]   buf_data;
	 wire          buf_rdreq;
    wire          buf_wrreq;
	 wire [7:0]    uart_tx_data;
	 wire          buf_empty;
	 wire          uart_tx_data_en;
	 wire           uart_tx_o;
	 wire[1:0]     verifydata;
	 always@(posedge pclk)
begin
 uart_tx_o1<= uart_tx_o;
end
	 
 apbtest m11
(
   .pclk(pclk),
	.presetn(presetn),
	.haddr_i(haddr_i),
	.hsel_i(hsel_i),
	.hwrite_i(hwrite_i),
	.hwdata_i(hwdata_i),
   .prdata_i(prdata_i),
	.psel_o(psel_o),
	.penable_o(penable_o),
	.pwrite_o(pwrite_o),
	.paddr_o(paddr_o),
	.pwdata_o(pwdata_o),
	.hrdata_o(hrdata_o)
);

  uart_tx_fifo u11
(
   .clk(pclk),
	.resetn(presetn),
	.addr( paddr_o),
	.sel(psel_o),
	.enable(penable_o),
	.write(pwrite_o),
	.wdata(pwdata_o),
	.uart_tx_ready(uart_tx_ready),
	.buf_empty(buf_empty),
	.buf_data(buf_data),
	.buf_rdreq(buf_rdreq),
   .buf_wrreq(buf_wrreq),
	.uart_tx_data_en(uart_tx_data_en),
	.verifydata(verifydata),
   .prdata()
);


    uart_tx u1
	 (
    .clk_i(pclk),
    .resetn_i(presetn),
	 .datain_i(uart_tx_data),
	 .shoot_i(uart_tx_data_en),
	 .verify(verifydata),
	 .uart_tx_o(uart_tx_o),
	 .uart_busy_o(uart_tx_ready)
);


 uart_buf uart_buf_m1(
	.aclr(~presetn),
	.data(buf_data),
	.rdclk(pclk),
	.rdreq(buf_rdreq),
	.wrclk(pclk),
	.wrreq(buf_wrreq),
	.q(uart_tx_data),
	.rdempty(buf_empty),
	.wrfull()
	);

endmodule