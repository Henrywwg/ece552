`default_nettype none

/*  
   Filename        : forward.v
   Description     : Logic determines where/if data can be forwarded
*/

module forward(rs, rt, rs_v, rt_v, xm_rw, xm_dr, mwb_rw, mwb_dr, forward_A, forward_B);
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
         input wire [2:0]xm_rw;  //Register Write 
         input wire [2:0]xm_dr;  //Destination reg
         
         // MEMORY/WRITEBACK PIPE //
         input wire [2:0]mwb_rw; //Register Write
         input wire [2:0]mwb_dr; //Destination reg

      //Module outputs
         output wire forward_A;
         output wire forward_B;

   ///////////
   // LOGIC //
   ///////////
      //Mux control to select A input of execute
      assign forward_A = ((xm_dr == rs) & xm_rw & rs_v) ? 2'b10 : (
                        ((mwb_dr == rs) & mwb_rw & rs_v) ? 2'b01 : 2'b00); 
      
      //Mux control to select B input of execute (rt if you will)
      assign forward_B = ((xm_dr == rt) & xm_rw & rt_v) ? 2'b10 : (
                        ((mwb_dr == rt) & mwb_rw & rt_v) ? 2'b01 : 2'b00);
endmodule

`default_nettype wire