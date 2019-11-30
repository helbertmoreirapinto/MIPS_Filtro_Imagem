.data
	f_in:	.asciiz "in.pgm"	# File IN
	f_out:	.asciiz "out.pgm"	# File OUT
	opc:	.word 0				# Opcao menu
	menu0:	.asciiz "Selecione"
	menu1:	.asciiz "[1]Filtro 1"
	menu2:	.asciiz "[2]Filtro 2"
	menu3:	.asciiz "[3]Filtro 3"
	buffer:	.space 0x19000		#100 kBytes -> 100 * 1024 = 102400

.text
.globl main

main:
	# Open File IN [Read]
	li $v0 0x0D		# system call for open file
	la $a0 f_in		# input file name
	li $a1 0x00		# flag for reading
	li $a2 0x00		# mode is ignored
	syscall			# open file
	move $s0 $v0
	
	# Open File OUT [Write]
	#li $v1 0x0D		# system call for open file
	#la $a0 f_in		# input file name
	#li $a1 0x01		# flag for writing
	#li $a2 0x00		# mode is ignored
	#syscall			# open file
	#move $s1 $v1

	# Buffer
	li $v0 0x0E		# system call for reading from file
	move $a0 $s0	# file descriptor
	la $a1 buffer   # address of buffer from which to read
	li $a2 0x19000	# hardcoded buffer length
	syscall
	
	# Close File IN
	li $v0 0x11		# system call for close file
	move $a0 $s6	# file descriptor to close
	syscall
	
	# Close File OUT
	#li $v1 0x11	# system call for close file
	#move $a0 $s6	# file descriptor to close
	#syscall
	
	# End Program
	li $v0 0x0A
	syscall 




