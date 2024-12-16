/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

`default_nettype none
module mem_system_sc(/*AUTOARG*/
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
      reg [15:0] cache_data_in;
      reg [15:0] cache_addr;
      reg cache_comp;
      reg toggle_victim_way;
      reg cache_rd;
      reg cache_wr;

      reg en_v_reg;


      //Signals for internal registers
      wire [15:0] addr_internal;
      wire [15:0] data_internal;
      reg        en_int_reg;
      reg        clr_int_reg;

      reg        inc_cntr;
      reg        clr_cntr;

      wire [3:0] state;
      reg  [3:0] next_state;

      //Internal registers hold data given by the CPU in case this data changes while the cache is operating
      dff requested_addr_reg[15:0](.q(addr_internal), .d(en_int_reg ? Addr : addr_internal), .clk(clk), .rst(rst));
      dff given_data_reg[15:0](.q(data_internal), .d(en_int_reg ? DataIn : data_internal), .clk(clk), .rst(rst));

      //Counter for storing and loading from imperfect memory
      wire [3:0]  cntr, next_cnt;   //counter for store and load from mem
      dff three_bit_cntr[3:0](.q(cntr), .d(inc_cntr ? next_cnt : cntr), .clk(clk), .rst(clr_cntr));
      cla_4b cntr_inc(.sum(next_cnt), .a(cntr), .b(4'h1), .c_out(/*Unused*/), .c_in(1'b0));

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
      wire c0_valid_raw, c0_dirty_raw, c0_hit_raw, c0_err;
      wire c1_valid_raw, c1_dirty_raw, c1_hit_raw, c1_err;
      wire [4:0] c0_tag_out, c1_tag_out;
      wire [15:0] c0_data_out, c1_data_out;

      //////////////////////////////////////////////////////////////////////////////////////////////////////////
      // assigned signals
      reg c0_en, c1_en;
      wire victim;
      wire cache_valid;
      wire real_hit;
      wire victimize;
      wire [4:0] actual_tag;
      wire [15:0] cache_data_out;

      // Flags
      wire c0_FLAG, c1_FLAG;

      assign cache_valid = cache_wr & ~cache_comp;

      assign real_hit = ((c0_hit_raw & c0_valid_raw) | (c1_hit_raw & c1_valid_raw));// & (Rd | Wr);

      assign victimize = ((c0_dirty_raw & ~c0_hit_raw) | (c1_dirty_raw & ~c1_hit_raw)) & (c0_valid_raw & c1_valid_raw);

      assign actual_tag =  (c0_tag_out == cache_addr[15:11])   ? c0_tag_out : 
                           ((c1_tag_out == cache_addr[15:11])  ? c1_tag_out : (
                              victim ? c1_tag_out : c0_tag_out));


      assign cache_data_out = (c0_tag_out == cache_addr[15:11])   ? c0_data_out : 
                              ((c1_tag_out == cache_addr[15:11])  ? c1_data_out : (
                              victim ? c1_data_out : c0_data_out));

      //////////////////////////////////////////////////////////////////////////////////////////////////////////
      // victim automatically selects cache to use during eviction
      dff victim_FF (.q(victim), .d(toggle_victim_way ? ~victim : victim), .clk(clk), .rst(rst));

      //Flag reg
      dff FLAG1 (.q(c0_FLAG), .d(en_v_reg ? c0_valid_raw : c0_FLAG), .clk(clk), .rst(rst));
      dff FLAG2 (.q(c1_FLAG), .d(en_v_reg ? c1_valid_raw : c1_FLAG), .clk(clk), .rst(rst));


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
   
////////////////////////////////////
   // State machine sequential logic //
   ////////////////////////////////////
      //Assign next/current states
      dff state_ff[3:0](.q(state), .d(next_state), .clk(clk), .rst(rst));

   //////////////////////////
   // Combination SM logic //
   //////////////////////////
      always @(*) begin
      //Default signals to prevent latches
      Done = 1'b0;
      Stall = 1'b1;
      CacheHit = 1'b0;
      DataOut = 16'h0800;
      next_state = state;
      inc_cntr = 1'b0;
      clr_cntr = 1'b0;
      clr_int_reg = 1'b0;
      en_int_reg = 1'b0;
      cache_comp = 1'b0;
      mem_data_in = 16'h0000;
      mem_addr = 16'h0000;
      cache_addr = 16'h0000;
      mem_read = 1'b0;
      mem_write = 1'b0;
      cache_data_in = 16'h0000;
      cache_rd = 1'b0;
      cache_wr = 1'b0;
      toggle_victim_way = 1'b0;
      c0_en = 1'b0;
      c1_en = 1'b0;  
      en_v_reg = 1'b0;

      case(state)

         ///////////////////////
         // IDLE (reset here) //
         ///////////////////////
         4'b0000: begin
            //Don't stall in IDLE - we want new requests!
            Stall = ~real_hit & (Rd | Wr);
			   en_v_reg = 1'b1; //Clear register
            //Ensure counters are ready for rd/wr  
            clr_cntr = 1'b1;
            cache_rd = 1'b1;

            //Store Addr internally in case CPU changes it
            en_int_reg = 1'b1;


            // Use our internal signals to
            // do a compare read.
            toggle_victim_way = Rd | Wr;
            cache_addr = addr_internal;
            cache_comp = 1'b1;

            c0_en = 1'b1;
            c1_en = 1'b1;

            // On hit set outputs
            Done = real_hit;
            CacheHit = real_hit;
            DataOut = cache_data_out;

            cache_wr = Wr;
            cache_rd = Rd;

            cache_data_in = data_internal;


            //Victimized determines next state (disregarding a hit)
            next_state =   real_hit ? 4'b0000 : (
                           Rd ? (victimize ? 4'b1001 : 4'b1010 ) : (
                           Wr ? (victimize ? 4'b0101 : 4'b0110): 4'b0000));
         end

         ///////////////////
         // rd BASE STATE //
         ///////////////////
         4'b0001: begin
            Done = 1'b1;
            next_state = 4'b0000;
         end

         ///////////////////////////
         // MEMORY WRITEBACK (rd) //
         ///////////////////////////
         4'b0101: begin
            //Stop counter at 3
            inc_cntr = (cntr != 4'h3);
            clr_cntr = (cntr == 4'h3); //Clear cntr bwhen it stops so its ready for next step

            mem_addr = {actual_tag, addr_internal[10:3], cntr[1:0], 1'b0};
            mem_write = 1'b1;
            mem_data_in = cache_data_out;

            c0_en = ~victim;
            c1_en =  victim;

            cache_addr = {addr_internal[15:3], cntr[1:0], 1'b0};
            
            cache_rd = 1'b1;

            next_state = (cntr == 4'h3) ? 4'b0110 : 4'b0101;   //If done with 4 writes get new data from mem
         end

         /////////////////////////////////////////
         // READ MEM-'LINE' WRITE TO CACHE (rd) //
         /////////////////////////////////////////
         4'b0110: begin
            inc_cntr = 1'b1;
            mem_addr = {addr_internal[15:3], cntr[1:0], 1'b0};
            mem_read = ~|cntr[3:2];

            c0_en = (~c0_FLAG          )? 1'b1 : ~victim & c0_FLAG & c1_FLAG;
            c1_en = (c0_FLAG & ~c1_FLAG)? 1'b1 : victim & c0_FLAG & c1_FLAG;
            
            cache_data_in = mem_data_out; 
            cache_addr = {addr_internal[15:3], cntr[2], cntr[0], 1'b0}; //im so fucking smart
            cache_wr = (|cntr[3:1]);   //if in second cycle or later then we are writing to cache


            next_state = (cntr == 4'h5) ? 4'b0111 : 4'b0110;   //If done with 4 retrieves then move to MISS Request
         end

         //////////////////////////
         // READ AND RETURN (rd) //
         //////////////////////////
         4'b0111: begin
            //Do access read
            cache_addr = addr_internal;
            cache_rd = 1;

            c0_en = (          ~c0_FLAG)? 1'b1 : ~victim & c0_FLAG & c1_FLAG;
            c1_en = (c0_FLAG & ~c1_FLAG)? 1'b1 : victim & c0_FLAG & c1_FLAG;

            //Done now -> IDLE
            DataOut = cache_data_out;
            Done = 1;
            
            next_state = 4'b0000;   
         end

         ////////////////////////////
         //    END OF rd STATES    //
         // BEGINNING OF wr STATES //
         ////////////////////////////

         ///////////////////
         // wr BASE STATE //
         ///////////////////
         4'b0100: begin
            //Toggle victim way
            toggle_victim_way = 1'b1;

            c0_en = 1'b1;
            c1_en = 1'b1;
            en_v_reg = 1'b1;

            // Do compare write
            cache_comp = 1'b1;
            cache_wr = 1'b1;

            cache_addr = addr_internal;
            cache_data_in = data_internal;

            // On hit we're done - return to IDLE
            Done = real_hit;
            CacheHit = real_hit;

            //Victimized determines next state (disregarding a hit)
            next_state =   real_hit ? 4'b0000 : (
                           victimize ? 4'b1001 : 4'b1010 );
         end

         ///////////////////////////
         // MEMORY WRITEBACK (wr) //
         ///////////////////////////
         4'b1001: begin
            c0_en = ~victim;
            c1_en = victim;

            inc_cntr = (cntr != 4'h3);
            clr_cntr = (cntr == 4'h3);//Clear cntr before retrieving data from memory

            cache_addr = {addr_internal[15:3], cntr[1:0], 1'b0};
            cache_rd = 1'b1;

            mem_addr = {actual_tag, addr_internal[10:3], cntr[1:0], 1'b0};
            mem_write = 1'b1;
            mem_data_in = cache_data_out;

            next_state = (cntr == 4'h3) ? 4'b1010 : 4'b1001;   //If done with 4 writes get new data from mem
         end

         /////////////////////////////////////////
         // READ MEM-'LINE' WRITE TO CACHE (wr) //
         /////////////////////////////////////////
         4'b1010: begin 
            inc_cntr = 1'b1; //mem_busy[];
            mem_addr = {addr_internal[15:3], cntr[1:0], 1'b0};
            mem_read = ~|cntr[3:2];


            c0_en = (~c0_FLAG          )? 1'b1 :~victim & c0_FLAG & c1_FLAG;
            c1_en = (c0_FLAG & ~c1_FLAG)? 1'b1 : victim & c0_FLAG & c1_FLAG;
            
            cache_data_in = mem_data_out; 
            cache_addr = {addr_internal[15:3], cntr[2], cntr[0], 1'b0}; //im so fucking smart
            cache_wr = (|cntr[3:1]);   //if in second cycle or later then we are writing to cache

            next_state = (cntr == 4'h5) ? 4'b1011 : 4'b1010;   //If done with 4 retrieves then move to MISS Write and return
         end

         ///////////////////////////
         // WRITE AND RETURN (wr) //
         ///////////////////////////
         4'b1011: begin
            // Do compare write of the CPU data
            // to set dirty bit 
            // NOTE: (This dirty little POS took me 4 hours to fix ~ Henry ^w^)

            c0_en = (~c0_FLAG          )? 1'b1 :~victim & c0_FLAG & c1_FLAG;
            c1_en = (c0_FLAG & ~c1_FLAG)? 1'b1 : victim & c0_FLAG & c1_FLAG;

            cache_addr = addr_internal;
            cache_data_in = data_internal;
            cache_wr = 1'b1;
            cache_comp = 1'b1;
            Done = 1'b1;

            next_state = 4'b0000;   //Proceed to IDLE write (4'b1100)
         end

         /////////////////////
         // DEFAULT TO IDLE //
         /////////////////////
         default: 
            next_state = 4'b0000;

      endcase
   end


   /////////////////
   // ERROR LOGIC //
   /////////////////
   always @(*) begin
      err = 1'b0;
      case({c1_err, c0_err, mem_err})
         3'b000: 
            err = 1'b0;
         default:
            err = Rd | Wr;
      endcase
   end

   


   
endmodule // mem_system
`default_nettype wire
// DUMMY LINE FOR REV CONTROL :9:
