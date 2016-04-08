--[[

 This is the LuaRocks rockspec for the LXSH module.

 Author: Peter Odding <peter@peterodding.com>
 Last Change: {{DATE}}
 Homepage: http://peterodding.com/code/lua/lxsh

]]

package = 'LXSH'
version = '{{VERSION}}'

source = {
  url = 'http://peterodding.com/code/lua/lxsh/downloads/lxsh-{{VERSION}}.zip',
  md5 = '{{HASH}}',
}

description = {
  summary = 'Lexing & syntax highlighting in Lua',
  detailed = [[
    LXSH is a collection of lexers and syntax highlighters written in Lua using
    the excellent pattern-matching library LPeg. The syntax highlighters can
    generate HTML, LaTeX (PDF) and RTF output.
  ]],
  homepage = 'http://peterodding.com/code/lua/lxsh',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1',
  'lpeg >= 0.9'
}

build = {
  type = 'builtin',
  modules = {
    ['lxsh.init'] = 'lxsh/init.lua',
    ['lxsh.lexers.init'] = 'lxsh/lexers/init.lua',
    ['lxsh.lexers.lua'] = 'lxsh/lexers/lua.lua',
    ['lxsh.lexers.c'] = 'lxsh/lexers/c.lua',
    ['lxsh.lexers.bib'] = 'lxsh/lexers/bib.lua',
    ['lxsh.lexers.sh'] = 'lxsh/lexers/sh.lua',
    ['lxsh.highlighters.init'] = 'lxsh/highlighters/init.lua',
    ['lxsh.highlighters.lua'] = 'lxsh/highlighters/lua.lua',
    ['lxsh.highlighters.c'] = 'lxsh/highlighters/c.lua',
    ['lxsh.highlighters.bib'] = 'lxsh/highlighters/bib.lua',
    ['lxsh.highlighters.sh'] = 'lxsh/highlighters/sh.lua',
    ['lxsh.docs.lua'] = 'lxsh/docs/lua.lua',
    ['lxsh.docs.c'] = 'lxsh/docs/c.lua',
    ['lxsh.docs.bib'] = 'lxsh/docs/bib.lua',
    ['lxsh.formatters.html'] = 'lxsh/formatters/html.lua',
    ['lxsh.formatters.latex'] = 'lxsh/formatters/latex.lua',
    ['lxsh.formatters.rtf'] = 'lxsh/formatters/rtf.lua',
    ['lxsh.colors.earendel'] = 'lxsh/colors/earendel.lua',
    ['lxsh.colors.slate'] = 'lxsh/colors/slate.lua',
    ['lxsh.colors.wiki'] = 'lxsh/colors/wiki.lua',
  },
  copy_directories = { 'etc', 'examples', 'test' },
}

-- vim: ft=lua ts=2 sw=2 et
