" Vim syntax file
" Language: ZIL (Zork Implementation Language)
" Maintainer: Converted from vscode-zil-language TextMate grammar
" URL: https://foss.heptapod.net/zilf/vscode-zil-language
" Last Change: 2026-01-08

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

" ZIL is case-insensitive
syn case ignore

" Comments - semicolon followed by any expression (typically string or form)
syn match zilComment /;.*$/ contains=zilCommentString
syn region zilCommentString start=/"/ skip=/\\./ end=/"/ contained

" Strings
syn region zilString start=/"/ skip=/\\./ end=/"/ contains=zilEscape
syn match zilEscape /\\./ contained

" Numbers
syn match zilNumber /-\?[0-9]\+\>/
syn match zilOctalNumber /\*[0-7]\+\*/
syn match zilBinaryNumber /#\s*0*2\s\+[01]\+/
syn match zilHexNumber /#\s*0*16\s\+[0-9a-fA-F]\+/

" Character literals
syn match zilCharacter /!\\\./

" Boolean constants
syn match zilBoolean /<\s*>/ " false
syn keyword zilBoolean T

" Control flow keywords (in forms)
syn keyword zilControl COND BIND PROG REPEAT DO MAPR MAPF
syn keyword zilControl MAP-CONTENTS MAP-DIRECTIONS
syn keyword zilControl AGAIN RETURN RTRUE RFALSE
syn keyword zilControl CATCH THROW EVAL AND OR NOT
syn keyword zilControl ELSE

" Arithmetic operators
syn keyword zilOperator MOD MIN MAX
syn match zilOperator /[+\-*/]/
syn keyword zilOperator OR? AND?

" Bitwise operators
syn keyword zilOperator BAND BOR ANDB ORB LSH XORB EQVB

" Comparison operators
syn match zilOperator /[=<>]\?=?/
syn match zilOperator /N==\?/
syn match zilOperator /[LG]=\?/
syn match zilOperator /[01TF]?/

" Output/IO keywords
syn keyword zilOutput TELL TELL-TOKENS ADD-TELL-TOKENS CRLF
syn keyword zilOutput PRINT PRINTI PRINTN PRINTR PRINC PRIN1

" Z-machine model keywords
syn keyword zilZModel FSET FSET? FCLEAR MOVE REMOVE IN? FIRST? NEXT?
syn keyword zilZModel PUTP GETP PROPDEF GETPT PTSIZE INTBL?
syn keyword zilZModel TABLE PTABLE LTABLE PLTABLE ITABLE
syn keyword zilZModel GET GETB GET/B PUT PUTB PUT/B ZGET ZPUT
syn keyword zilZModel VOC SYNONYM VERB-SYNONYM PREP-SYNONYM
syn keyword zilZModel ADJ-SYNONYM DIR-SYNONYM BIT-SYNONYM
syn keyword zilZModel DIRECTIONS BUZZ

" Meta/preprocessor keywords
syn keyword zilMeta INSERT-FILE PACKAGE ENDPACKAGE USE ENTRY RENTRY
syn keyword zilMeta VERSION COMPILATION-FLAG COMPILATION-FLAG-DEFAULT
syn keyword zilMeta REPLACE-DEFINITION DELAY-DEFINITION DEFAULT-DEFINITION
syn match zilMeta /IF-[A-Z0-9][A-Z0-9-]*/

" Definition keywords
syn keyword zilDefine DEFINE DEFINE20 DEFMAC ROUTINE FUNCTION

" Object/room definitions
syn keyword zilDefine OBJECT ROOM

" Global/constant definitions
syn keyword zilDefine SETG CONSTANT GLOBAL GASSIGNED? GUNASSIGN

" Local variable definitions
syn keyword zilDefine SET ASSIGNED? UNASSIGN

" Type keywords
syn keyword zilType CHTYPE TYPE TYPE? PRIMTYPE
syn keyword zilType NEWTYPE DEFSTRUCT APPLYTYPE EVALTYPE PRINTTYPE TYPEPRIM

" Syntax definition
syn keyword zilVocab SYNTAX

" Argument spec separators
syn match zilArgSep /"AUX"/
syn match zilArgSep /"EXTRA"/
syn match zilArgSep /"OPT"/
syn match zilArgSep /"OPTIONAL"/
syn match zilArgSep /"ARGS"/
syn match zilArgSep /"TUPLE"/
syn match zilArgSep /"NAME"/
syn match zilArgSep /"ACT"/
syn match zilArgSep /"BIND"/
syn match zilArgSep /"CALL"/

" Property names (common ones)
syn keyword zilProperty IN LOC DESC SYNONYM ADJECTIVE FLAGS
syn keyword zilProperty GLOBAL GENERIC ACTION DESCFCN CONTFCN
syn keyword zilProperty LDESC FDESC

" Direction properties
syn keyword zilDirection NORTH SOUTH EAST WEST UP DOWN OUT
syn keyword zilDirection NW SW NE SE

" Local variable reference (.name)
syn match zilLocalVar /\.[A-Za-z][A-Za-z0-9?-]*/

" Global variable reference (,name)
syn match zilGlobalVar /,[A-Za-z][A-Za-z0-9?-]*/

" Segment prefix
syn match zilSegment /!,/
syn match zilSegment /!\./
syn match zilSegment /!</

" Quote prefix
syn match zilQuote /'/

" Backquote/tilde (for macro templates)
syn match zilBackquote /`/
syn match zilTilde /\~/

" Macro evaluation prefix
syn match zilMacro /%/
syn match zilMacro /%%/

" Structure delimiters
syn match zilDelimiter /[()<>\[\]]/
syn match zilDelimiter /!\[/
syn match zilDelimiter /!\]/
syn match zilDelimiter /!(/
syn match zilDelimiter /!)/
syn match zilDelimiter /!>/

" Atoms (identifiers) - catch-all for unmatched words
syn match zilAtom /[A-Za-z?][A-Za-z0-9?-]*/

" Highlighting links
hi def link zilComment Comment
hi def link zilCommentString Comment
hi def link zilString String
hi def link zilEscape SpecialChar
hi def link zilNumber Number
hi def link zilOctalNumber Number
hi def link zilBinaryNumber Number
hi def link zilHexNumber Number
hi def link zilCharacter Character
hi def link zilBoolean Boolean

hi def link zilControl Conditional
hi def link zilOperator Operator
hi def link zilOutput Function
hi def link zilZModel Function
hi def link zilMeta PreProc
hi def link zilDefine Keyword
hi def link zilType Type
hi def link zilVocab Keyword
hi def link zilArgSep Special

hi def link zilProperty Identifier
hi def link zilDirection Constant

hi def link zilLocalVar Identifier
hi def link zilGlobalVar Identifier
hi def link zilSegment Special
hi def link zilQuote Special
hi def link zilBackquote Special
hi def link zilTilde Special
hi def link zilMacro PreProc
hi def link zilDelimiter Delimiter
hi def link zilAtom Normal

let b:current_syntax = "zil"

let &cpo = s:cpo_save
unlet s:cpo_save
