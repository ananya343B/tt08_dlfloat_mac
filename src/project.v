/* 
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_dlfloatmac (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

wire [15:0]data_in;
wire [15:0] c;
wire [15:0]wa,wb;

wire [7:0] c_byte;


assign uio_oe = 8'b0;
assign uio_out= 8'b0;
  
assign data_in = {uio_in,ui_in};

reg_wrapper wrap(clk,rst_n,data_in,wa,wb);
dlfloat_mac MAC(clk,rst_n,wa,wb,c);
out_wrapper wrap2(clk,rst_n,c,c_byte); 


assign uo_out = c_byte[7:0];
wire _unused = &{ena, 1'b0};
   
endmodule

module reg_wrapper(
    input clk,
    input rst_n,
    input [15:0] data_in,
    output reg [15:0] reg_a,
    output reg [15:0] reg_b
);

   reg [1:0] state;
   reg [15:0] temp_data;

 always @(posedge clk or negedge rst_n) begin
     if (!rst_n) begin
        state <= 2'b00; 
        reg_a <= 16'b0;
        reg_b <= 16'b0;
        temp_data <= 16'b0;
     end
     else begin
        case (state)
            2'b00: begin
                temp_data <= data_in;
                reg_a<=16'b0;
                reg_b<=16'b0;
                state <= 2'b01;
            end
            2'b01: begin
                reg_a <= temp_data;
                reg_b <= data_in;
                state <= 2'b00;
            end
            default: state <= 2'b00; 
        endcase
     end
  end

endmodule

module out_wrapper(
    input clk,
    input rst_n,
    input [15:0] c,
    output reg [7:0] c_byte
);

    reg [1:0] state;

   always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= 2'b00; 
        c_byte <=8'b0;
    end
    else begin
        case (state)
            2'b00: begin
		    c_byte <= c[7:0];
                state <= 2'b01;
            end
            2'b01: begin
		    c_byte <= c[15:8]; 
                state <= 2'b00;
            end
            default: state <= 2'b00; 
        endcase
    end
end

endmodule

module dlfloat_mac(clk,rst_n,a,b,c_out);
  input [15:0]a,b;
  input clk,rst_n;
  output reg [15:0]c_out;
  wire [15:0]fprod,fadd;
  
  always @(posedge clk or negedge rst_n ) begin
    if(!rst_n) begin
      c_out<=16'b0;
    end
    else begin
  	c_out<= fadd;
    end
  end
  	
  dlfloat_mult mul(a,b,fprod,clk,rst_n);
  dlfloat_adder add(fprod,c_out,fadd);
  
endmodule 
  
module dlfloat_mult(a,b,c_mul,clk,rst_n);
  input  [15:0]a,b;
  input clk,rst_n;
  output  reg[15:0]c_mul;
    
    reg [9:0]ma,mb; //1 extra because 1.smthng
    reg [8:0] mant;
    reg [19:0]m_temp; //after multiplication
    reg [5:0] ea,eb,e_temp,exp;
    reg sa,sb,s;
    reg [15:0] c_mul1;
	
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      c_mul<=16'b0;
    end
    else begin
      c_mul<=c_mul1;
    end
  end	
  	
  always@(*) begin
        ma ={1'b1,a[8:0]};
        mb= {1'b1,b[8:0]};
        sa = a[15];
        sb = b[15];
        ea = a[14:9];
        eb = b[14:9];
  	
       //to avoid latch inference
  	e_temp = 6'b0;
  	m_temp = 20'b0;
  	mant=9'b0;
  	exp= 6'b0;
  	s=0;
  	
  	//checking for underflow/overflow
    if (  (ea + eb) <= 31 ) begin
  		c_mul1=16'b0;//pushing to zero on underflow
  	end
    else if ( (ea + eb) > 94) begin
      if( (sa ^ sb) ) begin
          c_mul1=16'hFDFE;//pushing to largest -ve number on overflow
        end
      else begin
          c_mul1=16'h7DFE;//pushing to largest +ve number on overflow
      end
    end
        
  	else if ( (ea + eb) == 94 ) begin
		c_mul1=16'hFFFF;//pushing to inf if exp is all ones
 	end
        else begin	
        e_temp = ea + eb - 31;
        m_temp = ma * mb;
		
        mant = m_temp[19] ? m_temp[18:10] : m_temp[17:9];
        exp = m_temp[19] ? e_temp+1'b1 : e_temp;	
        s=sa ^ sb;
		
 	//checking for special cases	
         if( a==16'hFFFF | b==16'hFFFF ) begin
            c_mul1 =16'hFFFF;
         end
        else begin
           c_mul1 = (a==0 | b==0) ? 0 :{s,exp,mant};
         end 
 	end 
    end 
	wire _unused = &{m_temp[8:0], 9'b0};
endmodule 
 
module dlfloat_adder(input [15:0] a1, input [15:0] b1,output reg [15:0] c_add);
   
   	
    reg    [5:0] Num_shift_80; 
    reg    [5:0]  Larger_exp_80,Final_expo_80;
    reg    [9:0] Small_exp_mantissa_80,S_mantissa_80,L_mantissa_80,Large_mantissa_80;
    reg    [8:0] Final_mant_80;
    reg    [10:0] Add_mant_80,Add1_mant_80;
    reg    [5:0]  e1_80,e2_80;
    reg    [8:0] m1_80,m2_80;
    reg          s1_80,s2_80,Final_sign_80;
    reg    [8:0]  renorm_shift_80;
    reg signed [5:0] renorm_exp_80;
    reg signed [5:0] larger_expo_neg;
   
    
    always@(*) begin
        //stage 1
     	     e1_80 = a1[14:9];
    	     e2_80 = b1[14:9];
             m1_80 = a1[8:0];
     	     m2_80 = b1[8:0];
             s1_80 = a1[15];
       	     s2_80 = b1[15];
        
	    Num_shift_80=6'b0;
	  
           if (e1_80  > e2_80) begin
              Num_shift_80           = e1_80 - e2_80;
              Larger_exp_80          = e1_80;                     
              Small_exp_mantissa_80  = {1'b1,m2_80};
              Large_mantissa_80      = {1'b1,m1_80};
           end
        
           else begin
             Num_shift_80           = e2_80 - e1_80;
             Larger_exp_80          = e2_80;
             Small_exp_mantissa_80  = {1'b1,m1_80};
             Large_mantissa_80      = {1'b1,m2_80};
           end
        
	    if (e1_80 == 0 | e2_80 ==0) begin
	        Num_shift_80 = 0;
	        Small_exp_mantissa_80 = 10'd512; //to avoid subnormal mantissa to be greater than normal mantissa pushing it to all zeros and leading 1      
	    end
	    else begin
	        Num_shift_80 = Num_shift_80;
	    end
            
            
           //stage 2 
           //shift and append smaller mantissa
	    Small_exp_mantissa_80  = (Small_exp_mantissa_80 >> Num_shift_80);
              
           //stage 3
           //add the mantissas
                                                    
            if (Small_exp_mantissa_80  < Large_mantissa_80) begin
		   S_mantissa_80 = Small_exp_mantissa_80;
	    	   L_mantissa_80 = Large_mantissa_80;
            end
            else begin
			
		   S_mantissa_80 = Large_mantissa_80;
		   L_mantissa_80 = Small_exp_mantissa_80;
            end       
                       
            Add_mant_80=11'b0;
	
	    if (e1_80!=0 & e2_80!=0) begin
		   if (s1_80 == s2_80) begin
        		Add_mant_80 = S_mantissa_80 + L_mantissa_80;
		    end else begin
			   Add_mant_80 = L_mantissa_80 - S_mantissa_80;
		    end
	    end	
 	    else begin
		    Add_mant_80 ={1'b0, L_mantissa_80};
	    end
      
	   //renormalization for mantissa and exponent
           //stage 4
	   //to avoid latch inference
	   renorm_exp_80=6'd0;
	   renorm_shift_80=9'd0;
	   Add1_mant_80=Add1_mant_80;
	   
           if (Add_mant_80[10] ) begin
		   Add1_mant_80= Add_mant_80 >> 1;
		   renorm_exp_80 = 6'd1;
	   end
           else begin 
              if (Add_mant_80[9])begin
	   	     renorm_shift_80 = 0;
	   	     renorm_exp_80 = 0;		
	      end
              else if (Add_mant_80[8])begin
	   	     renorm_shift_80 = 9'd1; 
	   	     renorm_exp_80 = -1;
	      end 
              else if (Add_mant_80[7])begin
	      	      renorm_shift_80 = 9'd2; 
	      	      renorm_exp_80 = -2;		
	      end  
              else if (Add_mant_80[6])begin
	    	      renorm_shift_80 = 9'd3; 
	    	      renorm_exp_80 = -3;		
	      end
              else if (Add_mant_80[5])begin
	    	      renorm_shift_80 = 9'd4; 
	   	      renorm_exp_80 = -4;		
	      end
              else if (Add_mant_80[4])begin
	    	      renorm_shift_80 = 9'd5; 
	    	      renorm_exp_80 = -5;		
	      end
              else if (Add_mant_80[3])begin
	   	      renorm_shift_80 = 9'd6; 
	   	      renorm_exp_80 = -6;		
	      end
              else if (Add_mant_80[2])begin
	   	      renorm_shift_80 = 9'd7; 
	   	      renorm_exp_80 = -7;		
	       end
              else if (Add_mant_80[1])begin
	   	      renorm_shift_80 = 9'd8; 
	    	      renorm_exp_80 = -8;		
	      end
              else if (Add_mant_80[0])begin
	    	      renorm_shift_80 = 9'd9; 
	    	      renorm_exp_80 = -9;		
	      end
	      else begin
		      renorm_exp_80=6'd0;
	              renorm_shift_80=9'd0;
	              Add1_mant_80=Add1_mant_80;
	      end
	  	   
              Add1_mant_80 = Add_mant_80 << renorm_shift_80;
            
          end

          Final_expo_80 = 6'd0;//to avoid latch inference
	  Final_mant_80 = 9'd0;//to avoid latch inference  
	  Final_sign_80=0;//to avoid latch inference 
          larger_expo_neg = -Larger_exp_80;
      
        //calculating final sign	   
	       if (s1_80 == s2_80) begin
		     Final_sign_80 = s1_80;
	       end 
	       else begin   //if sign is different
	          if (e1_80 > e2_80) begin
	       	     Final_sign_80 = s1_80;	
	          end 
	          else if (e2_80 > e1_80) begin
		     Final_sign_80 = s2_80;
	          end
	          else begin
                     if (m1_80 > m2_80) begin
			            Final_sign_80 = s1_80;		
		             end
		            else if (m1_80 < m2_80) begin
			           Final_sign_80 = s2_80;
		            end
		           else begin
		              Final_sign_80 = 0;
		           end	  
                 end
	       end
      
         
           //checking for overflow/underflow
           if(  Larger_exp_80 == 63 & renorm_exp_80 == 1) begin //overflow
             if (  Final_sign_80 ) begin
                c_add=16'hFDFE;//largest -ve value
             end
             else begin
               c_add=16'h7DFE;//largest +ve value
             end
  
           end
           else if ((Larger_exp_80 >= 1) & (Larger_exp_80 <= 8) & (renorm_exp_80 <  larger_expo_neg)) begin //underflow
             if (  Final_sign_80 ) begin
               c_add=16'h8201;//smallest -ve value
               end
             else begin
               c_add=16'd513;//smallest +ve value
             end
            end 
           else begin
      	   
               Final_expo_80 =  Larger_exp_80 + renorm_exp_80;
      
      	       if(Final_expo_80 == 6'b0) begin
                     c_add=16'b0;
               end
               else if( Final_expo_80 == 63) begin
                     c_add=16'hFFFF;
               end      
	      
               Final_mant_80 = Add1_mant_80[8:0]; 
	       
               //checking for special cases
               if( a1==16'hFFFF | b1==16'hFFFF) begin
                 c_add = 16'hFFFF;
               end
               else begin
                 c_add = (a1==0 & b1==0)?0:{Final_sign_80,Final_expo_80,Final_mant_80};
               end 
           end//for overflow/underflow 
  end //for always block 
endmodule
