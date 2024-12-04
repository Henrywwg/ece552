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

      assign real_hit = cache_hit_raw & cache_valid_raw;
      assign victimize = ~cache_hit_raw & cache_dirty_raw;
      assign cache_en = (cache_rd | cache_wr) & ~cache_force_disable;


      //State machine logic signals
      wire [3:0]  state;
      wire [3:0]  next_state_out;
      wire [3:0]  next_state;
      wire        inc_cntr;
      wire        clr_cntr;

      //Counter for storing and loading from imperfect memory
      wire [3:0]  cntr, next_cnt;   //counter for store and load from mem
      dff three_bit_cntr(.q(cntr), .d(inc_cntr ? next_cnt : cntr), .clk(clk), .rst(clr_cntr));
      cla_4b cntr_inc(.sum(next_cnt), .a(cntr), .b(4'h1), .cout(/*Unused*/), .c_in(1'b0));

      //Signals for internal registers
      wire [15:0] addr_internal;
      wire        en_int_reg;
      wire        clr_int_reg;


      dff requested_addr_reg[15:0](.q(addr_internal), .d(en_int_reg ? Addr : addr_internal), .clk(clk), .rst(rst));

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
      dff state_ff[3:0](.q(state), .d(next_state_out), .clk(clk), .rst(rst));
      dff next_state_ff[3:0](.q(next_state_out), .d(next_state), .clk(clk), .rst(rst));
   

      //States...
      // 0000 IDLE
      // 0001 rd
      // 0010 wait_rd_wr
      // 0011 wait_rd_rd
      // 0100 wr
      // 0101
      // 0110

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
      inc_cntr = 1'b0;
      clr_cntr = 1'b0;
      clr_int_reg = 1'b0;
      en_int_reg = 1'b0;
      cache_comp = 1'b0;

      case(state)
         4'b0000: begin
            Stall = 1'b0;
            clr_cntr = 1'b1;

            //Set address...
            cache_addr = Addr;

            //Prepare data if needed
            cache_data_in = data_in;

            //Only one should be asserted at a time
            cache_rd = Rd;
            cache_wr = Wr;

            //If doing anything with cache in this state
            // cache_comp should be high
            cache_comp = Rd | Wr;

            //Store Addr internally in case it changes
            en_int_reg = 1'b1;

            next_state =   Rd ? 4'b0001 : (
                           Wr ? 4'b0100 : 4'b0000);
         end

         //READ base state
         4'b0001: begin

            // Miss and victimize (write and read)
            mem_write = victimize;                 //mem_wr = 1;

            // Miss and no victimize (just read)
            mem_read = ~victimize;                 //mem_rd = 1;

            //Set cache addr in case needed
            cache_addr = {addr_internal[15:3], 3'b000}
            
            // Set next state
            next_state =   cache_hit ? 4'b0010 : (
                           victimize ? 4'b0101 : 4'b0101);
         end

         //If we hit
         4'b0010: begin
            cache_hit = 1;
            Done = 1;
            data_out = cache_data_out;

            next_state = 4'b0000;
         end

         //If we miss and line is dirty - store and replace line
         //    This step 'pre-loads' the first cache word so 
         //    when we store the line to memory in next state
         //    less delay and complexity is needed.
         4'b0011: begin
            //Request first word we're evicting from cache
            cache_addr = {addr_internal[15:3], 3'b000}
            cache_rd = 1'b1;

            next_state = 4'b0101;
         end

         //Store line to memory (dirty bit write)
         4'b0101: begin
            inc_cntr = (cntr != 4'h3);
            clr_cntr = (cntr == 4'h3);//Clear cntr before retrieving data from memory

            mem_addr = {actual_tag, addr_internal[9:2], cntr[1:0], 1'b0};
            mem_wr = 1'b1;
            mem_data_in = cache_data_out;

            cache_addr = {addr_internal[15:3], next_cnt[1:0], 1'b0};
            
            cache_rd = 1'b1;
            cache_comp = 1'b0;


            next_state = (cntr == 4'h3) ? 4'b0110 : 4'b0101;   //If done with 4 writes get new data from mem
         end

         //Retrieve line from memory 
         4'b0110: begin
            inc_cntr = 1'b1;
            mem_addr = {addr_internal[15:2], cntr[1:0], 1'b0};
            mem_rd = 1'b1;

            
            cache_data_in = mem_data_out; 
            cache_addr = {addr_internal[15:2], cntr[2], cntr[0], 1'b0}; //im so fucking smart
            cache_wr = (|cntr[3:1]);   //if in second cycle or later then we are writing to cache


            next_state = (cntr == 4'h5) ? 4'b0111 : 4'b0110;   //If done with 4 retrieves then move to MISS Request
         end

         //MISS Request and Return
         4'b0111: begin
            cache_addr = addr_internal;
            cache_rd = 1;

            next_state = 4'b1000;   //Proceed to MISS return (4'b1000)
         end
         4'b1000: begin
            Done = 1;
            data_out = cache_data_out;

            next_state = 4'b0000;   //Return to IDLE
         end

         // ST/ RETRIEVE
         4'b1000: begin

            

            next_state = 4'b0000;   //Return to IDLE
         end


         default: 
            next_state = 4'b0000;

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
