.MODEL SMALL
.STACK 100H

MOSTRAR MACRO cadena
    mov dx, OFFSET cadena
    mov ah, 09h
    int 21h
ENDM

CARGAR_N MACRO
    mov cl, NPOS
    xor ch, ch
ENDM

.DATA
    ; --- Configuracion del nivel actual (luego la llena el menu) ---
    NPOS        DB 4            ; posiciones (4 o 5)
    NCOLORES    DB 6            ; colores disponibles (6 u 8)

    ; --- Tablas principales (RT-05), 5 = maximo de posiciones ---
    SECRETO     DB 5 DUP(0)     ; codigo secreto
    INTENTO     DB 5 DUP(0)     ; intento en construccion
    USADO_S     DB 5 DUP(0)     ; marca: ficha del secreto ya emparejada
    USADO_I     DB 5 DUP(0)     ; marca: ficha del intento ya emparejada

    ; --- Resultado de la ultima evaluacion ---
    TOROS       DB 0
    VACAS       DB 0

    ; --- Datos del arnes de pruebas (N = 4) ---
    ; Formato por caso: secreto(4), intento(4), toros esperados, vacas esperadas
    ; Letras de la Tabla 2: R=1, V=2, A=3, M=4, N=5, B=6
    CASOS       DB 1,2,3,4,  1,3,2,4,  2,2     ; caso 1: RVAM / RAVM
                DB 1,1,2,3,  1,2,1,1,  1,2     ; caso 2: RRVA / RVRR
                DB 1,2,3,4,  5,6,5,6,  0,0     ; caso 3: RVAM / NBNB
                DB 3,3,3,3,  3,3,1,1,  2,0     ; caso 4: AAAA / AARR
    CASO_N      DB 1

    msgTitulo   DB 'PRUEBAS TOROS Y VACAS (Tabla 2)',13,10,'$'
    msgCaso     DB 'Caso $'
    msgT        DB ': T=$'
    msgV        DB ' V=$'
    msgOk       DB '  OK',13,10,'$'
    msgFalla    DB '  FALLA',13,10,'$'

.CODE

MAIN PROC FAR
    mov ax, @DATA
    mov ds, ax              ; DS apunta al segmento de datos

    MOSTRAR msgTitulo

    xor bx, bx              ; BX = desplazamiento del caso dentro de CASOS
bucle_casos:
    call CargarCaso
    call CalcularTorosVacas
    call MostrarResultado
    add bx, 10              ; cada caso ocupa 10 bytes
    inc CASO_N
    cmp CASO_N, 5
    jb bucle_casos

    mov ah, 4Ch             ; salida ordenada a DOS
    int 21h
MAIN ENDP

CalcularTorosVacas PROC NEAR
    push bx
    push cx
    push si
    push di

    ; Limpiar marcas de fichas usadas
    xor bx, bx
    CARGAR_N
ctv_limpiar:
    mov USADO_S[bx], 0
    mov USADO_I[bx], 0
    inc bx
    loop ctv_limpiar

    mov TOROS, 0
    mov VACAS, 0

    ; Pasada 1: toros (mismo color en la misma posicion)
    xor si, si
    CARGAR_N
ctv_p1:
    mov al, SECRETO[si]
    cmp al, INTENTO[si]
    jne ctv_p1_sig
    inc TOROS
    mov USADO_S[si], 1      ; esta ficha ya no puede dar vaca
    mov USADO_I[si], 1
ctv_p1_sig:
    inc si
    loop ctv_p1

    mov bl, NPOS
    xor bh, bh              ; BX = limite de posiciones
    xor si, si
ctv_ext:
    cmp si, bx
    jae ctv_fin
    cmp USADO_I[si], 0
    jne ctv_ext_sig
    mov al, INTENTO[si]
    xor di, di
ctv_int:
    cmp di, bx
    jae ctv_ext_sig
    cmp USADO_S[di], 0
    jne ctv_int_sig
    cmp al, SECRETO[di]
    jne ctv_int_sig
    inc VACAS
    mov USADO_S[di], 1      ; la ficha del secreto queda consumida
    jmp ctv_ext_sig
ctv_int_sig:
    inc di
    jmp ctv_int
ctv_ext_sig:
    inc si
    jmp ctv_ext

ctv_fin:
    mov al, TOROS
    mov ah, VACAS
    pop di
    pop si
    pop cx
    pop bx
    ret
CalcularTorosVacas ENDP

CargarCaso PROC NEAR
    push ax
    push cx
    push si

    xor si, si
    CARGAR_N
cc_copia:
    mov al, CASOS[bx+si]        ; base-indice: caso + posicion
    mov SECRETO[si], al
    mov al, CASOS[bx+si+4]
    mov INTENTO[si], al
    inc si
    loop cc_copia

    pop si
    pop cx
    pop ax
    ret
CargarCaso ENDP

MostrarResultado PROC NEAR
    push ax
    push dx

    MOSTRAR msgCaso
    mov dl, CASO_N
    call ImprimirDigito
    MOSTRAR msgT
    mov dl, TOROS
    call ImprimirDigito
    MOSTRAR msgV
    mov dl, VACAS
    call ImprimirDigito

    ; Comparar contra los valores esperados de la tabla
    mov al, TOROS
    cmp al, CASOS[bx+8]
    jne mr_falla
    mov al, VACAS
    cmp al, CASOS[bx+9]
    jne mr_falla
    MOSTRAR msgOk
    jmp mr_fin
mr_falla:
    MOSTRAR msgFalla
mr_fin:
    pop dx
    pop ax
    ret
MostrarResultado ENDP

ImprimirDigito PROC NEAR
    push ax
    push dx
    add dl, '0'             ; valor -> caracter ASCII
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret
ImprimirDigito ENDP

END MAIN