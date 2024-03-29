.386
.model flat, stdcall
.stack 4096
ExitProcess PROTO, dwExitCode: DWORD

INCLUDE Irvine32.inc

.data
    ; define your variables here
    menuText BYTE "PRESS 1 for typing tutor game and 2 for word dropping game: ", 0   

    ;for typing tutor game (1)
    str1 BYTE "Staring at the bottom of your glass hoping one day you'll make a dream last but dreams come slow, and they go so fast You see her when you close your eyes", 0
    counter BYTE 0
    cordY BYTE 0
    maxX BYTE ?

    ;for word dropping game (2)
    strTEST BYTE "WORD DROPPING GAME", 0

    ;for now - length will be max 7
    array_of_strings BYTE 500 DUP(?), 0


    arrXCords BYTE 30 DUP(?)
    arrYCords BYTE 30 DUP(?)
    ptrXCord DWORD ?
    ptrYcord DWORD ?

    blankText DWORD " ", 0
    finishLine BYTE "--------------------------------------------------------------------------------------",0
    lineHeight BYTE 24
    isTouchLine BYTE 0
    initTime DWORD ?
    timeRn DWORD ?
    mSec DWORD ?
    isLost BYTE 0
    msgLost BYTE "You lost! Try again", 0
    msgWon BYTE "You won!! Thanks for wasting your precious time on this game ", 0

    count DWORD 0
    wordsTyped DWORD 0
    charsTyped DWORD 0
    totalWords DWORD 0

    inputArr BYTE 12 DUP(?)
    input_correct BYTE 1
    error_count BYTE 0
    isWon BYTE 0

    wordsPrinted DWORD 1
    wordLength DWORD ?

    
    ;file reading business
    dict_4 BYTE "four.txt", 0
    dict_8 BYTE "eight.txt", 0
    dict_12 BYTE "twelve.txt", 0

    fileName BYTE "eight.txt", 0
    bufsize = 5000 ;5000 bytes
    buffer BYTE bufsize DUP(?)
    bytesRead DWORD ?
    fileErrMsg BYTE "Could not read file", 0
    fileHandle DWORD ?

    ;menu stuff
    msgWelcome BYTE "Welcome to Linn's Typing Tutor Game!", 0
    msgNavigate BYTE "Please select one of the following game modes using arrow keys", 0
    msgEasy BYTE "EASY", 0
    msgMedium BYTE "MEDIUM", 0
    msgHard BYTE "HARD", 0
    msgSurvival BYTE "Survival", 0

    ;hover difficulty
    hoverLevel BYTE 1

    ;loadingscreen stuff
    gameStart BYTE "GAME STARTING IN", 0
    dot BYTE ".", 0

    three BYTE "3", 0
    two BYTE "2", 0
    one BYTE "1", 0
    go BYTE "GO LANCER!", 0

    ;accuracy & stuff
    msgMistake BYTE "Mistakes: ", 0
    msgAccuracy BYTE "Accuracy: ", 0

    Mistakes DWORD 0
    ACCURACY DWORD 0 
    totalInputCount DWORD 0
    score DWORD 0
    msgWordsCompleted BYTE "Words Completed: ", 0

.code

loadingScreen PROC uses edx eax ecx
    
    ;gametart message
    mov dl, 48 ;column
    mov dh, 12
    call gotoxy
    mov edx, OFFSET gameStart
    call WriteString

    ;add dots
    mov ecx, 3

    dots:
        mov eax, 500
        call Delay
        mov edx, OFFSET dot
        call WriteString
    loop dots



    call clrscr

    ;3
    mov dl, 58 ;column
    mov dh, 12
    call gotoxy
    mov edx, OFFSET three
    call WriteString

    mov eax, 500
    call Delay
    call clrscr

    ;2
    mov dl, 58 ;column
    mov dh, 12
    call gotoxy
    mov edx, OFFSET two
    call WriteString

    mov eax, 500
    call Delay
    call clrscr

    ;1
    mov dl, 58 ;column
    mov dh, 12
    call gotoxy
    mov edx, OFFSET one
    call WriteString

    mov eax, 500
    call Delay
    call clrscr

    ;go
    mov dl, 54 ;column
    mov dh, 12
    call gotoxy
    mov edx, OFFSET go
    call WriteString

    mov eax, 500
    call Delay
    call clrscr



ret
loadingScreen ENDP



printMenuText PROC uses edx eax
    
    ;welcome message
    mov dl, 40 ;column
    mov dh, 8
    call gotoxy
    mov edx, OFFSET msgWelcome
    call WriteString

    ;navigate message
    mov dl, 27 ;column
    mov dh, 10
    call gotoxy
    mov edx, OFFSET msgNavigate
    call WriteString

    .IF hoverLevel == 1
        call setGreen
    .ENDIF
    ;easy message - 1
    mov dl, 53 ;column
    mov dh, 13
    call gotoxy
    mov edx, OFFSET msgEasy
    call WriteString
    call ResetColors

    .IF hoverLevel == 2
        call setGreen
    .ENDIF
    ;medium message - 2
    mov dl, 53 ;column
    mov dh, 15
    call gotoxy
    mov edx, OFFSET msgMedium
    call WriteString
    call ResetColors

    .IF hoverLevel == 3
        call setGreen
    .ENDIF
    ;hard message - 3
    mov dl, 53 ;column
    mov dh, 17
    call gotoxy
    mov edx, OFFSET msgHard
    call WriteString
    call ResetColors

COMMENT $
    .IF hoverLevel == 4
        call setGreen
    .ENDIF
    ;surival message - 4
    mov dl, 53 ;column
    mov dh, 19
    call gotoxy
    mov edx, OFFSET msgSurvival
    call WriteString
    call ResetColors $
ret
printMenuText ENDP

openMenu PROC uses edx eax
    
    call printMenuText

    ;get initial time before program starts
    call GetMseconds

    ;time interval for dropping words by one line
    mov msec, eax

    lookForKey:

        mov eax, 100
        call Delay

        call ReadKey         ; look for keyboard input
        call GetMseconds

        .IF dx == VK_DOWN
            inc hoverLevel

            .IF hoverLevel > 3
                mov hoverLevel, 1
            .ENDIF

        .ELSEIF dx == VK_UP
            dec hoverLevel

            .IF hoverLevel < 1
                mov hoverLevel, 3
            .ENDIF

        .ELSEIF dx == VK_RETURN
            jmp goToGame

        .ENDIF

        ;only jump line if 1 sec has passed
        .IF eax >= msec
            call printMenuText
            add msec, 1000

            ;hide cursor
            call getMaxXy
            mov dl, 119 ;column
            mov dh, 29
            call gotoxy
        .ENDIF


    loop lookForKey

    goToGame:

ret
openMenu ENDP

GetWordsFromFile PROC uses eax esi edi ecx edx

    .IF hoverLevel == 1
    mov wordLength, 4
    mov edx, OFFSET dict_4

    .ELSEIF hoverLevel == 2
    mov wordLength, 8
    mov edx, OFFSET dict_8
    
    .ELSEIF hoverLevel == 3
    mov wordLength, 12
    mov edx, OFFSET dict_12

    

.ENDIF

    ;mov edx, OFFSET fileName
    call OpenInputFile
    ;file handle is returned in eax
    mov fileHandle, eax

    mov edx, OFFSET buffer
    mov ecx, bufsize
    call ReadFromFile
    jc fileReadError
    mov bytesRead, eax

    ; Tokenize the content and store words in the array
    mov esi, offset buffer
    mov edi, offset array_of_strings

tokenize_loop:
    ; Read a character from the buffer
    mov al, [esi]
    cmp al, 0
    je  tokenize_done

    ; Check for space or newline character
    cmp al, ' '
    je  continue
    ;cmp al, 0Ah ; nextline character
    ;je continue

    mov [edi], al
    jmp done
    

continue:
    ;adjusting edi
    dec edi
    inc totalWords

done:
    inc edi
    inc esi
    jmp tokenize_loop

tokenize_done:

    inc totalWords
    jmp close_file

    fileReadError:
        mov edx, OFFSET fileErrMsg
        call WriteString

close_file: 
        ;call WriteString
        mov eax, fileHandle
        call CloseFile


        

ret
GetWordsFromFile ENDP

generateRandXY PROC uses ecx esi edx eax
    
    ;esi = x coordinate
    mov esi, OFFSET arrXCords
    ;edx = y coordinate
    mov edx, OFFSET arrYCords
    mov ecx, totalWords
    call randomize

    generate:
        ;for y coordinates
        mov al, 0
        mov [edx], al
        inc edx

        ;for x coordinates
        push edx
            call getMaxXY
            sub edx, wordLength
            movzx eax, dl ;eax is the range
            call randomRange
            ;eax now contains a random value
        pop edx
        mov [esi], al
        inc esi

    loop generate
    

ret
generateRandXY ENDP

GenerateStrings PROC uses ecx ebx esi
	mov ecx, totalWords					;loop counter
	mov esi, OFFSET array_of_strings
	call Randomize
	L1:
		call RandomString		;create random string in str_array
		add esi, wordLength			;move next index of str_array
		loop L1
	ret
GenerateStrings ENDP

;esi should hold the offset of str_array
RandomString PROC uses ecx eax esi		;return random string and stored in str_array

	mov ecx, wordLength
	inc ecx
	L5:
		mov eax, 26
		call RandomRange	;generate within 26 alphabets
		add eax, 'a'		;move eax to first Alpha
		mov [esi],al		;change the string
		inc esi				;increase to next index
		loop L5
		;inc count
	ret
RandomString ENDP

writePrompt PROC USES edx
;requires: the prompt needs to be in esi
    mov edx, esi
    call WriteString

ret
writePrompt ENDP


goToStart PROC USES edx
;go to start of the 0 x 0 on the screen

    mov dl, 0; column
    mov dh, 0; row
    call Gotoxy
ret
goToStart ENDP

setGreen PROC USES eax
    mov  eax,green+(black*16)
    call SetTextColor

ret
setGreen ENDP

setRed PROC USES eax
    mov  eax,red+(black*16)
    call SetTextColor

ret
setRed ENDP

resetColors PROC USES eax
;reset text color
    mov  eax,white+(black*16)
    call SetTextColor

ret
resetColors ENDP

dealBSpace PROC USES edx

    ;edgecase (1): x = 0
    cmp counter, 0
    jne NOT_EDGE

	;edgecase (2): also, y = 0
	cmp cordY, 0
	je NO_ACTION

	;if x = 0 but y != 0
	;set counter = largest column - 1
	call getMaxXY ;dl = highest column, dh = highest row
	mov counter, dl
	dec cordY

NOT_EDGE:
    ;going one step back
    dec counter 
    dec esi

	
    ;write the previous thing in black (backspace action)
    mov al, BYTE PTR [esi]
    call resetColors
    call locateCursor
    call WriteChar
    
    ;to maintain the correct looping
    add ecx, 1

NO_ACTION:
    add ecx, 1


ret
dealBSpace ENDP

locateCursor PROC USES edx

    mov dh, cordY
    mov dl, counter
    call gotoxy

ret
locateCursor ENDP

runTest PROC USES eax esi
;run typing test with given prompt, correct words will be green, wrong ones red
;requires: prompt is in the esi

L_INPUT: 

    ;read the char
    call ReadChar

    ;IF IT IS A BACKSPACE
    cmp al, 8   ;8 is ASCII for backspace
    jne NOT_BACKSPACE
	call dealBSpace
	jmp DONE


    ;IF IT IS NOT A BACKSPACE
NOT_BACKSPACE:
    ;compare the characters
    cmp BYTE PTR [esi], al
    jne CHAR_MISMATCH
    call setGreen
    jmp CHAR_MATCH

CHAR_MISMATCH: 
    call setRed

CHAR_MATCH:
    mov al, BYTE PTR [esi]
    call WriteChar

    ;increment by each character
    inc esi
    inc counter

	;check if it goes over the bound
	call getMaxXY ;dl = highest column, dh = highest row

    dec dl
	cmp dl, counter
	jae IN_BOUND
	;out of bound
	inc cordY
	mov counter, 0

IN_BOUND:
	;do nothing if inbound

DONE: 
    call locateCursor
    loop L_INPUT

	;reset counter to re use next time
	mov counter, 0
ret
runTest ENDP

menu PROC USES edx

mov edx, OFFSET menuText
call WriteString

ret
menu ENDP

typingTutorGame PROC USES esi ecx

    mov esi, OFFSET str1
    mov ecx, LENGTHOF str1
    ;make sure to take one space off of null char
    dec ecx

    call writePrompt
    call goToStart ;go to 0x0 to type    

    ;call the typing test
    call runTest 
    

    call resetColors

ret
typingTutorGame ENDP

drawFinishLine PROC USES edx eax ecx

    ;get maxX and maxY
    call getMaxXY

    ;choose vertical position
    mov dh, lineHeight
    ;fill the screen horizontally
    movzx ecx, dl 
    dec ecx

    mov dl, 0
    mov al, '-'

loopFLine:
    inc dl
    call gotoxy
    call WriteChar

    loop loopFLine

    
        ;print accuracy & mistake count
        call setRed

        call crlf
        mov edx, OFFSET msgMistake
        call WriteString

        mov eax, mistakes
        call WriteDec
        call crlf

COMMENT $
        mov edx, OFFSET msgAccuracy
        call WriteString

        call CalcAccu
        mov eax, accuracy
        call WriteDec $

        call resetColors
    
ret
drawFinishLine ENDP

drawBaseLine PROC uses edx

    mov dl, 1
    mov dh, lineHeight
    call gotoxy

    mov edx, OFFSET finishLine
    call WriteString

ret
drawBaseLine ENDP

CheckTouchLine PROC 

    ;check if any words have touched the base line
    cmp isTouchLine, 1
    jne CONTINUE_DROP
    mov ecx, 1
    mov isLost, 1

CONTINUE_DROP:

ret
CheckTouchLine ENDP

PrintWords PROC USES edx ecx esi eax ebx

    ;adjust loop count for completed words
    mov ecx, wordsPrinted
    sub ecx, wordsTyped

loopWords:

        mov ebx, count
        ;don't print if a word is completed
        add ebx, wordsTyped

        .IF count == 0
            ;adjust the esi pointer to next word
            push ecx
            .IF wordsTyped > 0
                mov ecx, wordsTyped
                movESI:
                    add esi, wordLength
                loop movESI
            .ENDIF 
            pop ecx

        .ENDIF

        mov dl, arrXcords[ebx]
        mov dh, arrYcords[ebx]
        call gotoxy

        ;check if it has touched the base line

        cmp dh, lineHeight
        jne CONTINUE_LW
        mov isTouchLine, 1
CONTINUE_LW:
       
        push ecx
        mov ecx, wordLength
    LOOP_CHAR:
            mov al, BYTE PTR [esi]
            call WriteChar
            inc esi
    loop LOOP_CHAR
        pop ecx
        

        ;increase business
        inc count

        loop loopWords

         ;reset count
         mov count, 0
ret
PrintWords ENDP

PrintInputArr PROC USES edx ecx esi eax ebx

    mov ebx, wordsTyped
    mov dl, arrXcords[ebx]
    mov dh, arrYcords[ebx]
    call gotoxy

    ;no need to check touchLine
    mov ecx, charsTyped

    ;esi points to InputArr
    mov esi, OFFSET inputArr

    .IF input_correct == 0
        call setRed
    .ELSEIF input_correct == 1
        call setGreen
    .ENDIF

    .IF charsTyped > 0
        LOOP_CHAR:
                mov al, BYTE PTR [esi]
                call WriteChar
                inc esi
        loop LOOP_CHAR
    .ENDIF    

    ;show the incorrect character
;-----------------------------------------
.IF (input_correct == 0) && (mistakes >= 1)
    mov esi, OFFSET array_of_strings
    add esi, charsTyped
    .IF wordsTyped > 0
        mov ecx, wordsTyped
        movESI:
            add esi, wordLength
        loop movESI
    .ENDIF

    mov al, BYTE PTR [esi]
    call WriteChar

    ;relocate cursor if wrong
    mov ebx, wordsTyped
    mov dl, arrXcords[ebx]
    mov dh, arrYcords[ebx]
    add edx, charsTyped
    call gotoxy
.ENDIF
;-------------------------------------


    call resetColors
    ;increase business
    inc count
        ;reset count
    mov count, 0
ret
PrintInputArr ENDP

CheckKey PROC USES edx esi eax ecx

    add esi, charsTyped

    .IF wordsTyped > 0
        mov ecx, wordsTyped
        movESI:
            add esi, wordLength
        loop movESI
    .ENDIF  
    
    mov eax, wordLength
    .IF charsTyped < eax
        mov eax, charsTyped
        ;add dl, al <--- I dont know why I put this, gave me errors!!
    .ENDIF

    mov eax, totalWords
    .IF wordsTyped < eax
        call gotoxy
    .ENDIF

    ;THIS SAVED MY LIFE OMFFGGGGGGGGGGG!!!
    mov eax, 10
    call Delay
    call ReadKey
    ;nothing is read into
    jz DONE
        
    ;keep track of how many have been typed
    inc totalInputCount

    cmp BYTE PTR [esi], al
    jne CHAR_MISMATCH
    call setGreen
    jmp CHAR_MATCH

CHAR_MISMATCH: 
    mov input_correct, 0
    inc mistakes
    jmp DONE

CHAR_MATCH:
    inc charsTyped

    ;update input array
    mov edx, OFFSET inputArr
    add edx, charsTyped
    dec edx
    mov [edx], al
    inc edx

    ;set input_correct
    mov input_correct, 1

DONE:  
     call PrintInputArr
     mov eax, wordLength
        .IF charsTyped >= eax
        inc wordsTyped
        mov charsTyped, 0
    .ENDIF

    mov eax, totalWords
    .IF wordsTyped == eax
        mov isWon, 1
    .ENDIF


ret
CheckKey ENDP

wordDroppingGame PROC USES edx ebx eax esi

    ;for setting difficulty
    ;mov wordLength, 4

    ;fill up strings
    ;call generateStrings
    call getWordsFromFile

;fill up cords
    call generateRandXY

;for now - loop infinitely until the finishline
    mov ecx, -1

;get initial time before program starts
    call GetMseconds
    mov initTime, eax

    ;time interval for dropping words by one line
    mov msec, eax


loopWD:

    ;-----------------
    ;hardcode ecx / the number of arrays for now
    mov ecx, totalWords
    mov esi, OFFSET array_of_strings

    
    ;call drawBaseLine

    

    call CheckKey

    call GetMseconds ;time right now -> eax

    ;only jump line if 1 sec has passed
    .IF eax >= msec
        
        call clrscr

        ;increase each y coords

        push ecx
        mov ecx, wordsPrinted
        increase_y:
            inc arrYcords[ecx - 1]
        loop increase_y
        pop ecx

             

        ;draw FinishLine
        call drawFinishLine

        ;print all the words in the array
        call printWords

        ;print typed characters
        ;call PrintInputArr
        
        mov eax, totalWords
        .IF wordsPrinted < eax
            inc wordsPrinted
        .ENDIF
        add msec, 1000
    .ENDIF  
   

    call CheckTouchLine
    .IF isWon == 1
        jmp DONE
    .ENDIF

NOT_NOW:
    mov count, 0

loop loopWD

DONE:
   
ret
wordDroppingGame ENDP


finishMsg PROC
;edx: message to print
    
    call clrscr

    mov dl, 27
    mov dh, 10
    call gotoxy
    .IF isLost == 1
        mov edx, OFFSET msgLost
    .ELSE
        mov edx, OFFSET msgWon
    .ENDIF

    call WriteString

ret
finishMsg ENDP




main PROC
    
    call openMenu
    ;call menu
    ;mov eax, 0
    ;user has chosen mode
    ;1 for typing tutor & 2 for word dropping
    ;call ReadInt ;response in eax
    call Clrscr

    .IF hoverLevel == 5
        jmp MODE_1

    .ELSEIF hoverlevel >= 1 && hoverLevel <= 4
        jmp MODE_2
    .ENDIF

    MODE_1: 
    call typingTutorGame
    jmp DONE
        
    MODE_2:
    call loadingScreen
    call wordDroppingGame

    DONE:

    call finishMsg
    call crlf
    call gameReport

    mov eax, 1000
    call delay

ENDPROGRAM:    

    INVOKE ExitProcess, 0
main ENDP

gameReport PROC uses EDX EAX3

    ;print accuracy & mistake count
 
        mov dl, 50
        mov dh, 12
        call gotoxy
        mov edx, OFFSET msgMistake
        call WriteString

        mov eax, mistakes
        call WriteDec
        call crlf

        mov dl, 50
        mov dh, 13
        call gotoxy
        mov edx, OFFSET msgAccuracy
        call WriteString

        call calc_accu
        mov eax, accuracy
        call WriteDec 

        ;words completed
        mov dl, 50
        mov dh, 14
        call gotoxy
        mov edx, OFFSET msgWordsCompleted
        call WriteString

        mov eax, wordsTyped
        call WriteDec 

        call crlf
        call crlf

ret
gameReport ENDP

calc_accu proc uses EAX EBX EDX
 
.IF totalInputCount > 0
     mov edx, 0
     mov eax, totalInputCount
     mov ebx, mistakes
     sub eax, ebx
     mov score, eax ;now eax has number of right char
     mov ebx, 100
     mul ebx; 
     mov ebx, totalInputCount
     div ebx
     mov ACCURACY, eax

.ELSE
    mov ACCURACY, 0
 .ENDIF

ret
calc_accu ENDP

END main