" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_metafly")
    finish
endif

" Legacy commands for backward compatibility
command! MetaFlyNotes lua require('MetaFly.picker.NotePicker').notesView()
command! MetaFlySnacksNotes lua require('MetaFly.picker.SnacksNotePicker').notesView()
command! MetaFlyUri lua require('MetaFly.model.database'):getInstance():printUri()

command! -nargs=* -complete=customlist,MetaFlyComplete MetaFly call s:MetaFlyDispatch(<f-args>)

function! s:MetaFlyDispatch(subcommand, ...)
    let l:args = join(a:000, ' ')
    call v:lua.require'MetaFly.command.ActionCommandHandler'.execute(a:subcommand, l:args)
endfunction


" Tab-completion function for MetaFly command
function! MetaFlyComplete(ArgLead, CmdLine, CursorPos)
    let l:parts = split(a:CmdLine, '\s\+')
    let l:numParts = len(l:parts)

    " If we're completing the first argument (action)
    if a:CmdLine =~ '^\s*MetaFly\s*$' || l:numParts == 1
        try
            return luaeval('require("MetaFly.command.ActionCommandHandler").ACTIONS')
        catch
            return []
        endtry
    endif

    return []
endfunction

let g:loaded_metafly = 1


