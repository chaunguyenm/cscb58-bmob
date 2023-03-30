#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Minh Chau Nguyen, 1007846422, nguy2855, chaum.nguyen@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes / no / yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

##### SAVED VALUES #####
# Important addresses
.eqv BASE_ADDRESS 0x10008000	# Location (0, 0) on bitmap display
.eqv KEYBOARD 0xffff0000	# Address of boolean key pressed

# RGB values
.eqv BOMB 0xed1c23
.eqv FIRE_LINE 0xff8000
.eqv FIRE_FILL 0xffc30e
.eqv WATER_FILL 0x00b7ef
.eqv WATER_LINE 0x99d9ea
.eqv PLATFORM 0x9c5a3c
.eqv ERASE 0x000000

# ASCII values for important keys
.eqv LEFT 97
.eqv RIGHT 100
.eqv JUMP 119
.eqv SHOOT 115
.eqv RESET 112

# Other
.eqv SIZE 64			# Size of bitmap display
.eqv SLEEP_TIME 1000		# Sleeping time in miliseconds


.data

.text
.globl main
main: 		li $t0, BASE_ADDRESS
		li $t1, FIRE_FILL
		li $t2, FIRE_LINE
		li $t3, BOMB
		li $t4, WATER_FILL
		li $t5, WATER_LINE
		li $t6, PLATFORM
		li $t7, ERASE
		
		# Draw platform
		li $a0, 0
		li $a1, 17
		jal bitmap_address
		
		add $s0, $s0, $t0
		sw $t6, 0($s0)
		sw $t6, 4($s0)
		sw $t6, 8($s0)
		sw $t6, 12($s0)
		sw $t6, 16($s0)
		sw $t6, 20($s0)
		sw $t6, 24($s0)
		sw $t6, 28($s0)
		sw $t6, 32($s0)
		sw $t6, 36($s0)
		sw $t6, 40($s0)
		sw $t6, 44($s0)
		sw $t6, 48($s0)
		sw $t6, 52($s0)
		sw $t6, 56($s0)
		sw $t6, 60($s0)
		sw $t6, 64($s0)
		sw $t6, 68($s0)
		sw $t6, 72($s0)
		sw $t6, 76($s0)
		
		li $a0, 0
		li $a1, 18
		jal bitmap_address
		add $s0, $s0, $t0
		sw $t6, 0($s0)
		sw $t6, 4($s0)
		sw $t6, 8($s0)
		sw $t6, 12($s0)
		sw $t6, 16($s0)
		sw $t6, 20($s0)
		sw $t6, 24($s0)
		sw $t6, 28($s0)
		sw $t6, 32($s0)
		sw $t6, 36($s0)
		sw $t6, 40($s0)
		sw $t6, 44($s0)
		sw $t6, 48($s0)
		sw $t6, 52($s0)
		sw $t6, 56($s0)
		sw $t6, 60($s0)
		sw $t6, 64($s0)
		sw $t6, 68($s0)
		sw $t6, 72($s0)
		sw $t6, 76($s0)
		
		# Sleep
		li $v0, 32
		li $a0, SLEEP_TIME
		syscall
		
		# Redraw to create animation of platform
		li $a0, 0
		li $a1, 17
		jal bitmap_address
		
		add $s0, $s0, $t0
		sw $t7, 0($s0)
		sw $t6, 80($s0)
		
		li $a0, 0
		li $a1, 18
		jal bitmap_address
		
		add $s0, $s0, $t0
		sw $t7, 0($s0)
		sw $t6, 80($s0)
		
		# Draw water
		li $a0, 3
		li $a1, 14
		jal bitmap_address
		
		addi $s0, $s0, BASE_ADDRESS
		sw $t4, 0($s0)
		sw $t4, 4($s0)
		sw $t4, 8($s0)
		sw $t5, 256($s0)
		sw $t4, 260($s0)
		sw $t4, 264($s0)
		sw $t5, 512($s0)
		sw $t5, 516($s0)
		sw $t4, 520($s0)
		
		# Receive keyboard input
keyboard:	li $t9, KEYBOARD 
		lw $t8, 0($t9) 
		beq $t8, 1, pressed	# if ==1 key is pressed
		j keyboard
		
pressed:	lw $t2, 4($t9)		# read what key is pressed
		beq $t2, RIGHT, right
		j keyboard

right:		sw $t7, 0($s0)
		sw $t7, 256($s0)
		sw $t7, 512($s0)
		sw $t4, 8($s0)
		sw $t4, 264($0)
		sw $t4, 520($s0)
		sw $t5, 260($s0)
		sw $t5, 516($s0)
		j keyboard
		
		# End program
		li $v0, 10
		syscall
		
bitmap_address:	li $s0, SIZE
		mult $a1, $s0
		mflo $s0
		add $s0, $s0, $a0
		sll $s0, $s0, 2
		jr $ra
		
draw_platform:	
