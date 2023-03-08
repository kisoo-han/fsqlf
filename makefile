PRJNAME=fsqlf

CFLAGS+=-std=c99
CFLAGS+=-Wall
CFLAGS+=-static
CFLAGS+=-pedantic-errors

BLD=builds
OS_TARGET=linux
PREFIX=/usr/local
EXEC_CLI=$(BLD)/fsqlf
CC=gcc
CXX=g++

.PHONY: all  clean  

all: $(EXEC_CLI)

#
# BUILD CLI
#
COBJ += $(BLD)/cli/main.o
COBJ += $(BLD)/cli/cli.o
COBJ += $(BLD)/lib_fsqlf/conf_file/conf_file_create.o
COBJ += $(BLD)/lib_fsqlf/conf_file/conf_file_read.o
COBJ += $(BLD)/cli/debuging.o
COBJ += $(BLD)/lib_fsqlf/formatter/globals.o
COBJ += $(BLD)/lib_fsqlf/formatter/lex.yy.o
COBJ += $(BLD)/lib_fsqlf/formatter/print_keywords.o
COBJ += $(BLD)/lib_fsqlf/kw/kw.o
COBJ += $(BLD)/lib_fsqlf/kw/kwall_init.o
COBJ += $(BLD)/utils/stack/stack.o
COBJ += $(BLD)/utils/string/read_int.o
BLDDIRS += $(dir $(COBJ))

$(COBJ): $(BLD)/%.o: %.c | $(BLDDIRS)
	$(CC) $(CFLAGS)  -c $<  -o $@

lib_fsqlf/conf_file/conf_file_create.o: lib_fsqlf/conf_file/conf_file_constants.h
lib_fsqlf/conf_file/conf_file_read.o: lib_fsqlf/conf_file/conf_file_constants.h utils/string/read_int.h
lib_fsqlf/main.o: lib_fsqlf/formatter/lex.yy.h

$(EXEC_CLI): $(COBJ)
	$(CC) $(CFLAGS)  $^   -o $@ -L$(BLD)
	strip $@

lib_fsqlf/formatter/lex.yy.h: lib_fsqlf/formatter/lex.yy.c
lib_fsqlf/formatter/lex.yy.c: lib_fsqlf/formatter/fsqlf.lex lib_fsqlf/formatter/globals.h lib_fsqlf/formatter/print_keywords.h
	# flex options (e.g. `-o`) has to be before input file
	flex  -o $@ --header-file=lib_fsqlf/formatter/lex.yy.h $<


#
# OUT OF SOURCE BUILD FOLDERS
#
$(sort $(BLDDIRS)):
	mkdir -p $@


#
#  CLEANUP
#
clean:
	rm -f -R builds/


# makefile reference
# $@ - target
# $+ - all prerequisites
# $^ - all prerequisites, but list each name only once
# $< - first prerequisite
# $? - all prerequisites newer then target
# $| - order only prerequisites
#
# See also:
# http://www.gnu.org/software/make/manual/make.html#Automatic-Variables
