.PHONY: assembler link build

assembler:
	@as src/* -o build/ajazz.o

link:
	@gcc build/* -o bin -nostdlib -static &&\
		rm build/*

build: assembler link
