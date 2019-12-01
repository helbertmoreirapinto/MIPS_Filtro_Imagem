.data
	f_in:		.asciiz "in.pgm"	# File IN
	f_out:		.asciiz "out.pgm"	# File OUT
	menu_p:		.asciiz "Filtros de Imagem\n[1]Filtro x\n[2]Filtro y\n[3]Filtro z\n[0]Sair\nSelecione: "
	cab:		.asciiz "P2\n# Make by Antonio Sebastian / Helbert Pinto #\n"
	new_line:	.asciiz "\n"
	c_space:	.asciiz " "

	val_byte:	.space 0x04
	temp:		.space 0x01
		
	tamPicX:	.word 0
	tamPicY:	.word 0
	bytesPic:	.word 0
	max_value:	.word 255
	buffer:		.word 0

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
	beq $k0 0xFFFFFFFF END_PROGRAM
	
	# Open File OUT [Write]
	li $v0 0x0D	# system call for open file
	la $a0 f_out	# input file name
	li $a1 0x01	# flag for write
	li $a2 0x00	# mode is ignored
	syscall		# open file
	move $k1 $v0	# K1 -> File OUT
	
	beq $k1 0xFFFFFFFF END_PROGRAM
	
	# Step header File IN
	lb $t0 new_line
	li $t3 0x00
STEP_HREADER:
	li $v0 0x0E
	move $a0 $k0
	la $a1 temp			# Guarda temporariamente em temp o valor do current char
	li $a2 0x01
	syscall				# Le um char
	lb $t1 temp			# Salva o char em t1
	bne $t0 $t1 STEP_HREADER	# Check t0['\n'] != t1[current char]
	addi $t3 $t3 0x01		# Incr cont '\n'
	bne $t3 0x02 STEP_HREADER	# Pular 02 '\n'
	
	la $t1 val_byte
	la $t2 temp
	sub $sp $sp 12
	sw $k0 0($sp)	# File
	sw $t1 4($sp)	# String val_byte
	sw $t2 8($sp)	# Char 
	jal GET_NUM_FILE
	sw $v0 tamPicX

	sub $sp $sp 12
	sw $k0 0($sp)	# File
	sw $t1 4($sp)	# String val_byte
	sb $t2 8($sp)	# Char 
	jal GET_NUM_FILE
	sw $v0 tamPicY
	
	lb $t0 new_line
LOOP_ENTER_2:
	li $v0 0x0E
	move $a0 $k0
	la $a1 temp
	li $a2 0x01
	syscall
	lb $t1 temp
	bne $t0 $t1 LOOP_ENTER_2

	lw $t0 tamPicX
	lw $t2 tamPicY
	mulu $t1 $t0 $t2
	sw $t1 bytesPic
	li $t0 0x00
	la $t2 buffer
	
	la $t3 val_byte
	la $t4 temp
	
INICIAR_BUFFER:
	sub $sp $sp 12
	sw $k0 0($sp)	# File
	sw $t3 4($sp)	# String val_byte
	sw $t4 8($sp)	# Char 
	jal GET_NUM_FILE
	beq $v0 0xFFFFFFFF INICIAR_BUFFER 
	sw $v0 ($t2)
	addi $t2 $t2 0x04
	addi $t0 $t0 0x01
	bne $t0 $t1 INICIAR_BUFFER
	
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
	
	addi $sp $sp -0x0C
	lw $a3 tamPicX
	sw $a3 0($sp)
	lw $a3 tamPicY
	sw $a3 4($sp)
	lw $a3 max_value
	sw $a3 8($sp)
	
	move $a0 $k1
	la $a1 cab
	la $a2 val_byte
	la $a3 c_space
	jal ESCREVE_CAB
    
	
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
	addi $s0 $s0 0x01	# cont caracteres string
	addi $s1 $s1 0x01
	j POS_CHAR
	
EXIT_LOOP:
	move $s1 $a0
	lb $s2 ($s1)
	addi $s2 $s2 0xFFFFFFD0
	addi $s0 $s0 0xFFFFFFFF
	beq $s0 0xFFFFFFFF RET_NULL
	beqz $s0 RET_ZERO
	move $s3 $s0
	
CALC:
	addi $s3 $s3 0xFFFFFFFF
	mul $s2 $s2 0x0A
	bnez $s3 CALC
	addu $v0 $v0 $s2
	addi $s0 $s0 0xFFFFFFFF
	move $s3 $s0
	beqz $s3 RET
	addi $s1 $s1 0x01
	lb $s2 ($s1)
	addi $s2 $s2 0xFFFFFFD0
	j CALC
	
RET:
	addi $s1 $s1 0x01
	lb $s2 ($s1)
	addi $s2 $s2 0xFFFFFFD0
	addu $v0 $v0 $s2

	li $s0 0x04
	li $s1 0x00
	move $s2 $a0
LIMPAR_VET:
	sb $s1 ($s2)
	addi $s2 $s2 0x01
	addi $s0 $s0 0xFFFFFFFF
	bnez $s0 LIMPAR_VET
	
	jr $ra
	
RET_NULL:
	li $v0 0xFFFFFFFF
	jr $ra
	
RET_ZERO:
	li $v0 0x00
	jr $ra

#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-#
#SUB ROTINA - Converte um int em uma string cujos caracteres e' o int
INT_TO_STRING:
	move $v0 $a0
	move $v1 $a1
	
	li $s0 0x04
	li $s1 0x00
	li $s3 0x00
	
ZERAR:
	sb $s1 ($v0)
	addi $v0 $v0 0x01
	addi $s0 $s0 0xFFFFFFFF
	bnez $s0 ZERAR
	move $v0 $a0
	
	move $s1 $v1
	li $s0 0x3E8
	div $s1 $s1 $s0
	beqz $s1 DIG0_NULL
	li $s3 0x01
	move $s2 $s1
	addi $s1 $s1 0x30
	sb $s1 ($v0)
	addi $v0 $v0 0x01
	mul $s1 $s2 0x3E8
	sub $v1 $v1 $s1
DIG0_NULL:
	
	move $s1 $v1
	li $s0 0x64
	div $s1 $s1 $s0
	bnez $s3 IMP_1
	beqz $s1 DIG1_NULL
	li $s3 0x01
IMP_1:
	move $s2 $s1
	addi $s1 $s1 0x30
	sb $s1 ($v0)
	addi $v0 $v0 0x01
	mul $s1 $s2 0x64
	sub $v1 $v1 $s1
DIG1_NULL:
	
	move $s1 $v1
	li $s0 0x0A
	div $s1 $s1 $s0
	bnez $s3 IMP_2
	beqz $s1 DIG2_NULL
	li $s3 0x01
IMP_2:
	move $s2 $s1
	addi $s1 $s1 0x30
	sb $s1 ($v0)
	addi $v0 $v0 0x01
	mul $s1 $s2 0x0A
	sub $v1 $v1 $s1
DIG2_NULL:
	
	move $s1 $v1
	addi $s1 $s1 0x30
	sb $s1 ($v0)
	
	move $v0 $a0
	jr $ra

#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-#
#SUB ROTINA - Escreve cabecalho File OUT
ESCREVE_CAB:
	move $s0 $a0	# File OUT
	move $s1 $a1	# cab
	move $s2 $a2	# val_byte
	move $s3 $a3	# c_space
	lw $s4 0($sp)	# tamX
	lw $s5 4($sp)	# tamY
	lw $s6 8($sp)	# max_val
	addi $sp $sp 0x0C
	
	# Write cab in File OUT
	move $a0 $s0
    li $v0 0x0F
   	move $a1 $s1
	la $a2 0x31
    syscall
	
	move $a0 $s2
	move $a1 $s4
	sub $sp $sp 12
	sw $ra 8($sp)
	sw $s0 4($sp)
	sw $s3 0($sp)
	jal INT_TO_STRING
	move $s2 $v0
	lw $s3 0($sp)
	lw $s0 4($sp)
	lw $ra 8($sp)
	add $sp $sp 12

	addi $sp $sp 0x40
	
	move $a0 $s0
    li $v0 0x0F
    move $a1 $s2
    la $a2 0x03
    syscall
	
	move $a0 $s0
    li $v0 0x0F
    move $a1 $s3
    la $a2 0x1
    syscall
	
	move $a0 $s0
    li $v0 0x0F
    move $a1 $s2
    la $a2 0x03
    syscall
	
	jr $ra

#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-#
#SUB ROTINA - Pega um numero do numero do arquivo(string), converte para int e retorna 
GET_NUM_FILE:
	lw $s0 0($sp)	# File
	lw $s1 4($sp)	# String val_byte
	lw $s2 8($sp)	# Char temp
	addi $sp $sp 0x0C
	li $s3 0x2F
	li $s4 0x3A
	move $s7 $s1
	
LER_NUM:
	li $v0 0x0E		# system call for reading from file
	move $a0 $s0	# file descriptor
	move $a1 $s2	# address of buffer from which to read
	li $a2 0x01		# read 01 byte (char)
	syscall			# read file
	
	lb $s5 ($s2)
	slt $s6 $s5 $s3
	beq $s6 0x01 END_NUM
	slt $s6 $s4 $s5
	beq $s6 0x01 END_NUM
	
	sb $s5 ($s7)
	addi $s7 $s7 0x01
	j LER_NUM
END_NUM:
	
	sub $sp $sp 4
	sw $ra 0($sp)
	move $a0 $s1
	jal STRING_TO_INT
	lw $ra 0($sp)
	
	jr $ra
