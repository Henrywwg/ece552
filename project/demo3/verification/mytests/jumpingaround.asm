lbi r1, 1 //r1 = 0x7F
lbi r2, 10
lbi r3, 1

slbi r1, 255 //r1 = (0x7F << 8) + 0xFF = 0x7FFF



.ohwoah:
	BLTZ r1, .wowzas
	SUB r1, r3, r1
	ADD r2, r2, r2
	ST r2, r1, 0
	J .ohwoah

.wowzas:
halt
halt
halt
halt


