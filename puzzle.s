# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

OTHER_X                 = 0xffff00a0
OTHER_Y                 = 0xffff00a4

TIMER                   = 0xffff001c
GET_MAP                 = 0xffff2008

REQUEST_PUZZLE          = 0xffff00d0  ## Puzzle
SUBMIT_SOLUTION         = 0xffff00d4  ## Puzzle

BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000
TIMER_ACK               = 0xffff006c

REQUEST_PUZZLE_INT_MASK = 0x800       ## Puzzle
REQUEST_PUZZLE_ACK      = 0xffff00d8  ## Puzzle

RESPAWN_INT_MASK        = 0x2000      ## Respawn
RESPAWN_ACK             = 0xffff00f0  ## Respawn

SHOOT                   = 0xffff2000
CHARGE_SHOT             = 0xffff2004

OTHER_BULLETS           = 0xffff200c
BOT_BULLETS             = 0xffff2010
GET_AMMO                = 0xffff2014

MMIO_STATUS             = 0xffff204c

.data
### Puzzle
puzzle:     .byte 0:400
solution:   .word 0 counts   # count in solution
counts:     .space 8
#### Puzzle

has_puzzle: .word 0

has_bonked:    .byte 0

puzzle_received: .word 0
timer_over: .word 0
# -- string literals --
.text
main:
    sub $sp, $sp, 4
    sw  $ra, 0($sp)

    # Construct interrupt mask
    li      $t4, 0
    or      $t4, $t4, TIMER_INT_MASK            # enable timer interrupt
    or      $t4, $t4, BONK_INT_MASK             # enable bonk interrupt
    or      $t4, $t4, REQUEST_PUZZLE_INT_MASK   # enable puzzle interrupt
    or      $t4, $t4, 1 # global enable
    mtc0    $t4, $12

    li $t1, 0
    sw $t1, ANGLE
    li $t1, 1
    sw $t1, ANGLE_CONTROL
    li $t2, 0
    sw $t2, VELOCITY

    # YOUR CODE GOES HERE!!!!!!
    jal turn_south
    jal move_space
    jal move_space
    jal turn_east
    jal move_space
    jal move_space

    jal handle_puzzle

    li  $t1, 1
    sw  $t1, SHOOT

    # move 10 spaces east
    li  $a0, 0
    li  $a1, 10
    jal move_spaces

    # move 5 spaces south
    li  $a0, 90
    li  $a1, 5
    jal move_spaces

    # move 3 spaces turn_east
    li  $a0, 0
    li  $a1, 2
    jal move_spaces

    jal turn_south

    li  $a0, 2
    jal charge_and_shoot

    li  $a0, 90
    lw  $a1, GET_AMMO
    jal move_spaces


loop: # Once done, enter an infinite loop so that your bot can be graded by QtSpimbot once 10,000,000 cycles have elapsed
    j loop

turn_east:
    li    $t0, 0
    sw    $t0, ANGLE
    li    $t0, 1
    sw    $t0, ANGLE_CONTROL
    jr    $ra

turn_south:
    li    $t0, 90
    sw    $t0, ANGLE
    li    $t0, 1
    sw    $t0, ANGLE_CONTROL
    jr    $ra

turn_west:
    li    $t0, 180
    sw    $t0, ANGLE
    li    $t0, 1
    sw    $t0, ANGLE_CONTROL
    jr    $ra

turn_north:
    li    $t0, 270
    sw    $t0, ANGLE
    li    $t0, 1
    sw    $t0, ANGLE_CONTROL
    jr    $ra

move_space:

    li    $t0, 10           # set max velocity
    sw    $t0, VELOCITY

    lw    $v0, TIMER        # calls timer interrupt
    add   $v0, $v0, 8000
    sw    $v0, TIMER

    li    $t1, 0            # stalls for 8000 cycles
    li    $t2, 2035
    stall_loop:
    bge   $t1, $t2, end_stall
    addi  $t1, $t1, 1
    j     stall_loop

    end_stall:

    li    $t0, 0           # end movement
    sw    $t0, VELOCITY

    jr    $ra

move_spaces:

  sub    $sp, $sp, 16    # allocate stack
  sw     $ra, 0($sp)
  sw     $s0, 4($sp)
  sw     $s1, 8($sp)
  sw     $s2, 12($sp)

  move   $s0, $a0       # storing the function parameters
  move   $s1, $a1

  sw    $s0, ANGLE
  li    $t0, 1
  sw    $t0, ANGLE_CONTROL

  li $s2, 0             # int i = 0
  move_n_loop:
    bge   $s2, $s1, end_move_loop  # for (i < $a1)
    jal move_space
    addi  $s2, $s2, 1      # i++
    j     move_n_loop

  end_move_loop:

  lw    $ra, 0($sp)
  lw    $s0, 4($sp)
  lw    $s1, 8($sp)
  lw    $s2, 12($sp)

  addi  $sp, $sp, 16

  jr    $ra


handle_puzzle:

   sub   $sp, $sp, 12
   sw    $ra, 0($sp)
   sw    $s0, 4($sp)
   sw    $s1, 8($sp)

   li    $s0, 0                    # int i = 0
   li    $s1, 10                    # int n = 4
   for_puzzle:
   bge   $s0, $s1, end_for_puzzle  # if  >=  then

   li    $t1, 0
   sw    $t1, puzzle_received

   la    $t1, puzzle
   sw    $t1, REQUEST_PUZZLE

   li    $t2, 1
   puzzle_loop:
   lw     $t3, puzzle_received
   beq    $t3, $t2, end_puzzle_loop
   j      puzzle_loop

   end_puzzle_loop:
     jal solve_puzzle

   la    $t1, solution
   sw    $t1, SUBMIT_SOLUTION

   addi  $s0, $s0, 1      #  i++
   j    for_puzzle
   end_for_puzzle:

   lw    $ra, 0($sp)
   lw    $s0, 4($sp)
   lw    $s1, 8($sp)
   addi  $sp, $sp, 12

   jr    $ra

solve_puzzle:

la      $t0, puzzle
addi    $t0, $t0, 16                  # 16 byte offset from puzzle
move    $a0, $t0                      # Line * line
la      $a1, puzzle                   # Canvas * canvas
la      $a2, solution                 # Solution * solution

sub     $sp, $sp, 4                   # allocate some stack
sw      $ra, 0($sp)                   # stores $ra

jal     count_disjoint_regions        # jump to  and save position to $ra

lw      $ra, 0($sp)                   # restores $ra
addi    $sp, $sp, 4

jr    $ra          # jump to

charge_shot_function:

   sw    $a0, CHARGE_SHOT

   lw    $v0, TIMER        # calls timer interrupt
   add   $v0, $v0, 10000
   sw    $v0, TIMER

   sw    $0, timer_over
   charge_wait_loop:
   li    $t1, 1
   lw    $t2, timer_over
   beq   $t1, $t2, end_charge_wait
   j     charge_wait_loop

   end_charge_wait:
   jr    $ra

charge_and_shoot:
   sub   $sp, $sp, 4
   sw    $ra, 0($sp)

   jal   charge_shot_function

   lw    $ra, 0($sp)
   addi  $sp, $sp, 4

   sw    $a0, SHOOT
   jr    $ra

.kdata
chunkIH:    .space 40
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
    move    $k1, $at        # Save $at
                            # NOTE: Don't touch $k1 or else you destroy $at!
.set at
    la      $k0, chunkIH
    sw      $a0, 0($k0)        # Get some free registers
    sw      $v0, 4($k0)        # by storing them to a global variable
    sw      $t0, 8($k0)
    sw      $t1, 12($k0)
    sw      $t2, 16($k0)
    sw      $t3, 20($k0)
    sw      $t4, 24($k0)
    sw      $t5, 28($k0)

    # Save coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    mfhi    $t0
    sw      $t0, 32($k0)
    mflo    $t0
    sw      $t0, 36($k0)

    mfc0    $k0, $13                # Get Cause register
    srl     $a0, $k0, 2
    and     $a0, $a0, 0xf           # ExcCode field
    bne     $a0, 0, non_intrpt



interrupt_dispatch:                 # Interrupt:
    mfc0    $k0, $13                # Get Cause register, again
    beq     $k0, 0, done            # handled all outstanding interrupts

    and     $a0, $k0, BONK_INT_MASK     # is there a bonk interrupt?
    bne     $a0, 0, bonk_interrupt

    and     $a0, $k0, TIMER_INT_MASK    # is there a timer interrupt?
    bne     $a0, 0, timer_interrupt

    and     $a0, $k0, REQUEST_PUZZLE_INT_MASK
    bne     $a0, 0, request_puzzle_interrupt

    and     $a0, $k0, RESPAWN_INT_MASK
    bne     $a0, 0, respawn_interrupt

    li      $v0, PRINT_STRING       # Unhandled interrupt types
    la      $a0, unhandled_str
    syscall
    j       done

bonk_interrupt:
    sw      $0, BONK_ACK
    la      $t0, has_bonked
    li      $t1, 1
    sb      $t1, 0($t0)
    #Fill in your bonk handler code here
    j       interrupt_dispatch      # see if other interrupts are waiting

timer_interrupt:
    sw      $0, TIMER_ACK
    #Fill your timer interrupt code here
    li      $t1, 1
    sw      $t1, timer_over
    j        interrupt_dispatch     # see if other interrupts are waiting

request_puzzle_interrupt:
    li      $t1, 1
    sw      $t1, REQUEST_PUZZLE_ACK
    #Fill in your puzzle interrupt code here
    sw      $t1, puzzle_received
    j       interrupt_dispatch

respawn_interrupt:
    sw      $0, RESPAWN_ACK
    #Fill in your respawn handler code here
    j       interrupt_dispatch

non_intrpt:                         # was some non-interrupt
    li      $v0, PRINT_STRING
    la      $a0, non_intrpt_str
    syscall                         # print out an error message
    # fall through to done

done:
    la      $k0, chunkIH

    # Restore coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    lw      $t0, 32($k0)
    mthi    $t0
    lw      $t0, 36($k0)
    mtlo    $t0

    lw      $a0, 0($k0)             # Restore saved registers
    lw      $v0, 4($k0)
    lw      $t0, 8($k0)
    lw      $t1, 12($k0)
    lw      $t2, 16($k0)
    lw      $t3, 20($k0)
    lw      $t4, 24($k0)
    lw      $t5, 28($k0)

.set noat
    move    $at, $k1        # Restore $at
.set at
    eret

# Below are the provided puzzle functionality.
.text

.globl draw_line
draw_line:
    lw      $t0, 4($a2)     # t0 = width = canvas->width
    li      $t1, 1          # t1 = step_size = 1
    sub     $t2, $a1, $a0   # t2 = end_pos - start_pos
    blt     $t2, $t0, dl_cont
    move    $t1, $t0        # step_size = width;
dl_cont:
    move    $t3, $a0        # t3 = pos = start_pos
    add     $t4, $a1, $t1   # t4 = end_pos + step_size
    lw      $t5, 12($a2)    # t5 = &canvas->canvas
    lbu     $t6, 8($a2)     # t6 = canvas->pattern
dl_for_loop:
    beq     $t3, $t4, dl_end_for
    div     $t3, $t0        #
    mfhi    $t7             # t7 = pos % width
    mflo    $t8             # t8 = pos / width
    mul     $t9, $t8, 4		# t9 = pos/width*4
    add     $t9, $t9, $t5   # t9 = &canvas->canvas[pos / width]
    lw      $t9, 0($t9)     # t9 = canvas->canvas[pos / width]
    add     $t9, $t9, $t7
    sb      $t6, 0($t9)     # canvas->canvas[pos / width][pos % width] = canvas->pattern
    add     $t3, $t3, $t1   # pos += step_size
    j       dl_for_loop
dl_end_for:
    jr      $ra


.globl flood_fill
flood_fill:
	blt	$a0, $zero, ff_end	# row < 0
	blt	$a1, $zero, ff_end	# col < 0
	lw	$t0, 0($a3)		    # $t0 = canvas->height
	bge	$a0, $t0, ff_end	# row >= canvas->height
	lw	$t0, 4($a3)		    # $t0 = canvas->width
	bge	$a1, $t0, ff_end	# col >= canvas->width
	j 	ff_recur			# NONE TRUE
ff_recur:
	# Find curr
	lw	$t0, 12($a3)		# canvas->canvas
	mul	$t1, $a0, 4		    # row * sizeof(char*)
	add	$t1, $t1, $t0		# $t1 = canvas->canvas + row * sizeof(char*) = canvas[row]
	lw	$t2, 0($t1)		    # $t2 = &char = char* = & canvas[row][0]
	add	$t2, $a1, $t2		# $t2 = &canvas[row][col]
	lb	$t3, 0($t2)		    # $t3 = curr

	lb	$t4, 8($a3)		    # $t4 = canvas->pattern

	beq	$t3, $t4, ff_end	# curr == canvas->pattern : break
	beq	$t3, $a2, ff_end	# curr == marker          : break

	#FLOODFILL
	sb	$a2, ($t2)

	# Save depenedecies
	sub	$sp, $sp, 12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	move	$s0, $a0
	move	$s1, $a1

	sub	$a0, $s0, 1
	move	$a1, $s1
	jal	flood_fill

	move	$a0, $s0
	add	$a1, $s1, 1
	jal	flood_fill

	add	$a0, $s0, 1
	move	$a1, $s1
	jal	flood_fill

	move	$a0, $s0
	sub	$a1, $s1, 1
	jal	flood_fill

	# Restore VARS
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	add	$sp, $sp, 12
ff_end:
	jr 	$ra


.globl count_disjoint_regions_step
count_disjoint_regions_step:
    sub	    $sp, $sp, 24
	sw	    $ra, 0 ($sp)
	sw	    $s0, 4 ($sp)        # marker
    sw      $s1, 8 ($sp)        # canvas
    sw      $s2, 12($sp)        # region_count
    sw      $s3, 16($sp)        # row
    sw      $s4, 20($sp)        # col

    move    $s0, $a0
    move    $s1, $a1
	li	    $s2, 0			    # unsigned int region_count = 0;

    li      $s3, 0              # row = 0
cdrs_outer_loop:                # for (unsigned int row = 0; row < canvas->height; row++) {
    lw      $t0, 0($s1)         # canvas->height
    bge     $s3, $t0, cdrs_end_outer_loop   # row < canvas->height : fallthrough

    li      $s4, 0              # col = 0
cdrs_inner_loop:                # for (unsigned int col = 0; col < canvas->width; col++) {
    lw      $t0, 4($s1)         # canvas->width
    bge     $s4, $t0, cdrs_end_inner_loop   # col < canvas->width : fallthrough

    # unsigned char curr_char = canvas->canvas[row][col];
    lw      $t1, 12($s1)        # &(canvas->canvas)
    mul     $t2, $s3, 4         # $t2 = row * 4
    add     $t2, $t2, $t1       # $t2 = canvas->canvas + row * sizeof(char*) = canvas[row]
    lw	$t1, 0($t2)		        # $t1 = &char = char* = & canvas[row][0]
    add	$t1, $s4, $t1           # $t1 = &canvas[row][col]
    lb	$t1, 0($t1)		        # $t1 = canvas[row][col] = curr_char

    lb      $t2, 8($s1)         # $t2 = canvas->pattern

    # temps:        $t1 = curr_char         $t2 = canvas->pattern

    # if (curr_char != canvas->pattern && curr_char != marker) {
    beq     $t1, $t2, cdrs_endif    # if (curr_char != canvas->pattern) fall
    beq	$t1, $s0, cdrs_endif        # if (curr_char != marker)          fall

    add     $s2, $s2, 1         # region_count ++;
    move    $a0, $s3            # (row,
    move    $a1, $s4            #  col,
    move    $a2, $s0            #  marker,
    move    $a3, $s1            #  canvas);
    jal     flood_fill          # flood_fill(row, col, marker, canvas);

cdrs_endif:
    add     $s4, $s4, 1         # col++
    j       cdrs_inner_loop     # loop again

cdrs_end_inner_loop:
    add     $s3, $s3, 1         # row++
    j       cdrs_outer_loop     # loop again

cdrs_end_outer_loop:
	move	$v0, $s2		    # Copy return val
	lw	    $ra, 0($sp)
	lw	    $s0, 4 ($sp)        # marker
    lw      $s1, 8 ($sp)        # canvas
    lw      $s2, 12($sp)        # region_count
    lw      $s3, 16($sp)        # row
    lw      $s4, 20($sp)        # col

	add	$sp, $sp, 24
	jr      $ra


.globl count_disjoint_regions
count_disjoint_regions:
    sub     $sp, $sp, 20
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)
    sw      $s2, 12($sp)
    sw      $s3, 16($sp)

    move    $s0, $a0                # line
    move    $s1, $a1                # canvas
    move    $s2, $a2                # solution

    li      $s3, 0                  # unsigned int i = 0;
cdr_loop:
    lw	    $t0, 0($s0)		        # $t0 = lines->num_lines
    bge     $s3, $t0, cdr_end       # i < lines->num_lines : fallthrough

    #lines->coords[0][i];
    lw	$t1, 4($s0)		# $t1 = &(lines->coords[0][0])
    lw	$t2, 8($s0)		# $t2 = &(lines->coords[1][0])

    mul     $t3, $s3, 4             # i * sizeof(int*)
    add     $t1, $t3, $t1           # $t1 = &(lines->coords[0][i])
    add     $t2, $t3, $t2           # $t2 = &(lines->coords[1][i])

    lw      $a0, 0($t1)             # $a0 = lines->coords[0][i] = start_pos
    lw      $a1, 0($t2)             # $a1 = lines->coords[0][i] = end_pos
    move    $a2, $s1                # $a2 = canvas
    jal     draw_line               # draw_line(start_pos, end_pos, canvas);

    li      $a0, 65                 # Immediate value A
    rem     $t1, $s3, 2             # i % 2
    add     $a0, $a0, $t1           # 'A' or 'B'
    move    $a1, $s1
    jal     count_disjoint_regions_step  # count_disjoint_regions_step('A' + (i % 2), canvas);
    # $v0 = count_disjoint_regions_step('A' + (i % 2), canvas);

    lw      $t0, 4($s2)             # &counts = &counts[0]
    mul     $t1, $s3, 4             #  i * sizeof(unsigned int)
    add     $t0, $t1, $t0           # *counts[i]
    sw      $v0, 0($t0)

##         // Update the solution struct. Memory for counts is preallocated.
##         solution->counts[i] = count;

    add     $s3, $s3, 1             # i++
    j       cdr_loop
cdr_end:
    lw      $t0, 0($s0)             # lines->num_lines
    sw      $t0, 0($s2)             # solution->length = lines->num_lines
    lw      $ra, 0($sp)
    lw      $s0, 4($sp)
    lw      $s1, 8($sp)
    lw      $s2, 12($sp)
    lw      $s3, 16($sp)
    add     $sp, $sp, 20
    jr      $ra
