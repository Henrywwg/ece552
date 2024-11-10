`default_nettype none

/*  
   Filename        : forward.v
   Description     : Logic determines where/if data can be forwarded
*/

module forward(rs, rt, xm_rw, xm_dr, mwb_rw, mwb_dr, forward_A, forward_B);
   //////////////
   //    IO    //
   //////////////
      //Module Inputs
         // INSTRUCTION REG //    
         input wire [2:0]rs;     //rs for current instruction
         input wire [2:0]rt;     //rt ^
         
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
      assign forward_A = ((xm_rw == rs) & xm_rw) ? 2'b10 : (
                        ((mwb_dr == rs) & mwb_rw) ? 2'b01 : 2'b00); 
      
      //Mux control to select B input of execute (rt if you will)
      assign forward_B = ((xm_rw == rt) & xm_rw) ? 2'b10 : (
                        ((mwb_dr == rt) & mwb_rw) ? 2'b01 : 2'b00);
endmodule

`default_nettype wire