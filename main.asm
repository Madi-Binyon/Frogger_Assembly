;Frogger
;Madi Binyon, Tyler Gamlem, Ezekiel Pierson
;Last Modified: 12/09/2019

TITLE Conio_wrapper
; Description: Illustrates how to "wrap", for lack of a better term, C/C++ functionality. See pp. 574-583.
; Revision date: 18 November 2016

;For Irvine functions
INCLUDE Irvine32.inc

;For C/C++ functions. Make a prototype for any you're gonna use.
 _kbhit PROTO C
getch PROTO C

.data
border BYTE " ", 0			;border string, White
frog BYTE "   ", 0			;frog string, green
car BYTE "      ", 0		;car string, red
car_length DWORD 6			;the length of a car
log BYTE "         ", 0		;log string, brown
log_length DWORD 9			;length of a log
count BYTE 1				;side count for border
count1 BYTE 0				;top/bottom count for border
cars_x DWORD 5, 30, 50, 60, 10, 20, 60, 30, 5, 50		;x coordinates for the cars
cars_y DWORD 55, 50, 45, 40, 35, 55, 50, 45, 40, 35		;y coordinates for the cars
logs_x DWORD 45, 73, 37, 65, 29, 57, 21, 49, 13, 41, 5, 33, 45, 73, 37, 65, 29, 57, 21, 49, 13, 41, 5, 33		;x coordinates for logs
logs_y DWORD 27, 25, 23, 21, 19, 17, 15, 13, 11, 9, 7, 5, 27, 25, 23, 21, 19, 17, 15, 13, 11, 9, 7, 5			;y coordinates for logs
current_log_x DWORD 0		;x value of the current log
current_log_y DWORD 0		;y value of the current log
finish BYTE "Congratulations!",0		;game win message
.code

;printWater: prints water to the top of the screen
;No variables passed into the procedure
printWater PROC
	LOCAL water_x: BYTE				;water x coordinate
	LOCAL water_y: BYTE				;water y coordinate
	mov water_x, 1					;starting place for water
	mov water_y, 4
	mov ecx, 25						;loop 25 times for 25 lines of water
printWater_y:
	push ecx						;push ecx so we don't lose this counter
	mov ecx, 79						;79 so that we get 79 spaces of water in a line
	printWater_x:
		mov dh, water_y				;move water coordinates
		mov dl, water_x
		call GotoXY					;print to the right place on the screen
		mov eax, (blue * 16)		;print in blue (what a concept!)
		call SetTextColor
		mov edx, OFFSET border		;use the border string for water to keep from unnecessary global variables
		call WriteString
		add water_x, 1				;update x
	loop printWater_x
	pop ecx							;get the y counter back
	add water_y, 1					;update x and y
	mov water_x, 1
loop printWater_y
ret
printWater ENDP

;printBorder: prints the border around the console
;No variables are passed into the procedure
printBorder PROC
	mov ecx, 81						;counter to be 81 for the x
printTop:
	mov dh, 0						;go to the right place in the console window
	mov dl, count1
	call GotoXY
	mov eax, (white * 16)			;print in white
	call SetTextColor
	mov edx, OFFSET border
	call WriteString
	add count1, 1					;update count1 (x value)
loop printTop

;this will bounce from left to right in the console window
mov ecx, 59							;counter to be 59 for y
printSides:
	mov dl,0						;go to the left of the console window
	mov dh,count
	call GotoXY
	mov eax, (white * 16)			;print in white
	call SetTextColor
	mov edx, OFFSET border
	call WriteString

	mov dl,80						;go to the right of the console window
	mov dh,count
	call GotoXY
	mov eax, (white * 16)			;print in white
	call SetTextColor
	mov edx, OFFSET border
	call WriteString
	add count, 1					;update count (y value)
loop printSides

mov count1, 0						;reset the count for the bottom
mov ecx, 81							;81 to move across the bottom of the screen
printBottom:
	mov dl, count1					;go to the right place in the console window
	mov dh, 60
	call GotoXY
	mov eax, (white * 16)			;print in white
	call SetTextColor
	mov edx, OFFSET border
	call WriteString
	add count1, 1					;update count1 (x value)
loop printBottom

mov count1, 0
ret
printBorder ENDP

;printObject: prints an object to the screen
;takes in a color and a pointer holding the OFFSET of the object's string
printObject PROC, color: DWORD, pointer: DWORD
	mov ebx, 16						;to be used for multiplication
	mov eax, color					;color we want
	mul ebx							;multiply by 16 to change background color
	call SetTextColor				;print in the correct color
	mov edx, pointer				;print the right string for the object
	call WriteString
	;Don't print the rest of the line in a random color.
	mov eax, (black * 16)
 call SetTextColor
ret
printObject ENDP

;eraseObject: resets the spaces behind an object to the correct background color after an object moves
;takes in x and y values for where to print, pointer for the string to print
eraseObject PROC, X: DWORD, Y:DWORD, pointer: DWORD
	push eax						;preserve eax value through the comparisons
	mov dh, BYTE PTR Y				;print in the right place in the console window
	mov dl, BYTE PTR X
	call GotoXY
	cmp Y, 28						;check to see if Y is in the water area
	jle blueLabel1
	jg blackLabel

	blueLabel1:
		cmp Y, 4					;check to make sure Y has not left the water area
		jge blueLabel2

	blackLabel:
		mov eax, (black * 16)		;reset to black if not in the water
		call SetTextColor
		mov edx, pointer
		call WriteString
		jmp done					;jump to the label done

	blueLabel2:
		mov eax, (blue * 16)		;reset the background to blue if in water
		call SetTextColor
		mov edx, pointer
		call WriteString
	done:
		pop eax						;get back the eax value
		ret
eraseObject ENDP

;moveFrog: takes in user input on the keyboard to move the frog
;is passed an x and y value to be updated
moveFrog PROC, X:DWORD, Y:DWORD
	call getch		;Calls getch, then WriteInt to prove it was called. Returned the result in EAX
					;so the call to WriteInt will display the integer ASCII value for whatever
					;was entered.
	INVOKE EraseObject, X, Y, OFFSET frog ;Erase previous block of color
	
	cmp eax, 100			;check for right input (d key)
	jz rightLabel

	cmp eax, 97				;check for left input (a key)
	jz leftLabel

	cmp eax, 119			;check for up input (w key)
	jz upLabel

	cmp eax, 115			;check for down input (s key)
	jz downLabel
	
	upLabel:
		sub Y, 2			;move up two if we got up input
		jmp done
	
	rightLabel:
		add X, 3			;move right three if we got right input
		jmp done
	
	leftLabel:
		sub X, 3			;move left three if we got left input
		jmp done

	downLabel:
		add Y, 2			;move down two if we got down input
		jmp done

	done:
		mov dl, BYTE PTR X								;move to the updated position of frog
		mov dh, BYTE PTR Y
		call GotoXY
		INVOKE printObject, green, OFFSET frog			;print the frog again
		mov eax, X										;preserve the new x value
		mov ebx, Y										;preserve the new y value
ret
moveFrog ENDP

;drawObject: draws a car on the screen
;passed an x and y coordinate, color, string to be printed, and direction
drawObject PROC, X: DWORD, Y:DWORD, color: DWORD, object_pointer: DWORD, direction: DWORD
	push eax											;preserve eax value
	INVOKE eraseObject, X, Y, object_pointer			;call erase object to get rid of the object's previous position
	cmp direction, 1									;check to see if the object is moving forward or backward (based on the direction flag in the DrawLogs PROC)
	jz forward
	jnz backward

	forward:
		mov eax, 1										;if forward, add one to the x to move the log forward
		add X, eax
		jmp continue

	backward:
		mov eax, 1										;if backward, subtract one from the x to move the log backward
		sub X, eax

	continue:
		mov dl, BYTE PTR X								;Go to the new position (X+1, Y)
		mov dh, BYTE PTR Y
		call GotoXY
		push object_pointer								;push the offset of the string
		push color										;push the color of the object being printed
		cmp direction, 1								;check direction again
		jz forward_compare
		jnz backward_compare

	forward_compare:									;compare any logs going forward traveling right) to the right side of the screen
		cmp X, 74
		jz forward_resetLabel							;If the forward log hits the right side of the screen, forward_reset
		jnz continueLabel

	backward_compare:									;compare any logs going backwards (traveling left) to the left side of the screen
		cmp X, 1
		jz backward_resetLabel							;If the backward logs hits the left side of the screen, backward_reset
		jnz continueLabel

	forward_resetLabel:									;These labels are the same, except one resets the X to 1 (forward_reset) and the other resets the X to 74 (backward_reset)
		INVOKE eraseObject, X, Y, OFFSET car
		mov X, 1										;Assign 1 to the new X value
		jmp done

	backward_resetLabel:
		INVOKE eraseObject, X, Y, OFFSET car
		mov X, 74										;Assign 74 to the new X value
		jmp done

	continueLabel:
		call printObject

	done:
		pop eax											;restore eax value
		mov eax, X										;Whatever new X yvalue is set, mov it into eax for the next step in the process
		ret
drawObject ENDP

;collideFunction: checks to see if a frog has collided with a car
;passed a frog's x and y, a car's x and y, and the length of a car
collideFunction PROC, frog_x: DWORD, frog_y: DWORD, obstacle_x: DWORD, obstacle_y: DWORD, obstacle_length: DWORD
	mov ebx, frog_y					;hold the frog's y value in ebx
	sub ebx, obstacle_y				;subtract the obstacle's y to see if they are the same
	
	mov ecx, obstacle_length		;loop as many times as there are spaces in the obstacle's length
	x_check:
	mov eax, frog_x					;compare the frog and obstacle's x values to see if they are colliding
	sub eax, obstacle_x
	cmp eax, 0						;if they are the same, collide detected
	jz collide_detected
	add obstacle_x, 1				;add one to the obstacle to check the rest of the x's encompassed in the obstacle
	loop x_check

	jmp continueOn

	collide_detected:
		cmp ebx, 0					;if the y values are not the same, no death
		jnz continueOn
		call clrscr					;clear screen to show death
		mov eax, 2000
		call Delay
		call ExitProcess			;end game
		ret

	continueOn:
	ret
collideFunction ENDP

;drawScreenObjects: prints the cars and frog to the screen
drawScreenObjects PROC, X_pointers: DWORD, Y_pointers: DWORD, objects_count: DWORD, frog_x: DWORD, frog_y: DWORD, color: DWORD, object_pointer: DWORD, object_size: DWORD, direction: DWORD
	mov ecx, objects_count
	mov esi, X_pointers			;x coordinates for different objects
	mov edi, Y_pointers			;y coordinates for different objects
	
	generateCars:
		push ecx				;keep the counter after drawObject adn collideFunction are called
		INVOKE drawObject, [esi], [edi], color, object_pointer, direction			;drawObject invoked to print the object to the screen
		mov [esi], eax			;mov the new x into esi
		INVOKE collideFunction, frog_x, frog_y, [esi], [edi], object_size			;call the collideFunction to make sure the frog is not colliding with anything that was just drawn
		pop ecx					;get our counter back
		add esi, 4				;move to the next x and y values
		add edi, 4
	loop generateCars
	ret
drawScreenObjects ENDP

;logCollideCheck: checks to see if a frog is colliding with a log
;passed frog x and y coordinates, log x and y coordinates, log length, and direction the log moves
logCollideCheck PROC, frog_x: DWORD, frog_y: DWORD, obstacle_x: DWORD, obstacle_y: DWORD, obstacle_length: DWORD, direction: DWORD
	LOCAL temp_x: DWORD					;temp_x to be manipulated
	mov ebx, obstacle_x
	mov temp_x, ebx
	cmp frog_y, 28						;check to see if the frog is in water
	jle inWater
	jmp continueOn

	inWater:
		cmp frog_y, 4					;check to see if frog has left water
		jge check_collide
		jmp continueOn

	check_collide:						;frog is confirmed in water
	mov ebx, frog_y						;check to see if frog has the same y as a log
	sub ebx, obstacle_y
	cmp ebx, 0
		jnz log_check

	mov ecx, obstacle_length			;loop to check every log x value to see if the frog collides
	x_check:
		mov eax, frog_x					;compare the frog x and obstacle x
		sub eax, temp_x
		cmp eax, 0
		jz collide_detected
		add temp_x, 1
	loop x_check						;Loop to check every single value of the log on the x-axis so that the frog doesn't die if it hits the right end of the log
	jmp continueOn

	collide_detected:					;if the x values are the same
		cmp direction, 1				;check to see which direction a log is moving
		jz forward
		jnz backward
		forward:
			mov eax, obstacle_x			;if the direction is forward
			add eax, 1					;add one to the x 
			mov ch, 1					;flag to tell that a collide is happening
			jmp continueOn

		backward:
			mov eax, obstacle_x			;if the direction is backwards
			sub eax, 1					;subtract one from the x
			mov ch, 1					;flag to tell that a collide is happening
			jmp continueOn

		log_check:
			mov ch, 0					;flag to tell that a collide is not happening
		
		jmp continueOn


	continueOn:
	ret
logCollideCheck ENDP

;drawLogs: draws logs to the screen, also draws frogs to the screen if they are colliding with a log
;passed frog x and y, log x and y arrays, color, the log's string, the size of a log, and the direction that the log will move
drawLogs PROC, X_pointers: DWORD, Y_pointers: DWORD, logs_count: DWORD, frog_x: DWORD, frog_y: DWORD, color: DWORD, log_pointer: DWORD, log_size: DWORD, direction: DWORD
	LOCAL new_frog_x: DWORD, on_log: BYTE
	mov ecx, frog_x
	mov new_frog_x, ecx				;move the frog's x value to this temp variable
	mov ecx, logs_count				;loop through however many times there are logs
	mov esi, X_pointers				;move the x values of logs
	mov edi, Y_pointers				;move the y values of logs

	generateLogs:
		not direction
		push ecx					;preserve our counter after the INVOKEs
		INVOKE drawObject, [esi], [edi], color, log_pointer, direction					;draw the object
		INVOKE logCollideCheck, frog_x, frog_y, [esi], [edi], log_size, direction		;check if a log collide occurs
		mov [esi], eax				;update the log's x value

		cmp ch, 1					;check if frog is on the log
		jnz continueLoop
		jz set_on_log

		set_on_log:
			mov on_log, ch			;hold the on log flag
			check_y:
				mov ebx, [edi]		;check if the frog is on this log
				cmp frog_y, ebx
				jz redraw_frog		;redraw the frog as the log moves
				jnz continueLoop
			redraw_frog:			;redraw the frog
				mov eax, [esi]
				mov new_frog_x, eax	;retain these values through the INVOKE
				push ebx
				INVOKE drawObject, [esi], frog_y, green, OFFSET frog, direction
				pop ebx
			continueLoop:
			pop ecx					;get the counter back
			add esi, 4				;move to the next x and y
			add edi, 4

	loop generateLogs
	mov ebx, frog_y					;store frog x and y values
	mov eax, new_frog_x

	cmp new_frog_x, 1				;Check if the frog hits the left border
	jz frog_death					;If it does, kill the frog
	jnz rightside_check

	rightside_check:
		cmp new_frog_x, 74			;Check if the frog hits the right border
		jz frog_death				;If it does, kill the frog

	cmp on_log, 1
	jz done

	cmp frog_y, 28					;check if frog is in water area
	jle inWater
	jg done

	inWater:
		cmp frog_y, 4				;check if frog is in the water or in the finishLine section
		jle done

	frog_death:						;kill frog if it is not on a log, is in water, and has not finished the game (Y > 4 && Y < 28)
		call clrscr
		mov eax, 2000
		call Delay
		call ExitProcess

	done:
	mov ch, 0						;set on log flag to 0 (not on a log)
	ret
drawLogs ENDP

asmMain PROC C
	LOCAL frog_x: DWORD, frog_y: DWORD, car_x: DWORD, car_counter:DWORD, direction:DWORD
	mov frog_x, 40				;starting frog x
	mov frog_y, 59				;starting frog y
	mov car_x, 1
	mov ecx, -1					;loop forever until game is won or lost
	mov direction, 1
	call printBorder			;print white border around the game
	call printWater				;print water in the top half of the screen
	DrawFrog:
		mov dl, BYTE PTR frog_x ;get frog's x coordinate
		mov dh, BYTE PTR frog_y ;get frog's y coordinate
		call GotoXY				;go to the (x,y) to print the frog
		INVOKE printObject, green, OFFSET frog		;Invoke the printObject procedure to print the frog
		INVOKE moveFrog, frog_x, frog_y				;Invoke the moveFrog procedure to allow a frog to move with a keyboard input
		mov frog_y, ebx								;update the frog's y coordinate
		mov frog_x, eax								;update the frog's x coordinate
		jmp EndCondition							;jump to the loop that draws cars, logs
	L1:
	call _kbhit					;check to see if the keyboard has been hit
	cmp eax, 1
	mov eax, 0				    ;reset eax
	jz DrawFrog					;draw the frog if the keyboard has been hit
	EndCondition:
		INVOKE drawScreenObjects, OFFSET cars_x, OFFSET cars_y, 10, frog_x, frog_y, red, OFFSET car, car_length, direction		;Invoke the procedure to draw objects to the screen
		INVOKE drawLogs, OFFSET logs_x, OFFSET logs_y, 24, frog_x, frog_y, brown, OFFSET log, log_length, direction				;Draw all the logs to the screen
		mov frog_x, eax
		mov frog_y, ebx
		
		cmp frog_y, 4			;if the frog has gotten past the water
		jl finishLine
		mov eax, 150			;set a slight delay for visuals
		call Delay
	loop L1

	finishLine:					;Get here when game is won
		call clrscr				;clear the game
		mov eax, (white * 16)	;change text color
		call SetTextColor
		mov edx, OFFSET finish	;grab the finish message
		call WriteString		;print congratulatory message
	ret							;return execution control to the C++ main.
asmMain ENDP
END