`default_nettype none

/*  
   Filename        : forward.v
   Description     : Logic determines where/if data can be forwarded
*/

module forward(rs, rt, rs_v, rt_v, xm_wr, xm_rd, mwb_wr, mwb_rd, forward_A, forward_B);
   //////////////
   //    IO    //
   //////////////
      //Module Inputs
         // INSTRUCTION REG //    
         input wire [2:0]rs;     //rs for current instruction
         input wire [2:0]rt;     //rt ^

         input wire rs_v;
         input wire rt_v;
         
         // EXECUTE/MEMORY PIPE //
         input wire xm_wr;  //Register Write 
         input wire [2:0]xm_rd;  //Destination reg
         
         // MEMORY/WRITEBACK PIPE //
         input wire mwb_wr; //Register Write
         input wire [2:0]mwb_rd; //Destination reg

      //Module outputs
         output wire [1:0]forward_A;
         output wire [1:0]forward_B;

   ///////////
   // LOGIC //
   ///////////
      //Mux control to select A input of execute
      assign forward_A = ((xm_rd == rs) & xm_wr & rs_v) ? 2'b10 : (
                        ((mwb_rd == rs) & mwb_wr & rs_v) ? 2'b01 : 2'b00); 
      
      //Mux control to select B input of execute (rt if you will)
      assign forward_B = ((xm_rd == rt) & xm_wr & rt_v) ? 2'b10 : (
                        ((mwb_rd == rt) & mwb_wr & rt_v) ? 2'b01 : 2'b00);
endmodule

`default_nettype wire
