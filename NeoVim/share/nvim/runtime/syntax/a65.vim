" Vim syntax file
" Language:	xa 6502 cross assembler
" Maintainer:	Clemens Kirchgatterer <clemens@1541.org>
" Last Change:	2016 Aug 31

" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

syn case ignore

" Opcodes
syn match a65Opcode	"\<PHP\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<PLA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<PLX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<PLY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<SEC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<CLD\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<SED\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<CLI\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BVC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BVS\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BCS\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BCC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<DEY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<DEC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<CMP\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<CPX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BIT\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<ROL\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<ROR\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<ASL\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<TXA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<TYA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<TSX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<TXS\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<LDA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<LDX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<LDY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<STA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<PLP\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BRK\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<RTI\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<NOP\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<SEI\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<CLV\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<PHA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<PHX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BRA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<JMP\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<JSR\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<RTS\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<CPY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BNE\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BEQ\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BMI\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<LSR\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<INX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<INY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<INC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<ADC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<SBC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<AND\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<ORA\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<STX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<STY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<STZ\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<EOR\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<DEX\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BPL\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<CLC\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<PHY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<TRB\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BBR\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<BBS\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<RMB\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<SMB\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<TAY\($\|\s\)" nextgroup=a65Address
syn match a65Opcode	"\<TAX\($\|\s\)" nextgroup=a65Address

" Addresses
syn match a65Address	"\s*!\=$[0-9A-F]\{2}\($\|\s\)"
syn match a65Address	"\s*!\=$[0-9A-F]\{4}\($\|\s\)"
syn match a65Address	"\s*!\=$[0-9A-F]\{2},X\($\|\s\)"
syn match a65Address	"\s*!\=$[0-9A-F]\{4},X\($\|\s\)"
syn match a65Address	"\s*!\=$[0-9A-F]\{2},Y\($\|\s\)"
syn match a65Address	"\s*!\=$[0-9A-F]\{4},Y\($\|\s\)"
syn match a65Address	"\s*($[0-9A-F]\{2})\($\|\s\)"
syn match a65Address	"\s*($[0-9A-F]\{4})\($\|\s\)"
syn match a65Address	"\s*($[0-9A-F]\{2},X)\($\|\s\)"
syn match a65Address	"\s*($[0-9A-F]\{2}),Y\($\|\s\)"

" Numbers
syn match a65Number	"#\=[0-9]*\>"
syn match a65Number	"#\=$[0-9A-F]*\>"
syn match a65Number	"#\=&[0-7]*\>"
syn match a65Number	"#\=%[01]*\>"

syn case match

" Types
syn match a65Type	"\(^\|\s\)\.byt\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.word\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.asc\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.dsb\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.fopt\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.text\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.data\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.bss\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.zero\($\|\s\)"
syn match a65Type	"\(^\|\s\)\.align\($\|\s\)"

" Blocks
syn match a65Section	"\(^\|\s\)\.(\($\|\s\)"
syn match a65Section	"\(^\|\s\)\.)\($\|\s\)"

" Strings
syn match a65String	"\".*\""

" Program Counter
syn region a65PC	start="\*=" end="\>" keepend

" HI/LO Byte
syn region a65HiLo	start="#[<>]" end="$\|\s" contains=a65Comment keepend

" Comments
syn keyword a65Todo	TODO XXX FIXME BUG contained
syn match   a65Comment	";.*"hs=s+1 contains=a65Todo
syn region  a65Comment	start="/\*" end="\*/" contains=a65Todo,a65Comment

" Preprocessor
syn region a65PreProc	start="^#" end="$" contains=a65Comment,a65Continue
syn match  a65End			excludenl /end$/ contained
syn match  a65Continue	"\\$" contained

" Define the default highlighting.
" Only when an item doesn't have highlighting yet

hi def link a65Section	Special
hi def link a65Address	Special
hi def link a65Comment	Comment
hi def link a65PreProc	PreProc
hi def link a65Number	Number
hi def link a65String	String
hi def link a65Type	Statement
hi def link a65Opcode	Type
hi def link a65PC		Error
hi def link a65Todo	Todo
hi def link a65HiLo	Number


let b:current_syntax = "a65"
