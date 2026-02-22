# Implement: if (a >= b) then print "Greater or Equal"
# else print "Less Than"
.data
	ge_msg: .asciiz "Greater or Equal\n"
	lt_msg: .asciiz "Less Than\n"
.text
.globl main
main:
	li $t0, 7 # a = 30
	li $t1, 30 # b = 30
	# YOUR CODE HERE
	# Hint: slt $t2, $t0, $t1 sets $t2=1 if $t0 < $t1
	slt $t2 $t0 $t1
	beqz $t2 ge
	
	la $a0 lt_msg
	li $v0 4
	syscall
	j end_program
	
ge:
	la $a0 ge_msg
	li $v0 4
	syscall
	
end_program:
	li $v0 10
	syscall