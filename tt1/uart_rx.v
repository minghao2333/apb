`timescale 1 ns/ 1 ps
module uart_rx
#(
    parameter VERIFY_ON = 1'b0,
	 parameter VERIFY_EVEN = 1'b0
	 )
	 (
	 input                clk_i,
	 input                resetn_i,
	 //input         clk_en_i,
	 input                uart_rx,
	 output reg           dataout_vaild,
	 output reg [7:0]     dataout
     );

localparam S_IDLE  = 4'd0; 
localparam S_START = 4'd1; 
localparam S_DATA  = 4'd2; 
localparam S_VERIFY = 4'd3; 
localparam S_STOP  = 4'd4;

   reg [3:0]         clk_cnt = 4'h0;
   reg               clk_rx_en = 1'b0;   
   reg [2:0]         sample_cnt = 2'b0;
   reg               sample_value = 1'b0;   
   reg [2:0]         bitcnt = 3'b0;
   reg               uart_rx_i = 1'b0;
   reg               uart_rx_i2 = 1'b0;
   reg               uart_rx_i3 = 1'b0;
   reg               verify_ok = 1'b0;


reg[3:0] state = S_IDLE;
reg[3:0] next_state = S_IDLE;
reg       resetn=0;
reg       reset=0;
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

 always @( posedge clk_i ) 
	  begin 
	   uart_rx_i <= uart_rx; 
      uart_rx_i2 <= uart_rx_i;
      uart_rx_i3 <= uart_rx_i2;
         
   end
   
always@(clk_rx_en or bitcnt or sample_value or state or uart_rx_i2 or uart_rx_i3 or verify_ok)
 begin
      //next_state = state;
      case(state)
        S_IDLE:
          if( ~uart_rx_i2 && uart_rx_i3)
            next_state <= S_START;
				else
               next_state <= S_IDLE;
        S_START:
          if(clk_rx_en) begin
             if(~ sample_value)
               next_state <= S_DATA;        
             else
               next_state <= S_IDLE;
          end        
        S_DATA:
          if(clk_rx_en && bitcnt == 3'd7)begin
             if(VERIFY_ON)
               next_state <= S_VERIFY;
             else
               next_state <= S_STOP;
          end        
        S_VERIFY:
          if(clk_rx_en && verify_ok)
            next_state <= S_STOP;
          else if (clk_rx_en && ~verify_ok)
            next_state <= S_IDLE;        
        S_STOP:
          if(clk_rx_en)
            next_state <= S_IDLE;
        default:
          next_state <= S_IDLE;
      endcase // case (state)        
   end

always @ ( posedge clk_i or posedge reset ) 
  begin
      if(reset) 
		begin
         clk_cnt <= 4'h0;
         clk_rx_en <= 1'h0;
      end
		else
	   	begin
         case(state)
           S_IDLE: begin
              clk_cnt <= 4'h0;
              clk_rx_en <= 1'b0;
           end              
           S_START: 
			  begin
              if(clk_en_i && clk_cnt != 4'hE)
                clk_cnt <= clk_cnt + 1'b1;
              else if (clk_en_i && clk_cnt == 4'hE)
                   clk_cnt <= 4'h0;
                  else
                   clk_cnt <= clk_cnt;
						 
              if(clk_en_i && clk_cnt == 4'hE)
                clk_rx_en <= 1'b1;
              else
                clk_rx_en <= 1'b0;              
           end   
           S_STOP:                 
            begin
              if(clk_en_i && clk_cnt != 4'hE)
                clk_cnt <= clk_cnt + 1'b1;
              else if (clk_en_i && clk_cnt == 4'hE)
                clk_cnt <= 4'h0;
              else
                clk_cnt <= clk_cnt;
					 
              if(clk_en_i && clk_cnt == 4'hE)
                clk_rx_en <= 1'b1;
              else
                clk_rx_en <= 1'b0;              
            end
           default: begin
              if(clk_en_i && clk_cnt != 4'hF)
                clk_cnt <= clk_cnt + 1'b1;
              else if (clk_en_i && clk_cnt == 4'hF)
                clk_cnt <= 4'h0;
              else
                clk_cnt <= clk_cnt;
              if(clk_en_i && clk_cnt == 4'hF)
                clk_rx_en <= 1'b1;
              else
                clk_rx_en <= 1'b0;                            
           end
         endcase           
      end 
   end 

  //always @ ( posedge clk_i or posedge reset )
   always @ ( clk_cnt or reset )
    begin
      if(reset)
		begin
         sample_cnt <= 2'h0;
         sample_value <= 1'h0;
      end 
		else 
		begin
         if(clk_cnt == 4'h0)
           sample_cnt <= 2'b0;         
         else if(clk_cnt > 5 && clk_cnt < 10)
           sample_cnt <= sample_cnt + uart_rx_i3;
         else
           sample_cnt <= sample_cnt;
			  
         if(clk_cnt == 4'ha)
           if(sample_cnt > 2'h1)
             sample_value <= 1'b1;
           else
             sample_value <= 1'b0;
         else
           sample_value <= sample_value;
      end      
   end
	
  always @ ( posedge clk_i or posedge reset ) 
    begin
      if(reset)
        verify_ok <= 1'b0;
      else begin
         if(state == S_VERIFY)
           verify_ok <= (^dataout) ^ VERIFY_EVEN ^~ sample_value;
         else
           verify_ok <= 1'b0;
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
		  if(clk_rx_en)
			    bitcnt<=bitcnt+1;
		   else
			   bitcnt<=bitcnt;
		  end
		else
		   bitcnt<=4'h0;
		 
		 end
  end

   always @ ( posedge clk_i ) 
	begin
      //dataout <= dataout;      
      case(state)
        S_IDLE:
          dataout <= 8'h0;
        S_DATA:
          if(clk_rx_en)
            dataout <= {sample_value,dataout[7:1]};
        default;
      endcase     
   end

   always @ ( posedge clk_i or posedge reset ) begin
      if(reset)
        dataout_vaild <= 1'b0;
      else
        if(state == S_STOP && clk_rx_en)
          dataout_vaild <= 1'b1;
        else
        dataout_vaild <= 1'b0;      
   end
   

clk_divider u01(.clk_i(clk_i),.resetn_i(resetn_i),.clk_en_o(clk_en_i));
endmodule 