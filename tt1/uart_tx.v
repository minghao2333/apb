`timescale 1 ns/ 1 ps
module uart_tx
//#(
    //parameter VERIFY_ON = 1'b0,
	// parameter VERIFY_EVEN = 1'b0
	// )
	 (
	 input         clk_i,
	 input         resetn_i,
	// input         clk_en_i,
	 input[7:0]    datain_i,
	 input         shoot_i,
	 input[1:0]    verify,
	 output reg    uart_tx_o = 1'b1,
	 output reg    uart_busy_o
);


localparam S_IDLE  = 4'd0; 
localparam S_START = 4'd1; 
localparam S_DATA  = 4'd2; 
localparam S_VERIFY = 4'd3; 
localparam S_STOP  = 4'd4;

reg[3:0]     clkcnt=0;
reg[3:0]     bitcnt=0;
reg[7:0]     checkdata=0;
reg          uart_tx_i=1;
reg          uart_tx_i2=1;

reg[3:0] state = S_IDLE;
reg[3:0] next_state = S_IDLE;
reg       resetn=0;
reg       reset=0;
reg       clk_tx_en;
wire      clk_en_i;
always@(posedge clk_i or negedge resetn_i)
begin
if(~resetn_i)
  begin
  resetn <= 1'b1;
  reset <= 1'b1;
  end
  else
  begin
  resetn <= 1'b0;
  reset <= resetn;
  end
end

always@(posedge clk_i or posedge reset)
  begin
    if(reset)
	 state<= S_IDLE;
	 else
	 state<= next_state;
  end
  
always@(*)
  begin
  next_state=state;
  case(state)
     S_IDLE:
	        if(shoot_i)
			     next_state= S_START;
				  
     S_START:
			  if(clk_tx_en)
			    next_state= S_DATA;
				 
		S_DATA:
		     if(clk_tx_en&&bitcnt==4'd7)
			     if(verify[1])
				      next_state= S_VERIFY;
					else
					   next_state= S_STOP;

		S_VERIFY:
		     if(clk_tx_en)
			    next_state= S_STOP;

		S_STOP:
		    if(clk_tx_en)
			    next_state= S_IDLE;

		default:
		  next_state= S_IDLE;
    endcase
    end
	 
always@(posedge clk_i or posedge reset)
  begin
    if(reset)
	   begin
	    clkcnt<=0;
		 clk_tx_en<=0;
	   end
	else 
	begin
	  if(state== S_IDLE)
	    begin
		 clkcnt<=4'h0;
		 clk_tx_en<=4'h0;
		 end
		 else
		   begin
			   if(clk_en_i)
			    clkcnt<=clkcnt+1;
				if(clk_en_i&&(clkcnt==4'hE))
				 clk_tx_en<=1'b1;
				else
				 clk_tx_en<=1'b0;
			end
		 end 
  end
  
always@(posedge clk_i or posedge reset)
  begin
     if(reset)
	    bitcnt<=0;
	else 
	begin
	  if(state== S_DATA)
	    begin
		  if(clk_tx_en)
			    bitcnt<=bitcnt+1;
		   else
			   bitcnt<=bitcnt;
		  end
		else
		   bitcnt<=4'h0;
		 
		 end
  end

always@(posedge clk_i)
begin
   if(state == S_IDLE&& shoot_i)
	   checkdata<=datain_i;
	 if(state == S_DATA&&clk_tx_en)
	   checkdata<={datain_i[0],checkdata[7:1]};	
end  
 
 always @ ( posedge clk_i ) begin
      uart_tx_i2 <= uart_tx_i;
      uart_tx_o <= uart_tx_i2;      
   end
   
 always @ (checkdata or state)
 begin
      //uart_tx_i = 1'b1;
      case(state)
        S_START:
          uart_tx_i <= 1'b0;
        S_DATA:
          uart_tx_i <= checkdata[0];
        S_VERIFY:
          uart_tx_i <= (^checkdata) ^ (~verify[0]);
        default:
          uart_tx_i <= 1'b1;
      endcase // case (state)        
   end
	
	 always @ ( posedge clk_i or posedge reset ) 
	 begin
      if(reset)
         uart_busy_o <= 1'b1;
		else 
		 begin
         if(state == S_IDLE)
           uart_busy_o <= 1'b1;
         else
           uart_busy_o <= 1'b0;
      end      
   end 

clk_divider u0(.clk_i(clk_i),.resetn_i(resetn_i),.clk_en_o(clk_en_i));

endmodule