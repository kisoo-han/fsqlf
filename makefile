PRJNAME=fsqlf

CFLAGS+=-std=c99
CFLAGS+=-Wall
CFLAGS+=-pedantic-errors
CFLAGS+=-g
CFLAGS+=-Iinclude

OS := $(shell uname -s)

ifdef ComSpec
	OS := Windows
endif

ifeq ($(OS), Windows)
	BLD=builds/windows
	OS_TARGET=windows
	EXEC_CLI=$(BLD)/fsqlf.exe
	CFLAGS+=-DBUILDING_LIBFSQLF
	CC=gcc
	LDFLAGS=-static
	FLEX=win_flex
else
	BLD=builds/linux
	OS_TARGET=linux
	PREFIX=/usr/local
	EXEC_CLI=$(BLD)/fsqlf
	CC=gcc
	CFLAGS+=-m32
	FLEX=flex
endif


.PHONY: build clean

FSQLF_CONF=$(BLD)/formatting.conf



build: $(EXEC_CLI) $(FSQLF_CONF)



#
# BUILD LIB
#
LCOBJ += $(BLD)/lib_fsqlf/conf_file/conf_file_create.o
LCOBJ += $(BLD)/lib_fsqlf/conf_file/conf_file_read.o
LCOBJ += $(BLD)/lib_fsqlf/formatter/lex_wrapper.o
LCOBJ += $(BLD)/lib_fsqlf/formatter/print_keywords.o
LCOBJ += $(BLD)/lib_fsqlf/formatter/tokque.o
LCOBJ += $(BLD)/lib_fsqlf/kw/kw.o
LCOBJ += $(BLD)/lib_fsqlf/kw/kwmap.o
LCOBJ += $(BLD)/lib_fsqlf/lex/token.o
LCOBJ += $(BLD)/utils/queue/queue.o
LCOBJ += $(BLD)/utils/stack/stack.o
LCOBJ += $(BLD)/utils/string/read_int.o
BLDDIRS += $(dir $(LCOBJ))

$(LCOBJ): $(BLD)/%.o: ./%.c | $(BLDDIRS)
	$(CC) -o $@ -c $< $(CFLAGS) -I$(BLD) -Ilib_fsqlf/formatter
$(BLD)/lex.yy.o: $(BLD)/lex.yy.c
	$(CC) -o $@ -c $< $(CFLAGS) -Ilib_fsqlf/formatter

$(filter lib_fsqlf/%,$(LCOBJ)): $(BLDP)%.o: ./%.c include/lib_fsqlf.h
	
$(BLD)/lex.yy.c: lib_fsqlf/formatter/fsqlf.lex lib_fsqlf/formatter/print_keywords.h
	$(FLEX) -o $(BLD)/lex.yy.c --header-file=$(BLD)/lex.yy.h $<

$(BLD)/lib_fsqlf/conf_file/conf_file_read.o: utils/string/read_int.h
$(BLD)/lib_fsqlf/formatter/lex_wrapper.o: $(BLD)/lex.yy.h
$(BLD)/lex.yy.h: $(BLD)/lex.yy.c

#
# BUILD CLI
#
COBJ += $(BLD)/cli/main.o
COBJ += $(BLD)/cli/cli.o
BLDDIRS += $(dir $(COBJ))

$(COBJ): $(BLD)/%.o: ./%.c include/lib_fsqlf.h | $(BLDDIRS)
	$(CC) -o $@ -c $< $(CFLAGS)   

ifeq ($(OS), Windows)
$(EXEC_CLI): $(COBJ) $(LCOBJ) $(BLD)/lex.yy.o
	$(CC) -o $@ $(CFLAGS) $(COBJ) $(LCOBJ) $(BLD)/lex.yy.o $(LDFLAGS)
else
$(EXEC_CLI): $(COBJ) $(LCOBJ) $(BLD)/lex.yy.o
	$(CC) -o $@ $(CFLAGS) $^
endif

$(FSQLF_CONF): $(EXEC_CLI)
	$(EXEC_CLI) --create-config-file $(FSQLF_CONF)

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
# $? - all prerequisites newer than target
# $| - order only prerequisites
#
# See also:
# http://www.gnu.org/software/make/manual/make.html#Automatic-Variables
