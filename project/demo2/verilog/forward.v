module forward(rs, rt, xm_rw, xm_dr mwb_rw, mwb_dr, forward_A, forward_B);
   //////////////
   //    IO    //
   //////////////
      //Module Inputs    
      input wire forward_A;
      input wire forward_B;

      input wire [2:0]mwb_dr;

      assign forward_A = ((xm_rw == rd) & mwb_rw) ? 2'b10 : (
                        ((mwb_rw == rd) & mwb_rw) ? (2'b01 : 2'b00)); 

      assign forward_A = ((xm_rw == rd) & mwb_rw) ? 2'b10 : (
                        ((mwb_rw == rd) & mwb_rw) ? (2'b01 : 2'b00));
endmodule