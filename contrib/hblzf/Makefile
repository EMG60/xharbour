#
# $Id: Makefile 9279 2011-02-14 18:06:32Z druzus $
#

ROOT = ../../

C_SOURCES = \
	core.c \
	lzf_c.c \
	lzf_d.c \

PRG_SOURCES= \

C_HEADERS=\

PRG_HEADERS=\
	hblzf.ch

LIBNAME=hblzf

include $(TOP)$(ROOT)config/header.cf
INSTALL_RULE_HEADERS := $(INSTALL_RULE)
include $(TOP)$(ROOT)config/lib.cf

install::
	$(INSTALL_RULE_HEADERS)
