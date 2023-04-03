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

# Size
.eqv SIZE_BY_UNIT 64		# Size of bitmap display by buffer unit
.eqv SIZE_BY_BYTE 256		# Size of one bitmap display row by byte
.eqv ENEMY_HEIGHT 3
.eqv PLAYER_HEIGHT 6
.eqv PLAYER_LEFT 2
.eqv PLAYER_RIGHT 2
.eqv BOMB_HEIGHT 3

.eqv SLEEP_TIME 20		# Sleeping time in miliseconds
.eqv JUMP_HEIGHT 20		# How high player can jump


.data
playerState:	.word		0, 1000, 0
enemyState:	.word		0:7
bombState:	.word		0:7
platformState:	.word		0:7

# Debug messages
newline:	.asciiz		"\n"

.text
.globl main
setup:		jal erase_screen

		# Draw first platform
 		li $a0, 0			# Store x coordinate
		li $a1, 17			# Store y coordinate
		jal bitmap_address		# Compute start address
		la $s1, platformState		# Load memory address of platformState
		li $a1, 3			# Number of platforms for this level
		sw $a1, 0($s1)			# Store number of platforms at start of array platformState
		sw $s0, 4($s1)			# Store location of first platform into memory
		add $a0, $s0, $zero		# Store start address
		li $a1, 21			# Declare size of platform
		sw $a1, 8($s1)			# Store size of platform
		jal draw_platform		# Draw platform
		
		# Draw second platform
		li $a0, 32			# Store x coordinate
		li $a1, 30			# Store y coordinate
		jal bitmap_address		# Compute start address
		la $s1, platformState		# Load memory address of platformState
		sw $s0, 12($s1)			# Store location of second platform into memory
		add $a0, $s0, $zero		# Store start address
		li $a1, 32			# Define size of platform
		sw $a1, 16($s1)			# Store size of platform into memory
		jal draw_platform		# Draw platform

		# Draw third platform
		li $a0, 9			# Store x coordinate
		li $a1, 45			# Store y coordinate
		jal bitmap_address		# Compute start address
		la $s1, platformState		# Load memory address of platformState
		sw $s0, 20($s1)			# Store location of third platform into memory
		add $a0, $s0, $zero		# Store start address
		li $a1, 46			# Define size of platform
		sw $a1, 24($s1)			# Store size of platform into memory
		jal draw_platform		# Draw platform
		
		# Draw bomb
		li $a0, 45			# Store x coordinate
		li $a1, 42			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		jal draw_bomb			# Draw bomb
			
		# Draw first enemy
		li $a0, 0			# Store x coordinate
		li $a1, 14			# Store y coordinate
		jal bitmap_address		# Compute start address
		la $s1, enemyState		# Load memory address of enemyState
		li $a1, 3			# Number of enemies for this level
		sw $a1, 0($s1)			# Store number of enemies at start of array
		sw $s0, 4($s1)			# Store location of enemy in enemyState
		add $a0, $s0, $zero		# Define start address
		jal draw_enemy			# Draw enemy
			
		# Draw second enemy
		li $a0, 53			# Store x coordinate
		li $a1, 27			# Store y coordinate
		jal bitmap_address		# Compute start address
		la $s1, enemyState		# Load memory address of enemyState
		sw $s0, 12($s1)			# Store location of enemy in enemyState
		add $a0, $s0, $zero		# Define start address
		jal draw_enemy			# Draw enemy
		
		# Draw third enemy
		li $a0, 40			# Store x coordinate
		li $a1, 42			# Store y coordinate
		jal bitmap_address		# Compute start address
		la $s1, enemyState		# Load memory address of enemyState
		sw $s0, 20($s1)			# Store location of enemy in enemyState
		add $a0, $s0, $zero		# Define start address
		jal draw_enemy			# Draw enemy
		
		# Draw player
		li $a0, 6			# Store x coordinate
		li $a1, 12			# Store y coordinate
		jal bitmap_address		# Compute start address
		la $s1, playerState		# Load the memory address that stores location of player
		sw $s0, 0($s1)			# Store location of player in memory
		add $a0, $s0, $zero		# Store start address
		jal draw_player			# Draw player
		
main:		# Check for collision with enemies
		la $a1, playerState		# Get address of playerState
		lw $a0, 0($a1)			# Load current location of player into $a0
		jal xy_address			# Calculate xy-coordinates for player
		add $t1, $s0, $zero		# $t1 stores x-coordinate of player
		add $t2, $s1, $zero		# $t2 stores y-coordinate of player
		
		la $s7, enemyState		# $s7 stores address of enemyState
		lw $t0, 0($s7)			# $t0 stores number of enemies
		addi $s7, $s7, 4		# $s7 stores address of enemy
		
ce_loop:	beqz $t0, cj			# When done checking all enemies, check jumping state

		lw $a0, 0($s7)			# $a0 stores location of enemy
		jal xy_address			# Calculate xy-coordinates for enemy
		add $t3, $s0, $zero		# $t3 stores x-coordinate of enemy
		add $t4, $s1, $zero		# $t4 stores y-coordinate of enemy
		
		addi $t5, $t2, 4		# $t5 stores bottom y-coordinate of player
		addi $t6, $t4, 2		# $t6 stores bottom y-coordinate of enemy
		bne $t5, $t6, ce_skip		# Check collision by y-coordinate
		addi $t5, $t1, 3
		add $t6, $t3, $zero
		beq $t5, $t6, collision		# Check collision by x-coordinate right of player
		addi $t5, $t1, -3
		addi $t6, $t3, 2
		beq $t5, $t6, collision		# Check collision by x-coordinate left of player
		j ce_skip			# If reaches here, no collision
		
collision:	la $a1, playerState		# Get address of playerState
		lw $a0, 4($a1)			# Load current player health
		addi $a0, $a0, -1		# Decrease health of player
		blez $a0, fail			# If out of health, fail
		sw $a0, 4($a1)			# Store new health into memory
		li $v0, 1			# Print health to debug
		syscall
		li $v0, 4
		la $a0, newline
		syscall
		j keyboard		
ce_skip:	addi $s7, $s7, 8		# $a0 stores address of next enemy
		addi $t0, $t0, -1		# Decrement $t0 (number of enemies left to check)
		j ce_loop
		
		# Check if player is jumping
cj:		la $a1, playerState		# Get address of playerState
		lw $a0, 0($a1)			# Load current location of player into $a0
		lw $t0, 8($a1)			# Loading jumping state into $t0
		bgtz $t0, jump_once
		
cp:		# Check if player is standing on platform
		la $a1, playerState		# Get address of playerState
		lw $a0, 0($a1)			# Load current location of player into $a0
		jal xy_address			# Calculate xy-coordinates for player
		add $t1, $s0, $zero		# $t1 stores x-coordinate of player
		add $t2, $s1, $zero		# $t2 stores y-coordinate of player
		
		la $s7, platformState		# $s7 stores address of platformState
		lw $t0, 0($s7)			# $t0 stores number of platforms
		addi $s7, $s7, 4		# $s7 stores address of platform
		
cp_loop:	beqz $t0, falling		# If number of platforms left reaches 0, player is not standing on platform
		lw $a0, 0($s7)			# $a0 stores location of platform
		jal xy_address			# Calculate xy-coordinates for platform
		lw $a0, 4($s7)			# $a0 stores size of platform
		add $t3, $s0, $zero		# $t3 stores x-coordinate of platform
		add $t4, $s1, $zero		# $t4 stores y-coordinate of platform
		
		addi $t5, $t2, 5		# $t5 stores bottom y-coordinate of player
		bne $t5, $t4, cp_skip		# If player bottom != platform top, not standing on platform
		addi $t5, $t1, 2		# $t5 stores rightmost x-coordinate of player
		blt $t5, $t3, cp_skip		# If player right < platform left, not standing on platform
		add $t6, $t3, $a0
		addi $t6, $t6, -1		# $t6 stores platform rightmost x-coordinate
		addi $t5, $t1, -2		# $t5 stores player leftmost x-coordinate
		ble $t5, $t6, keyboard		# If player center <= platform right, standing on platform
 
cp_skip:	addi $s7, $s7, 8		# $s7 stores address of next platform
		addi $t0, $t0, -1		# Decrement $t0 (number of platforms left to check)
		la $a1, playerState		# Get address of playerState
		sw $zero, 8($a1)		# Update state of player to standing on platform
		j cp_loop	
		
falling:	la $a1, playerState		# Get address of playerState
		li $a0, -1			# Define falling state
		sw $a0, 8($a1)			# Update falling state of player
		lw $a0, 0($a1)			# Load current location of player into $a0
		lw $a2, 0($a1)			# Load current location of player into $a2
		jal xy_address			# Compute current xy-coordinates of player
		addi $s1, $s1, 1		# Compute new y-coordinate of player (fall below by 1)
		bgt $s1, 64, fail		# If fall out of screen, fail
		add $a0, $a2, $zero		# Restore current address
		jal erase_player		# Erase player at current location
		addi $a0, $a0, SIZE_BY_BYTE	# Get new address after key pressed
		sw $a0, 0($a1)			# Store new address in memeory
		jal draw_player			# Draw player at new location
				
keyboard:	li $t9, 0xffff0000 		# Store address of keystroke event
		lw $t8, 0($t9)  		# Check for keystroke event
		beq $t8, 1, pressed		# If some key is pressed, branch to pressed
		
		li $v0, 32			# Sleep
		li $a0, SLEEP_TIME
		j main				# Repeat main
		
pressed:	lw $t8, 4($t9)			# Read what key is pressed
		beq $t8, RIGHT, go_right
		beq $t8, LEFT, go_left
		beq $t8, JUMP, jump
		j main
		
go_right:	la $a1, playerState		# Get address of player location
		lw $a0, 0($a1)			# Load current location of player into $a0
		lw $a2, 0($a1)			# Load current location of player into $a2
		jal xy_address			# Compute current xy-coordinates of player
		addi $s0, $s0, 3		# Compute next rightmost x coordinate of player
		bge $s0, SIZE_BY_UNIT, main	# If next x coordinate goes beyond screen, do nothing
		add $a0, $a2, $zero		# Restore current address
		jal erase_player		# Erase player at current location
		lw $a2, 8($a1)			# Loading state of player
		bnez $a2, bigger_rstep		# If player is jumping or falling, take a bigger step
		addi $a0, $a0, 4		# Get new address after key pressed
to_right:	sw $a0, 0($a1)			# Store new address in memeory
		jal draw_player			# Draw player at new location
		j main
		
bigger_rstep:	addi $a0, $a0, 12
		j to_right
		
go_left:	la $a1, playerState		# Get address of player location
		lw $a0, 0($a1)			# Load current location of player into $a0
		lw $a2, 0($a1)			# Load current location of player into $a2
		jal xy_address			# Compute current xy-coordinates of player
		subi $s0, $s0, 3		# Compute next leftmost x coordinate of player
		blt $s0, 0, main		# If next x coordinate goes beyond screen, do nothing
		add $a0, $a2, $zero		# Restore current address
		jal erase_player		# Erase player at current location
		lw $a2, 8($a1)			# Loading state of player
		bnez $a2, bigger_lstep		# If player is jumping or falling, take a bigger step
		subi $a0, $a0, 4		# Get new address after key pressed
to_left:	sw $a0, 0($a1)			# Store new address in memeory
		jal draw_player			# Draw player at new location
		j main
		
bigger_lstep:	subi $a0, $a0, 12
		j to_left
		
jump:		la $a1, playerState		# Get address of player location
		li $a0, JUMP_HEIGHT		# Define jump height
		sw $a0, 8($a1)			# Update jumping state of player
		j main
		
jump_once:	la $s7, playerState		# Get address of playerState
		lw $a0, 0($s7)			# Load current location of player into $a0
		jal xy_address			# Compute current xy-coordinates of player
		
		add $t1, $s0, $zero		# $t1 stores x-coordinate of player
		add $t2, $s1, $zero		# $t2 stores y-coordinate of player
		
		beqz $t2, jump_max		# If reach top of screen, jump_max
		
		la $s6, platformState		# $s6 stores address of platformState
		lw $t0, 0($s6)			# $t0 stores number of platforms
		addi $s6, $s6, 4		# $s6 stores address of platform
		
rp_loop:	beqz $t0, jump_next		# If number of platforms left reaches 0, player does not touch platform
		lw $a0, 0($s6)			# $a0 stores location of platform
		jal xy_address			# Calculate xy-coordinates for platform
		lw $t7, 4($s6)			# $t7 stores size of platform
		add $t3, $s0, $zero		# $t3 stores x-coordinate of platform
		add $t4, $s1, $zero		# $t4 stores y-coordinate of platform
		
		addi $t6, $t4, 2		# $t6 stores bottom y-coordinate of platform
		bne $t2, $t6, rp_skip		# If player top != platform bottom, not touching platform
		addi $t5, $t1, 2		# $t5 stores rightmost x-coordinate of player
		blt $t5, $t3, rp_skip		# If player right < platform left, not touching platform
		addi $t5, $t1, -2		# $t5 stores leftmost x-coordinate of player
		add $t6, $t3, $t7
		addi $t6, $t6, -1		# $t6 stores rightmost x-coordinate of platform
		ble $t5, $t6, jump_max		# If player left <= platform right, touching platform

rp_skip:	addi $s6, $s6, 8
		addi $t0, $t0, -1
		j rp_loop	
	
jump_next:	lw $a0, 0($s7)			# Load current location of player into $a0
		jal erase_player		# Erase player at current location
		subi $a0, $a0, SIZE_BY_BYTE	# Compute new location (one row above)
		jal draw_player			# Draw player at new location
		sw $a0, 0($a1)			# Store new location
		
		lw $a0, 8($s7)			# Load jumping state of player into $a0
		addi $a0, $a0, -1		# Decrement jumping state (number of cells left to move up)
		sw $a0, 8($s7)			# Store new jumping state
		j keyboard

jump_max:	sw $zero, 8($s7)		# If reach top of screen, stop jumping
		j cj
		
fail:		jal erase_screen
		# End program
		li $v0, 10
		syscall
		
# Arguments:	x coordinate	$a0
#		y coordinate	$a1
# Registers:	tmp, return	$s0
# Returns:	Start address	$s0
bitmap_address:	li $s0, SIZE_BY_UNIT
		mult $a1, $s0
		mflo $s0
		add $s0, $s0, $a0
		sll $s0, $s0, 2
		addi $s0, $s0, BASE_ADDRESS
		jr $ra
		
xy_address:	subi $a0, $a0, BASE_ADDRESS	# Get offset from (0, 0)
		sra $a0, $a0, 2			# Divide by 4 to get (y*width + x)
		li $s0, SIZE_BY_UNIT		
		div $a0, $s0			# Divide by width to get x and y
		mfhi $s0			# Remainder is x
		mflo $s1			# Quotient is y
		jr $ra

# Arguments:	Start address	$a0
#		Size		$a1
# Registers:	Color value	$s0
#		Current address	$s1
# Returns:	Draw a platform of size $a1 starting from $a0	
draw_platform:	li $s0, PLATFORM		# Load color for platform
		add $s1, $a0, $zero		# Intialize counter
		sll $a1, $a1, 2			# Multiply size by 4 to use as offset
		add $a1, $a1, $a0		# Last address to color
pf_loop:	bge $s1, $a1, pf_fin		# Branch to fin when done coloring
		sw $s0, 0($s1)			# Color first row
		sw $s0, SIZE_BY_BYTE($s1)	# Color second row
		addi $s1, $s1, 4		# Increment address
		j pf_loop
pf_fin:		jr $ra

# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	Draw an enemy at $a0	
draw_enemy:	li $s0, WATER_FILL		# Load filled color for enemy
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 260($a0)
		sw $s0, 264($a0)
		sw $s0, 520($a0)
		li $s0, WATER_LINE		# Load line color for enemy
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		sw $s0, 516($a0)
		jr $ra

# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	Draw player at $a0	
draw_player:	li $s0, FIRE_LINE		# Load line color for player
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 252($a0)
		sw $s0, 256($a0)
		sw $s0, 260($a0)
		sw $s0, 508($a0)
		sw $s0, 516($a0)
		sw $s0, 520($a0)
		sw $s0, 760($a0)
		sw $s0, 764($a0)
		sw $s0, 776($a0)
		sw $s0, 1016($a0)
		sw $s0, 1032($a0)
		li $s0, FIRE_FILL		# Load fill color for player
		sw $s0, 512($a0)
		sw $s0, 768($a0)
		sw $s0, 772($a0)
		sw $s0, 1020($a0)
		sw $s0, 1024($a0)
		sw $s0, 1028($a0) 
		jr $ra

# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	Draw bomb at $a0		
draw_bomb:	li $s0, BOMB			# Load color for bomb
		sw $s0, 0($a0)
		sw $s0, 252($a0)
		sw $s0, 256($a0)
		sw $s0, 260($a0)
		sw $s0, 508($a0)
		sw $s0, 512($a0)
		jr $ra
		
# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	Erase player at $a0	
erase_player:	li $s0, ERASE			# Load line color to erase
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 252($a0)
		sw $s0, 256($a0)
		sw $s0, 260($a0)
		sw $s0, 508($a0)
		sw $s0, 516($a0)
		sw $s0, 520($a0)
		sw $s0, 760($a0)
		sw $s0, 764($a0)
		sw $s0, 776($a0)
		sw $s0, 1016($a0)
		sw $s0, 1032($a0)
		sw $s0, 512($a0)
		sw $s0, 768($a0)
		sw $s0, 772($a0)
		sw $s0, 1020($a0)
		sw $s0, 1024($a0)
		sw $s0, 1028($a0) 
		jr $ra

# Arguments:	None
# Registers:	Color value	$s0
# 		Current cell	$s1
#		Last cell	$s2
# Returns:	All screen reset
erase_screen:	li $s0, ERASE
		li $s1, BASE_ADDRESS
		addi $s2, $s1, 16380
es_loop:	bgt $s1, $s2, es_fin
		sw $s0, 0($s1)
		addi $s1, $s1, 4
		j es_loop
es_fin:		jr $ra
		

