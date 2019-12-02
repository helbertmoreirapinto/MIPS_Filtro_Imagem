.data
	f_in:		.asciiz "in.pgm"	# File IN
	f_out:		.asciiz "out.pgm"	# File OUT
	menu_p:		.asciiz "Filtros de Imagem\n[1]Filtro Identy\n[2]Filtro Emboss\n[3]Filtro Sharpen\n[0]Sair\nSelecione: "
	cab:		.asciiz "P2\n# Make by Antonio Sebastian / Helbert Pinto #\n"
	new_line:	.asciiz "\n"
	c_space:	.asciiz " "
	
	FilIdenty:	.word  0, 0,0, 0,1, 0,0, 0,0
	FilEmboss:	.word -2,-1,0,-1,1, 1,0, 1,2
	FilSharpen:	.word  0,-1,0,-1,5,-1,0,-1,0
	tamPicX:	.word 0
	tamPicY:	.word 0
	bytesPic:	.word 0
	max_value:	.word 0

	val_byte:	.space 0x04
	temp:		.space 0x01
	.align 2
	buffer:		.space 0x00019000 #100kBits
	
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
	beq $k0 -1 END_PROGRAM
	
	# Open File OUT [Write]
	li $v0 0x0D	# system call for open file
	la $a0 f_out	# input file name
	li $a1 0x01	# flag for write
	li $a2 0x00	# mode is ignored
	syscall		# open file
	move $k1 $v0	# K1 -> File OUT
	
	beq $k1 -1 END_PROGRAM
	
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
	# Save X
	sub $sp $sp 12
	sw $k0 0($sp)	# File
	sw $t1 4($sp)	# String val_byte
	sw $t2 8($sp)	# Char 
	jal GET_NUM_FILE
	sw $v0 tamPicX
	
	# Save Y
	sub $sp $sp 12
	sw $k0 0($sp)	# File
	sw $t1 4($sp)	# String val_byte
	sb $t2 8($sp)	# Char 
	jal GET_NUM_FILE
	sw $v0 tamPicY
	
	li $v0 0x0E
	move $a0 $k0
	la   $a1 temp
	li   $a2 0x01
	syscall
	
	# Save Max value
	sub $sp $sp 12
	sw $k0 0($sp)	# File
	sw $t1 4($sp)	# String val_byte
	sb $t2 8($sp)	# Char 
	jal GET_NUM_FILE
	sw $v0 max_value

	lw $t0 tamPicX
	lw $t2 tamPicY
	mulu $t1 $t0 $t2
	sw $t1 bytesPic
	addi $t1 $t1 0x01
	li $t0 0x00
	la $t2 buffer
	
	la $t3 val_byte
	la $t4 temp
	
WRITE_BUFFER:
	sub $sp $sp 12
	sw $k0 0($sp)	# File
	sw $t3 4($sp)	# String val_byte
	sw $t4 8($sp)	# Char temp
	jal GET_NUM_FILE
	beq $v0 -1 WRITE_BUFFER 
	sw $v0 ($t2)
	addi $t2 $t2 0x04
	addi $t0 $t0 0x01
	bne $t0 $t1 WRITE_BUFFER
	
	# MENU
	# Print menu_p in console
	li $v0 0x04		# system call for print string
	la $a0 menu_p	# select string
	syscall			# print string
	
	# Get int keyboard
	li $v0 0x05	# system call for get int keyboard
	syscall		# get int keyboard
	move $t7 $v0
	
	# Write cab File OUT
	la $t0 cab			# cab
	la $t1 val_byte		# val_byte
	la $t2 new_line		# new_line
	la $t3 c_space		# c_space
	lw $t4 tamPicX		# tamX
	lw $t5 tamPicY		# tamY
	lw $t6 max_value	# max_val
	
	sub $sp $sp 0x20	
	sw $k1 00($sp)	# File OUT
	sw $t0 04($sp)	# cab
	sw $t1 08($sp)	# val_byte
	sw $t2 12($sp)	# new_line
	sw $t3 16($sp)	# c_space
	sw $t4 20($sp)	# tamX
	sw $t5 24($sp)	# tamY
	sw $t6 28($sp)	# max_val
	jal ESCREVE_CAB
	
	# Select filter
	beq $t7 0x01 SEL_FILTRO_1
	beq $t7 0x02 SEL_FILTRO_2
	beq $t7 0x03 SEL_FILTRO_3
	beq $t7 $zero END_PROGRAM

SEL_FILTRO_1:
	# Filter 1 - Identy
	j APLICAR_FILTRO
	
SEL_FILTRO_2:
	# Filter 2 - Emboss
	j APLICAR_FILTRO
	
SEL_FILTRO_3:
	# Filter 3 - Sharpen
	j APLICAR_FILTRO

APLICAR_FILTRO:
	la $t0 buffer	# Matriz
	lw $t1 tamPicX	# Max I
	lw $t2 tamPicY	# Max J
	li $t3 0x00		# I
	li $t4 0x00		# J
	li $t5 0x00		# indice ref pixel
	li $t6 0x00		# indice_aux
	li $t7 0x00		# Soma

RODAR_MATRIZ:
	mul $t5 $t3 0x64
	add $t5 $t5 $t4

	beqz $t3 PIXEL_BORDA
	beq $t1 $t3 PIXEL_BORDA
	beqz $t4 PIXEL_BORDA
	beq $t2 $t4 PIXEL_BORDA
	li $t7 0x00
NAO_BORDA:
	sub $t6 $t5 0x65
	li $t8 0x00 	# multiplicador pixel Top-Left
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0
	
	sub $t6 $t5 0x64
	li $t8 0x00 	# multiplicador pixel Top
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0

	sub $t6 $t5 0x63
	li $t8 0x00 	# multiplicador pixel Top-Right
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0
	
	sub $t6 $t5 0x01
	li $t8 0x00 	# multiplicador pixel Left
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0
	
	li $t8 0x01 	# multiplicador pixel Center
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0
	
	addi $t6 $t5 0x01
	li $t8 0x00 	# multiplicador pixel Right
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0
	
	addi $t6 $t5 0x63
	li $t8 0x00 	# multiplicador pixel Botton-Left
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0
	
	addi $t6 $t5 0x64
	li $t8 0x00 	# multiplicador pixel Botton
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0

	addi $t6 $t5 0x65
	li $t8 0x00 	# multiplicador pixel Botton-Right
	move $a0 $t0		# Buffer
	move $a1 $t6		# indice
	move $a2 $t8		# multiplicador
	jal CALCULO_VALOR_PIXEL
	add $t7 $t7 $v0

PIXEL_BORDA:
	
	#escrever $t7 como string no output.pgm
	#escrever space no output.pgm
	
	
	addi $t4 $t4 0x01
	bne $t2 $t4 RODAR_MATRIZ
	beq $t1 $t3 FIM_FILTRO
RESET_LINHA:
	addi $t3 $t3 1
	li $t4 0x00
	j RODAR_MATRIZ
FIM_FILTRO:
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
	sub $s2 $s2 0x30
	sub $s0 $s0 0x01
	beq $s0 -1 RET_NULL
	beqz $s0 RET_ZERO
	move $s3 $s0
	
CALC:
	sub $s3 $s3 0x01
	mul $s2 $s2 0x0A
	bnez $s3 CALC
	addu $v0 $v0 $s2
	sub $s0 $s0 0x01
	move $s3 $s0
	beqz $s3 RET
	addi $s1 $s1 0x01
	lb $s2 ($s1)
	sub $s2 $s2 0x30
	j CALC
	
RET:
	addi $s1 $s1 0x01
	lb $s2 ($s1)
	sub $s2 $s2 0x30
	addu $v0 $v0 $s2

	li $s0 0x04
	li $s1 0x00
	move $s2 $a0
LIMPAR_VET:
	sb $s1 ($s2)
	addi $s2 $s2 0x01
	sub $s0 $s0 0x01
	bnez $s0 LIMPAR_VET
	
	jr $ra
	
RET_NULL:
	li $v0 -1
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
	sub $s0 $s0 0x01
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
	lw $s0 0($sp)	# File OUT
	lw $s1 4($sp)	# cab
	lw $s2 8($sp)	# val_byte
	lw $s3 12($sp)	# new_line
	lw $s4 16($sp)	# c_space
	lw $s5 20($sp)	# tamX
	lw $s6 24($sp)	# tamY
	lw $s7 28($sp)	# max_val
	addi $sp $sp 0x20
	
	# Write cab in File OUT
	li $v0 0x0F
	move $a0 $s0
   	move $a1 $s1
	la   $a2 0x31
    syscall
	
	# X int to string 
	move $a0 $s2
	move $a1 $s5
	sub $sp $sp 0x20
	sw $ra 28($sp)
	sw $s7 24($sp)
	sw $s6 20($sp)
	sw $s4 16($sp)
	sw $s3 12($sp)
	sw $s2 08($sp)
	sw $s1 04($sp)
	sw $s0 00($sp)
	jal INT_TO_STRING
	move $s5 $v0
	lw $s0 00($sp)	# File OUT
	lw $s1 04($sp)	# cab
	lw $s2 08($sp)	# val_byte
	lw $s3 12($sp)	# new_line
	lw $s4 16($sp)	# c_space
	lw $s6 20($sp)	# tamY
	lw $s7 24($sp)	# max_val
	lw $ra 28($sp)
	addi $sp $sp 0x20
	
	# Write X
    li $v0 0x0F
	move $a0 $s0
    move $a1 $s5
    la   $a2 0x03
    syscall
	
	# Write space
    li $v0 0x0F
    move $a0 $s0
	move $a1 $s4
    la   $a2 0x1
    syscall
	
	# Y int to string
	move $a0 $s2
	move $a1 $s6
	sub $sp $sp 0x18
	sw $ra 24($sp)
	sw $s7 20($sp)
	sw $s3 12($sp)
	sw $s2 08($sp)
	sw $s1 04($sp)
	sw $s0 00($sp)
	jal INT_TO_STRING
	move $s6 $v0
	lw $s0 00($sp)	# File OUT
	lw $s1 04($sp)	# cab
	lw $s2 08($sp)	# val_byte
	lw $s3 12($sp)	# new_line
	lw $s7 20($sp)	# max_val
	lw $ra 24($sp)
	addi $sp $sp 0x18
	
	# Write Y
	li $v0 0x0F
    move $a0 $s0
	move $a1 $s6
    la   $a2 0x03
    syscall
	
	# Write enter
    li $v0 0x0F
    move $a0 $s0
	move $a1 $s3
    la   $a2 0x01
    syscall
	
	# max int to string
	move $a0 $s2
	move $a1 $s7
	sub $sp $sp 0x10
	sw $ra 12($sp)
	sw $s3 08($sp)
	sw $s1 04($sp)
	sw $s0 00($sp)
	jal INT_TO_STRING
	move $s7 $v0
	lw $s0 00($sp)	# File OUT
	lw $s1 04($sp)	# cab
	lw $s3 08($sp)	# new_line
	lw $ra 12($sp)
	addi $sp $sp 0x10
	
	# Write MAX
	li $v0 0x0F
    move $a0 $s0
	move $a1 $s7
    la   $a2 0x03
    syscall
	
	# Write enter
    li $v0 0x0F
    move $a0 $s0
	move $a1 $s3
    la   $a2 0x01
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
	
CALCULO_VALOR_PIXEL:
	move $s0 $a0	# END Buffer
	move $s1 $a1	# INT indice vetor
	move $s2 $a2	# INT multiplicador
	
	mul $s1 $s1 0x04
	add $s0 $s0 $s1
	lw $s3 ($s0)
	mul $v0 $s2 $s3
	
	jr $ra
