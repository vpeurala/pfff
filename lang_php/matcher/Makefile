TOP=../..
##############################################################################
# Variables
##############################################################################
TARGET=lib

SRC= flag_matcher_php.ml   \
     metavars_php.ml \
     php_vs_php.ml \
     matching_php.ml \
     transforming_php.ml \
     sgrep_php.ml \
     spatch_php.ml \
     unit_matcher_php.ml \

SYSLIBS= str.cma unix.cma
LIBS=$(TOP)/commons/commons.cma \
     $(TOP)/h_program-lang/lib.cma \
     ../parsing/lib.cma \

INCLUDEDIRS= $(TOP)/commons $(TOP)/commons/ocollection \
   $(TOP)/commons/ocamlextra \
   $(TOP)/h_program-lang $(TOP)/h_version-control  \
   $(TOP)/globals \
   ../parsing

##############################################################################
# Generic variables
##############################################################################
-include $(TOP)/Makefile.common

##############################################################################
# Top rules
##############################################################################
all:: $(TARGET).cma
all.opt:: $(TARGET).cmxa

$(TARGET).cma: $(OBJS)
	$(OCAMLC) -a -o $(TARGET).cma $(OBJS)

$(TARGET).cmxa: $(OPTOBJS) $(LIBS:.cma=.cmxa)
	$(OCAMLOPT) -a -o $(TARGET).cmxa $(OPTOBJS)

$(TARGET).top: $(OBJS) $(LIBS)
	$(OCAMLMKTOP) -o $(TARGET).top $(SYSLIBS) $(LIBS) $(OBJS)

clean::
	rm -f $(TARGET).top


##############################################################################
# Literate Programming rules
##############################################################################
