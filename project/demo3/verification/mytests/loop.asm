lbi r0, 5
lbi r1, 10          // r1 = 10
.loop1:
addi r1, r1, 3      // r1 = 13,16,19,22,25
addi r0, r0, -1
bnez r0, .loop1
HALT
