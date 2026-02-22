#Menu Options:
#1. Right-angled triangle
#2. Isosceles triangle
#3. Diamond pattern
#4. Hollow square
#5. Pascal's triangle (first n rows)
#Example Outputs:
#Right-angled triangle (n=5):
#*
#**
#***
#****
#*****
#Diamond pattern (n=5):
#*
#***
#*****
#*******
#*********
#*******
#*****
#***
#*
#Requirements:
#• Use nested loops for all patterns
#• Allow user to specify size/rows
#• Validate input (reasonable ranges)
#• Clean, modular code structure
#• Continue showing menu until user exits


.data
	menu: .asciiz "1) Right-Angled Triangle\n2) Isoceles Triangle\n3) Diamond Pattern\n4) Hollow Square\n5) Pascal's Triangle\n-1) End Program\nUser Choice: "
	row_prompt: .asciiz "Number of rows: "
	invalid: .asciiz "Invalid Shape Choice\n\n"
	not_implemented: .asciiz "Not yet implemented\n\n"
	ending: .asciiz "Ending the program\n"
	newline: .asciiz "\n"
	star: .asciiz "*"
	gap: .asciiz " "
	
.text
.globl main
main:
	li $t3 -1 # Exit code
	
menu_loop:
	# Print out the menu to select from
	li   $v0, 4
	la   $a0, menu
	syscall

	li   $v0, 5 # Take in integer input
	syscall
	
	move $t0 $v0
	beq $t0 $t3 end_program # End program if exit code
	
	la $a0 row_prompt # Ask user for number of rows
	li $v0 4
	syscall
	
	li $v0 5
	syscall
	move $t4 $v0
	
	la $a0 newline
	li $v0 4
	syscall
	
	li $t1 0 # Set i = 0 (outer loop)
	jal outer_loop # Process selection
	
	j menu_loop # Restart the loop for input
	

end_program:
	la $a0 ending
	li $v0 4
	syscall
	
	li $v0 10
	syscall
	
outer_loop:
	bgt $t1 $t4 return_to_menu # Return execution address back to menu
	li $t2 0 # Set j = 0 (inner loop)
	beq $t0 1 right
	beq $t0 2 isoceles
	beq $t0 3 diamond
	beq $t0 4 hollow
	beq $t0 5 pascal
	j invalid_choice
	

right:
	bge $t2 $t1 lower_out_loop
	la $a0 star
	li $v0 4
	syscall
	
	addi $t2 $t2 1
	j right
	
isoceles:
	la $a0 not_implemented
	li $v0 4
	syscall
	j return_to_menu

diamond:
	la $a0 not_implemented
	li $v0 4
	syscall
	j return_to_menu
	
hollow:
	la $a0 not_implemented
	li $v0 4
	syscall
	j return_to_menu
	
pascal:
	la $a0 not_implemented
	li $v0 4
	syscall
	j return_to_menu
	
lower_out_loop:
	addi $t1 $t1 1 # Increment i
	
	la $a0 newline
	li $v0 4
	syscall
	
	j outer_loop # Restart loop
	
return_to_menu:
	jr $ra
	
invalid_choice:
	la $a0 invalid
	li $v0 4
	syscall
	j menu_loop
	
