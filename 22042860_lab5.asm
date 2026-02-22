# Program Name: Integer Property Analyzer
# Author: Mensah Philemon Edem Yao
# Date: 15 Feb 2026
# Id: 22042860
#
# Description:
# This program accepts an integer from the user and analyzes
# its mathematical properties.
#
# It determines:
#   - Whether the number is even or odd
#   - Whether it is positive, negative, or zero
#   - Its absolute value
#   - Its square
#   - The sum of integers from 1 to the number (if positive)
#
# Algorithm:
# 1. Prompt and read integer input.
# 2. Use modulus logic to determine even/odd.
# 3. Use branch comparisons to determine sign.
# 4. Call reusable procedure to compute absolute value.
# 5. Compute square using multiplication.
# 6. If number > 0, compute summation using loop.
# 7. Display results with clear formatted labels.



.data 
	newline: .asciiz "\n"
	prompt: .asciiz "Input an integer: "
	is_even: .asciiz "The number is even\n"
	is_odd: .asciiz "The number is odd\n"
	positive: .asciiz "The number is positive\n"
	negative: .asciiz "The number is negative\n"
	zero: .asciiz "The number is a zero\n"
	absolute: .asciiz "The absolute value of the number is: "
	squared: .asciiz "The number squared is: "
	summation: .asciiz "The sum of all numbers from 1 to the number is: "
	negative_case: .asciiz "Summation not computed (Integer is negative)\n"
.text
.globl main
main:
	la $a0 prompt
	li $v0 4
	syscall # Print the prompt to enter the integer
	
	li $v0 5
	syscall # Stores user integer input inside v0
	move $t0 $v0 # Move integer to t0 for reusability later
	
	bgtz $t0 positive_num # If the number is greater than 0, go to positive_num block
	beqz $t0 zero_num # If the number is a 0, go to zero_num block
	
	la $a0 negative # If it's not positive nor zero it will come here
	li $v0 4
	syscall
	
	j end_positive_if # Jump to the end of the if statement so the other blocks won't execute
	
positive_num:
	la $a0 positive
	li $v0 4
	syscall
	
	j end_positive_if # Jump to the end of the if statement so the other blocks won't execute
zero_num:
	la $a0 zero
	li $v0 4
	syscall
	j end_positive_if # Jump to the end of the if statement so the other blocks won't execute

end_positive_if:
	rem $t1 $t0  2 # Using reminder of a division by two to check parity. If there is a reminder of 1 then it's odd else even
	beqz $t1 even_if # if it's 0 go to the even side
	
	la $a0 is_odd 
	# Print the odd message if it's odd
	li $v0 4
	syscall
	j end_even_if # Go to the end of the if statement
		
even_if:
	la $a0 is_even
	li $v0 4
	syscall
	j end_even_if # Not necessary but f it
	
end_even_if:
	la $a0 absolute
	li $v0 4
	syscall # Print absolute message
	
	move $a0 $t0 
	jal abs_value_calc # Jump to abs_value_calc block while keeping the reference back to this line so the program can return back to this line quickly
	
	move $a0 $v0 # Move abs value which was stored in v0 from inside the abs_value_calc into a0 so I can print it
	li $v0 1
	syscall
	
	la $a0 newline
	li $v0 4
	syscall
	
	la $a0 squared
	li $v0 4
	syscall # Print squared message
	
	mul $a0 $t0 $t0
	li $v0 1
	syscall # Calc square by multiplying the num by itself. Note: t0 still contains the users input number
	
	la $a0 newline
	li $v0 4
	syscall
	
	li $t1 0 
	li $t2 0
	# Store two variables that will aid in adding sum of numbers
	
	bgez $t0 loop # If it's positive go ahead to add the numbers
	j negative_no_loop # Else it would be negative so you ignore the loop and go to this branch
	
loop:
	bne $t0 $t1 increment # If the value in t0 and t0 are not equal keep iterating. t0 is your number and t1 is the number of iterations
	j end_loop # Else if it they are equal then end the loop
increment:
	addi $t1 $t1 1 # Increment the iteration
	add $t2 $t2 $t1 # Add the value of the sum of interation to the number. This mimicks the summation of all numbers before the num
	j loop # Go back to the start of the loop and work with it again
	
end_loop:
	la $a0 summation
	li $v0 4
	syscall
	
	move $a0 $t2 # Move the summation which is stored in t2 into a0 for printing
	li $v0 1
	syscall
	
	j end_program # end the program here because there is no need to continue
	
negative_no_loop:
	la $a0 negative_case 
	li $v0 4
	syscall # Print the negative message for the summation if a negative case
	
	
end_program:
	li $v0 10 
	syscall
	
	
abs_value_calc:
	abs $v0 $a0 # calc abs value and store in v0
	jr $ra # Jump back to the jal line to continue execution
