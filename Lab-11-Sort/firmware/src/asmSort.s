/*** asmSort.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data
.align    

@ Define the globals so that the C code can access them
/* define and initialize global variables that C can access */
/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Ian Moser"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
function name: asmSwap(inpAddr,signed,elementSize)
function description:
    Checks magnitude of each of two input values 
    v1 and v2 that are stored in adjacent in 32bit memory words.
    v1 is located in memory location (inpAddr)
    v2 is located at mem location (inpAddr + M4 word size)
    
    If v1 or v2 is 0, this function immediately
    places -1 in r0 and returns to the caller.
    
    Else, if v1 <= v2, this function 
    does not modify memory, and returns 0 in r0. 

    Else, if v1 > v2, this function 
    swaps the values and returns 1 in r0

Inputs: r0: inpAddr: Address of v1 to be examined. 
	             Address of v2 is: inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: size: number of bytes for each input value.
                  Valid values: 1, 2, 4
                  The values v1 and v2 are stored in
                  the least significant bits at locations
                  inpAddr and (inpAddr + M4 word size).
                  Any bits not used in the word may be
                  set to random values. They should be ignored
                  and must not be modified.
Outputs: r0 returns: -1 If either v1 or v2 is 0
                      0 If neither v1 or v2 is 0, 
                        and a swap WAS NOT made
                      1 If neither v1 or v2 is 0, 
                        and a swap WAS made             
             
         Memory: if v1>v2:
			swap v1 and v2.
                 Else, if v1 == 0 OR v2 == 0 OR if v1 <= v2:
			DO NOT swap values in memory.

NOTE: definitions: "greater than" means most positive number
********************************************************************/     
.global asmSwap
.type asmSwap,%function     
asmSwap:

    /* YOUR asmSwap CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */

    /*Step 1: Check r2 to see what we're loading from.*/
    /*NOTE: Never touch r1 and r2*/
    push {r4-r11,LR}
    
    cmp r2, 1
    BEQ byteLoad
    
    cmp r2, 2
    BEQ halfWordLoad
    
    cmp r2, 4
    BEQ wordLoad
    
byteLoad:
    
    ldrb r10, [r0], 4
    /*v1 is in r10, and r0 is now pointing to the next word*/
    ldrb r11, [r0]
    /*v2 is now in r11.*/
    b loaded
    /*this will make sure we don't do all those loads at once.*/
    
halfWordLoad:
    /*this will be the same thing as byteLoad, but using the halfword load*/
    
    ldrh r10, [r0], 4
    /*v1 is in r10, and r0 is now pointing to the next word*/
    ldrh r11, [r0]
    /*v2 is now in r11.*/
    b loaded
    
wordLoad:
    /*same as the last two, but just using plain ol load*/
    
    ldrh r10, [r0], 4
    /*v1 is in r10, and r0 is now pointing to the next word*/
    ldrh r11, [r0]
    /*v2 is now in r11.*/
    b loaded
    
loaded:
    /*step two: check both v1 and v2 for zeroes*/
    
    cmp r10, 0
    beq zeroEnd
    cmp r11, 0
    beq zeroEnd
    
    /*step three: Assuming we have no zeroes, we must enact SORTING!
     So we must see: is this signed? that is stored in r1.*/
    
    cmp r1, 1
    beq minusFixing
    
    /*the following will be an unsigned swap: the signed swap will be elsewhere.*/
    
    cmp r10, r11
    /*if v1, in r10, is larger, we swap. If it isn't larger or is equal, we
     leave it. So we only need to branch on larger.*/
    bhi swap
    
    /*currently on this branch, we are unsigned, with no zeroes, and v1 is not
     larger than v2, so we will go to the non swapping branch.*/
    b noSwap
    

minusFixing:
    /*we'll need to check both v1 and v2 to see if they're negative. If v2 is
     negative and v1 isn't, we can just swap. If v1 is negative and v2 isn't,
     we can just noSwap. If they're both negative, we have to NEG them both,
     and then see which number is SMALLER (the closer to zero, the greater)*/
    
    mov r8, 0
    mov r9, 0
    /*using these to check the signs of each one. 0 for pos, 1 for neg*/
    
    cmp r10, 0
    movlt r8, 1
    /*if v1 is negative, r8 = 1*/
    
    cmp r11, 0
    movlt r9, 1
    /*if v2 is negative, r9 = 1*/
    
    cmp r8, r9
    
    /*if r8 is larger, that means v1 is negative and v2 is positive, so we
     don't swap.*/
    bgt noSwap
    /*if r8 is smaller, that means v1 is positive and v2 is negative, so we
     do swap.*/
    blt swap
    
    /*if we haven't hit swap or noSwap, that means the signs are the same.
     lets find out if the signs are pos or negative.*/
    cmp r8, 1
    beq signSwitch
    
    /*if we didn't branch, these are both positive numbers and we can just 
     compare them.*/
    
    cmp r10, r11
    bgt swap
    b noSwap
    /*again, only if v1 is larger do we swap- in any other case we don't.*/
    
signSwitch:
    /*if we're here, both v1 and v2 are negative. We need to find out which
     is closer to zero and then swap. We'll do that by setting r8 to 2 if v1 is
     larger.*/
    
    neg r10, r10
    neg r11, r11
    /*remember, if r10, v1, is SMALLER, it is closer to zero, and thus, greater.*/
    
    cmp r10, r11
    movlt r8, 2
    
    neg r10, r10
    neg r11, r11
    /*gotta put r10 and r11 back into their storable states, or we'll have 
     problems down the line.*/
    
    cmp r8, 2
    beq swap
    b noSwap
    /*if r8 is 2, that's because v1 is the greater number, and v1 and v2 must
     be swapped. otherwise, we don't swap.*/
    
swap:
    /*now, tragically, we actually have THREE swap codes- depending on byte,
    half word, or full word. So first, we check r2.*/
    
    cmp r2, 1
    BEQ byteSwap
    
    cmp r2, 2
    BEQ halfWordSwap
    
    cmp r2, 4
    BEQ wordSwap
   
byteSwap:
    /*use strb here*/
    strb r10, [r0]
    sub r0, r0, 4
    /*subtracting because I'm not sure you can use a negative number in
     indexed addressing*/
    strb r11, [r0]
    
    mov r0, 1
    /*the output for a swapped pair*/
    b swappingDone
    
halfWordSwap:
    /*use strh here*/
    strh r10, [r0]
    sub r0, r0, 4
    /*subtracting because I'm not sure you can use a negative number in
     indexed addressing*/
    strh r11, [r0]
    
    mov r0, 1
    /*the output for a swapped pair*/
    b swappingDone
    
wordSwap:
    /*use normal str here!*/
    str r10, [r0]
    sub r0, r0, 4
    /*subtracting because I'm not sure you can use a negative number in
     indexed addressing*/
    str r11, [r0]
    
    mov r0, 1
    /*the output for a swapped pair*/
    b swappingDone
    
noSwap:
    /*if we aren't swapping, we don't need to store anything- the numbers are
     already in the order they should be stored in. So all we do is set the 
     output to 0*/
    
    mov r0, 0
    b swappingDone
    
zeroEnd:
    /*if either number is 0, we've hit the end of the list, and we need to
     just set the output to -1.*/
    
    mov r0, #-1
    b swappingDone
    
swappingDone:
    /*now we just do our ARM calling conventions to close out back to asmSort*/
    pop {r4-r11,LR}
    
    BX LR

    /* YOUR asmSwap CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */
    
    
/********************************************************************
function name: asmSort(startAddr,signed,elementSize)
function description:
    Sorts value in an array from lowest to highest.
    The end of the input array is marked by a value
    of 0.
    The values are sorted "in-place" (i.e. upon returning
    to the caller, the first element of the sorted array 
    is located at the original startAddr)
    The function returns the total number of swaps that were
    required to put the array in order in r0. 
    
         
Inputs: r0: startAddr: address of first value in array.
		      Next element will be located at:
                          inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: elementSize: number of bytes for each input value.
                          Valid values: 1, 2, 4
Outputs: r0: number of swaps required to sort the array
         Memory: The original input values will be
                 sorted and stored in memory starting
		 at mem location startAddr
NOTE: definitions: "greater than" means most positive number    
********************************************************************/     
.global asmSort
.type asmSort,%function
asmSort:   

    /* Note to Profs: 
     */

    /* YOUR asmSort CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    
    push {r4-r11,LR}
    
    /*things we will be tracking:
     our start address in r4
     our previous input address in r5
     our swap count from the CURRENT loop in r6
     our TOTAL swap count in r7*/
    
    /*step one: we initialize our 3 mini-variables.*/
    
    mov r4, r0
    mov r5, r0
    mov r6, 0
    mov r7, 0
    
    /*step two: call asmSwap. currently, r0 is the start address, an r1/2 are
     the sign and bit size. NEVER change r1 or r2.*/
loop:
    /*if we loop, it'll be up here.*/
    BL asmSwap
    
    /*now, r0 SHOULD be the output: -1 if we need to stop looping, 0 if we did 
     not swap,or 1 if we did swap.*/
    
    cmp r0, 0
    blt checkEnd
    /*if it's -1, we see if we're ending or doing another run around.*/
    addgt r6, #1
    /*if it's 1 (or greater than zero, specifically), we mark down that we did 
    a swap.*/
    
    add r5, #4
    mov r0, r5
    /*now we step to the next word, so we can swap again at the new location by
    setting r0 to be equal to that!*/
    b loop
    
checkEnd:
    /*if you're here, that means r0 = -1. We need to: add the swap count to
     the total swap count, then, if the current swap count is 0, we put the
     total in r0, because we're done. If the current loop's swap count isn't 0,
     we need to run another set of loops to see if the bubble sort is done.*/
    
    /*step one: add current loop's sorts to the total.*/
    add r7, r7, r6
    
    /*step two: was the last loop swapless?*/
    cmp r6, 0
    beq sortDone
    /*if it was, the sorting is done. If it isn't, we'll prep the loop again.*/
    
    /*to prep the loop again, we must: put the swap count back to 0, and put
     r0 back to the start of the address list.*/
    mov r6, 0
    mov r0, r4
    mov r5, r4
    b loop
    
sortDone:
    /*in sort done we need to set the number of swaps we did to the output, and
     we're done.*/
    mov r0, r7
    
    mov r0,r0 /* these are do-nothing lines to deal with IDE mem display bug */
    mov r0,r0
    
    pop {r4-r11,LR}
    

    
BX LR    
    /* YOUR asmSort CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




