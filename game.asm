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
.eqv SIZE_BY_UNIT 64		# Size of bitmap display by buffer unit
.eqv SIZE_BY_BYTE 256		# Size of one bitmap display row by byte
.eqv SLEEP_TIME 1000		# Sleeping time in miliseconds


.data

.text
.globl main
main:		# Draw first platform
 		li $a0, 0			# Store x coordinate
		li $a1, 17			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		li $a1, 21			# Store size of platform
		jal draw_platform		# Draw platform
		
		# Draw second platform
		li $a0, 32			# Store x coordinate
		li $a1, 30			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		li $a1, 32			# Store size of platform
		jal draw_platform		# Draw platform

		# Draw third platform
		li $a0, 9			# Store x coordinate
		li $a1, 45			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		li $a1, 46			# Store size of platform
		jal draw_platform		# Draw platform
		
		# Draw first enemy
		li $a0, 0			# Store x coordinate
		li $a1, 14			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		jal draw_enemy			# Draw enemy
			
		# Draw second enemy
		li $a0, 53			# Store x coordinate
		li $a1, 27			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		jal draw_enemy			# Draw enemy
		
		# Draw third enemy
		li $a0, 52			# Store x coordinate
		li $a1, 42			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		jal draw_enemy			# Draw enemy
		
		# Draw player
		li $a0, 21			# Store x coordinate
		li $a1, 40			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		jal draw_player			# Draw player
		
		# Draw bomb
		li $a0, 45			# Store x coordinate
		li $a1, 42			# Store y coordinate
		jal bitmap_address		# Compute start address
		add $a0, $s0, $zero		# Store start address
		jal draw_bomb			# Draw bomb
		
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
		