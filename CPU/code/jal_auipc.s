.org 0x0
.global _start

_start:

# ================== Test for cmp ops =======================
	lui x1,0xffff0		# x1 				= 0xffff0000
	slt x2, x1, x0		# x2				= 1		notice: signed
	sltu x2, x1, x0		# x2				= 0		notice: unsigned
	lui x1, 0x00001		# x1				= 0x00001000
	slti x3, x1, -0x800	# x3				= 0		notice: signed
	sltiu x3, x1, -0x800 # x3				= 1		notice: signed extend and unsigned comparation




