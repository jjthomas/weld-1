OS=$(shell uname -s)
LLVM_VERSION=3.5

ifeq (${OS}, Darwin)
	# OS X
	CLANG ?= /usr/local/opt/llvm$(LLVM_VERSION:.)/bin/clang
	CLANGPP ?= /usr/local/opt/llvm$(LLVM_VERSION:.)/bin/clang++
	FLAGS=-march=native -O3 -flto
else ifeq (${OS}, Linux)
	# Linux
	CLANG ?= /usr/bin/clang-${LLVM_VERSION}
	CLANGPP ?= /usr/bin/clang++-${LLVM_VERSION}
	FLAGS=-march=native -O3 -flto -fuse-ld=gold
else
	$(error Unsupported platform: ${OS})
endif

all:
	$(CLANG) bench.cpp benchtest.cpp -o benchtests

clean:
	rm -f benchtests *.benchmark
