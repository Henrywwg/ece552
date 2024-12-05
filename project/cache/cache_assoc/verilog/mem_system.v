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
   output reg        Done;       // not in schematic
   output reg        Stall;
   output reg        CacheHit;   // not in schematic
   output reg        err;

   
      //////////////////////////////////////////////////////////////////////////////////////////////////////////
      // state machine signals  
      // caches 
      reg force_enable;
      reg [15:0] cache_data_in;
      reg [15:0] cache_addr;
      reg cache_comp;
      reg toggle_victim_way;
      reg cache_rd;
      reg cache_wr;

      // mem
      reg [15:0] mem_data_in;
      reg [15:0] mem_addr;
      reg mem_write;
      reg mem_read;

      //////////////////////////////////////////////////////////////////////////////////////////////////////////
      // interface signals
      // mem
      wire mem_err;
      wire mem_stall;
      wire [3:0] mem_busy;
      wire [15:0] mem_data_out;

      // caches
      wire c0_valid_raw, c0_dirty_raw, c0_hit_raw, c0_tag_out, c0_data_out, c0_err;
      wire c1_valid_raw, c1_dirty_raw, c1_hit_raw, c1_tag_out, c1_data_out, c1_err;

      //////////////////////////////////////////////////////////////////////////////////////////////////////////
      // assigned signals
      wire c0_en, c1_en;
      wire victim;
      wire cache_valid;
      wire real_hit;
      wire victimize;
      wire [4:0] actual_tag;
      wire [15:0] cache_data_out;

      assign c0_en = (cache_rd | cache_wr) & (~cache_comp & ~victim) & ~force_enable;
      assign c1_en = (cache_rd | cache_wr) & victim;

      assign cache_valid = cache_wr & ~cache_comp;

      assign real_hit = (c0_hit_raw & c0_valid_raw) | (c1_hit_raw & c1_valid_raw);

      assign victimize = (c0_dirty_raw & ~c0_hit_raw) | (c1_dirty_raw & ~ c1_hit_raw);

      assign actual_tag = (c0_tag_out == cache_addr[15:11]) ? c0_tag_out : 

      assign cache_data_out = 

      //////////////////////////////////////////////////////////////////////////////////////////////////////////
      // victim automatically selects cache to use during eviction
      dff victim_FF (.q(victim), .d(toggle_victim_way ? ~victim : victim), .clk(clk), .rst(rst));


   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter memtype = 0;
   cache #(0 + memtype) c0(// Outputs
                          .tag_out              (c0_tag_out),
                          .data_out             (c0_data_out),
                          .hit                  (c0_hit_raw),
                          .dirty                (c0_dirty_raw),
                          .valid                (c0_valid_raw),
                          .err                  (c0_err),
                          // Inputs
                          .enable               (c0_en),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (cache_addr[15:11]),
                          .index                (cache_addr[10:3]),
                          .offset               (cache_addr[2:0]),
                          .data_in              (cache_data_in),
                          .comp                 (cache_comp),
                          .write                (cache_wr),
                          .valid_in             (cache_valid));
   cache #(2 + memtype) c1(// Outputs
                          .tag_out              (c1_tag_out),
                          .data_out             (c1_data_out),
                          .hit                  (c1_hit_raw),
                          .dirty                (c1_dirty_raw),
                          .valid                (c1_valid_raw),
                          .err                  (c1_err),
                          // Inputs
                          .enable               (c1_en),
                          .clk                  (clk),
                          .rst                  (rst),
                          .createdump           (createdump),
                          .tag_in               (cache_addr[15:11]),
                          .index                (cache_addr[10:3]),
                          .offset               (cache_addr[2:0]),
                          .data_in              (cache_data_in),
                          .comp                 (cache_comp),
                          .write                (cache_wr),
                          .valid_in             (cache_valid));

   four_bank_mem mem(// Outputs
                     .data_out          (mem_data_out),
                     .stall             (mem_stall),
                     .busy              (mem_busy),
                     .err               (mem_err),
                     // Inputs
                     .clk               (clk),
                     .rst               (rst),
                     .createdump        (createdump),
                     .addr              (mem_addr),
                     .data_in           (mem_data_in),
                     .wr                (mem_write),
                     .rd                (mem_read));
   

   


   
endmodule // mem_system
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :9:
