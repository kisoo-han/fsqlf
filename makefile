PRJNAME=fsqlf

CFLAGS+=-std=c99
CFLAGS+=-Wall
CFLAGS+=-pedantic-errors
CFLAGS+=-g
CFLAGS+=-Iinclude

ifeq ($(OS),WIN)
	BLD=builds/windows
	OS_TARGET=windows
	EXEC_CLI=$(BLD)/fsqlf.exe
	CFLAGS+=-DBUILDING_LIBFSQLF
	CC=i686-w64-mingw32-gcc
	LIBNAME=$(BLD)/libfsqlf.dll
	LIBNAME2=$(BLD)/libfsqlf.lib
	LIBFLAGS=-shared -Wl,--out-implib,$(LIBNAME2)
else
	BLD=builds/linux
	OS_TARGET=linux
	PREFIX=/usr/local
	EXEC_CLI=$(BLD)/fsqlf
	CC=gcc
	CFLAGS+=-m32
	LIBNAME=$(BLD)/libfsqlf.so
	LIBFLAGS=-shared
endif


.PHONY: build clean



build: $(EXEC_CLI)



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

$(LIBNAME): $(LCOBJ) $(BLD)/lex.yy.o
	$(CC) -o $@ $^ $(CFLAGS) $(LIBFLAGS)

$(BLD)/lib_fsqlf/conf_file/conf_file_read.o: utils/string/read_int.h
$(BLD)/lib_fsqlf/formatter/lex_wrapper.o: $(BLD)/lex.yy.h
$(BLD)/lex.yy.h: $(BLD)/lex.yy.c
$(BLD)/lex.yy.c: lib_fsqlf/formatter/fsqlf.lex lib_fsqlf/formatter/print_keywords.h
	# flex options (e.g. `-o`) has to be before input file
	flex -o $@ --header-file=$(BLD)/lex.yy.h $<


#
# BUILD CLI
#
COBJ += $(BLD)/cli/main.o
COBJ += $(BLD)/cli/cli.o
BLDDIRS += $(dir $(COBJ))

$(COBJ): $(BLD)/%.o: ./%.c include/lib_fsqlf.h | $(BLDDIRS)
	$(CC) -o $@ -c $< $(CFLAGS)   

INTUTIL = $(BLD)/utils/string/read_int.o
$(EXEC_CLI): $(COBJ) $(INTUTIL) $(LIBNAME)
	$(CC) -o $@ $(CFLAGS) $(COBJ) $(INTUTIL) -L$(BLD) -lfsqlf -Wl,-rpath,.

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
