.data
	f_in:		.asciiz "in.pgm"	# File IN
	f_out:		.asciiz "out.pgm"	# File OUT
	menu_p:		.asciiz "Filtros de Imagem\n[1]Filtro x\n[2]Filtro y\n[3]Filtro z\n[0]Sair\nSelecione: "
	new_line:	.word 0x0A
	cont_xbyte:	.word 0
	cont_ybyte:	.word 0
	val_byte:	.space 0x04
	temp:		.space 0x01
	buffer:		.space 0x00019000		#100kBytes -> 100 * 1024 = 102400
	
.text
.globl main

main:

	# Open File IN [Read]
	li $v0 0x0D		# system call for open file
	la $a0 f_in		# input file name
	li $a1 0x00		# flag for read
	li $a2 0x00		# mode is ignored
	syscall			# open file
	move $k0 $v0	# K0 -> File IN
	
	# Check sucess open File IN
	beq $s0 0xFFFFFFFF END_PROGRAM
	
	# Open File OUT [Write]
	li $v0 0x0D		# system call for open file
	la $a0 f_out	# input file name
	li $a1 0x01		# flag for write
	li $a2 0x00		# mode is ignored
	syscall			# open file
	move $k1 $v0	# K1 -> File OUT
	
	beq $s1 0xFFFFFFFF END_PROGRAM
	
	# Step header File IN
	lw $t0 new_line
	li $t3 0x00
LOOP_CHAR:
	li $v0 0x0E		# system call for reading from file
	move $a0 $k0	# file descriptor
	la $a1 temp		# address of buffer from which to read
	li $a2 0x01		# read 01 byte (char)
	syscall			# read file
	lw $t1 temp
	bne $t0 $t1 LOOP_CHAR	# Check if char is <ENTER>
	addi $t3 0x01			# Inc cont '\n' <ENTER>
	bne $t3 0x02 LOOP_CHAR	# Step 02 '\n' <ENTER>

	# int x <- ler ate espaco
	# int y <- ler ate espaco
	
	# Buffer
	li $v0 0x0E		# system call for reading from file
	move $a0 $k0	# file descriptor
	la $a1 buffer   # address of buffer from which to read
	li $a2 0x19000	# hardcoded buffer length
	syscall
	
	# MENU
	# Print menu_p in console
	li $v0 0x04		# system call for print string
	la $a0 menu_p	# select string
	syscall			# print string
	
	# Get int keyboard
	li $v0 0x05	# system call for get int keyboard
	syscall		# get int keyboard
	
	# Select filter
	beq $v0 0x01 FILTRO_1
	beq $v0 0x02 FILTRO_2
	beq $v0 0x03 FILTRO_3
	beq $v0 $zero END_PROGRAM
	
FILTRO_1:
	# Filter 1 - x
	# Write File OUT
    move $a0 $k1	# Syscall 15 requieres file descriptor in $a0
    li $v0 0x0F
    la $a1 teste
    la $a2 0x01
    syscall
	j CLOSE_FILE
	
FILTRO_2:
	# Filter 2 - y
	j CLOSE_FILE
	
FILTRO_3:
	# Filter 3 - z
	j CLOSE_FILE

CLOSE_FILE:
	# Close File IN
	li $v0 0x11		# system call for close file
	move $a0 $k0	# file descriptor to close
	syscall
	
	# Close File OUT
	li $v0 0x11		# system call for close file
	move $a0 $k1	# file descriptor to close
	syscall

END_PROGRAM:
	# End Program
	li $v0 0x0A
	syscall




