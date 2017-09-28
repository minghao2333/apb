`timescale 1 ns/ 1 ps
module apbslave
(
   input         pclk,
	input         presetn,
	input[5:0]    paddr,
	input         psel,
	input         penable,
	input         pwrite,
	input[31:0]   pwdata,
	output wire[31:0]  prdata,
	 input	        datavaild,
	 output reg       interrupt,
	
	input         uart_tx_ready,
	output reg   uart_tx_data_en,
	input [7:0] prx_data,
	output reg [1:0] control_data=0,
	output wire[7:0] uart_tx_data
);

localparam[5:0] txrxaddr=6'h8;
localparam[5:0] controladdr=6'h4;
localparam S_RD_IDLE   = 4'd0;
localparam S_RD_FIFO   = 4'd1;
localparam S_RD_SEND   = 4'd5;
localparam S_RD_DELAY   = 4'd2;
localparam S_RD_DELAYY   = 4'd3;
localparam S_RD_DELAYYY   = 4'd4;

//reg   uart_tx_reg;
//reg   uart_rx_reg;
//reg   control_reg;
//reg[1:0] verifydata;
reg    intuerrupt;


reg[31:0] buf_data;
//wire uart_tx_ready;
//wire uart_tx_data_en;
reg buf_rdreq;
reg buf_wrreq;
wire buf_empty;
reg  rx_buf_wrreq;
reg[7:0]  rx_data=0;   
reg[3:0] rd_state;

//assign uart_tx_data_en = (rd_state == S_RD_DELAY);

assign write_act = psel & pwrite & penable;
assign read_act = psel & (~pwrite);


always@(posedge pclk)
begin
if(rd_state == S_RD_DELAY)
uart_tx_data_en<=1;
else
  uart_tx_data_en<=0;
end

always@(posedge pclk)
begin
interrupt<=intuerrupt;
end

		

//write
always@(posedge pclk or negedge  presetn)
begin
if(~presetn)
	begin
    buf_wrreq <= 1'b0;
    buf_data <= 32'd0;
	  intuerrupt<=0;
	 end
	 else	 
	 
	 begin
	 if(paddr==controladdr)
	   begin
		if(penable)
	   control_data<=pwdata[1:0];
	  end
	  else
	    begin
		 if(paddr==txrxaddr)
		   if(read_act)
			begin
			 intuerrupt<=1;
			 //uart_rx_reg<=1;
			 end
			 else
			  begin 
			  intuerrupt<=0;
			   if(write_act)
				begin
			     buf_wrreq <= 1'b1;	
		       buf_data <= pwdata;
				 end
			   else
				begin
			     buf_wrreq <= 1'b0;
				buf_data <=0;  
				  end
		      end
		 end
   end
end
   
//read

always@(posedge pclk or negedge presetn)
begin
	if(~presetn)
	begin
		buf_rdreq <= 1'b0;
		rd_state <= S_RD_IDLE;
	end
	else
	begin
		case(rd_state)
			S_RD_IDLE:
			begin
				if(~buf_empty)
				begin
					buf_rdreq <= 1'b1;
					rd_state <= S_RD_FIFO;
				end
			end
			S_RD_FIFO:
			begin
				buf_rdreq <= 1'b0;
				rd_state <= S_RD_DELAY;
			end
			
		S_RD_DELAY:
			begin
			rd_state <= S_RD_DELAYY;
			end
			
			S_RD_DELAYY:
			begin
			rd_state <= S_RD_DELAYYY;
			end
			
			S_RD_DELAYYY:
			begin
			rd_state <= S_RD_SEND;
			end
			
			S_RD_SEND:
			begin
				if(uart_tx_ready)
					rd_state <= S_RD_IDLE;
				else
					rd_state <= S_RD_SEND;
			end
			default:
				rd_state <= S_RD_IDLE;
		endcase
	end
end


always@(posedge pclk or negedge presetn)
begin
	if(~presetn)
	begin
		rx_buf_wrreq <= 1'b0;
	end
	else
	
			begin
				if(datavaild)
				begin
					rx_buf_wrreq  <= 1'b1;
					rx_data<=prx_data;
					end
				else
			     rx_buf_wrreq  <= 1'b0;		
	end
end
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

uart_rx_buf uart_rx_buf_m11(
	.aclr(~presetn),
	.data(rx_data),
	.rdclk(pclk),
	.rdreq(intuerrupt),
	.wrclk(pclk),
	.wrreq(rx_buf_wrreq),
	.q(prdata),
	.rdempty(),
	.wrfull()
	);

endmodule