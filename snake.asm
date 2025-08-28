; snake.asm - 16-bit NASM .COM Snake (working version with two snakes and AI collision avoidance)
; Assemble: nasm -f bin snake.asm -o snake.com

org 0x100

; ---------- CONFIG ----------
WIDTH       equ 78
HEIGHT      equ 23
MAX_SEG     equ 100

CHAR_SNAKE1 equ '#'
ATTR_SNAKE1 equ 0x0A  ; light green
CHAR_SNAKE2 equ '@'
ATTR_SNAKE2 equ 0x0B  ; light cyan

CHAR_FOOD   equ '*'
ATTR_FOOD   equ 0x0C  ; light red

; ---------- DATA ----------
section .data
; Snake 1 (Player)
snake1Len   dw 3
dir1X       db 1         ; moving right initially
dir1Y       db 0
snake1X     times MAX_SEG db 0
snake1Y     times MAX_SEG db 0

; Snake 2 (AI Opponent)
snake2Len   dw 3
dir2X       db -1        ; moving left initially
dir2Y       db 0
snake2X     times MAX_SEG db 0
snake2Y     times MAX_SEG db 0

foodX       db 20
foodY       db 10
gameRunning db 1

seed        dw 0x1234

; ---------- CODE ----------
section .text

_start:
    ; clear screen
    mov ax, 0x0003
    int 0x10
    
    ; hide cursor
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10

    ; initialize snake 1
    mov byte [snake1X], 40    ; head
    mov byte [snake1Y], 12
    mov byte [snake1X + 1], 39    ; body 1
    mov byte [snake1Y + 1], 12
    mov byte [snake1X + 2], 38    ; body 2 (tail)
    mov byte [snake1Y + 2], 12

    ; initialize snake 2
    mov byte [snake2X], 20    ; head
    mov byte [snake2Y], 10
    mov byte [snake2X + 1], 21    ; body 1
    mov byte [snake2Y + 1], 10
    mov byte [snake2X + 2], 22    ; body 2 (tail)
    mov byte [snake2Y + 2], 10

    ; set video segment
    mov ax, 0xB800
    mov es, ax

    call place_food

main_loop:
    cmp byte [gameRunning], 0
    je game_over
    
    call draw_game

    ; Player input for Snake 1
    call get_input

    ; AI for Snake 2
    call ai_snake2
    
    call update_snake1
    call update_snake2
    call delay
    jmp main_loop

; ---------- SIMPLIFIED AI FOR SNAKE 2 ----------
ai_snake2:
    push ax
    push bx
    push cx
    push dx

    ; Get snake2 head position
    mov al, [snake2X]     ; head X
    mov bl, [snake2Y]     ; head Y
    mov cl, [foodX]       ; food X
    mov dl, [foodY]       ; food Y

    ; Simple AI: move towards food
    ; Check X direction first
    cmp al, cl
    je .check_y_direction
    jl .try_move_right
    
.try_move_left:
    ; Try to move left (only if not currently moving right)
    cmp byte [dir2X], 1
    je .check_y_direction
    call check_safe_move_left
    jc .check_y_direction
    mov byte [dir2X], -1
    mov byte [dir2Y], 0
    jmp .ai_done

.try_move_right:
    ; Try to move right (only if not currently moving left)
    cmp byte [dir2X], -1
    je .check_y_direction
    call check_safe_move_right
    jc .check_y_direction
    mov byte [dir2X], 1
    mov byte [dir2Y], 0
    jmp .ai_done

.check_y_direction:
    cmp bl, dl
    je .try_any_safe_move
    jl .try_move_down

.try_move_up:
    ; Try to move up (only if not currently moving down)
    cmp byte [dir2Y], 1
    je .try_any_safe_move
    call check_safe_move_up
    jc .try_any_safe_move
    mov byte [dir2X], 0
    mov byte [dir2Y], -1
    jmp .ai_done

.try_move_down:
    ; Try to move down (only if not currently moving up)
    cmp byte [dir2Y], -1
    je .try_any_safe_move
    call check_safe_move_down
    jc .try_any_safe_move
    mov byte [dir2X], 0
    mov byte [dir2Y], 1
    jmp .ai_done

.try_any_safe_move:
    ; If can't move towards food, try any safe direction
    call check_safe_move_right
    jnc .set_right
    call check_safe_move_left
    jnc .set_left
    call check_safe_move_down
    jnc .set_down
    call check_safe_move_up
    jnc .set_up
    jmp .ai_done  ; No safe move found, keep current direction

.set_right:
    cmp byte [dir2X], -1  ; Don't reverse
    je .try_any_safe_move
    mov byte [dir2X], 1
    mov byte [dir2Y], 0
    jmp .ai_done

.set_left:
    cmp byte [dir2X], 1   ; Don't reverse
    je .try_any_safe_move
    mov byte [dir2X], -1
    mov byte [dir2Y], 0
    jmp .ai_done

.set_down:
    cmp byte [dir2Y], -1  ; Don't reverse
    je .try_any_safe_move
    mov byte [dir2X], 0
    mov byte [dir2Y], 1
    jmp .ai_done

.set_up:
    cmp byte [dir2Y], 1   ; Don't reverse
    je .try_any_safe_move
    mov byte [dir2X], 0
    mov byte [dir2Y], -1

.ai_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ---------- SAFETY CHECK FUNCTIONS ----------
check_safe_move_right:
    ; Check if moving right is safe for snake2
    mov al, [snake2X]
    inc al                ; next X position
    mov bl, [snake2Y]     ; current Y position
    jmp check_position_safe

check_safe_move_left:
    mov al, [snake2X]
    dec al                ; next X position
    mov bl, [snake2Y]     ; current Y position
    jmp check_position_safe

check_safe_move_up:
    mov al, [snake2X]     ; current X position
    mov bl, [snake2Y]
    dec bl                ; next Y position
    jmp check_position_safe

check_safe_move_down:
    mov al, [snake2X]     ; current X position
    mov bl, [snake2Y]
    inc bl                ; next Y position
    jmp check_position_safe

check_position_safe:
    ; Input: AL = X position to check, BL = Y position to check
    ; Output: Carry flag set if unsafe, clear if safe
    
    ; Check walls
    cmp al, 0
    jl .unsafe
    cmp al, WIDTH
    jge .unsafe
    cmp bl, 0
    jl .unsafe
    cmp bl, HEIGHT
    jge .unsafe
    
    ; Check collision with snake1
    push cx
    push si
    mov cx, [snake1Len]
    mov si, 0
    
.check_snake1_loop:
    cmp si, cx
    jge .check_snake2
    
    mov ah, [snake1X + si]
    cmp al, ah
    jne .next_snake1_seg
    mov ah, [snake1Y + si]
    cmp bl, ah
    je .collision_found
    
.next_snake1_seg:
    inc si
    jmp .check_snake1_loop

.check_snake2:
    ; Check collision with snake2 body (not head)
    mov cx, [snake2Len]
    mov si, 1             ; Start from segment 1 (skip head)
    
.check_snake2_loop:
    cmp si, cx
    jge .safe
    
    mov ah, [snake2X + si]
    cmp al, ah
    jne .next_snake2_seg
    mov ah, [snake2Y + si]
    cmp bl, ah
    je .collision_found
    
.next_snake2_seg:
    inc si
    jmp .check_snake2_loop

.safe:
    pop si
    pop cx
    clc                   ; Clear carry flag (safe)
    ret

.collision_found:
    pop si
    pop cx
.unsafe:
    stc                   ; Set carry flag (unsafe)
    ret

; ---------- PLAYER INPUT (for Snake 1) ----------
get_input:
    mov ah, 0x01
    int 0x16
    jz .no_key

    mov ah, 0x00
    int 0x16
    
    cmp al, 27        ; ESC
    jne .not_esc
    mov byte [gameRunning], 0
    ret
    
.not_esc:
    cmp ah, 0x4B      ; Left arrow
    jne .not_left
    cmp byte [dir1X], 1
    je .no_key        ; can't reverse
    mov byte [dir1X], -1
    mov byte [dir1Y], 0
    jmp .no_key
    
.not_left:
    cmp ah, 0x4D      ; Right arrow
    jne .not_right
    cmp byte [dir1X], -1
    je .no_key
    mov byte [dir1X], 1
    mov byte [dir1Y], 0
    jmp .no_key
    
.not_right:
    cmp ah, 0x48      ; Up arrow
    jne .not_up
    cmp byte [dir1Y], 1
    je .no_key
    mov byte [dir1X], 0
    mov byte [dir1Y], -1
    jmp .no_key
    
.not_up:
    cmp ah, 0x50      ; Down arrow
    jne .no_key
    cmp byte [dir1Y], -1
    je .no_key
    mov byte [dir1X], 0
    mov byte [dir1Y], 1

.no_key:
    ret

; ---------- GAME UPDATE (Snake 1) ----------
update_snake1:
    ; move body segments from tail to neck
    mov cx, [snake1Len]
    dec cx              ; start from tail
    
.move_body_loop:
    cmp cx, 0
    je .move_head
    
    ; copy segment cx-1 to segment cx
    mov bx, cx
    dec bx
    mov al, [snake1X + bx]
    mov bx, cx
    mov [snake1X + bx], al
    
    mov bx, cx
    dec bx
    mov al, [snake1Y + bx]
    mov bx, cx
    mov [snake1Y + bx], al
    
    dec cx
    jmp .move_body_loop

.move_head:
    ; move head in current direction
    mov al, [dir1X]
    add [snake1X], al
    mov al, [dir1Y]
    add [snake1Y], al

    ; check wall collision
    mov al, [snake1X]
    cmp al, 0
    jl .hit_wall
    cmp al, WIDTH
    jge .hit_wall
    mov al, [snake1Y]
    cmp al, 0
    jl .hit_wall
    cmp al, HEIGHT
    jge .hit_wall
    jmp .check_self

.hit_wall:
    mov byte [gameRunning], 0
    ret

.check_self:
    ; check self collision (head vs body)
    mov cx, [snake1Len]
    dec cx              ; don't check head against itself
    
.self_loop:
    cmp cx, 0
    je .check_other_snake_collision
    
    mov bx, cx
    mov al, [snake1X]        ; head X
    cmp al, [snake1X + bx]   ; body segment X
    jne .next_body_seg
    mov al, [snake1Y]        ; head Y  
    cmp al, [snake1Y + bx]   ; body segment Y
    jne .next_body_seg
    
    ; collision detected
    mov byte [gameRunning], 0
    ret

.next_body_seg:
    dec cx
    jmp .self_loop

.check_other_snake_collision:
    ; Check snake1 head against snake2's body and head
    mov cx, [snake2Len]
    
.other_snake_loop:
    cmp cx, 0
    je .check_food
    
    mov bx, cx
    dec bx ; Check all segments of other snake including head
    mov al, [snake1X]        ; snake1 head X
    cmp al, [snake2X + bx]   ; snake2 segment X
    jne .next_other_seg
    mov al, [snake1Y]        ; snake1 head Y  
    cmp al, [snake2Y + bx]   ; snake2 segment Y
    jne .next_other_seg
    
    ; collision detected
    mov byte [gameRunning], 0
    ret

.next_other_seg:
    loop .other_snake_loop

.check_food:
    ; check if head ate food
    mov al, [snake1X]
    cmp al, [foodX]
    jne .done_update
    mov al, [snake1Y]
    cmp al, [foodY]
    jne .done_update
    
    ; ate food - grow snake by 1 segment
    inc word [snake1Len]
    call place_food

.done_update:
    ret

; ---------- GAME UPDATE (Snake 2) ----------
update_snake2:
    ; move body segments from tail to neck
    mov cx, [snake2Len]
    dec cx              ; start from tail
    
.move_body_loop:
    cmp cx, 0
    je .move_head
    
    ; copy segment cx-1 to segment cx
    mov bx, cx
    dec bx
    mov al, [snake2X + bx]
    mov bx, cx
    mov [snake2X + bx], al
    
    mov bx, cx
    dec bx
    mov al, [snake2Y + bx]
    mov bx, cx
    mov [snake2Y + bx], al
    
    dec cx
    jmp .move_body_loop

.move_head:
    ; move head in current direction
    mov al, [dir2X]
    add [snake2X], al
    mov al, [dir2Y]
    add [snake2Y], al

    ; check wall collision
    mov al, [snake2X]
    cmp al, 0
    jl .hit_wall
    cmp al, WIDTH
    jge .hit_wall
    mov al, [snake2Y]
    cmp al, 0
    jl .hit_wall
    cmp al, HEIGHT
    jge .hit_wall
    jmp .check_self

.hit_wall:
    mov byte [gameRunning], 0
    ret

.check_self:
    ; check self collision (head vs body)
    mov cx, [snake2Len]
    dec cx              ; don't check head against itself
    
.self_loop:
    cmp cx, 0
    je .check_other_snake_collision
    
    mov bx, cx
    mov al, [snake2X]        ; head X
    cmp al, [snake2X + bx]   ; body segment X
    jne .next_body_seg
    mov al, [snake2Y]        ; head Y  
    cmp al, [snake2Y + bx]   ; body segment Y
    jne .next_body_seg
    
    ; collision detected
    mov byte [gameRunning], 0
    ret

.next_body_seg:
    dec cx
    jmp .self_loop

.check_other_snake_collision:
    ; Check snake2 head against snake1's body and head
    mov cx, [snake1Len]
    
.other_snake_loop:
    cmp cx, 0
    je .check_food
    
    mov bx, cx
    dec bx ; Check all segments of other snake including head
    mov al, [snake2X]        ; snake2 head X
    cmp al, [snake1X + bx]   ; snake1 segment X
    jne .next_other_seg
    mov al, [snake2Y]        ; snake2 head Y  
    cmp al, [snake1Y + bx]   ; snake1 segment Y
    jne .next_other_seg
    
    ; collision detected
    mov byte [gameRunning], 0
    ret

.next_other_seg:
    loop .other_snake_loop

.check_food:
    ; check if head ate food
    mov al, [snake2X]
    cmp al, [foodX]
    jne .done_update
    mov al, [snake2Y]
    cmp al, [foodY]
    jne .done_update
    
    ; ate food - grow snake by 1 segment
    inc word [snake2Len]
    call place_food

.done_update:
    ret

; ---------- FOOD PLACEMENT ----------
place_food:
.try_again:
    ; simple random food placement
    mov ax, [seed]
    mov dx, 25173
    mul dx
    add ax, 13849
    mov [seed], ax
    
    ; get X position (0 to WIDTH-1)
    xor dx, dx
    mov bx, WIDTH
    div bx
    mov [foodX], dl
    
    ; get Y position (0 to HEIGHT-1)
    mov ax, [seed]
    add ax, 12345
    mov [seed], ax
    xor dx, dx
    mov bx, HEIGHT
    div bx
    mov [foodY], dl
    
    ; check if food overlaps with snake 1
    mov cx, [snake1Len]
.check_overlap_s1:
    cmp cx, 0
    je .check_overlap_s2
    
    dec cx
    mov bx, cx
    mov al, [foodX]
    cmp al, [snake1X + bx]
    jne .next_check_s1
    mov al, [foodY]
    cmp al, [snake1Y + bx]
    je .try_again       ; overlap found, try new position
    
.next_check_s1:
    jmp .check_overlap_s1

    ; check if food overlaps with snake 2
.check_overlap_s2:
    mov cx, [snake2Len]
.check_overlap_s2_loop:
    cmp cx, 0
    je .food_ok
    
    dec cx
    mov bx, cx
    mov al, [foodX]
    cmp al, [snake2X + bx]
    jne .next_check_s2
    mov al, [foodY]
    cmp al, [snake2Y + bx]
    je .try_again       ; overlap found, try new position
    
.next_check_s2:
    jmp .check_overlap_s2_loop
    
.food_ok:
    ret

; ---------- DRAWING ----------
draw_game:
    ; clear screen
    xor di, di
    mov cx, 80 * 25
    mov ax, 0x0720      ; space with black background
.clear:
    stosw
    loop .clear

    ; draw food
    xor ax, ax
    mov al, [foodY]
    mov bx, 80
    mul bx
    add al, [foodX]
    adc ah, 0
    shl ax, 1
    mov di, ax
    mov ax, (ATTR_FOOD << 8) | CHAR_FOOD
    mov es:[di], ax

    ; draw snake 1
    mov cx, [snake1Len]
    xor si, si
    
.draw_snake1_loop:
    cmp si, cx
    jge .draw_snake2_start
    
    ; calculate screen position for segment si
    mov bx, si
    xor ax, ax
    mov al, [snake1Y + bx]
    mov bx, 80
    mul bx
    mov bx, si
    add al, [snake1X + bx]
    adc ah, 0
    shl ax, 1
    mov di, ax
    
    ; draw segment
    mov ax, (ATTR_SNAKE1 << 8) | CHAR_SNAKE1
    mov es:[di], ax
    
    inc si
    jmp .draw_snake1_loop

.draw_snake2_start:
    ; draw snake 2
    mov cx, [snake2Len]
    xor si, si
    
.draw_snake2_loop:
    cmp si, cx
    jge .done_draw
    
    ; calculate screen position for segment si
    mov bx, si
    xor ax, ax
    mov al, [snake2Y + bx]
    mov bx, 80
    mul bx
    mov bx, si
    add al, [snake2X + bx]
    adc ah, 0
    shl ax, 1
    mov di, ax
    
    ; draw segment
    mov ax, (ATTR_SNAKE2 << 8) | CHAR_SNAKE2
    mov es:[di], ax
    
    inc si
    jmp .draw_snake2_loop

.done_draw:
    ret

; ---------- DELAY ----------  
delay:
    mov cx, 800
.delay_loop:
    push cx
    mov cx, 200
.inner_loop:
    nop
    loop .inner_loop
    pop cx
    loop .delay_loop
    ret

; ---------- GAME OVER ----------
game_over:
    ; show cursor
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    
    ; clear screen
    mov ax, 0x0003
    int 0x10
    
    ; print message
    mov ah, 0x09
    mov dx, game_over_msg
    int 0x21

    ; wait for key
    mov ah, 0x00
    int 0x16

    ; exit
    mov ah, 0x4C
    int 0x21

game_over_msg db 'Game Over! Press any key to exit.$'