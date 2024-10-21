/* 
 * Title:   decode_tb
 * Descr:   Testbench decode
 * Author:  Henry Wysong-Grass
 * Date:    2024-10-20
 */

module decode_tb();
    
    ////////////
    //STIMULUS//
    ////////////
    reg clk; 
    reg rst;
    reg [15:0]instruction;

    wire [2:0]write_reg;
    wire [15:0]write_data;


    //Output signals (to monitor)
    //PC sigs
    wire  immSrc;
    wire  ALUJump;
 
    //ALU sigs
    wire  InvA;
    wire  InvB;
    wire  Cin;
    wire  sign;
    wire  [2:0]brType;
    wire  [3:0]Oper;
    wire  [1:0]BSrc;
 
    //Reg sigs
    wire  [2:0]RegDst, RegSrc;
 
    //Memory sig
    wire  MemWrt;
 
    //Sign extend s
    wire  [15:0]five_extend, eight_extend, eleven_extend;
 
    //Register s
    wire  [15:0]R1, R2;
 
    //Error flag
    wire  err;


    


    decode iD (.clk(clk), .rst(rst), .err(error_decode), .instruction(instruction), 
    .write_reg(write_reg), .write_data(write_data), .immSrc(immSrc), .ALUJump(ALUJump), .MemWrt(MemWrt),
    .InvA(InvA), .InvB(InvB), .Cin(Cin), .sign(sign), .brType(brType), .BSrc(BSrc), .Oper(Oper), 
    .RegDst(RegDst), .RegSrc(RegSrc), .five_extend(five_extend), .eight_extend(eight_extend), 
    .eleven_extend(eleven_extend), .R1(R1), .R2(R2));


    initial begin
        clk = 0;
		rst = 1;

        //Initial test is NOP
        instruction = 16'b0000_1000_0001_0000;

        repeat(2)@(negedge clk);
        rst = 0;

        repeat(2)@(negedge clk);
        
        
        /////////
        // NOP //
        /////////
            $display("Testing NOP");
            //Check sign extension is rudimentarily working
            if((five_extend !== 16'hFFF0) || (eight_extend != 16'h0010) || (eleven_extend != 16'h0010))
                $display("ERROR: Extended values do not match expected");

            //Check control signals match expected.
            if(
            (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 
            (InvA !== InvB !== 1'b0) || (Cin !== 1'b0)      || 
            (sign !== 1'b0) ||          (brType !== 3'b000) || 
            (Oper !== 4'b0000) ||      (BSrc !== 2'b00)    ||
            (RegDst !== 2'b00) ||       (RegSrc !== 2'b00)  ||
            (MemWrt !== 1'b0))
                $display("ERROR: Output signals do not match expected. Dumping all values...
                        \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                        \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                        immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);

            else
                $display("NOP Passed (1/38)");


        //////////
        // ADDI //
        //////////
            $display("Testing ADDI");
            @(negedge clk);
            instruction = 16'b0100_0000_0001_1000;
            @(negedge clk);
            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'hFFF8)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 
                (InvA !== InvB !== 1'b0) || (Cin !== 1'b0)      || 
                (sign !== 1'b1) ||          (brType !== 3'b000) || 
                (Oper !== 4'b0100) ||      (BSrc !== 2'b01)    ||
                (RegDst !== 2'b01) ||       (RegSrc !== 2'b10)  ||
                (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else
                    $display("ADDI Passed (2/38)");


        //////////
        // SUBI //
        //////////
            $display("Testing SUBI");
            @(negedge clk);        
            instruction = 16'b0100_1000_0000_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0008)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b1) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b1)      ||      (sign !== 1'b1) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0100) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("ADDI Passed (3/38)");

        //////////
        // XORI //
        //////////
            $display("Testing XORI");
            instruction = 16'b0101_0000_0001_1000;

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0018)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b0) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0111) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("XORI Passed (4/38)");



        ///////////
        // ANDNI //
        ///////////
            $display("Testing ANDNI");
            @(negedge clk);
            instruction = 16'b0101_1000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0018)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b1)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b0) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0101) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("ANDNI Passed (5/38)");



        ///////////
        // ROLI  //
        ///////////
            $display("Testing ROLI");
            @(negedge clk);
            instruction = 16'b1010_0000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0018)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b0) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0000) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("ROLI Passed (6/38)");

        ///////////
        // SLLI  //
        ///////////
            $display("Testing SLLI");
            @(negedge clk);
            instruction = 16'b1010_1000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0018)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b0) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0001) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("SLLI Passed (7/38)");


        ///////////
        // RORI  //
        ///////////
            $display("Testing RORI");
            @(negedge clk);
            instruction = 16'b1011_0000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0018)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b1)     ||
                (Cin !== 1'b1)      ||      (sign !== 1'b0) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0000) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("RORI Passed (8/38)");



        ///////////
        // SRLI  //
        ///////////
            $display("Testing SRLI");
            @(negedge clk);
            instruction = 16'b1011_1000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0018)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b1) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0011) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("SRLI Passed (9/38)");


        ////////
        // ST //
        ////////
            $display("Testing ST");
            @(negedge clk);
            instruction = 16'b1000_0000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'hFFF8)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b1) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0100) ||      
                (BSrc !== 2'b01)    ||      (RegDst == 2'bXX) ||       
                (RegSrc == 2'bXX)  ||      (MemWrt !== 1'b1))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("ST Passed (10/38)");



        /////////
        // LD  //
        /////////
            $display("Testing LD");
            @(negedge clk);
            instruction = 16'b1000_1000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'hFFF8)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b1) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0100) ||      
                (BSrc !== 2'b01)    ||      (RegDst !== 2'b01) ||       
                (RegSrc !== 2'b01)  ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("LD Passed (11/38)");

        /////////
        // STU //
        /////////
            $display("Testing STU");
            @(negedge clk);
            instruction = 16'b1000_0000_0001_1000;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'hFFF8)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                (InvA !== 1'b0) ||          (InvB !== 1'b0)     ||
                (Cin !== 1'b0)      ||      (sign !== 1'b1) ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0100) ||      
                (BSrc !== 2'b01)    ||      (RegDst == 2'b00) ||       
                (RegSrc == 2'b10)  ||      (MemWrt !== 1'b1))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("STU Passed (12/38)");


        ///////////////////////////////////////
        //IMMEDIATE INSTRUCTIONS DONE TESTING//
        ///////////////////////////////////////
            //////////
            // BTR  //          NOTE:STILL NEEDS TO BE IMPLEMENTED
            //////////
                $display("Testing BTR");
                @(negedge clk);
                instruction = 16'b11001_000_0000_0000;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0000)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b11)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("BTR Passed (13/38)");



            //////////
            // ADD  //
            //////////
                $display("Testing ADD");
                @(negedge clk);
                instruction = 16'b11011_000_0000_0000;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0000)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b1)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("ADD Passed (14/38)");


            //////////
            // SUB  //       
            //////////
                $display("Testing SUB");
                @(negedge clk);
                instruction = 16'b11011_000_0000_0001;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0001)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc !=1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b1)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b1)      ||      (sign !== 1'b1)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SUB Passed (15/38)");


            //////////
            // XOR  //       
            //////////
                $display("Testing XOR");
                @(negedge clk);
                instruction = 16'b11011_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0111) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("XOR Passed (16/38)");


            //////////
            // ANDN //       
            //////////
                $display("Testing ANDN");
                @(negedge clk);
                instruction = 16'b11011_000_0000_0011;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0003)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b1)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0101) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("ANDN Passed (17/38)");



            /////////
            // ROL //       
            /////////
                $display("Testing ROL");
                @(negedge clk);
                instruction = 16'b11010_000_0000_0000;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0000)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0000) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("ROL Passed (18/38)");

            /////////
            // SLL //       
            /////////
                $display("Testing SLL");
                @(negedge clk);
                instruction = 16'b11010_000_0000_0001;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0000)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0001) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SLL Passed (19/38)");




            /////////
            // ROR //       
            /////////
                $display("Testing ROR");
                @(negedge clk);
                instruction = 16'b11010_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b1)     ||
                    (Cin !== 1'b1)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0000) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("ROR Passed (20/38)");


            /////////
            // SRL //       
            /////////
                $display("Testing SRL");
                @(negedge clk);
                instruction = 16'b11010_000_0000_0011;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0011) ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SRL Passed (21/38)");



        ///////////////////////
        // VALUE COMPARISONS //
        ///////////////////////
            /////////
            // SEQ //       
            /////////
                $display("Testing SEQ");
                @(negedge clk);
                instruction = 16'b11100_000_0000_0000;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0000)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b1)     ||
                    (Cin !== 1'b1)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b1100)  ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SEQ Passed (22/38)");

            /////////
            // SLT //       
            /////////
                $display("Testing SLT");
                @(negedge clk);
                instruction = 16'b11101_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b1)     ||
                    (Cin !== 1'b1)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b1100)  ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SLT Passed (23/38)");

            /////////
            // SLE //       
            /////////
                $display("Testing SLE");
                @(negedge clk);
                instruction = 16'b11110_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b1)     ||
                    (Cin !== 1'b1)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b1100)  ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SLE Passed (24/38)");

            /////////
            // SCO //       
            /////////
                $display("Testing SCO");
                @(negedge clk);
                instruction = 16'b11111_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)  || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b1100)  ||      
                    (BSrc !== 2'b00)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc !== 2'b10)  ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SCO Passed (25/38)");


        /////////////////////////
        // BRANCH INSTRUCTIONS //
        /////////////////////////

            //////////
            // BEQZ //       
            //////////
                $display("Testing BEQZ");
                @(negedge clk);
                instruction = 16'b01100_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b100) ||      (Oper !== 4'b0100)  ||      //brType: branch if MSB is 1, LSBs gives type - Comparison: Check if Rs == 0
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc == 2'bxx)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("BEQZ Passed (26/38)");



            //////////
            // BNEZ //       
            //////////
                $display("Testing BNEZ");
                @(negedge clk);
                instruction = 16'b01101_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b101) ||      (Oper !== 4'b0100)  ||      //brType: branch if MSB is 1, LSBs gives type - Comparison: Check if Rs == 0
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc == 2'bxx)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("BNEZ Passed (27/38)");

            //////////
            // BLTZ //       
            //////////
                $display("Testing BLTZ");
                @(negedge clk);
                instruction = 16'b01110_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||
                    (Cin !== 1'b0)      ||      (sign !== 1'b1)     ||          
                    (brType !== 3'b110) ||      (Oper !== 4'b0100)  ||      //brType: branch if MSB is 1, LSBs gives type - Comparison: Check if Rs == 0
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc == 2'bxx)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("BLTZ Passed (28/38)");


            //////////
            // BGEZ //       
            //////////
                $display("Testing BGEZ");
                @(negedge clk);
                instruction = 16'b01111_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                    (Cin !== 1'b0)      ||      (sign !== 1'b1)     ||          
                    (brType !== 3'b111) ||      (Oper !== 4'b0100)  ||      //brType: branch if MSB is 1, LSBs gives type - Comparison: Check if Rs == 0
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc == 2'bxx)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("BGEZ Passed (29/38)");

        ///////////////
        // xLBI INST //
        ///////////////
            //////////
            // LBI //       
            //////////
                $display("Testing LBI");
                @(negedge clk);
                instruction = 16'b11000_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100)  ||      //brType: branch if MSB is 1, LSBs gives type - Comparison: Check if Rs == 0
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b10)  ||       
                    (RegSrc == 2'b11)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("LBI Passed (30/38)");

            //////////
            // SLBI //       
            //////////
                $display("Testing SLBI");
                @(negedge clk);
                instruction = 16'b10010_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100)  ||      //brType: branch if MSB is 1, LSBs gives type - Comparison: Check if Rs == 0
                    (BSrc !== 2'b11)    ||      (RegDst !== 2'b00)  ||       
                    (RegSrc == 2'b11)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("SLBI Passed (31/38)");




        ///////////////
        // JUMP INST //
        ///////////////
            //////////
            // J //       
            //////////
                $display("Testing J");
                @(negedge clk);
                instruction = 16'b00100_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b1) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100)  ||      //TODO: ADD A WAY FOR BRCHCND TO SET TkBrch IF A J COMMAND IS ISSUED
                    (BSrc !== 2'b11)    ||      (RegDst !== 2'b00)  ||       
                    (RegSrc == 2'b11)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("J Passed (32/38)");

            //////////
            // JR //       
            //////////
                $display("Testing JR");
                @(negedge clk);
                instruction = 16'b00101_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b1)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100)  ||      //TODO: ADD A WAY FOR BRCHCND TO SET TkBrch IF A J COMMAND IS ISSUED
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b00)  ||       
                    (RegSrc == 2'b11)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("JR Passed (33/38)");

            //////////
            // JAL //       
            //////////
                $display("Testing JAL");
                @(negedge clk);
                instruction = 16'b00110_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b1) ||        (ALUJump !== 1'b0)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100)  ||      //TODO: ADD A WAY FOR BRCHCND TO SET TkBrch IF A J COMMAND IS ISSUED
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b11)  ||       
                    (RegSrc == 2'b00)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("JAL Passed (34/38)");

            //////////
            // JALR //       
            //////////
                $display("Testing JALR");
                @(negedge clk);
                instruction = 16'b00110_000_0000_0010;
                @(negedge clk);

                //Check we are getting a 5 bit extended value
                if(five_extend !== 16'h0002)
                    $display("ERROR: Extended values do not match expected");

                    //Check control signals match expected.
                if(
                    (immSrc != 1'b0) ||        (ALUJump !== 1'b1)   || 

                    (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                    (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                    (brType !== 3'b000) ||      (Oper !== 4'b0100)  ||      //TODO: ADD A WAY FOR BRCHCND TO SET TkBrch IF A J COMMAND IS ISSUED
                    (BSrc !== 2'b10)    ||      (RegDst !== 2'b11)  ||       
                    (RegSrc == 2'b00)   ||      (MemWrt !== 1'b0))
                        $display("ERROR: Output signals do not match expected. Dumping all values...
                                \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                                \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                                immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
            
                else    $display("JALR Passed (35/38)");


        //////////
        // HALT //
        //////////
            $display("Testing HALT");
            @(negedge clk);
            instruction = 16'b00110_000_0000_0010;
            @(negedge clk);

            //Check we are getting a 5 bit extended value
            if(five_extend !== 16'h0002)
                $display("ERROR: Extended values do not match expected");

                //Check control signals match expected.
            if(
                (immSrc != 1'b0) ||        (ALUJump !== 1'b0)   || 

                (InvA !== 1'b0)     ||      (InvB !== 1'b0)     ||      
                (Cin !== 1'b0)      ||      (sign !== 1'b0)     ||          
                (brType !== 3'b000) ||      (Oper !== 4'b0100)  ||    
                (BSrc !== 2'b00)    ||      (RegDst !== 2'b00)  ||       
                (RegSrc == 2'b00)   ||      (MemWrt !== 1'b0))
                    $display("ERROR: Output signals do not match expected. Dumping all values...
                            \n immSrc: %b\n ALUJump: %b\n InvA, InvB: %b, %b\n Cin: %b\n brType %b
                            \n Oper: %b\n BSrc: %b\n RegDst, RegSrc: %b, %b\n MemWrt: %b\n",
                            immSrc, ALUJump, InvA, InvB, Cin, sign, brType, Oper, BSrc, RegDst, RegSrc, MemWrt);
        
            else    $display("HALT Passed (36/38)");

        $exit();
    end

    always
        #5 clk <= ~clk;



endmodule
