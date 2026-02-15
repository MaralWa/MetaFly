" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_metafly")
    finish
endif

" New unified MetaFly command with tab-completion
command! -nargs=* -complete=custom,MetaFlyComplete MetaFly lua require('MetaFly.command.CommandHandler').execute(<f-args>)

" Legacy commands for backward compatibility
command! MetaFlyNotes lua require('MetaFly.picker.NotePicker').notesView()
command! MetaFlyView lua require('MetaFly.picker.NotePicker').notesView("/Users/sarah/Documents/MetaFly/views/Gwallore.yml")
command! MetaFlyUri lua require('MetaFly.model.database'):getInstance():printUri()
command! -nargs=+ MetaFlySqlResult lua require('MetaFly.view.SqlResultWindow').displaySqlResult(require('MetaFly.model.database'):getInstance(), <q-args>)

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


