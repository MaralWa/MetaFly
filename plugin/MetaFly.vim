" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_metafly")
    finish
endif

command! MetaFlyNotes lua require('MetaFly.picker.NotePicker').notesView()
command! MetaFlyView lua require('MetaFly.picker.NotePicker').notesView("/Users/sarah/Documents/MetaFly/views/Gwallore.yml")
command! MetaFlyUri lua require('MetaFly.model.database'):getInstance():printUri()

let g:loaded_metafly = 1

