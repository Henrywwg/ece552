//Silly.asm
// test 
lbi r1, 10
lbi r2, 1
lbi r3, 0 
btr r2, r2

slbi r2, 69

st r2, r3, 0	//mem[0] = R2

add r1, r1, r1 //Ensure NOP works correctly 
add r2, r1, r3 //by making a bunch of RAWs
add r3, r1, r2

J 2

add, r2, r2, r2 //This should be skipped

ld r2, r3, 0

add r1, r1, r1 //A few more fun instructions
add r3, r1, r2 //on the way out



rori r1, r1, 8
rori r1, r1, 8
rori r1, r1, 0
rori r2, r2, 0
andni r1, r1, 0
	





halt
