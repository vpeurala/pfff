TOP=../..
##############################################################################
# Variables
##############################################################################
TARGET=lib

-include $(TOP)/Makefile.config

SRC= flag_parsing_cpp.ml \
     ast_cpp.ml \
     meta_ast_cpp.ml \
     export_ast_cpp.ml \
     visitor_cpp.ml lib_parsing_cpp.ml \
     type_cpp.ml \
     semantic_cpp.ml \
     lexer_parser_cpp.ml \
     parser_cpp.ml lexer_cpp.ml \
     parsing_stat_cpp.ml \
     token_helpers_cpp.ml \
     parsing_hacks.ml \
     parse_cpp.ml \
     test_parsing_cpp.ml \

# parser_php_mly_helper.ml \

#todo:  empty for now
SRC+=parsing_consistency.ml parsing_recovery.ml pp_analysis.ml \
  pp_ast.ml pp_token.ml token_cpp.ml token_views_cpp.ml

SYSLIBS= str.cma unix.cma 
LIBS=$(TOP)/commons/commons.cma \
   $(TOP)/h_program-lang/lib.cma
INCLUDEDIRS= \
 $(TOP)/commons $(TOP)/commons/lib-sexp $(TOP)/commons/lib-json \
  $(TOP)/h_program-lang

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


lexer_cpp.ml: lexer_cpp.mll
	$(OCAMLLEX) $<
clean::
	rm -f lexer_cpp.ml
beforedepend:: lexer_cpp.ml


parser_cpp.ml parser_cpp.mli: parser_cpp.mly
	$(OCAMLYACC) $<
clean::
	rm -f parser_cpp.ml parser_cpp.mli parser_cpp.output
beforedepend:: parser_cpp.ml parser_cpp.mli


visitor_cpp.cmo: visitor_cpp.ml
	$(OCAMLC) -w y -c $<

parsing_hacks.cmo: parsing_hacks.ml
	$(OCAMLC) -w -9 -c $<

##############################################################################
# Generic rules
##############################################################################

##############################################################################
# Literate Programming rules
##############################################################################

# set of noweb (.nw) files
SRCMLNW1=parse_php.mli.nw  ast_php.mli.nw visitor_php.mli.nw \
      sexp_ast_php.mli.nw json_ast_php.mli.nw \
      unparse_php.mli.nw \
      lib_parsing_php.mli.nw \
      flag_parsing_php.ml.nw test_parsing_php.mli.nw 

SRCMLNW2=ast_php.ml.nw #type_php.mli scope_php.mli
SRCMLNW3=lexer_php.mll.nw #token_helpers_php.mli
SRCMLNW4=parser_php.mly.nw #parser_php_mly_helper.ml
SRCMLNW5=parse_php.ml.nw
SRCMLNW6=lib_parsing_php.ml.nw \
      json_ast_php.ml.nw \
      type_php.ml.nw scope_php.ml.nw \
      test_parsing_php.ml.nw 

# must be in the same order of the #include for syncweb multi files support
# to work
SRCNW=Parsing_php.tex.nw Parsing_php_intro.tex.nw Parsing_php_use.tex.nw \
      $(SRCMLNW1) \
      Parsing_php_implem.tex.nw \
      $(SRCMLNW3) $(SRCMLNW4) $(SRCMLNW5) \
      unparse_php.ml.nw \
      ast_php.ml.nw \
      $(SRCMLNW6)


TEXMAIN=Parsing_php.tex.nw
TEX=Parsing_php.tex

# set of ml files, used by lpclean target
SRCML=$(SRCMLNW1) $(SRCMLNW2) $(SRCMLNW5) unparse_php.ml $(SRCMLNW6) 
LPSRC=$(SRCML:.nw=)
LPSRCOTHER=$(SRCMLNW3:.nw=) $(SRCMLNW4:.nw=) \
  token_helpers_php.mli parser_php_mly_helper.ml \
  type_php.mli scope_php.mli

sync:
	for i in $(LPSRC); do $(SYNCWEB) $(SRCNW) $$i || exit 1; done 
	$(SYNCWEB) -lang ocamlyacc $(SRCNW) parser_php.mly
	$(SYNCWEB) -lang ocaml $(SRCNW) lexer_php.mll
	$(SYNCWEB) -lang ocaml $(SRCNW) token_helpers_php.mli
	$(SYNCWEB) -lang ocaml $(SRCNW) parser_php_mly_helper.ml
	$(SYNCWEB) -lang ocaml $(SRCNW) type_php.mli
	$(SYNCWEB) -lang ocaml $(SRCNW) scope_php.mli

sync2:
	$(SYNCWEB) -lang ocaml $(SRCNW) show_function_calls1.ml
	$(SYNCWEB) -lang ocaml $(SRCNW) show_function_calls2.ml
	$(SYNCWEB) -lang ocaml $(SRCNW) show_function_calls3.ml
	$(SYNCWEB) -lang ocaml $(SRCNW) foo1.php
	$(SYNCWEB) -lang ocaml $(SRCNW) foo2.php
	$(SYNCWEB) -lang ocaml $(SRCNW) dumpDependencyTree.php

CMD=
compile2:
	ocamlc -I ../commons/ -I ../parsing_php/ \
	  unix.cma str.cma bigarray.cma nums.cma \
	  ../commons/commons.cma ../parsing_php/parsing_php.cma \
	  show_function_calls1.ml -o show_function_calls1
	ocamlc -I ../commons/ -I ../parsing_php/ \
	  unix.cma str.cma bigarray.cma nums.cma \
	  ../commons/commons.cma ../parsing_php/parsing_php.cma \
	  show_function_calls2.ml -o show_function_calls2
	ocamlc -I ../commons/ -I ../parsing_php/ \
	  unix.cma str.cma bigarray.cma nums.cma \
	  ../commons/commons.cma ../parsing_php/parsing_php.cma \
	  show_function_calls3.ml -o show_function_calls3


# have bugs in the past in generating ast_php.mli
sync3:
	$(SYNCWEB) -lang ocaml $(SRCNW) ast_php.mli

pdf:
	$(NOWEB) $(TEXMAIN) > $(TEX)
	pdflatex $(TEX)
#	pdflatex $(TEX)

lpclean::
	rm -f $(TEX) $(LPSRC) $(LPSRCOTHER) .md5sum_*


OCAMLDOC=ocamldoc $(INCLUDES)

SRCI=$(SRC:ml=mli)
NOSRCI=flag_parsing_php.mli lexer_php.mli parser_php.mli
NOSRCI+=test_parsing_php.mli token_helpers_php.mli
SRCILP=$(filter-out $(NOSRCI),$(SRCI))



