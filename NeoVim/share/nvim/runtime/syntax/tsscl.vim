" Vim syntax file
" Language:     TSS (Thermal Synthesizer System) Command Line
" Maintainer:   Adrian Nagle, anagle@ball.com
" Last Change:  2003 May 11
" Filenames:    *.tsscl
" URL:		http://www.naglenet.org/vim/syntax/tsscl.vim
" MAIN URL:     http://www.naglenet.org/vim/



" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif



" Ignore case
syn case ignore



"
"
" Begin syntax definitions for tss geometry file.
"

" Load TSS geometry syntax file
"source $VIM/myvim/tssgm.vim
"source $VIMRUNTIME/syntax/c.vim

" Define keywords for TSS
syn keyword tssclCommand  begin radk list heatrates attr draw

syn keyword tssclKeyword   cells rays error nodes levels objects cpu
syn keyword tssclKeyword   units length positions energy time unit solar
syn keyword tssclKeyword   solar_constant albedo planet_power

syn keyword tssclEnd    exit

syn keyword tssclUnits  cm feet meters inches
syn keyword tssclUnits  Celsius Kelvin Fahrenheit Rankine



" Define matches for TSS
syn match  tssclString    /"[^"]\+"/ contains=ALLBUT,tssInteger,tssclKeyword,tssclCommand,tssclEnd,tssclUnits

syn match  tssclComment     "#.*$"

"  rational and logical operators
"  <       Less than
"  >       Greater than
"  <=      Less than or equal
"  >=      Greater than or equal
"  == or = Equal to
"  !=      Not equal to
"  && or & Logical AND
"  || or | Logical OR
"  !       Logical NOT
"
" algebraic operators:
"  ^ or ** Exponentation
"  *       Multiplication
"  /       Division
"  %       Remainder
"  +       Addition
"  -       Subtraction
"
syn match  tssclOper      "||\||\|&&\|&\|!=\|!\|>=\|<=\|>\|<\|+\|-\|^\|\*\*\|\*\|/\|%\|==\|=\|\." skipwhite

" CLI Directive Commands, with arguments
"
" BASIC COMMAND LIST
" *ADD input_source
" *ARITHMETIC { [ON] | OFF }
" *CLOSE unit_number
" *CPU
" *DEFINE
" *ECHO[/qualifiers] { [ON] | OFF }
" *ELSE [IF { 0 | 1 } ]
" *END { IF | WHILE }
" *EXIT
" *IF { 0 | 1 }
" *LIST/n list variable
" *OPEN[/r | /r+ | /w | /w+ ] unit_number file_name
" *PROMPT prompt_string sybol_name
" *READ/unit=unit_number[/LOCAL | /GLOBAL ] sym1 [sym2, [sym3 ...]]
" *REWIND
" *STOP
" *STRCMP string_1 string_2 difference
" *SYSTEM command
" *UNDEFINE[/LOCAL][/GLOBAL] symbol_name
" *WHILE { 0 | 1 }
" *WRITE[/unit=unit_number] output text
"
syn match  tssclDirective "\*ADD"
syn match  tssclDirective "\*ARITHMETIC \+\(ON\|OFF\)"
syn match  tssclDirective "\*CLOSE"
syn match  tssclDirective "\*CPU"
syn match  tssclDirective "\*DEFINE"
syn match  tssclDirective "\*ECHO"
syn match  tssclConditional "\*ELSE"
syn match  tssclConditional "\*END \+\(IF\|WHILE\)"
syn match  tssclDirective "\*EXIT"
syn match  tssclConditional "\*IF"
syn match  tssclDirective "\*LIST"
syn match  tssclDirective "\*OPEN"
syn match  tssclDirective "\*PROMPT"
syn match  tssclDirective "\*READ"
syn match  tssclDirective "\*REWIND"
syn match  tssclDirective "\*STOP"
syn match  tssclDirective "\*STRCMP"
syn match  tssclDirective "\*SYSTEM"
syn match  tssclDirective "\*UNDEFINE"
syn match  tssclConditional "\*WHILE"
syn match  tssclDirective "\*WRITE"

syn match  tssclContChar  "-$"

" C library functoins
" Bessel functions (jn, yn)
" Error and complementary error fuctions (erf, erfc)
" Exponential functions (exp)
" Logrithm (log, log10)
" Power (pow)
" Square root (sqrt)
" Floor (floor)
" Ceiling (ceil)
" Floating point remainder (fmod)
" Floating point absolute value (fabs)
" Gamma (gamma)
" Euclidean distance function (hypot)
" Hperbolic functions (sinh, cosh, tanh)
" Trigometric functions in radians (sin, cos, tan, asin, acos, atan, atan2)
" Trigometric functions in degrees (sind, cosd, tand, asind, acosd, atand,
"    atan2d)
"
" local varialbles: cl_arg1, cl_arg2, etc. (cl_arg is an array of arguments)
" cl_args is the number of arguments
"
"
" I/O: *PROMPT, *WRITE, *READ
"
" Conditional branching:
" IF, ELSE IF, END
" *IF value       *IF I==10
" *ELSE IF value  *ELSE IF I<10
" *ELSE		  *ELSE
" *ENDIF	  *ENDIF
"
"
" Iterative looping:
" WHILE
" *WHILE test
" .....
" *END WHILE
"
"
" EXAMPLE:
" *DEFINE I = 1
" *WHILE (I <= 10)
"    *WRITE I = 'I'
"    *DEFINE I = (I + 1)
" *END WHILE
"

syn match  tssclQualifier "/[^/ ]\+"hs=s+1
syn match  tssclSymbol    "'\S\+'"
"syn match  tssclSymbol2   " \S\+ " contained

syn match  tssclInteger     "-\=\<[0-9]*\>"
syn match  tssclFloat       "-\=\<[0-9]*\.[0-9]*"
syn match  tssclScientific  "-\=\<[0-9]*\.[0-9]*E[-+]\=[0-9]\+\>"



" Define the default highlighting
" Only when an item doesn't have highlighting yet

hi def link tssclCommand		Statement
hi def link tssclKeyword		Special
hi def link tssclEnd		Macro
hi def link tssclUnits		Special

hi def link tssclComment		Comment
hi def link tssclDirective		Statement
hi def link tssclConditional	Conditional
hi def link tssclContChar		Macro
hi def link tssclQualifier		Typedef
hi def link tssclSymbol		Identifier
hi def link tssclSymbol2		Symbol
hi def link tssclString		String
hi def link tssclOper		Operator

hi def link tssclInteger		Number
hi def link tssclFloat		Number
hi def link tssclScientific	Number



let b:current_syntax = "tsscl"

" vim: ts=8 sw=2
