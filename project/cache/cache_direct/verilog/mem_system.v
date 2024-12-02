/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

`default_nettype none
module mem_system(/*AUTOARG*/
   // Outputs
   DataOut, Done, Stall, CacheHit, err,
   // Inputs
   Addr, DataIn, Rd, Wr, createdump, clk, rst
   );
   
   input wire [15:0] Addr;
   input wire [15:0] DataIn;
   input wire        Rd;
   input wire        Wr;
   input wire        createdump;
   input wire        clk;
   input wire        rst;
   
   output reg [15:0] DataOut;
   output reg        Done;       // anot in schematic
   output reg        Stall;         
   output reg        CacheHit;   // also not in schematic 
   output reg        err;       
   
   ////////////////////
   //INTERNAL SIGNALS//
   ////////////////////
      // Cache Signals
         //Inputs
         wire        cache_en;
         wire        cache_force_disable;
         wire        cache_data_in;
         wire [15:0] cache_addr;
         wire        cache_comp;
         wire        cache_rd;
         wire        cache_wr;
         wire        cache_valid;

         // Outputs
         wire [15:0] cache_data_out
         wire        real_hit;
         wire        victimize;
         wire [4:0]  actual_tag;

      // Mem signals
      wire [15:0] mem_data_in;
      wire [15:0] mem_data_out;
      wire [15:0] mem_addr;
      wire        mem_write;
      wire        mem_read;
      wire        mem_stall;
      wire [3:0]  mem_busy;

      //DEBUG err sig
      wire ERR_mem;
      wire ERR_cache;

      //Intermediate internals
      wire cache_hit_raw;
      wire cache_dirty_raw;
      wire cache_valid_raw;

      wire 

      assign real_hit = cache_hit_raw & cache_valid_raw;
      assign victimize = ~cache_hit_raw & cache_dirty_raw;
      assign cache_en = (cache_rd | cache_wr) & ~cache_force_disable;


      //State machine logic
      wire state;
      wire next_state_out;
      wire next_state;


   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (actual_tag),
                          .data_out             (cache_data_out),
                          .hit                  (cache_hit_raw),
                          .dirty                (cache_dirty_raw),
                          .valid                (cache_valid_raw),
                          .err                  (ERR_cache),
                          // Inputs
                          .enable               (cache_en),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (cache_addr[15:11]),
                          .index                (cache_addr[10:3]),
                          .offset               (cache_addr[2:0]),
                          .data_in              (cache_data_in),
                          .comp                 (cache_comp),
                          .write                (cache_wr),
                          .valid_in             (cache_valid));      //Not actually sure what this does

   four_bank_mem mem(// Outputs
                     .data_out          (mem_data_out),
                     .stall             (mem_stall),
                     .busy              (mem_busy),
                     .err               (ERR_mem),
                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (mem_addr),
                     .data_in           (mem_data_in),
                     .wr                (mem_write),
                     .rd                (mem_read));

   ////////////////////////////////////
   // State machine sequential logic //
   ////////////////////////////////////
      //Assign next/current states
      dff state_ff(.q(state), .d(next_state_out), .clk(clk), .rst(rst));
      dff next_state_ff(.q(next_state_out), .d(next_state), .clk(clk), .rst(rst));
   
   //////////////////////////
   // Combination SM logic //
   //////////////////////////
      always @(*) begin
      //Default signals to prevent latches
      Done = 0;
      Stall = 0;
      CacheHit = 0;
      DataOut = 16'h0000;
      next_state = state;

      case()
      endcase
   end




   /////////////////
   // ERROR LOGIC //
   /////////////////
   always @(*) begin
      err = 1'b0;
      case({ERR_cache, ERR_mem})
         2'b00: 
            err = 1'b0;
         default:
            err = 1'b1;
      endcase
   end


   
endmodule // mem_system
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :9:
