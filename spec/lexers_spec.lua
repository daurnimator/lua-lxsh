describe("Unit tests for the lexers of the LXSH module", function()
	local lxsh = require 'lxsh'

	-- Check that token stream returned by lexer matches expected output.
	local function check_tokens(iterator, values)
		local i = 0
		for kind, text in iterator do
			i = i + 1
			assert.same(values[i][1], kind)
			assert.same(values[i][2], text)
		end
		assert.same(i, #values)
	end

	it("lxsh.sync() works", function()
		local l, c = lxsh.sync('')
		assert(l == 1 and c == 1)

		local l, c = lxsh.sync(' ')
		assert(l == 1 and c == 2)

		local l, c = lxsh.sync('\n')
		assert(l == 2 and c == 1)

		local l, c = lxsh.sync(' \n \n \n ')
		assert(l == 4 and c == 2)

		local l, c = lxsh.sync(' ', 13, 42)
		assert(l == 13 and c == 43)

		local l, c = lxsh.sync('\n', 13, 42)
		assert(l == 14 and c == 1)
	end)

	describe("Lua lexer", function()
		it("lexs whitespace characters", function()
			check_tokens(lxsh.lexers.lua.gmatch '\r\n\f\t\v ', {
				{ 'whitespace', '\r\n\f\t\v ' },
			})
		end)

		it("lexs constants (true, false and nil)", function()
			check_tokens(lxsh.lexers.lua.gmatch 'true false nil', {
				{ 'constant', 'true' },
				{ 'whitespace', ' ' },
				{ 'constant', 'false' },
				{ 'whitespace', ' ' },
				{ 'constant', 'nil' },
			})
		end)

		it("lexs interactive prompt", function()
			check_tokens(lxsh.lexers.lua.gmatch [[
Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
> print "Hello world!"]], {
				{ 'prompt', 'Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio' },
				{ 'whitespace', '\n' },
				{ 'prompt', '>' },
				{ 'whitespace', ' ' },
				{ 'identifier', 'print' },
				{ 'whitespace', ' ' },
				{ 'string', '"Hello world!"' },
			})
		end)

		it("lexs numbers", function()
			check_tokens(lxsh.lexers.lua.gmatch '1 3.14 1. .1 0x0123456789ABCDEF 1e5 0xA23p-4 0X1.921FB54442D18P+1', {
				{ 'number', '1' },
				{ 'whitespace', ' ' },
				{ 'number', '3.14' },
				{ 'whitespace', ' ' },
				{ 'number', '1.' },
				{ 'whitespace', ' ' },
				{ 'number', '.1' },
				{ 'whitespace', ' ' },
				{ 'number', '0x0123456789ABCDEF' },
				{ 'whitespace', ' ' },
				{ 'number', '1e5' },
				{ 'whitespace', ' ' },
				{ 'number', '0xA23p-4' },
				{ 'whitespace', ' ' },
				{ 'number', '0X1.921FB54442D18P+1' },
			})
		end)

		it("String literals", function()
			check_tokens(lxsh.lexers.lua.gmatch [==[
'single quoted string'
"double quoted string"
[[long string]]
[[multi line
long string]]
[=[nested [[long]] string]=]
]==], {
				{ 'string', "'single quoted string'" },
				{ 'whitespace', '\n' },
				{ 'string', '"double quoted string"' },
				{ 'whitespace', '\n' },
				{ 'string', '[[long string]]' },
				{ 'whitespace', '\n' },
				{ 'string', '[[multi line\nlong string]]' },
				{ 'whitespace', '\n' },
				{ 'string', '[=[nested [[long]] string]=]' },
				{ 'whitespace', '\n' },
			})
		end)

		it("Comments", function()
			check_tokens(lxsh.lexers.lua.gmatch [==[
#!shebang line
-- single line comment
--[=[
long
comment
]=]
--[[
nested
--[=[long]=]
comment
]]
]==], {
				{ 'comment', '#!shebang line\n' },
				{ 'comment', '-- single line comment\n' },
				{ 'comment', '--[=[\nlong\ncomment\n]=]' },
				{ 'whitespace', '\n' },
				{ 'comment', '--[[\nnested\n--[=[long]=]\ncomment\n]]' },
				{ 'whitespace', '\n' },
			})
		end)

		it("Operators", function()
			local operators = 'not ... and .. ~= == >= <= or ] { = > ^ [ < ; ) * ( % } + - : , / . #'
			check_tokens(lxsh.lexers.lua.gmatch(operators), {
				{ 'operator', 'not' },
				{ 'whitespace', ' ' },
				{ 'operator', '...' },
				{ 'whitespace', ' ' },
				{ 'operator', 'and' },
				{ 'whitespace', ' ' },
				{ 'operator', '..' },
				{ 'whitespace', ' ' },
				{ 'operator', '~=' },
				{ 'whitespace', ' ' },
				{ 'operator', '==' },
				{ 'whitespace', ' ' },
				{ 'operator', '>=' },
				{ 'whitespace', ' ' },
				{ 'operator', '<=' },
				{ 'whitespace', ' ' },
				{ 'operator', 'or' },
				{ 'whitespace', ' ' },
				{ 'operator', ']' },
				{ 'whitespace', ' ' },
				{ 'operator', '{' },
				{ 'whitespace', ' ' },
				{ 'operator', '=' },
				{ 'whitespace', ' ' },
				{ 'operator', '>' },
				{ 'whitespace', ' ' },
				{ 'operator', '^' },
				{ 'whitespace', ' ' },
				{ 'operator', '[' },
				{ 'whitespace', ' ' },
				{ 'operator', '<' },
				{ 'whitespace', ' ' },
				{ 'operator', ';' },
				{ 'whitespace', ' ' },
				{ 'operator', ')' },
				{ 'whitespace', ' ' },
				{ 'operator', '*' },
				{ 'whitespace', ' ' },
				{ 'operator', '(' },
				{ 'whitespace', ' ' },
				{ 'operator', '%' },
				{ 'whitespace', ' ' },
				{ 'operator', '}' },
				{ 'whitespace', ' ' },
				{ 'operator', '+' },
				{ 'whitespace', ' ' },
				{ 'operator', '-' },
				{ 'whitespace', ' ' },
				{ 'operator', ':' },
				{ 'whitespace', ' ' },
				{ 'operator', ',' },
				{ 'whitespace', ' ' },
				{ 'operator', '/' },
				{ 'whitespace', ' ' },
				{ 'operator', '.' },
				{ 'whitespace', ' ' },
				{ 'operator', '#' },
			})
		end)

		it("Keywords", function()
			local keywords = 'break do else elseif end for function goto if in local repeat return then until while'
			check_tokens(lxsh.lexers.lua.gmatch(keywords), {
				{ 'keyword', 'break' }, { 'whitespace', ' ' },
				{ 'keyword', 'do' }, { 'whitespace', ' ' },
				{ 'keyword', 'else' }, { 'whitespace', ' ' },
				{ 'keyword', 'elseif' }, { 'whitespace', ' ' },
				{ 'keyword', 'end' }, { 'whitespace', ' ' },
				{ 'keyword', 'for' }, { 'whitespace', ' ' },
				{ 'keyword', 'function' }, { 'whitespace', ' ' },
				{ 'keyword', 'goto' }, { 'whitespace', ' ' },
				{ 'keyword', 'if' }, { 'whitespace', ' ' },
				{ 'keyword', 'in' }, { 'whitespace', ' ' },
				{ 'keyword', 'local' }, { 'whitespace', ' ' },
				{ 'keyword', 'repeat' }, { 'whitespace', ' ' },
				{ 'keyword', 'return' }, { 'whitespace', ' ' },
				{ 'keyword', 'then' }, { 'whitespace', ' ' },
				{ 'keyword', 'until' }, { 'whitespace', ' ' },
				{ 'keyword', 'while' },
			})
		end)

		it("Identifiers", function()
			check_tokens(lxsh.lexers.lua.gmatch('io.write'), {
				{ 'identifier', 'io' },
				{ 'operator', '.' },
				{ 'identifier', 'write' },
			})
			check_tokens(lxsh.lexers.lua.gmatch('io.write', {join_identifiers=true}), {
				{ 'identifier', 'io.write' },
			})
		end)
	end)

	describe("C lexer", function()
		it("Whitespace characters", function()
			check_tokens(lxsh.lexers.c.gmatch '\r\n\f\t\v ', {
				{ 'whitespace', '\r\n\f\t\v ' },
			})
		end)

		it("Identifiers", function()
			check_tokens(lxsh.lexers.c.gmatch 'variable=value', {
				{ 'identifier', 'variable' },
				{ 'operator', '=' },
				{ 'identifier', 'value' },
			})
		end)

		it("Preprocessor instructions", function()
			check_tokens(lxsh.lexers.c.gmatch [[
#if
#else
#endif
#define foo bar
#define \
  foo \
  bar
]], {
				{ 'preprocessor', '#if\n' },
				{ 'preprocessor', '#else\n' },
				{ 'preprocessor', '#endif\n' },
				{ 'preprocessor', '#define foo bar\n' },
				{ 'preprocessor', '#define \\\n  foo \\\n  bar\n' },
			})
		end)

		it("Character and string literals", function()
			check_tokens(lxsh.lexers.c.gmatch [[
'c'
'\n'
'\000'
'\xFF'
"string literal"
"multi line\
string literal"
]], {
				{ 'character', "'c'" },
				{ 'whitespace', '\n' },
				{ 'character', "'\\n'" },
				{ 'whitespace', '\n' },
				{ 'character', "'\\000'" },
				{ 'whitespace', '\n' },
				{ 'character', "'\\xFF'" },
				{ 'whitespace', '\n' },
				{ 'string', '"string literal"' },
				{ 'whitespace', '\n' },
				{ 'string', '"multi line\\\nstring literal"' },
				{ 'whitespace', '\n' },
			})
		end)

		it("Comments", function()
			check_tokens(lxsh.lexers.c.gmatch [[
// single line comment
/* multi
   line
   comment */
]], {
				{ 'comment', '// single line comment\n' },
				{ 'comment', '/* multi\n   line\n   comment */' },
				{ 'whitespace', '\n' },
			})
		end)

		it("Operators", function()
			check_tokens(lxsh.lexers.c.gmatch [[
>>=
<<=
--
>>
>=
/=
==
<=
+=
<<
*=
++
&&
|=
||
!=
&=
-=
^=
%=
->
,
)
*
%
+
&
(
-
~
/
^
]
{
}
|
.
[
>
!
?
:
=
<
;
]], {
			{ 'operator', '>>=' },
			{ 'whitespace', '\n' },
			{ 'operator', '<<=' },
			{ 'whitespace', '\n' },
			{ 'operator', '--' },
			{ 'whitespace', '\n' },
			{ 'operator', '>>' },
			{ 'whitespace', '\n' },
			{ 'operator', '>=' },
			{ 'whitespace', '\n' },
			{ 'operator', '/=' },
			{ 'whitespace', '\n' },
			{ 'operator', '==' },
			{ 'whitespace', '\n' },
			{ 'operator', '<=' },
			{ 'whitespace', '\n' },
			{ 'operator', '+=' },
			{ 'whitespace', '\n' },
			{ 'operator', '<<' },
			{ 'whitespace', '\n' },
			{ 'operator', '*=' },
			{ 'whitespace', '\n' },
			{ 'operator', '++' },
			{ 'whitespace', '\n' },
			{ 'operator', '&&' },
			{ 'whitespace', '\n' },
			{ 'operator', '|=' },
			{ 'whitespace', '\n' },
			{ 'operator', '||' },
			{ 'whitespace', '\n' },
			{ 'operator', '!=' },
			{ 'whitespace', '\n' },
			{ 'operator', '&=' },
			{ 'whitespace', '\n' },
			{ 'operator', '-=' },
			{ 'whitespace', '\n' },
			{ 'operator', '^=' },
			{ 'whitespace', '\n' },
			{ 'operator', '%=' },
			{ 'whitespace', '\n' },
			{ 'operator', '->' },
			{ 'whitespace', '\n' },
			{ 'operator', ',' },
			{ 'whitespace', '\n' },
			{ 'operator', ')' },
			{ 'whitespace', '\n' },
			{ 'operator', '*' },
			{ 'whitespace', '\n' },
			{ 'operator', '%' },
			{ 'whitespace', '\n' },
			{ 'operator', '+' },
			{ 'whitespace', '\n' },
			{ 'operator', '&' },
			{ 'whitespace', '\n' },
			{ 'operator', '(' },
			{ 'whitespace', '\n' },
			{ 'operator', '-' },
			{ 'whitespace', '\n' },
			{ 'operator', '~' },
			{ 'whitespace', '\n' },
			{ 'operator', '/' },
			{ 'whitespace', '\n' },
			{ 'operator', '^' },
			{ 'whitespace', '\n' },
			{ 'operator', ']' },
			{ 'whitespace', '\n' },
			{ 'operator', '{' },
			{ 'whitespace', '\n' },
			{ 'operator', '}' },
			{ 'whitespace', '\n' },
			{ 'operator', '|' },
			{ 'whitespace', '\n' },
			{ 'operator', '.' },
			{ 'whitespace', '\n' },
			{ 'operator', '[' },
			{ 'whitespace', '\n' },
			{ 'operator', '>' },
			{ 'whitespace', '\n' },
			{ 'operator', '!' },
			{ 'whitespace', '\n' },
			{ 'operator', '?' },
			{ 'whitespace', '\n' },
			{ 'operator', ':' },
			{ 'whitespace', '\n' },
			{ 'operator', '=' },
			{ 'whitespace', '\n' },
			{ 'operator', '<' },
			{ 'whitespace', '\n' },
			{ 'operator', ';' },
			{ 'whitespace', '\n' },
		})
		end)

		it("Numbers", function()
			check_tokens(lxsh.lexers.c.gmatch [[
0x0123456789ABCDEFabcdef
123456789
01234567
0x1l
500LL
1.0
1.
.1
1f
]], {
				{ 'number', '0x0123456789ABCDEFabcdef' },
				{ 'whitespace', '\n' },
				{ 'number', '123456789' },
				{ 'whitespace', '\n' },
				{ 'number', '01234567' },
				{ 'whitespace', '\n' },
				{ 'number', '0x1l' },
				{ 'whitespace', '\n' },
				{ 'number', '500LL' },
				{ 'whitespace', '\n' },
				{ 'number', '1.0' },
				{ 'whitespace', '\n' },
				{ 'number', '1.' },
				{ 'whitespace', '\n' },
				{ 'number', '.1' },
				{ 'whitespace', '\n' },
				{ 'number', '1f' },
				{ 'whitespace', '\n' },
			})
		end)

		it("Keywords", function()
			check_tokens(lxsh.lexers.c.gmatch [[
auto
break
case
char
const
continue
default
do
double
else
enum
extern
float
for
goto
if
int
long
register
return
short
signed
sizeof
static
struct
switch
typedef
union
unsigned
void
volatile
while
]], {
				{ 'keyword', 'auto' }, { 'whitespace', '\n' },
				{ 'keyword', 'break' }, { 'whitespace', '\n' },
				{ 'keyword', 'case' }, { 'whitespace', '\n' },
				{ 'keyword', 'char' }, { 'whitespace', '\n' },
				{ 'keyword', 'const' }, { 'whitespace', '\n' },
				{ 'keyword', 'continue' }, { 'whitespace', '\n' },
				{ 'keyword', 'default' }, { 'whitespace', '\n' },
				{ 'keyword', 'do' }, { 'whitespace', '\n' },
				{ 'keyword', 'double' }, { 'whitespace', '\n' },
				{ 'keyword', 'else' }, { 'whitespace', '\n' },
				{ 'keyword', 'enum' }, { 'whitespace', '\n' },
				{ 'keyword', 'extern' }, { 'whitespace', '\n' },
				{ 'keyword', 'float' }, { 'whitespace', '\n' },
				{ 'keyword', 'for' }, { 'whitespace', '\n' },
				{ 'keyword', 'goto' }, { 'whitespace', '\n' },
				{ 'keyword', 'if' }, { 'whitespace', '\n' },
				{ 'keyword', 'int' }, { 'whitespace', '\n' },
				{ 'keyword', 'long' }, { 'whitespace', '\n' },
				{ 'keyword', 'register' }, { 'whitespace', '\n' },
				{ 'keyword', 'return' }, { 'whitespace', '\n' },
				{ 'keyword', 'short' }, { 'whitespace', '\n' },
				{ 'keyword', 'signed' }, { 'whitespace', '\n' },
				{ 'keyword', 'sizeof' }, { 'whitespace', '\n' },
				{ 'keyword', 'static' }, { 'whitespace', '\n' },
				{ 'keyword', 'struct' }, { 'whitespace', '\n' },
				{ 'keyword', 'switch' }, { 'whitespace', '\n' },
				{ 'keyword', 'typedef' }, { 'whitespace', '\n' },
				{ 'keyword', 'union' }, { 'whitespace', '\n' },
				{ 'keyword', 'unsigned' }, { 'whitespace', '\n' },
				{ 'keyword', 'void' }, { 'whitespace', '\n' },
				{ 'keyword', 'volatile' }, { 'whitespace', '\n' },
				{ 'keyword', 'while' }, { 'whitespace', '\n' },
			})
		end)
	end)
	describe("Tests for the BibTeX lexer", function()
		it("lexes", function()
			check_tokens(lxsh.lexers.bib.gmatch [[
@Book{abramowitz+stegun,
 author    = "Milton {Abramowitz} and Irene A. {Stegun}",
 title     = "Handbook of Mathematical Functions with
              Formulas, Graphs, and Mathematical Tables",
 publisher = "Dover",
 year      =  1964,
 address   = "New York",
 edition   = "ninth Dover printing, tenth GPO printing"
}
]], {
				{ "entry", "@Book" },
				{ "delimiter", "{" },
				{ "identifier", "abramowitz" },
				{ "error", "+" },
				{ "identifier", "stegun" },
				{ "delimiter", "," },
				{ "whitespace", "\n " },
				{ "field", "author" },
				{ "whitespace", "    " },
				{ "operator", "=" },
				{ "whitespace", " " },
				{ "string", "\"Milton {Abramowitz} and Irene A. {Stegun}\"" },
				{ "delimiter", "," },
				{ "whitespace", "\n " },
				{ "field", "title" },
				{ "whitespace", "     " },
				{ "operator", "=" },
				{ "whitespace", " " },
				{ "string", "\"Handbook of Mathematical Functions with\n              Formulas, Graphs, and Mathematical Tables\"" },
				{ "delimiter", "," },
				{ "whitespace", "\n " },
				{ "field", "publisher" },
				{ "whitespace", " " },
				{ "operator", "=" },
				{ "whitespace", " " },
				{ "string", "\"Dover\"" },
				{ "delimiter", "," },
				{ "whitespace", "\n " },
				{ "field", "year" },
				{ "whitespace", "      " },
				{ "operator", "=" },
				{ "whitespace", "  " },
				{ "number", "1964" },
				{ "delimiter", "," },
				{ "whitespace", "\n " },
				{ "field", "address" },
				{ "whitespace", "   " },
				{ "operator", "=" },
				{ "whitespace", " " },
				{ "string", "\"New York\"" },
				{ "delimiter", "," },
				{ "whitespace", "\n " },
				{ "field", "edition" },
				{ "whitespace", "   " },
				{ "operator", "=" },
				{ "whitespace", " " },
				{ "string", "\"ninth Dover printing, tenth GPO printing\"" },
				{ "whitespace", "\n" },
				{ "delimiter", "}" },
				{ "whitespace", "\n" },
			})
		end)
	end)
end)
