" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_metafly")
    finish
endif

" Legacy commands for backward compatibility
command! MetaFlyNotes lua require('MetaFly.picker.NotePicker').notesView()
" Note: MetaFlyView contains a hardcoded path for backward compatibility with existing user configurations
command! MetaFlyView lua require('MetaFly.picker.NotePicker').notesView("/Users/sarah/Documents/MetaFly/views/Gwallore.yml")
command! MetaFlyUri lua require('MetaFly.model.database'):getInstance():printUri()
command! -nargs=+ MetaFlySqlResult lua require('MetaFly.view.SqlResultWindow').displaySqlResult(require('MetaFly.model.database'):getInstance(), <q-args>)

command! -nargs=* -complete=custom,MetaFlyComplete MetaFly call s:MetaFlyDispatch(<f-args>)

function! s:MetaFlyDispatch(subcommand, ...)
    if a:subcommand == 'SqlResult'
        " Für SqlResult, kombiniere alle Argumente zu einem String
        let l:sqlStatement = join(a:000, ' ')
        call luaeval('require("MetaFly.view.SqlResultWindow").displaySqlResult(require("MetaFly.model.database"):getInstance(), _A)', l:sqlStatement)
    else
        " Für andere Subcommands, benutze den normalen Handler
        call luaeval('require("MetaFly.command.CommandHandler").execute(_A)', [a:subcommand] + a:000)
    endif
endfunction


" Tab-completion function for MetaFly command
function! MetaFlyComplete(ArgLead, CmdLine, CursorPos)
    let l:parts = split(a:CmdLine, '\s\+')
    let l:numParts = len(l:parts)
    
    " If we're completing the first argument (subcommand)
    if a:CmdLine =~ '^\s*MetaFly\s*$' || l:numParts == 1
        return ['Picker', 'Notes', 'Uri', 'SqlResult']
    endif
    
    " If we're completing arguments for the Picker subcommand
    if l:numParts >= 2 && l:parts[1] == 'Picker'
        let l:views = []
        let l:viewsPath = luaeval("require('MetaFly').config.views or '~/.config/views/'")
        let l:viewsPath = expand(l:viewsPath)
        
        if isdirectory(l:viewsPath)
            let l:files = globpath(l:viewsPath, '*.yml', 0, 1)
            for l:file in l:files
                let l:basename = fnamemodify(l:file, ':t:r')
                call add(l:views, l:basename)
            endfor
        endif
        
        return filter(l:views, 'v:val =~ "^" . a:ArgLead')
    endif
    
    return []
endfunction

let g:loaded_metafly = 1


