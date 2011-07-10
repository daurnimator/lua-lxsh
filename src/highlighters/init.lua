--[[

 Infrastructure to make it easier to define syntax highlighters.

 Author: Peter Odding <peter@peterodding.com>
 Last Change: July 10, 2011
 URL: http://peterodding.com/code/lua/lxsh/

 The syntax highlighters in the LXSH module decorate the token streams produced
 by the lexers with the following additional tokens:

  - TODO, FIXME and XXX markers in comments
  - e-mail addresses and hyper links in strings and comments
  - escape sequences in character and string literals

 Coroutines are used to simplify the implementation of the decorated token
 stream and while it works I'm not happy with the code. Note also that the
 token stream is flat which means the following Lua source code:

   -- TODO Nested tokens?

 Produces the following HTML source code (reformatted for readability):

   <span class="comment">--</span>
   <span class="marker">TODO</span>
   <span class="comment">Nested tokens?</span>

 Instead of what you may have expected:

   <span class="comment">--
   <span class="marker">TODO</span>
   Nested tokens?</span>

]]

local lxsh = require 'lxsh'
local lpeg = require 'lpeg'

-- Internal functions. {{{1

local function obfuscate(email)
  return (email:gsub('.', function(c)
    return ('&#%d;'):format(c:byte())
  end))
end

local entities = { ['<'] = '&lt;', ['>'] = '&gt;', ['&'] = '&amp;' }
local function htmlencode(text)
  return (text:gsub('[<>&]', entities))
end

local function fixspaces(text)
  return (text:gsub(' +', function(space)
    return string.rep('&nbsp;', #space)
  end))
end

local function wrap(token, text, options)
  if token then
    local attr = options.external and 'class' or 'style'
    local value = options.external and token or options.colors[token]
    if value then
      local template = '<span %s="%s">%s</span>'
      return template:format(attr, value, text)
    end
  end
  return text
end

-- LPeg patterns to decorate the token stream (richer highlighting). {{{1

-- LPeg patterns to scan for comment markers.
local comment_marker = lpeg.P'TODO' + 'FIXME' + 'XXX'
local comment_scanner = lpeg.Cc'marker' * lpeg.C(comment_marker)
                      + lpeg.Carg(1) * lpeg.C((1 - comment_marker)^1)

-- LPeg patterns to match e-mail addresses.
local alnum = lpeg.R('AZ', 'az', '09')
local domainpart = alnum^1 * (lpeg.S'_-' * alnum^1)^0
local domain = domainpart * ('.' * domainpart)^1
local email = alnum^1 * (lpeg.S'_-.+' * alnum^1)^0 * '@' * domain

-- LPeg patterns to match URLs.
local protocol = ((lpeg.P'https' + 'http' + 'ftp' + 'irc') * '://') + 'mailto:'
local remainder = ((1-lpeg.S'\r\n\f\t\v ,."}])') + (lpeg.S',."}])' * (1-lpeg.S'\r\n\f\t\v ')))^0
local url = protocol * remainder

-- LPeg pattern to scan for e-mail addresses and URLs.
local other = (1 - (email + url))^1
local url_scanner = lpeg.Cc'email' * lpeg.C(email)
                  + lpeg.Cc'url' * lpeg.C(url)
                  + lpeg.Carg(1) * lpeg.C(other)

-- Constructor for syntax highlighting modes. {{{1

-- Construct a new syntax highlighter from the given parameters.
function lxsh.highlighters.new(lexer, docs, escseq, isstring)

  -- Implementation of decorated token stream (depends on lexer as upvalue). {{{2

  -- LPeg pattern to scan for escape sequences in character and string literals.
  local escape_scanner = lpeg.Cc'escape' * lpeg.C(escseq)
                       + lpeg.Carg(1) * lpeg.C((1 - escseq)^1)

  -- Turn an LPeg pattern into an iterator that produces (kind, text) pairs.
  local function iterator(kind, text, pattern)
    local index = 1
    while index <= #text do
      local subkind, subtext = pattern:match(text, index, kind)
      if subkind and subtext then
        coroutine.yield(subkind, subtext)
        index = index + #subtext
      end
    end
  end

  -- Decorate the token stream produced by a lexer so that comment markers,
  -- URLs, e-mail addresses and escape sequences are recognized as well.
  local function decorator(lexer, subject)
    for kind, text in lexer.gmatch(subject) do
      if kind == 'comment' or kind == 'constant' or kind == 'string' then
        -- Identify e-mail addresses and URLs.
        for kind, text in coroutine.wrap(function() iterator(kind, text, url_scanner) end) do
          if kind == 'comment' then
            -- Identify comment markers.
            iterator(kind, text, comment_scanner)
          elseif kind == 'constant' or kind == 'string' then
            -- Identify escape sequences.
            iterator(kind, text, escape_scanner)
          else
            coroutine.yield(kind, text)
          end
        end
      else
        coroutine.yield(kind, text)
      end
    end
  end

  -- Highlighter function (depends on lexer and decorator as upvalues). {{{2

  return function(subject, options)

    local output = {}
    local options = type(options) == 'table' and options or {}
    if not options.colors then options.colors = lxsh.colors.earendel end

    for kind, text in coroutine.wrap(function() decorator(lexer, subject) end) do
      local doclink = docs[text]
      local html
      if doclink then
        local template = '<a href="%s" %s="%s">%s</a>'
        local attr = options.external and 'class' or 'style'
        local value = options.external and 'library' or options.colors.library
        html = template:format(doclink, attr, value, text)
      elseif kind == 'email' or kind == 'url' then
        local url = text
        if url:find '@' and not url:find '://' then
          if not url:find '^mailto:' then
            url = 'mailto:' .. url
          end
          url = obfuscate(url)
          text = obfuscate(text)
        end
        html = '<a href="' .. url .. '"'
        if options.colors.url and not options.external then
          html = html .. ' style="' .. options.colors.url .. '"'
        end
        html = html .. '>' .. text .. '</a>'
      else
        html = htmlencode(text)
        if options.encodews then
          html = fixspaces(html)
        end
        if kind == 'string' then
          kind = 'constant'
        end
        if kind ~= 'whitespace' then
          html = wrap(kind, html, options)
        end
      end
      output[#output + 1] = html
    end

    local wrapper = options.wrapper or 'pre'
    local elem = '<' .. wrapper
    if not options.external then
      elem = elem .. ' style="' .. options.colors.default .. '"'
    end
    table.insert(output, 1, elem .. ' class="sourcecode ' .. lexer.language .. '">')
    table.insert(output, '</' .. wrapper .. '>')
    local html = table.concat(output)

    if options.encodews then
      html = html:gsub('\r?\n', '<br>')
    end

    return html
  end

end

-- Style sheet generator. {{{1

function lxsh.highlighters.includestyles(default, includeswitcher)
  local template = '<link rel="%s" type="text/css" href="http://peterodding.com/code/lua/lxsh/styles/%s.css" title="%s">'
  local output = {}
  for _, style in ipairs { 'earendel', 'slate', 'wiki' } do
    local rel = style == default and 'stylesheet' or 'alternate stylesheet'
    output[#output + 1] = template:format(rel, style, style:gsub('^%w', string.upper))
  end
  if includeswitcher then
    output[#output + 1] = '<script type="text/javascript" src="http://peterodding.com/code/lua/lxsh/styleswitcher.js"></script>'
  end
  return table.concat(output, '\n')
end

function lxsh.highlighters.stylesheet(name)
  local colors = require('lxsh.colors.' .. name)
  local keys = {}
  for k in pairs(colors) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  local output = {}
  for _, key in ipairs(keys) do
    if key == 'default' then
      output[#output + 1] = ('.sourcecode { %s; }'):format(colors[key])
    elseif key == 'url' then
      output[#output + 1] = ('.sourcecode a:link, .sourcecode a:visited { %s; }'):format(colors[key])
    elseif key == 'library' then
      local styles = (colors[key] .. ';'):gsub(';', ' !important;')
      output[#output + 1] = ('.sourcecode .%s { %s }'):format(key, styles)
    else
      output[#output + 1] = ('.sourcecode .%s { %s; }'):format(key, colors[key])
    end
  end
  return table.concat(output, '\n')
end

-- }}}1

return lxsh.highlighters