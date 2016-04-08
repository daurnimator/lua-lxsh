# Makefile for the Lua LXSH module.
# 
# Author: Peter Odding <peter@peterodding.com>
# Last Change: October 4, 2011
# URL: http://peterodding.com/code/lua/lxsh/

VERSION = $(shell grep _VERSION lxsh/init.lua | cut "-d'" -f 2)
RELEASE = $(VERSION)-1
PACKAGE = lxsh-$(RELEASE)
STYLESHEETS = examples/earendel.css \
              examples/slate.css \
              examples/wiki.css

demo: $(STYLESHEETS)
	@mkdir -p examples/earendel examples/slate examples/wiki
	@lua etc/demo.lua

test:
	@lua test/lexers.lua
	@lua test/highlighters.lua

links:
	@lua etc/doclinks.lua

examples/%.css: lxsh/colors/%.lua lxsh/init.lua
	@lua -e "print(require 'lxsh'.formatters.html.stylesheet'$(notdir $(basename $@))')" > $@

package: demo
	@rm -f $(PACKAGE).zip
	@mkdir -p $(PACKAGE)/etc
	@cp -al etc/lxsh etc/demo.lua etc/doclinks.lua etc/styleswitcher.js $(PACKAGE)/etc
	@cp -al examples $(PACKAGE)
	@cp -al lxsh $(PACKAGE)
	@cp README.md TODO.md $(PACKAGE)
	@zip $(PACKAGE).zip  -x '*.sw*' -r $(PACKAGE)
	@rm -R $(PACKAGE)
	@echo Generated $(PACKAGE).zip

rockspec: package
	@cat etc/template.rockspec \
		| sed "s/{{VERSION}}/$(RELEASE)/g" \
		| sed "s/{{DATE}}/`export LANG=; date '+%B %d, %Y'`/" \
		| sed "s/{{HASH}}/`md5sum $(PACKAGE).zip | cut '-d ' -f1 `/" \
		> $(PACKAGE).rockspec
	@echo Generated $(PACKAGE).rockspec

.PHONY: demo test links package
