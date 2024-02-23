AS=as
LD=ld

all:
	$(AS) -g base64.s -o base64.o
	$(AS) -g base64_lib.s -o base64_lib.o
	$(LD) -g base64.o base64_lib.o -o base64

clean:
	rm base64 base64.o base64_lib.o
