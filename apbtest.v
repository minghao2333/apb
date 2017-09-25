`timescale 1 ns/ 1 ps
module apbtest
(
   input         pclk,
	input         presetn,
	input[31:0]   haddr_i,
	input[3:0]    hsel_i,
	input         hwrite_i,
	input[31:0]   hwdata_i,
	//input         hready,
   input [31:0]  prdata_i,
	output reg [3:0]   psel_o=0,
	output reg    penable_o=0,
	output reg    pwrite_o=0,
	output reg [31:0]   paddr_o=0,
	output reg [31:0]   pwdata_o=0,
	output reg [31:0]   hrdata_o=0
);



localparam[3:0] IDLE=4'h1;
localparam[3:0] SETUP=4'h2;
localparam[3:0] ENABLE=4'h3;

reg [3:0]   state=IDLE;
reg [3:0]   next_state=IDLE;
reg         penable;
reg[31:0]   wdata;
reg[31:0]   address;
reg         write;
reg[31:0]   rdata;
reg         psel;
reg         hsel;

always@(posedge pclk or negedge presetn)
  begin
    if(~presetn)
	 state<= IDLE;
	 else
	 state<= next_state;
  end

always@(*)
  begin
   next_state = state;
    case(state)
	    IDLE:
		    if(hsel)
			 next_state=SETUP;		
		 SETUP:
			 next_state=ENABLE;
			  
		ENABLE:
		    if(hsel)
			   next_state=SETUP;
			  else
			  next_state=IDLE;
			  
		default:
		   next_state=IDLE;
    endcase
	 end

always@(posedge pclk or negedge presetn)
   begin
	  if(~presetn)
		   hsel<=0;
		else
		   hsel<=hsel_i;
	end

always@(state or presetn)
   begin
	  if(~presetn)
	    begin
		   penable=0;
			wdata=0;
			rdata=0;
			address=0;
			write=0;
			psel=0;
		 end
	else
	   begin
		  case(state)
		     IDLE:
			       begin
					     psel=0;
						  penable=0;	  
					 end
					 
			  SETUP:
			       begin
					      psel=1;
							penable=0;
							wdata= hwdata_i;
						   address= haddr_i;
						   write= hwrite_i;	
					 end
					 
		    ENABLE:
			       begin
					      penable=1;
						if(~write)
						begin
					     rdata= prdata_i;
						  end
					 end
					 
		    default:
			      begin
					    psel=0;
						  penable=0; 
					end
		endcase
		
		end
	
	end


  always@( posedge pclk)
	begin
     case(state)
	  IDLE:
	  begin
	  psel_o<=psel; 
	  penable_o<= penable; 
	  end
	  
			ENABLE:
			begin
			  psel_o<=psel;  
           pwrite_o<= write;
	        paddr_o<= address;
	        pwdata_o<= wdata;
	          hrdata_o<= rdata;		
			    penable_o<= penable;
				 end
			endcase  
end

 
endmodule