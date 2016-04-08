describe("Unit tests for the HTML syntax highlighters of the LXSH module", function()
	local lxsh = require 'lxsh'

	describe("Tests for the Lua highlighter", function()
		local function lua2html(source)
			return lxsh.highlighters.lua(source, {
				external = true,
				formatter = lxsh.formatters.html,
			})
		end
		it("Highlights Constants (true, false and nil)", function()
			assert.same([[<pre class="sourcecode lua"><span class="constant">true</span> <span class="constant">false</span> <span class="constant">nil</span></pre>]],
				lua2html 'true false nil')
		end)

		it("Highlights Interactive prompt", function()
			assert.same([[
<pre class="sourcecode lua"><span class="prompt">Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio</span>
<span class="prompt">&gt;</span> <a href="http://www.lua.org/manual/5.1/manual.html#pdf-print" class="library">print</a> <span class="constant">"Hello world!"</span></pre>]],
				lua2html [[
Lua 5.1.4  Copyright (C) 1994-2008 Lua.org, PUC-Rio
> print "Hello world!"]])
		end)

		it("Highlights Numbers", function()
			assert.same([[<pre class="sourcecode lua"><span class="number">1</span> <span class="number">3.14</span> <span class="number">1.</span> <span class="number">.1</span> <span class="number">0x0123456789ABCDEF</span> <span class="number">1e5</span></pre>]],
				lua2html '1 3.14 1. .1 0x0123456789ABCDEF 1e5')
		end)

		it("Highlights String literals", function()
			assert.same([==[
<pre class="sourcecode lua"><span class="constant">'single quoted string'</span>
<span class="constant">"double quoted string"</span>
<span class="constant">[[long string]]</span>
<span class="constant">[[multi line
long string]]</span>
<span class="constant">[=[nested [[long]] string]=]</span>
</pre>]==], lua2html [==[
'single quoted string'
"double quoted string"
[[long string]]
[[multi line
long string]]
[=[nested [[long]] string]=]
]==])
		end)

		it("Highlights Comments", function()
			assert.same([==[
<pre class="sourcecode lua"><span class="comment">#!shebang line
</span><span class="comment">-- single line comment
</span><span class="comment">--[=[
 long
 comment
]=]</span>
<span class="comment">--[[
nested
--[=[long]=]
comment
]]</span>
</pre>]==], lua2html [==[
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
]==])
		end)

		it("Highlights Operators", function()
			assert.same([==[<pre class="sourcecode lua"><span class="operator">not</span> <span class="operator">...</span> <span class="operator">and</span> <span class="operator">..</span> <span class="operator">~=</span> <span class="operator">==</span> <span class="operator">&gt;=</span> <span class="operator">&lt;=</span> <span class="operator">or</span> <span class="operator">]</span> <span class="operator">{</span> <span class="operator">=</span> <span class="operator">&gt;</span> <span class="operator">^</span> <span class="operator">[</span> <span class="operator">&lt;</span> <span class="operator">;</span> <span class="operator">)</span> <span class="operator">*</span> <span class="operator">(</span> <span class="operator">%</span> <span class="operator">}</span> <span class="operator">+</span> <span class="operator">-</span> <span class="operator">:</span> <span class="operator">,</span> <span class="operator">/</span> <span class="operator">.</span> <span class="operator">#</span></pre>]==],
				lua2html 'not ... and .. ~= == >= <= or ] { = > ^ [ < ; ) * ( % } + - : , / . #')
		end)

		it("Highlights Keywords", function()
			assert.same([==[<pre class="sourcecode lua"><span class="keyword">break</span> <span class="keyword">do</span> <span class="keyword">else</span> <span class="keyword">elseif</span> <span class="keyword">end</span> <span class="keyword">for</span> <span class="keyword">function</span> <span class="keyword">if</span> <span class="keyword">in</span> <span class="keyword">local</span> <span class="keyword">repeat</span> <span class="keyword">return</span> <span class="keyword">then</span> <span class="keyword">until</span> <span class="keyword">while</span></pre>]==],
				lua2html 'break do else elseif end for function if in local repeat return then until while')
		end)

		it("Highlights Hyper links embedded in strings/comments and documentation links", function()
			assert.same(lua2html [[
-- http://peterodding.com/code/lua/lxsh
os.execute("firefox http://lua.org")
]], [[
<pre class="sourcecode lua"><span class="comment">-- </span><a href="http://peterodding.com/code/lua/lxsh" class="url">http://peterodding.com/code/lua/lxsh</a><span class="comment">
</span><a href="http://www.lua.org/manual/5.1/manual.html#pdf-os.execute" class="library">os.execute</a><span class="operator">(</span><span class="constant">"firefox </span><a href="http://lua.org" class="url">http://lua.org</a><span class="constant">"</span><span class="operator">)</span>
</pre>]])
		end)

		it("Highlights Escape sequences in strings", function()

-- Escape sequences in single quoted strings are highlighted.
			assert.same(lua2html [['foo\000bar']], [[
<pre class="sourcecode lua"><span class="constant">'foo</span><span class="escape">\000</span><span class="constant">bar'</span></pre>]])

-- Escape sequences in double quoted strings are highlighted.
			assert.same(lua2html [["foo\000bar"]], [[
<pre class="sourcecode lua"><span class="constant">"foo</span><span class="escape">\000</span><span class="constant">bar"</span></pre>]])

-- Escape sequences in long strings are NOT highlighted.
			assert.same(lua2html '[[foo\\000bar]]', [=[
<pre class="sourcecode lua"><span class="constant">[[foo\000bar]]</span></pre>]=])
		end)
	end)
end)
