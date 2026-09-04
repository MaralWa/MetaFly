.PHONY: test

# Run the full test suite using the minimal Neovim configuration so that the
# user's personal init.lua (and its plugin dependencies such as lspconfig) is
# never loaded during test execution.
test:
	nvim --headless --noplugin -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
