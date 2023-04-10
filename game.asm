#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Minh Chau Nguyen, 1007846422, nguy2855, chaum.nguyen@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 
# - Unit height in pixels: 8 
# - Display width in pixels: 512 
# - Display height in pixels: 512 
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# - Milestone 1
# - Milestone 2
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# 1. Double jump
# 2. Health
# 3. Fail condition
# 4. Win condition
# 5. Shoot enemies
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes, and please share this project github link as well!
#
# Any additional information that the TA needs to know:
#
#
#####################################################################

# What is my game loop?
# Act upon user input -> Update all game objects -> Redraw screen
# Act upon user input: A - go left if A is not restricted (not touching any objects on the left)
#		       D - go right if D is not restricted (not touching any objects on the right)
#		       W - jump if W is not restricted (not touching any objects on top, is standing on a platform, is not already jumping)
#		       S - place bomb if S is not restricted (standing on a platform)
# Update all game objects: collisionEnemy: Left, Right, Top, Bottom
#			   collisionPlatform: Left, Right, Top, Bottom
#			   collisionBomb: Left, Right, Top, Bottom
#			   Player: Location, xVelocity, yVelocity (W pressed -> set yVelocity to 20 -> decrease by 1 every loop until 0)
#			   Platform state: Location, Size
#			   Enemy state: Location
#			   Bomb state: Location, Time until explosion

# Redraw screen:


# Important addresses
.eqv BASE_ADDRESS 0x10008000	# Location (0, 0) on bitmap display
.eqv HEALTH_BAR_START 0x1000820C
.eqv HEALTH_BAR_END 0x100082D0
.eqv LEVEL_ADDRESS 0x100081E8
.eqv KEYBOARD 0xffff0000	# Address of boolean key pressed

# RGB values
.eqv BOMB 0xed1c23
.eqv FIRE_LINE 0xff8000
.eqv FIRE_FILL 0xffc30e
.eqv FIRE_OFF 0x546d8e
.eqv WATER_FILL 0x00b7ef
.eqv WATER_LINE 0x99d9ea
.eqv PLATFORM 0x9c5a3c
.eqv ERASE 0xf5e59c
.eqv MENU_BACKGROUND 0xe5aa7a
.eqv MENU_TEXT 0x990030
.eqv HEALTH_BAR_FULL 0x990030
.eqv HEALTH_BAR_EMPTY 0xb4b4b4
.eqv FAIL_TEXT 0xed1c23
.eqv FAIL_SHADOW 0x990030
.eqv WIN_TEXT 0xed1c23
.eqv WIN_SHADOW 0x990030
.eqv WIN_CUP_FILL 0xffc30e
.eqv WIN_CUP_SHADOW 0xe2af14
.eqv WIN_CUP_LIGHT 0xffd557


# ASCII values for input keys
.eqv LEFT 97
.eqv RIGHT 100
.eqv JUMP 119
.eqv SHOOT 115
.eqv RESET 112

# Size
.eqv SIZE_BY_UNIT 64		# Size of bitmap display by buffer unit
.eqv SIZE_BY_BYTE 256		# Size of one bitmap display row by byte

.eqv SLEEP_TIME 40		# Sleeping time in miliseconds
.eqv JUMP_HEIGHT 20		# How high player can jump
.eqv HEALTH 500
.eqv MAX_BOMB 3
.eqv EXPLOSION_TIME 40
.eqv EXPLOSION_RANGE 10


.data
collisionEnemy:		.word		0:4		# Left, Right, Top, Bottom
collisionPlatform:	.word		0, 0, 0, 1	# Left, Right, Top, Bottom
collisionBomb:		.word		0:4		# Left, Right, Top, Bottom
collisionScreen:	.word		0:4		# Left, Right, Top, Bottom

numPlatform:		.word		0
platformLoc:		.word		0:10
platformSize:		.word		0:10
platformQueue:		.word		0:10

numEnemy:		.word		0
enemyLoc:		.word		0:10
enemyPos:		.word		0, 0, 10, 0, 0, 0
enemyQueue:		.word		0:10

numBomb:		.word		0
bombLoc:		.word		0:3
bombTime:		.word		1, 0, 0
bombQueue:		.word		0:3

playerLoc:		.word		0:3		# Location, xVelocity, yVelocity
playerHealth:		.word		HEALTH
level:			.word		1

newline:		.asciiz		"\n"

.text
.globl main
setup:		jal erase_screen
		li $t9, HEALTH			# Reset playerHealth
		sw $t9, playerHealth
		sw $zero, playerLoc + 4		# Reset xVelocity
		sw $zero, playerLoc + 8		# Reset yVelocity
		sw $zero, collisionEnemy	# Reset collisionEnemy
		sw $zero, collisionEnemy + 4
		sw $zero, collisionEnemy + 8
		sw $zero, collisionEnemy + 12
		sw $zero, collisionScreen	# Reset collisionScreen
		sw $zero, collisionScreen + 4
		sw $zero, collisionScreen + 8
		sw $zero, collisionScreen + 12 
		sw $zero, collisionPlatform	# Reset collisionPlatform
		sw $zero, collisionPlatform + 4
		sw $zero, collisionPlatform + 8
		#sw $zero, collisionPlatform + 12
		sw $zero, collisionBomb		# Reset collisionBomb
		sw $zero, collisionBomb + 4
		sw $zero, collisionBomb + 8
		sw $zero, collisionBomb + 12
		lw $t9, level
		beq $t9, 1, setup_level1
		beq $t9, 2, setup_level2
		beq $t9, 3, setup_level3

setup_level1:	li $a0, 3			# Store number of platforms and enemies for this level
		sw $a0, numPlatform
		sw $a0, numEnemy
		li $a0, 1
		sw $a0, numBomb
		
		# Draw health bar
		jal draw_menu
		jal draw_health_bar
		jal draw_level

		# Draw first platform
 		li $a0, 0			# Compute start memory address
		li $a1, 17
		jal bitmap_address
		sw $s0, platformLoc		# Store location of first platform into memory
		add $a0, $s0, $zero
		li $a1, 21			# Store size of platform
		sw $a1, platformSize
		jal draw_platform		# Draw platform
		
		# Draw second platform
		li $a0, 32			# Compute start memory address
		li $a1, 30
		jal bitmap_address
		sw $s0, platformLoc + 4		# Store location of first platform into memory
		add $a0, $s0, $zero
		li $a1, 32			# Store size of platform
		sw $a1, platformSize + 4
		jal draw_platform		# Draw platform

		# Draw third platform
		li $a0, 9			# Compute start memory address
		li $a1, 45
		jal bitmap_address
		sw $s0, platformLoc + 8		# Store location of first platform into memory
		add $a0, $s0, $zero
		li $a1, 46			# Store size of platform
		sw $a1, platformSize + 8
		jal draw_platform		# Draw platform
		
		# Draw bomb
		li $a0, 49			# Compute start memory address
		li $a1, 42
		jal bitmap_address
		sw $s0, bombLoc
		add $a0, $s0, $zero		# Store start address
		jal draw_bomb			# Draw bomb
			
		# Draw first enemy
		li $a0, 2			# Compute start memory address
		li $a1, 14
		jal bitmap_address
		sw $s0, enemyLoc		# Store location of enemy in enemyState
		add $a0, $s0, $zero
		jal draw_enemy			# Draw enemy
			
		# Draw second enemy
		li $a0, 53			# Compute start memory address
		li $a1, 27
		jal bitmap_address
		sw $s0, enemyLoc + 4		# Store location of enemy in enemyState
		add $a0, $s0, $zero
		jal draw_enemy			# Draw enemy
		
		# Draw third enemy
		li $a0, 40			# Compute start memory address
		li $a1, 42
		jal bitmap_address
		sw $s0, enemyLoc + 8		# Store location of enemy in enemyState
		add $a0, $s0, $zero
		jal draw_enemy			# Draw enemy
		
		# Draw player
		li $a0, 25			# Compute start memory address
		li $a1, 40
		jal bitmap_address
		sw $s0, playerLoc		# Store location of player in memory
		add $a0, $s0, $zero
		jal draw_player			# Draw player
		
		j main
		
setup_level2:	jal draw_level
		li $v0, 10
		syscall
		
setup_level3:	jal draw_level
		li $v0, 10
		syscall
		
main:		li $t9, KEYBOARD 		# Store address of keystroke event
		lw $t8, 0($t9)  		# Check for keystroke event
		beq $t8, 1, pressed		# If no key press, check collision with enemies	
		j jumping
		
pressed:	lw $t8, 4($t9)			# Read what key is pressed
		beq $t8, RIGHT, go_right
		beq $t8, LEFT, go_left
		beq $t8, JUMP, go_up
		beq $t8, SHOOT, place_bomb
		beq $t8, RESET, setup
		j jumping
		
go_left:	lw $a0, collisionEnemy		# Check if player is colliding with any object/screen on the left
		lw $a1, collisionPlatform
		lw $a2, collisionBomb
		lw $a3, collisionScreen
		or $s0, $a0, $a1
		or $s0, $s0, $a2
		or $s0, $s0, $a3
		beq $s0, 1, jumping		# If player is colliding with an object/screen on the left, skip this action
		lw $a0, playerLoc		# Erase player at current location
		jal erase_player
		addi $a0, $a0, -4		# Draw player at new location
		li $a1, -1			# Update xVelocity
		sw $a0, playerLoc
		sw $a1, playerLoc + 4
		jal draw_player
		jal collision_screen		# Update collision
		jal collision_enemy
		jal collision_platform
		jal collision_bomb
		j jumping
		
go_right:	lw $a0, collisionEnemy + 4	# Check if player is colliding with any object/screen on the right
		lw $a1, collisionPlatform + 4
		lw $a2, collisionBomb + 4
		lw $a3, collisionScreen + 4
		or $s0, $a0, $a1
		or $s0, $s0, $a2
		or $s0, $s0, $a3
		beq $s0, 1, jumping		# If player is colliding with an object/screen on the right, skip this action
		lw $a0, playerLoc		# Erase player at current location
		jal erase_player
		addi $a0, $a0, 4		# Draw player at new location
		li $a1, 1			# Update xVelocity
		sw $a0, playerLoc
		sw $a1, playerLoc + 4
		jal draw_player
		jal collision_screen		# Update collision
		jal collision_enemy
		jal collision_platform
		jal collision_bomb
		j jumping
		
go_up:		lw $a0, collisionEnemy + 8	# Check if player is colliding with any object/screen on the top
		lw $a1, collisionPlatform + 8
		lw $a2, collisionBomb + 8
		lw $a3, collisionScreen + 8
		or $s0, $a0, $a1
		or $s0, $s0, $a2
		or $s0, $s0, $a3
		beq $s0, 1, jumping		# If player is colliding with an object/screen on the top, skip this action
		lw $a0, playerLoc + 8		# Check if player is already jumping
		bgtz $a0, double_jump
		lw $a0, collisionPlatform + 12 	# Check if player is standing on platform or enemy
		lw $a1, collisionEnemy + 12
		or $s0, $a0, $a1
		beqz $s0, falling		# If player is not standing on a platform or enemy, skip this action
		addi $a0, $a0, JUMP_HEIGHT
		sw $a0, playerLoc + 8
		j jumping
double_jump:	bgt $a0, JUMP_HEIGHT, jumping	# If player is already double jumping, skip this action
		addi $a0, $a0, JUMP_HEIGHT
		sw $a0, playerLoc + 8		# If player is not double jumping, update yVelocity
		j jumping
		
place_bomb:	jal bombable			# Check if player can place bomb
		beqz $s0, jumping
		lw $t0, numBomb
		lw $a0, playerLoc
		lw $t0, playerLoc + 4		# Load xVelocity
		beq $t0, -1, bomb_left
bomb_right:	addi $a0, $a0, 528
		j bomb_fin
bomb_left:	addi $a0, $a0, 496
		j bomb_fin
bomb_fin:	jal draw_bomb			# Draw bomb at location in $a0
		lw $t0, numBomb			# Calculate offset from start of array from number of bombs
		sll $t0, $t0, 2
		la $t1, bombLoc			# Store location of new bomb into bombLoc
		add $t1, $t0, $t1
		sw $a0, 0($t1)
		la $t1, bombTime		# Store time until explosion into bombTime
		add $t1, $t0, $t1
		li $a0, EXPLOSION_TIME
		sw $a0, 0($t1)
		lw $t0, numBomb			# Increase numBomb by 1
		addi $t0, $t0, 1
		sw $t0, numBomb
		j jumping		
		
jumping:	lw $a0, playerLoc + 8		# Check if player is set to jumping
		blez $a0, falling		# If player is not jumping, skip this action
		lw $a0, collisionEnemy + 8	# Check if player is colliding with any object/screen on the top
		lw $a1, collisionPlatform + 8
		lw $a2, collisionBomb + 8
		lw $a3, collisionScreen + 8
		or $s0, $a0, $a1
		or $s0, $s0, $a2
		or $s0, $s0, $a3
		beq $s0, 1, falling		# If player is colliding with an object/screen on the top, skip this action
		lw $a0, playerLoc		# Erase player at current location
		jal erase_player
		addi $a0, $a0, -256		# Draw player at new location
		sw $a0, playerLoc
		jal draw_player
		lw $a0, playerLoc + 8		# Update yVelocity
		addi $a0, $a0, -1
		sw $a0, playerLoc + 8
		jal collision_screen		# Update collision
		jal collision_enemy
		jal collision_platform
		jal collision_bomb
		j falling
		
falling:	lw $a0, playerLoc + 8		# Check if player is set to jumping
		bgtz $a0, update		# If player is jumping, skip this action
		jal collision_screen		# Update collision
		jal collision_enemy
		jal collision_platform
		jal collision_bomb
		lw $a0, collisionPlatform + 12 	# Check if player is standing on platform/enemy/bomb
		lw $a1, collisionEnemy + 12
		lw $a2, collisionBomb + 12
		or $s0, $a0, $a1
		or $s0, $s0, $a2
		bnez $s0, update		# If player is standing on a platform or enemy, skip this action
		lw $a0, playerLoc		# Check if fall out of screen
		jal xy_address	
		addi $s1, $s1, 1
		bgt $s1, 64, fail		# If fall out of screen, fail
		lw $a0, playerLoc
		jal erase_player		# Erase player at current location
		addi $a0, $a0, 256		# Get new address after key pressed
		sw $a0, playerLoc		
		jal draw_player			# Draw player at new location
		
update:		jal explosion
		jal kill_bomb
		jal kill_player
		jal kill_enemy
		jal redraw_active_bomb
		lw $t0, playerHealth
		blez $t0, fail
		jal redraw_inactive_bomb
		lw $a0, playerLoc
		jal draw_player
		jal redraw_enemy
		lw $a0, numEnemy
		beqz $a0, level_up
		jal move_enemy
		jal collision_screen
		jal collision_platform
		jal collision_bomb
		jal collision_enemy
ce_check:	lw $t1, collisionEnemy
		lw $t2, collisionEnemy + 4
		lw $t3, collisionEnemy + 8
		lw $t4, collisionEnemy + 12
		or $t1, $t1, $t2
		or $t1, $t1, $t3
		or $t1, $t1, $t4
		bne $t1, 1, ce_n
ce_y:		lw $a0, playerLoc
		jal draw_player_off
		lw $t5, playerHealth		# Decrease health
		addi $t5, $t5, -1
		blez $t5, fail			# If health < 0, fail
		sw $t5, playerHealth
		li $v0, 1			# Print to debug
		add $a0, $t5, $zero
		syscall
		li $v0, 4
		la $a0, newline
		syscall
		jal decrease_health_bar
		j sleep
ce_n:		lw $a0, playerLoc
		jal draw_player
		j sleep		
	
sleep:		li $v0, 32			# Sleep to see animation
		li $a0, SLEEP_TIME
		j main				# Repeat main
		
fail:		jal erase_screen
		jal game_over
		# End program
		li $v0, 10
		syscall
		
level_up:	lw $a0, level
		beq $a0, 1, win
		addi $a0, $a0, 1
		sw $a0, level
		j setup
win:		jal erase_screen
		jal you_win
		li $v0, 10
		syscall
	
# This function checks collision with the screen and update collisionScreen.
# Arguments:	None
# Registers: 	$a0, $a1, $s0, $s1
# Returns:	None	
collision_screen: sw $zero, collisionScreen	# Reset collisionScreen
		sw $zero, collisionScreen + 4
		sw $zero, collisionScreen + 8
		sw $zero, collisionScreen + 12 
		lw $a0, playerLoc
		addi $sp, $sp, -4		# Push old $ra to stack to call xy_address
		sw $ra, 0($sp)
		jal xy_address
		lw $ra, 0($sp)
		addi $sp, $sp, 4
cs_top:		beq $s1, 7, cs_top_y
cs_top_n:	sw $zero, collisionScreen + 8
cs_bottom:	beq $s1, 59, cs_bottom_y
cs_bottom_n:	sw $zero, collisionScreen + 12
cs_left:	beq $s0, 2, cs_left_y
cs_left_n:	sw $zero, collisionScreen
cs_right:	beq $s0, 61, cs_right_y
cs_right_n:	sw $zero, collisionScreen + 4
		jr $ra
cs_top_y:	li $a1, 1
		sw $a1, collisionScreen + 8
		sw $zero, playerLoc + 8		# Update yVelocity
		j cs_bottom
cs_bottom_y:	li $a1, 1
		sw $a1, collisionScreen + 12
		j cs_left
cs_left_y:	li $a1, 1
		sw $a1, collisionScreen
		j cs_right
cs_right_y:	li $a1, 1
		sw $a1, collisionScreen + 4
		
# This function checks collision with enemies and updates collisionEnemy.
# Arguments:	None
# Registers:	$a0, $a1, $s0, $s1, $t0-$t6, $v0
# Returns:	None
collision_enemy: sw $zero, collisionEnemy	# Reset collisionEnemy
		sw $zero, collisionEnemy + 4
		sw $zero, collisionEnemy + 8
		sw $zero, collisionEnemy + 12
		addi $sp, $sp, -4		# Push old $ra to stack to call xy_address
		sw $ra, 0($sp)
		lw $a0, playerLoc		# Calculate xy-coordinates for player
		jal xy_address			# Calculate xy-coordinates for player
		add $t1, $s0, $zero
		add $t2, $s1, $zero
		lw $t0, numEnemy		# Load number of enemies to check
		la $a1, enemyLoc
ce_loop:	beqz $t0, ce_end		
		lw $a0, 0($a1)			# Calculate xy-coordinates for enemy
		jal xy_address
		add $t3, $s0, $zero
		add $t4, $s1, $zero
ce_bottom:	addi $t5, $t2, 5
		bne $t5, $t4, ce_left		# player bottom + 1 != enemy top, no bottom collision
		addi $t5, $t1, -2
		addi $t6, $t3, 2
		blt $t6, $t5, ce_left		# enemy right < player left, no bottom collision
		addi $t5, $t1, 2
		bgt $t3, $t5, ce_left		# enemy left > player right, no bottom collision
		li $t5, 1			# Update collision with enemy at bottom
		sw $t5, collisionEnemy + 12
ce_left:	addi $t5, $t1, -3
		addi $t6, $t3, 2
		bne $t5, $t6, ce_right		# player left - 1 != enemy right, no left collision
		addi $t5, $t2, 4
		blt $t5, $t4, ce_right		# player bottom < enemy top, no left collision
		addi $t6, $t4, 2
		bgt $t2, $t6, ce_right		# player top > enemy bottom, no left collision
		li $t5, 1			# Update collision with enemy on the left
		sw $t5, collisionEnemy
ce_right:	addi $t5, $t1, 3
		bne $t5, $t3, ce_top		# player right + 1 != enemy left, no right collision
		addi $t5, $t2, 4
		blt $t5, $t4, ce_top		# player bottom < enemy top, no right collision
		addi $t6, $t4, 2
		bgt $t2, $t6, ce_top		# player top > enemy bottom, no right collision
		li $t5, 1			# Update collision with enemy on the right
		sw $t5, collisionEnemy + 4
ce_top:		addi $t5, $t2, -1
		addi $t6, $t4, 2
		bne $t5, $t6, ce_skip		# player top + 1 != enemy bottom, no top collision
		addi $t5, $t1, -2
		addi $t6, $t3, 2
		blt $t6, $t5, ce_skip		# enemy right < player left, no top collision
		addi $t5, $t1, 2
		bgt $t3, $t5, ce_skip		# enemy left > player right, no top collision		
		li $t5, 1			# Update collision with enemy on top
		sw $t5, collisionEnemy + 8
		sw $zero, playerLoc + 8		# Update yVelocity
ce_skip:	addi $a1, $a1, 4		# $a2 stores address of next enemy
		addi $t0, $t0, -1		# Decrement $t0 (number of enemies left to check)
		j ce_loop
ce_end:		lw $ra, 0($sp)			# Pop old $ra
		addi $sp, $sp, 4
		jr $ra

# This function checks collision with platforms and updates collisionPlatform.
# Arguments:	None
# Registers:	$a0, $a1, $a2, $s0, $s1, $t0-$t6
collision_platform: sw $zero, collisionPlatform	# Reset collisionPlatform
		sw $zero, collisionPlatform + 4
		sw $zero, collisionPlatform + 8
		sw $zero, collisionPlatform + 12
		addi $sp, $sp, -4		# Push old $ra to stack to call xy_address
		sw $ra, 0($sp)
		lw $a0, playerLoc		# Calculate xy-coordinates for player
		jal xy_address
		add $t1, $s0, $zero
		add $t2, $s1, $zero
		lw $t0, numPlatform		# Load number of platforms to check
		la $a1, platformLoc
		la $a2, platformSize
cp_loop:	beqz $t0, cp_end		
		lw $a0, 0($a1)			# Calculate xy-coordinates for platform
		jal xy_address
		add $t3, $s0, $zero
		add $t4, $s1, $zero
		lw $a0, 0($a2)			# Store size of platform
cp_bottom:	addi $t5, $t2, 5
		bne $t5, $t4, cp_left		# player bottom + 1 != platform top, no bottom collision
		addi $t5, $t1, -2
		add $t6, $t3, $a0
		addi $t6, $t6, -1
		blt $t6, $t5, cp_left		# platform right < player left, no bottom collision
		addi $t5, $t1, 2
		bgt $t3, $t5, cp_left		# platform left > player right, no bottom collision
		li $t5, 1			# Update collision with platform at bottom
		sw $t5, collisionPlatform + 12
cp_left:	addi $t5, $t1, -3
		add $t6, $t3, $a0
		addi $t6, $t6, -1
		bne $t5, $t6, cp_right		# player left - 1 != platform right, no left collision
		addi $t5, $t2, 4
		blt $t5, $t4, cp_right		# player bottom < platform top, no left collision
		addi $t6, $t4, 1
		bgt $t2, $t6, cp_right		# player top > platform bottom, no left collision
		li $t5, 1			# Update collision with enemy on the left
		sw $t5, collisionPlatform
cp_right:	addi $t5, $t1, 3
		bne $t5, $t3, cp_top		# player right + 1 != platform left, no right collision
		addi $t5, $t2, 4
		blt $t5, $t4, cp_top		# player bottom < platform top, no right collision
		addi $t6, $t4, 1
		bgt $t2, $t6, cp_top		# player top > platform bottom, no right collision
		li $t5, 1			# Update collision with enemy on the right
		sw $t5, collisionPlatform + 4
cp_top:		addi $t5, $t2, -1
		addi $t6, $t4, 1
		bne $t5, $t6, cp_skip		# player top + 1 != platform bottom, no top collision
		addi $t5, $t1, -2
		add $t6, $t3, $a0
		addi $t6, $t6, -1
		blt $t6, $t5, cp_skip		# platform right < player left, no top collision
		addi $t5, $t1, 2
		bgt $t3, $t5, cp_skip		# platform left > player right, no top collision
		li $t5, 1			# Update collision with platform at top
		sw $t5, collisionPlatform + 8
		sw $zero, playerLoc + 8		# Update yVelocity
cp_skip:	addi $a1, $a1, 4		# $a1 stores address of next platform
		addi $a2, $a2, 4		# $a2 stores address of next platform size
		addi $t0, $t0, -1		# Decrement $t0 (number of platforms left to check)
		j cp_loop
cp_end: 	lw $ra, 0($sp)			# Pop old $ra
		addi $sp, $sp, 4
		jr $ra
		
# This function checks collision with bombs and updates collisionBomb.
# Arguments:	None
# Registers:	$a0, $a1, $s0, $s1, $t0-$t6
collision_bomb: sw $zero, collisionBomb		# Reset collisionBomb
		sw $zero, collisionBomb + 4
		sw $zero, collisionBomb + 8
		sw $zero, collisionBomb + 12
		addi $sp, $sp, -4		# Push old $ra to stack to call xy_address
		sw $ra, 0($sp)
		lw $a0, playerLoc		# Calculate xy-coordinates for player
		jal xy_address
		add $t1, $s0, $zero
		add $t2, $s1, $zero
		lw $t0, numBomb			# Load number of bombs to check
		la $a1, bombLoc
cb_loop:	beqz $t0, cb_end		
		lw $a0, 0($a1)			# Calculate xy-coordinates for bomb
		jal xy_address
		add $t3, $s0, $zero
		add $t4, $s1, $zero
cb_bottom:	addi $t5, $t2, 5
		bne $t5, $t4, cb_left		# player bottom + 1 != bomb top, no bottom collision
		addi $t5, $t1, -2
		addi $t6, $t3, 1
		blt $t6, $t5, cb_left		# bomb right < player left, no bottom collision
		addi $t5, $t1, 2
		addi $t6, $t3, -1
		bgt $t6, $t5, cb_left		# bomb left > player right, no bottom collision
		li $t5, 1			# Update collision with bomb at bottom
		sw $t5, collisionBomb + 12
cb_left:	addi $t5, $t1, -3
		addi $t6, $t3, 1
		bne $t5, $t6, cb_right		# player left - 1 != bomb right, no left collision
		addi $t5, $t2, 4
		blt $t5, $t4, cb_right		# player bottom < bomb top, no left collision
		addi $t6, $t4, 2
		bgt $t2, $t6, cb_right		# player top > bomb bottom, no left collision
		li $t5, 1			# Update collision with bomb on the left
		sw $t5, collisionBomb
cb_right:	addi $t5, $t1, 3
		addi $t6, $t3, -1
		bne $t5, $t6, cb_top		# player right + 1 != bomb left, no right collision
		addi $t5, $t2, 4
		blt $t5, $t4, cb_top		# player bottom < bomb top, no right collision
		addi $t6, $t4, 2
		bgt $t2, $t6, cb_top		# player top > bomb bottom, no right collision
		li $t5, 1			# Update collision with bomb on the right
		sw $t5, collisionBomb + 4
cb_top:		addi $t5, $t2, -1
		addi $t6, $t4, 2
		bne $t5, $t6, cb_skip		# player top + 1 != bomb bottom, no top collision
		addi $t5, $t1, -2
		addi $t6, $t3, 1
		blt $t6, $t5, cb_skip		# bomb right < player left, no top collision
		addi $t5, $t1, 2
		addi $t6, $t3, -1
		bgt $t6, $t5, cb_skip		# bomb left > player right, no top collision
		li $t5, 1			# Update collision with bomb at top
		sw $t5, collisionBomb + 8
		sw $zero, playerLoc + 8		# Update yVelocity
cb_skip:	addi $a1, $a1, 4		# $a1 stores address of next bomb
		addi $t0, $t0, -1		# Decrement $t0 (number of bombs left to check)
		j cb_loop
cb_end: 	lw $ra, 0($sp)			# Pop old $ra
		addi $sp, $sp, 4
		jr $ra

# This function checks whether player can place bomb.
bombable:	addi $sp, $sp, -4		# Push old $ra to stack to call xy_address
		sw $ra, 0($sp)
		lw $a0, collisionPlatform + 12	# If player is not standing on platform, cannot place bomb
		bne $a0, 1, bombable_n
		lw $a0, numBomb			# If player already have maximum active bombs, cannot place bomb
		bge $a0, MAX_BOMB, bombable_n
		lw $a0, playerLoc		# Compute xy-coordinates of player
		jal xy_address
		addi $t1, $s0, 0
		addi $t2, $s1, 0
		lw $t0, playerLoc + 4		# Load xVelocity
		beq $a0, -1, bombable_left
bombable_right:	bgt $t1, 60, bombable_n
		lw $a0, playerLoc
		addi $a0, $a0, 524
		lw $t0, 0($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, 4($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, 8($a0)
		bne $t0, ERASE, bombable_n
		addi $a0, $a0, 256
		lw $t0, 0($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, 4($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, 8($a0)
		bne $t0, ERASE, bombable_n
		addi $a0, $a0, 256
		lw $t0, 0($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, 4($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, 8($a0)
		bne $t0, ERASE, bombable_n
		j bombable_y
bombable_left:	blt $t1, 3, bombable_n
		lw $a0, playerLoc
		addi $a0, $a0, 500
		lw $t0, 0($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, -4($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, -8($a0)
		bne $t0, ERASE, bombable_n
		addi $a0, $a0, 256
		lw $t0, 0($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, -4($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, -8($a0)
		bne $t0, ERASE, bombable_n
		addi $a0, $a0, 256
		lw $t0, 0($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, -4($a0)
		bne $t0, ERASE, bombable_n
		lw $t0, -8($a0)
		bne $t0, ERASE, bombable_n
		j bombable_y
bombable_n:	li $s0, 0
		j bombable_end
bombable_y:	li $s0, 1
		j bombable_end
bombable_end:	lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

# This function counts down until explosion and updates bombTime.		
explosion:	la $a3, bombTime
		la $a2, bombQueue
		lw $t7, numBomb
explosion_loop:	blez $t7, explosion_fin	# Decrease time until explosion
		lw $t5, 0($a3)
		addi $t5, $t5, -1
		sw $t5, 0($a3)
		blez $t5, explosion_y
		addi $t7, $t7, -1
		addi $a2, $a2, 4
		addi $a3, $a3, 4
explosion_n:	sw $zero, 0($a2)
		j explosion_loop
explosion_fin:	jr $ra
explosion_y:	li $t5, 1
		sw $t5, 0($a2)
		addi $t7, $t7, -1
		addi $a2, $a2, 4
		addi $a3, $a3, 4
		j explosion_loop

# This function kills player if in close proximity with an exploding bomb.	
kill_player:	addi $sp, $sp, -4
		sw $ra, 0($sp)
		la $a2, bombLoc
		la $a3, bombTime
		lw $t7, numBomb
kp_check_bomb: 	blez $t7, kp_fin
		lw $t0, 0($a3)
		blez $t0, kp_check_player
kp_check_bomb_next: addi $t7, $t7, -1
		addi $a2, $a2, 4
		addi $a3, $a3, 4
		j kp_check_bomb
kp_check_player: lw $a0, playerLoc
		jal xy_address
		add $t1, $s0, $zero
		add $t2, $s1, $zero
		lw $a0, 0($a2)
		jal xy_address
		add $t3, $s0, $zero
		add $t4, $s1, $zero
		addi $t5, $t2, 2
		bne $t5, $t4, kp_check_bomb_next	# player and bomb not on the same y-coordinate, not kill player
		addi $t5, $t1, -2
		addi $t6, $t3, EXPLOSION_RANGE
		bge $t5, $t6, kp_check_bomb_next	# player left >= explosion right, not kill player (allow a bit contact)
		addi $t5, $t1, 2
		subi $t6, $t3, EXPLOSION_RANGE
		ble $t5, $t6, kp_check_bomb_next	# player right <= explosion left, not kill player (allow a bit contact)	
		sw $zero, playerHealth			# player in explosion range, kill player
kp_fin:		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
		
# This function kills enemies and updates enemyQueue if in close proximity with an exploding bomb.
kill_enemy:	addi $sp, $sp, -4
		sw $ra, 0($sp)
		la $a2, bombLoc
		la $a3, bombQueue
		lw $t7, numBomb
ke_check_bomb: 	blez $t7, ke_fin
		lw $t0, 0($a3)
		beq $t0, 1, ke_check_enemy
ke_check_bomb_next: addi $t7, $t7, -1
		addi $a2, $a2, 4
		addi $a3, $a3, 4
		j ke_check_bomb
ke_check_enemy:	lw $a0, 0($a2)
		jal xy_address
		add $t1, $s0, $zero
		add $t2, $s1, $zero
		lw $t0, numEnemy
		la $t8, enemyLoc
		la $t9, enemyQueue
ke_check_enemy_loop: beqz $t0, ke_check_bomb_next
		lw $a0, 0($t8)
		jal xy_address
		add $t3, $s0, $zero
		add $t4, $s1, $zero
		addi $t5, $t2, 2
		addi $t6, $t4, 2
		bne $t5, $t6, ke_check_enemy_n
		addi $t5, $t1, EXPLOSION_RANGE
		bgt $t3, $t5, ke_check_enemy_n
		subi $t5, $t1, EXPLOSION_RANGE
		addi $t6, $t3, 2
		blt $t6, $t5, ke_check_enemy_n
		li $t5, -1
		sw $t5, 0($t9)
ke_check_enemy_next: addi $t8, $t8, 4
		addi $t0, $t0, -1
		addi $t9, $t9, 4
		j ke_check_enemy_loop
ke_fin:		lw $ra, 0($sp)
		addi $sp, $sp 4
		jr $ra
ke_check_enemy_n: sw $zero, 0($t9)
		j ke_check_enemy_next
		
# This function aggregates effect of bomb if in close proximity and updates bombQueue.
kill_bomb:	addi $sp, $sp, -4
		sw $ra, 0($sp)
		la $a2, bombLoc
		la $a3, bombQueue
		lw $t7, numBomb
kb_check_bomb: 	blez $t7, kb_fin
		lw $t0, 0($a3)
		beq $t0, 1, kb_check_other
kb_check_bomb_next: addi $t7, $t7, -1
		addi $a2, $a2, 4
		addi $a3, $a3, 4
		j kb_check_bomb	
kb_check_other: lw $a0, 0($a2)
		jal xy_address
		add $t1, $s0, $zero
		add $t2, $s1, $zero
		lw $t0, numBomb
		la $t8, bombLoc
		la $t9, bombQueue
kb_check_other_loop: beqz $t0, kb_check_bomb_next
		lw $a0, 0($t8)
		jal xy_address
		add $t3, $s0, $zero
		add $t4, $s1, $zero
		bne $t2, $t4, kb_check_other_next
		addi $t5, $t1, EXPLOSION_RANGE
		addi $t6, $t3, -1
		bgt $t6, $t5, kb_check_other_next
		subi $t5, $t1, EXPLOSION_RANGE
		addi $t6, $t3, 1
		blt $t6, $t5, kb_check_other_next
		li $t5, 1
		sw $t5, 0($t9)
kb_check_other_next: addi $t8, $t8, 4
		addi $t0, $t0, -1
		addi $t9, $t9, 4
		j kb_check_other_loop
kb_fin:		lw $ra, 0($sp)
		addi $sp, $sp 4
		jr $ra
		
# This function draws explosion and updates bombQueue after done.	
redraw_active_bomb: addi $sp, $sp, -4
		sw $ra, 0($sp)
		la $a2, bombLoc
		la $a3, bombQueue
		lw $t7, numBomb
rab_loop:	blez $t7, rab_fin
		lw $t0, 0($a3)
		beq $t0, 1, rab_on
rab_next:	addi $t7, $t7, -1
		addi $a2, $a2, 4
		addi $a3, $a3, 4
		j rab_loop
rab_on:		li $s7, -1
		sw $s7, 0($a3)
		lw $s0, 0($a2)
		lw $s1, 0($a2)
		li $s7, 1
		li $s6, BOMB
rab_on_loop:	bgt $s7, EXPLOSION_RANGE, rab_next
		addi $s0, $s0, -4
		addi $s1, $s1, 4
		sw $s6, 0($s0)
		sw $s6, 0($s1)
		sw $s6, 256($s0)
		sw $s6, 256($s1)
		sw $s6, 512($s0)
		sw $s6, 512($s1)
		addi $s7, $s7, 1
		j rab_on_loop	
rab_fin:	lw $ra, 0($sp)
		addi $sp, $sp 4
		jr $ra
		
# This function redraws inactive bombs and updates bombLoc, bombTime, numBomb.	
redraw_inactive_bomb: addi $sp, $sp, -4
		sw $ra, 0($sp)
		la $a1, bombTime
		la $a2, bombLoc
		la $a3, bombQueue
		lw $t7, numBomb
rib_loop:	blez $t7, rib_fin
		lw $t0, 0($a3)
		beq $t0, -1, rib_off
rib_next:	addi $t7, $t7, -1
		addi $a1, $a1, 4
		addi $a2, $a2, 4
		addi $a3, $a3, 4
		j rib_loop
rib_off:	sw $zero, 0($a3)
		lw $s0, 0($a2)
		lw $s1, 0($a2)
		li $s7, 1
		li $s6, ERASE
		sw $s6, 0($s0)
		sw $s6, 256($s0)
		sw $s6, 512($s0)
rib_off_loop:	bgt $s7, EXPLOSION_RANGE, rib_remove
		addi $s0, $s0, -4
		addi $s1, $s1, 4
		sw $s6, 0($s0)
		sw $s6, 0($s1)
		sw $s6, 256($s0)
		sw $s6, 256($s1)
		sw $s6, 512($s0)
		sw $s6, 512($s1)
		addi $s7, $s7, 1
		j rib_off_loop
rib_remove:	lw $t6, numBomb
		lw $t5, numBomb
		addi $t5, $t5, -1
		sw $t5, numBomb
		add $s1, $a1, $zero
		add $s2, $a2, $zero
		add $s3, $a3, $zero
		beq $t6, 1, rib_remove_one
		addi $t6, $t7, -1
rib_remove_loop: blez $t6, rib_remove_next
		lw $s6, 4($s2)
		sw $s6, 0($s2)
		lw $s6, 4($s1)
		sw $s6, 0($s1)
		lw $s6, 4($s3)
		sw $s6, 0($s3)
		addi $s2, $s2, 4
		addi $s1, $s1, 4
		addi $s3, $s3, 4
		addi $t6, $t6, -1
		j rib_remove_loop
rib_remove_next: addi $t7, $t7, -1
		j rib_loop
rib_remove_one:	sw $zero, 0($s2)
		sw $zero, 0($s1)
		sw $zero, 0($s3)	
rib_fin:	lw $ra, 0($sp)
		addi $sp, $sp 4
		jr $ra
		
# This function redraws enemies and updates numEnemy, enemyLoc.
redraw_enemy: 	addi $sp, $sp, -4
		sw $ra, 0($sp)
		la $a1, enemyPos
		la $a2, enemyLoc
		la $a3, enemyQueue
		lw $t7, numEnemy
re_loop:	blez $t7, re_fin
		lw $t0, 0($a3)
		beq $t0, -1, re_remove
		lw $a0, 0($a2)
		jal draw_enemy
		addi $t7, $t7, -1
		addi $a1, $a1, 4
		addi $a2, $a2, 4
		addi $a3, $a3, 4
		j re_loop
re_remove:	lw $a0, 0($a2)
		jal erase_enemy
		lw $t6, numEnemy
		lw $t5, numEnemy
		addi $t5, $t5, -1
		sw $t5, numEnemy
		add $s1, $a1, $zero
		add $s2, $a2, $zero
		add $s3, $a3, $zero
		beq $t6, 1, re_remove_one
		addi $t6, $t7, -1
re_remove_loop: blez $t6, re_remove_next
		lw $s6, 4($s1)
		sw $s6, 0($s1)
		lw $s6, 4($s2)
		sw $s6, 0($s2)
		lw $s6, 4($s3)
		sw $s6, 0($s3)
		addi $s1, $s1, 4
		addi $s2, $s2, 4
		addi $s3, $s3, 4
		addi $t6, $t6, -1
		j re_remove_loop
re_remove_next: addi $t7, $t7, -1
		j re_loop
re_remove_one:	sw $zero, 0($s1)
		sw $zero, 0($s2)
		sw $zero, 0($s3)	
re_fin:		lw $ra, 0($sp)
		addi $sp, $sp 4
		jr $ra
		
# This function moves enemies.
move_enemy:	addi $sp, $sp, -4
		sw $ra, 0($sp)
		la $s1, enemyLoc
		la $s2, enemyPos
		lw $t0, numEnemy
me_loop:	blez $t0, me_fin
		lw $a0, 0($s1)
		jal erase_enemy
		lw $s0, 0($s1)
		lw $t1, 0($s2)
		lw $t3, 12($s0)
		bne $t3, ERASE, me_cont
		lw $t3, 268($s0)
		bne $t3, ERASE, me_cont
		lw $t3, 524($s0)
		bne $t3, ERASE, me_cont
		lw $t3, -4($s0)
		bne $t3, ERASE, me_cont
		lw $t3, 252($s0)
		bne $t3, ERASE, me_cont
		lw $t3, 508($s0)
		bne $t3, ERASE, me_cont
		beq $t1, 10, me_left
		beqz $t1, me_right
		lw $t2, 4($s2)
		add $s0, $s0, $t2
		bltz $t2, me_cont_left
me_cont_right:	addi $t1, $t1, 1
		sw $t1, 0($s2)
		j me_cont
me_cont_left:	addi $t1, $t1, -1
		sw $t1, 0($s2)
		j me_cont
me_right:	addi $s0, $s0, 4
		addi $t1, $t1, 1
		sw $t1, 0($s2)
		li $t2, 4
		sw $t2, 4($s2)
		j me_cont
me_left:	addi $s0, $s0, -4
		addi $t1, $t1, -1
		sw $t1, 0($s2)
		li $t2, -4
		sw $t2, 4($s2)
me_cont:	sw $s0, 0($s1)
		add $a0, $s0, $zero
		jal draw_enemy
		addi $t0, $t0, -1
		addi $s1, $s1, 4
		addi $s2, $s2, 8
		j me_loop
me_fin:		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
						
# This function clears the screen.
# Arguments:	None
# Registers:	Color value	$s0
# 		Current cell	$s1
#		Last cell	$s2
# Returns:	None
erase_screen:	li $s0, ERASE
		li $s1, BASE_ADDRESS
		addi $s2, $s1, 16380
es_loop:	bgt $s1, $s2, es_fin
		sw $s0, 0($s1)
		addi $s1, $s1, 4
		j es_loop
es_fin:		jr $ra

# This function erases player at address $a0.
# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	None	
erase_player:	li $s0, ERASE
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
		
# This function erases enemy at memory address $a0.
# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	None	
erase_enemy:	li $s0, ERASE
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 260($a0)
		sw $s0, 264($a0)
		sw $s0, 520($a0)
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		sw $s0, 516($a0)
		jr $ra

# This function computes the memory address of the given (x, y) location.	
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

# This function computes the (x, y) location given the memory address.	
# Arguments:	memory address	$a0
# Registers:	tmp, return	$s0
# Returns:	x-coordinate	$s0
#		y-coordinate	$s1	
xy_address:	subi $a0, $a0, BASE_ADDRESS	# Get offset from (0, 0)
		sra $a0, $a0, 2			# Divide by 4 to get (y*width + x)
		li $s0, SIZE_BY_UNIT		
		div $a0, $s0			# Divide by width to get x and y
		mfhi $s0			# Remainder is x
		mflo $s1			# Quotient is y
		jr $ra

# This function draws a platform of size $a1 starting from memory address $a0.	
# Arguments:	Start address	$a0
#		Size		$a1
# Registers:	Color value	$s0
#		Current address	$s1
# Returns:	None	
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

# This function draws an enemy at memory address $a0.
# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	None	
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

# This function draws player at memory address $a0.
# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	None	
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
		
# This function draws player losing health at memory address $a0.
# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	None	
draw_player_off: li $s0, FIRE_OFF		# Load line color for player
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

# This function draws a bomb at memory address $a0.
# Arguments:	Start address	$a0
# Registers:	Color value	$s0
# Returns:	None		
draw_bomb:	li $s0, BOMB			# Load color for bomb
		sw $s0, 0($a0)
		sw $s0, 252($a0)
		sw $s0, 256($a0)
		sw $s0, 260($a0)
		sw $s0, 508($a0)
		sw $s0, 512($a0)
		jr $ra
		
# This function draws a health bar on top left of the screen.
draw_health_bar: lw $s1, playerHealth
		li $s0, 10
		div $s1, $s0
		mflo $s1
		li $s0, HEALTH_BAR_FULL
		li $a0, HEALTH_BAR_START
hb_loop:	blez $s1, hb_fin
		sw $s0, 0($a0)
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		addi $s1, $s1, -1
		add $a0, $a0, 4
		j hb_loop
hb_fin:		jr $ra
		
# This function draws the menu bar
draw_menu:	li $s0, MENU_BACKGROUND
		li $a0, BASE_ADDRESS
		li $s1, 64
menu_loop:	blez $s1, menu_fin
		sw $s0, 0($a0)
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		sw $s0, 768($a0)
		sw $s0, 1024($a0)
		sw $s0, 1280($a0)
		sw $s0, 1536($a0)
		addi $s1, $s1, -1
		add $a0, $a0, 4
		j menu_loop
menu_fin:	jr $ra

# This function draws level number.
draw_level:	li $a0, LEVEL_ADDRESS
		lw $s0, level
		beq $s0, 2, level2
		beq $s0, 3, level3
		li $s0, MENU_TEXT
		sw $s0, 4($a0)
		sw $s0, 256($a0)
		sw $s0, 260($a0)
		sw $s0, 516($a0)
		sw $s0, 772($a0)
		sw $s0, 1024($a0)
		sw $s0, 1028($a0)
		sw $s0, 1032($a0)
		jr $ra
level2:		li $s0, MENU_TEXT
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 264($a0)
		sw $s0, 516($a0)
		sw $s0, 768($a0)
		sw $s0, 1024($a0)
		sw $s0, 1028($a0)
		sw $s0, 1032($a0)
		jr $ra
level3:		li $s0, MENU_TEXT
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 264($a0)
		sw $s0, 516($a0)
		sw $s0, 520($a0)
		sw $s0, 776($a0)
		sw $s0, 1024($a0)
		sw $s0, 1028($a0)
		sw $s0, 1032($a0)
		jr $ra

# This function erases the health bar from end to start.	
decrease_health_bar: li $a0, HEALTH_BAR_END
		lw $s0, playerHealth
		li $s1, 10
		div $s0, $s1
		li $s1, 50
		mflo $s0
		sub $s0, $s1, $s0
		mfhi $s1
		beqz $s1, dhb_loop
		addi $s0, $s0, -1
dhb_loop:	beqz $s0, dhb_fin
		li $s1, HEALTH_BAR_EMPTY
		sw $s1, 0($a0)
		sw $s1, 256($a0)
		sw $s1, 512($a0)
		addi $s0, $s0, -1
		addi $a0, $a0, -4
		j dhb_loop
dhb_fin:	jr $ra

# This function draws fail screen
game_over:	li $a0, 0x1000984C
		li $s0, FAIL_TEXT
		sw $s0, 4($a0)			# G
		sw $s0, 8($a0)
		sw $s0, 256($a0)
		sw $s0, 268($a0)
		sw $s0, 512($a0)
		sw $s0, 768($a0)
		sw $s0, 776($a0)
		sw $s0, 780($a0)
		sw $s0, 1024($a0)
		sw $s0, 1036($a0)
		sw $s0, 1284($a0)
		sw $s0, 1288($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 12($a0)
		sw $s0, 260($a0)
		sw $s0, 272($a0)
		sw $s0, 516($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 1028($a0)
		sw $s0, 1040($a0)
		sw $s0, 1292($a0)
		addi $a0, $a0, 24		# A
		li $s0, FAIL_TEXT
		sw $s0, 8($a0)
		sw $s0, 12($a0)
		sw $s0, 260($a0)
		sw $s0, 268($a0)
		sw $s0, 512($a0)
		sw $s0, 524($a0)
		sw $s0, 768($a0)
		sw $s0, 780($a0)
		sw $s0, 1024($a0)
		sw $s0, 1028($a0)
		sw $s0, 1032($a0)
		sw $s0, 1036($a0)
		sw $s0, 1280($a0)
		sw $s0, 1292($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 16($a0)
		sw $s0, 264($a0)
		sw $s0, 272($a0)
		sw $s0, 516($a0)
		sw $s0, 528($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 1040($a0)
		sw $s0, 1284($a0)
		sw $s0, 1296($a0)
		addi $a0, $a0, 24		# M
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 24($a0)
		sw $s0, 256($a0)
		sw $s0, 260($a0)
		sw $s0, 276($a0)
		sw $s0, 280($a0)
		sw $s0, 512($a0)
		sw $s0, 520($a0)
		sw $s0, 528($a0)
		sw $s0, 536($a0)
		sw $s0, 768($a0)
		sw $s0, 780($a0)
		sw $s0, 792($a0)
		sw $s0, 1024($a0)
		sw $s0, 1048($a0)
		sw $s0, 1280($a0)
		sw $s0, 1304($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 4($a0)
		sw $s0, 28($a0)
		sw $s0, 264($a0)
		sw $s0, 284($a0)
		sw $s0, 516($a0)
		sw $s0, 524($a0)
		sw $s0, 532($a0)
		sw $s0, 540($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 796($a0)
		sw $s0, 1028($a0)
		sw $s0, 1052($a0)
		sw $s0, 1284($a0)
		sw $s0, 1308($a0)
		addi $a0, $a0, 36		# E
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 12($a0)
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		sw $s0, 516($a0)
		sw $s0, 520($a0)
		sw $s0, 768($a0)
		sw $s0, 1024($a0)
		sw $s0, 1280($a0)
		sw $s0, 1284($a0)
		sw $s0, 1288($a0)
		sw $s0, 1292($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 16($a0)
		sw $s0, 260($a0)
		sw $s0, 524($a0)
		sw $s0, 772($a0)
		sw $s0, 1028($a0)
		sw $s0, 1296($a0)
		addi $a0, $a0, 1712		# O
		li $s0, FAIL_TEXT
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 256($a0)
		sw $s0, 268($a0)
		sw $s0, 512($a0)
		sw $s0, 524($a0)
		sw $s0, 768($a0)
		sw $s0, 780($a0)
		sw $s0, 1024($a0)
		sw $s0, 1036($a0)
		sw $s0, 1284($a0)
		sw $s0, 1288($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 12($a0)
		sw $s0, 260($a0)
		sw $s0, 272($a0)
		sw $s0, 516($a0)
		sw $s0, 528($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 1028($a0)
		sw $s0, 1040($a0)
		sw $s0, 1292($a0)
		addi $a0, $a0, 24		# V
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 16($a0)
		sw $s0, 256($a0)
		sw $s0, 272($a0)
		sw $s0, 512($a0)
		sw $s0, 528($a0)
		sw $s0, 768($a0)
		sw $s0, 784($a0)
		sw $s0, 1028($a0)
		sw $s0, 1036($a0)
		sw $s0, 1288($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 4($a0)
		sw $s0, 20($a0)
		sw $s0, 260($a0)
		sw $s0, 276($a0)
		sw $s0, 516($a0)
		sw $s0, 532($a0)
		sw $s0, 772($a0)
		sw $s0, 788($a0)
		sw $s0, 1032($a0)
		sw $s0, 1040($a0)
		sw $s0, 1292($a0)
		addi $a0, $a0, 28		# E
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 12($a0)
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		sw $s0, 516($a0)
		sw $s0, 520($a0)
		sw $s0, 768($a0)
		sw $s0, 1024($a0)
		sw $s0, 1280($a0)
		sw $s0, 1284($a0)
		sw $s0, 1288($a0)
		sw $s0, 1292($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 16($a0)
		sw $s0, 260($a0)
		sw $s0, 524($a0)
		sw $s0, 772($a0)
		sw $s0, 1028($a0)
		sw $s0, 1296($a0)
		addi $a0, $a0, 24		# R
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 256($a0)
		sw $s0, 268($a0)
		sw $s0, 512($a0)
		sw $s0, 524($a0)
		sw $s0, 768($a0)
		sw $s0, 772($a0)
		sw $s0, 776($a0)
		sw $s0, 1024($a0)
		sw $s0, 1032($a0)
		sw $s0, 1036($a0)
		sw $s0, 1280($a0)
		sw $s0, 1292($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 12($a0)
		sw $s0, 260($a0)
		sw $s0, 272($a0)
		sw $s0, 516($a0)
		sw $s0, 528($a0)
		sw $s0, 780($a0)
		sw $s0, 1028($a0)
		sw $s0, 1040($a0)
		sw $s0, 1284($a0)
		sw $s0, 1296($a0)
		jr $ra
		
# This function draws win screen.		
you_win:	li $a0, 0x10009D28
		li $s0, WIN_TEXT		# Y
		sw $s0, 0($a0)
		sw $s0, 16($a0)
		sw $s0, 256($a0)
		sw $s0, 272($a0)
		sw $s0, 512($a0)
		sw $s0, 528($a0)
		sw $s0, 772($a0)
		sw $s0, 776($a0)
		sw $s0, 780($a0)
		sw $s0, 1032($a0)
		sw $s0, 1288($a0)
		li $s0, WIN_SHADOW
		sw $s0, 4($a0)
		sw $s0, 20($a0)
		sw $s0, 260($a0)
		sw $s0, 276($a0)
		sw $s0, 516($a0)
		sw $s0, 532($a0)
		sw $s0, 784($a0)
		sw $s0, 1036($a0)
		sw $s0, 1292($a0)
		addi $a0, $a0, 28		# O
		li $s0, FAIL_TEXT
		sw $s0, 4($a0)
		sw $s0, 8($a0)
		sw $s0, 256($a0)
		sw $s0, 268($a0)
		sw $s0, 512($a0)
		sw $s0, 524($a0)
		sw $s0, 768($a0)
		sw $s0, 780($a0)
		sw $s0, 1024($a0)
		sw $s0, 1036($a0)
		sw $s0, 1284($a0)
		sw $s0, 1288($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 12($a0)
		sw $s0, 260($a0)
		sw $s0, 272($a0)
		sw $s0, 516($a0)
		sw $s0, 528($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 1028($a0)
		sw $s0, 1040($a0)
		sw $s0, 1292($a0)
		addi $a0, $a0, 24		# U
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 12($a0)
		sw $s0, 256($a0)
		sw $s0, 268($a0)
		sw $s0, 512($a0)
		sw $s0, 524($a0)
		sw $s0, 768($a0)
		sw $s0, 780($a0)
		sw $s0, 1024($a0)
		sw $s0, 1036($a0)
		sw $s0, 1284($a0)
		sw $s0, 1288($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 4($a0)
		sw $s0, 16($a0)
		sw $s0, 260($a0)
		sw $s0, 272($a0)
		sw $s0, 516($a0)
		sw $s0, 528($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 1028($a0)
		sw $s0, 1040($a0)
		sw $s0, 1292($a0)
		addi $a0, $a0, 32		# W
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 24($a0)
		sw $s0, 256($a0)
		sw $s0, 280($a0)
		sw $s0, 512($a0)
		sw $s0, 536($a0)
		sw $s0, 768($a0)
		sw $s0, 780($a0)
		sw $s0, 792($a0)
		sw $s0, 1024($a0)
		sw $s0, 1032($a0)
		sw $s0, 1040($a0)
		sw $s0, 1048($a0)
		sw $s0, 1284($a0)
		sw $s0, 1300($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 4($a0)
		sw $s0, 28($a0)
		sw $s0, 260($a0)
		sw $s0, 284($a0)
		sw $s0, 516($a0)
		sw $s0, 540($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 796($a0)
		sw $s0, 1028($a0)
		sw $s0, 1036($a0)
		sw $s0, 1044($a0)
		sw $s0, 1052($a0)
		sw $s0, 1288($a0)
		sw $s0, 1304($a0)
		addi $a0, $a0, 36		# I
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		sw $s0, 768($a0)
		sw $s0, 1024($a0)
		sw $s0, 1280($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 4($a0)
		sw $s0, 260($a0)
		sw $s0, 516($a0)
		sw $s0, 772($a0)
		sw $s0, 1028($a0)
		sw $s0, 1284($a0)
		addi $a0, $a0, 12		# N
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 4($a0)
		sw $s0, 20($a0)
		sw $s0, 256($a0)
		sw $s0, 264($a0)
		sw $s0, 276($a0)
		sw $s0, 512($a0)
		sw $s0, 520($a0)
		sw $s0, 532($a0)
		sw $s0, 768($a0)
		sw $s0, 780($a0)
		sw $s0, 788($a0)
		sw $s0, 1024($a0)
		sw $s0, 1036($a0)
		sw $s0, 1044($a0)
		sw $s0, 1280($a0)
		sw $s0, 1296($a0)
		sw $s0, 1300($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 8($a0)
		sw $s0, 24($a0)
		sw $s0, 260($a0)
		sw $s0, 268($a0)
		sw $s0, 280($a0)
		sw $s0, 516($a0)
		sw $s0, 524($a0)
		sw $s0, 536($a0)
		sw $s0, 772($a0)
		sw $s0, 784($a0)
		sw $s0, 792($a0)
		sw $s0, 1028($a0)
		sw $s0, 1040($a0)
		sw $s0, 1048($a0)
		sw $s0, 1284($a0)
		sw $s0, 1304($a0)
		addi $a0, $a0, 36		# !
		li $s0, FAIL_TEXT
		sw $s0, 0($a0)
		sw $s0, 256($a0)
		sw $s0, 512($a0)
		sw $s0, 768($a0)
		sw $s0, 1280($a0)
		li $s0, FAIL_SHADOW
		sw $s0, 4($a0)
		sw $s0, 260($a0)
		sw $s0, 516($a0)
		sw $s0, 772($a0)
		sw $s0, 1284($a0)
		li $a0, 0x10009270		# cup
		li $s0, WIN_CUP_FILL
		sw $s0, 8($a0)
		sw $s0, 12($a0)
		sw $s0, 16($a0)
		sw $s0, 20($a0)
		sw $s0, 24($a0)
		sw $s0, 264($a0)
		sw $s0, 272($a0)
		sw $s0, 276($a0)
		sw $s0, 280($a0)
		sw $s0, 512($a0)
		sw $s0, 516($a0)
		sw $s0, 520($a0)
		sw $s0, 528($a0)
		sw $s0, 532($a0)
		sw $s0, 536($a0)
		sw $s0, 544($a0)
		sw $s0, 548($a0)
		sw $s0, 768($a0)
		sw $s0, 776($a0)
		sw $s0, 784($a0)
		sw $s0, 788($a0)
		sw $s0, 792($a0)
		sw $s0, 804($a0)
		sw $s0, 1028($a0)
		sw $s0, 1032($a0)
		sw $s0, 1036($a0)
		sw $s0, 1044($a0)
		sw $s0, 1048($a0)
		sw $s0, 1056($a0)
		sw $s0, 1292($a0)
		sw $s0, 1296($a0)
		sw $s0, 1300($a0)
		sw $s0, 1552($a0)
		sw $s0, 2060($a0)
		sw $s0, 2064($a0)
		sw $s0, 2068($a0)
		sw $s0, 2072($a0)
		li $s0, WIN_CUP_SHADOW
		sw $s0, 28($a0)
		sw $s0, 284($a0)
		sw $s0, 540($a0)
		sw $s0, 796($a0)
		sw $s0, 1052($a0)
		sw $s0, 1304($a0)
		sw $s0, 1556($a0)
		sw $s0, 1808($a0)
		sw $s0, 1812($a0)
		li $s0, WIN_CUP_LIGHT
		sw $s0, 268($a0)
		sw $s0, 524($a0)
		sw $s0, 780($a0)
		sw $s0, 1040($a0)
		jr $ra
		
