.data
	f_in:		.asciiz "in.pgm"	# File IN
	f_out:		.asciiz "out.pgm"	# File OUT
	menu_p:		.asciiz "Filtros de Imagem\n[1]Filtro x\n[2]Filtro y\n[3]Filtro z\n[0]Sair\nSelecione: "
	new_line:	.word 0x0A
	tamX_pic:	.word 0
	tamY_pic:	.word 0
	val_byte:	.space 0x04
	temp:		.space 0x01
	buffer:		.space 0x00019000	#100kBytes -> 100 * 1024 = 102400

.text
.globl main

main:

	# Open File IN [Read]
	li $v0 0x0D	# system call for open file
	la $a0 f_in	# input file name
	li $a1 0x00	# flag for read
	li $a2 0x00	# mode is ignored
	syscall		# open file
	move $k0 $v0	# K0 -> File IN
	
	# Check sucess open File IN
	beq $s0 0xFFFFFFFF END_PROGRAM
	
	# Open File OUT [Write]
	li $v0 0x0D	# system call for open file
	la $a0 f_out	# input file name
	li $a1 0x01	# flag for write
	li $a2 0x00	# mode is ignored
	syscall		# open file
	move $k1 $v0	# K1 -> File OUT
	
	beq $s1 0xFFFFFFFF END_PROGRAM
	
	# Step header File IN
	lw $t0 new_line
	li $t3 0x00
LOOP_ENTER:
	li $v0 0x0E
	move $a0 $k0
	la $a1 temp
	li $a2 0x01
	syscall
	lw $t1 temp
	bne $t0 $t1 LOOP_ENTER	# Check if char is '\n'
	addi $t3 0x01			# Inc cont '\n'
	bne $t3 0x02 LOOP_ENTER	# Step 02 '\n'

	# Save X and Save Y
	li $t0 0x20		# Space 0x20 32 ' '
	li $t3 0x00
SAVE_RANGE:
	la $t4 val_byte
LOOP_RANGE:
	li $v0 0x0E		# system call for reading from file
	move $a0 $k0	# file descriptor
	la $a1 temp		# address of buffer from which to read
	li $a2 0x01		# read 01 byte (char)
	syscall			# read file
	lw $t1 temp
	beq $t0 $t1 SAVE_X	# Check if char is space
	sb $t1 ($t4)
	addi $t4 0x01
	j LOOP_RANGE

SAVE_X:
	addi $t3 0x01
	beq $t3 0x02 SAVE_Y
	lw $t0 new_line
	# x <- val_byte
	la $a0 val_byte
	jal STRING_TO_INT
	sw $v0 tamX_pic
	j SAVE_RANGE
	
SAVE_Y:
	# y <- val_byte
	la $a0 val_byte
	jal STRING_TO_INT
	sw $v0 tamY_pic

	lw $t0 new_line
LOOP_ENTER_2:
	li $v0 0x0E
	move $a0 $k0
	la $a1 temp
	li $a2 0x01
	syscall
	lw $t1 temp
	bne $t0 $t1 LOOP_ENTER_2

	# Buffer
	li $v0 0x0E	# system call for reading from file
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

#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-#
#SUB ROTINA - Converte uma string contendo um numero para int
STRING_TO_INT:
	li $v0 0x00
	li $s0 0x00
	li $s6 0x2F
	li $s7 0x3A
	move $s1 $a0
	
POS_CHAR:
	lb $s5 ($s1)
	slt $s4 $s5 $s6 	# Check < '0'
	beq $s4 0x01 EXIT_LOOP
	slt $s4 $s7 $s5 	# Check > '9'
	beq $s4 0x01 EXIT_LOOP
	addi $s0 0x01	# cont caracteres string
	addi $s1 0x01
	j POS_CHAR
	
EXIT_LOOP:
	move $s1 $a0
	lb $s2 ($s1)
	addi $s2 0xFFFFFFD0
	addi $s0 0xFFFFFFFF
	move $s3 $s0
	
CALC:
	addi $s3 0xFFFFFFFF
	mul $s2 $s2 0x0A
	bnez $s3 CALC
	addu $v0 $v0 $s2
	addi $s0 0xFFFFFFFF
	move $s3 $s0
	beqz $s3 RET
	addi $s1 0x01
	lb $s2 ($s1)
	addi $s2 0xFFFFFFD0
	j CALC
	
RET:
	addi $s1 0x01
	lb $s2 ($s1)
	addi $s2 0xFFFFFFD0
	addu $v0 $v0 $s2
	jr $ra

#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-#
#SUB ROTINA - Converte um int em uma string cujos caracteres e' o int
INT_TO_STRING:
	move $v0 $a0
	move $v1 $a1
	
	li $s0 0x04
	li $s1 0x00
ZERAR:
	sb $s1 ($v0)
	addi $v0 0x01
	addi $s0 0xFFFFFFFF
	bnez $s0 ZERAR
	move $v0 $a0
	
	move $s1 $v1
	li $s0 0x3E8
	div $s1 $s1 $s0
	beqz $s1 DIG0_NULL
	move $s2 $s1
	addi $s1 0x30
	sb $s1 ($v0)
	addi $v0 0x01
DIG0_NULL:
	mul $s1 $s2 0x3E8
	sub $v1 $v1 $s1
	
	move $s1 $v1
	li $s0 0x64
	div $s1 $s1 $s0
	beqz $s1 DIG1_NULL
	move $s2 $s1
	addi $s1 0x30
	sb $s1 ($v0)
	addi $v0 0x01
DIG1_NULL:
	mul $s1 $s2 0x64
	sub $v1 $v1 $s1
	
	move $s1 $v1
	li $s0 0x0A
	div $s1 $s1 $s0
	beqz $s1 DIG2_NULL
	move $s2 $s1
	addi $s1 0x30
	sb $s1 ($v0)
	addi $v0 0x01
DIG2_NULL:
	mul $s1 $s2 0x0A
	sub $v1 $v1 $s1
	
	move $s1 $v1
	addi $s1 0x30
	sb $s1 ($v0)
	
	move $v0 $a0
	jr $ra