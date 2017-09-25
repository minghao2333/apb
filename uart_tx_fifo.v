`timescale 1 ns/ 1 ps
module uart_tx_fifo
(
   input         clk,
	input         resetn,
	input[31:0]   addr,
	input[3:0]    sel,
	input         enable,
	input         write,
	input[31:0]   wdata,
	input         buf_empty,
	input         uart_tx_ready,
	
	output reg[31:0] buf_data,
	output reg buf_rdreq,
   output reg buf_wrreq,
   output reg   uart_tx_data_en,
	output reg [1:0] verifydata,
	
   output reg[31:0]  prdata
);


localparam[31:0] txaddr=32'h8;
localparam[31:0] controladdr=32'h4;
//读FIFO的状态机状态编码
localparam S_RD_IDLE   = 4'd0;
localparam S_RD_FIFO   = 4'd1;
localparam S_RD_SEND   = 4'd5;
localparam S_RD_DELAY   = 4'd2;
localparam S_RD_DELAYY   = 4'd3;
localparam S_RD_DELAYYY   = 4'd4;
//写FIFO的状态机状态编码
localparam S_WR_IDLE   = 4'd0;
localparam S_WR_SEND   = 4'd1;
localparam S_WR_STOP   = 4'd2;

//reg[31:0] buf_data;
reg        aa=0;
assign write_act = sel & write & enable;
assign read_act = sel & (~write) & enable;

//wire[7:0] uart_tx_data;
//wire uart_tx_ready;
//wire uart_tx_data_en1;
//reg[7:0] buf_data;
//reg buf_rdreq;
//reg buf_wrreq;
//wire buf_empty;

reg[31:0] timer_cnt;

reg[3:0] rd_state;
reg[3:0] wr_state;

//reg[7:0] byte_cnt;
//assign uart_tx_data_en = (rd_state == S_RD_DELAY);
always@(posedge clk)
begin
if(rd_state == S_RD_DELAY)
uart_tx_data_en<=1;
else
  uart_tx_data_en<=0;
end

always@(posedge clk or negedge  resetn)
begin
	if(~ resetn)
	begin
		timer_cnt <= 32'd0;
		buf_wrreq <= 1'b0;
		wr_state <= S_WR_IDLE;
		//byte_cnt <= 8'd0;
		buf_data <= 8'd0;
		aa<=0;
	end
	else
	begin
  if(addr==controladdr)
    verifydata<=wdata[1:0];
	 else
	 begin
	if(addr==txaddr)
	begin
		case(wr_state)
			S_WR_IDLE:
			begin
				if(timer_cnt == 32'd9)//每秒发送一次
				begin
					wr_state <= S_WR_SEND;
					timer_cnt <= 32'd0;
				end
				else
				begin
					wr_state <= S_WR_IDLE;
					timer_cnt <= timer_cnt + 32'd1;
				end
			end
			
			S_WR_SEND:
			begin
				if(aa)//遇到换行自动停止发送
				begin
					buf_wrreq <= 1'b0;
					wr_state <= S_WR_STOP;
					aa<=0;
				end
				else
				 begin
					buf_wrreq <= 1'b1;	
				   buf_data <= wdata;
					aa<=1;
				end
			end
			
			S_WR_STOP:
			begin
			if(write_act)
			wr_state <= S_WR_IDLE;
			else
			wr_state <= S_WR_STOP;
			end
			
			default:
				wr_state <= S_WR_IDLE;
		endcase
		end
		else
		 buf_data <= 0;
		 end
	end
end





 always@(posedge clk or negedge resetn)
begin
	if(~resetn)
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



endmodule