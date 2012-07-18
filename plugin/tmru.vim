" tmru.vim -- Most Recently Used Files
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tlib-mru)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-13.
" @Last Change: 2012-07-18.
" @Revision:    517
" GetLatestVimScripts: 1864 1 tmru.vim

if &cp || exists("loaded_tmru")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 45
    echoerr "tlib >= 0.45 is required"
    finish
endif
let loaded_tmru = 12


if !exists("g:tmruSize")
    " The number of recently edited files that are registered.
    let g:tmruSize = 50 "{{{2
endif


if !exists("g:tmruMenu")
    " The menu's prefix. If the value is "", the menu will be disabled.
    let g:tmruMenu = 'File.M&RU.' "{{{2
endif


if !exists("g:tmruMenuSize")
    " The number of recently edited files that are displayed in the 
    " menu.
    let g:tmruMenuSize = 20 "{{{2
endif


if !exists("g:tmru_events")
    " A dictionary of {EVENT: [LOAD, SAVE]}. If LOAD or SAVE evaluates 
    " to true, the mru list is load/saved for the respective |{event}|.
    "
    " LOAD =  1: Load the external representation of the mru list
    " LOAD =  0: Use the internal representation of the mru list
    " SAVE =  1: Save the mru list to its external representation
    " SAVE =  0: Save the mru list to its internal representation
    " SAVE = -1: Ignore this event for saving.
    "
    " :read: let g:tmru_events = {...} "{{{2
    if exists('g:tmruEvents')
        if type(g:tmruEvents) == 1
            let g:tmru_events = {}
            for s:ev in g:tmruEvents
                let g:tmru_events[s:ev] = {'load': 0, 'save': 1}
            endfor
            unlet s:ev
        else
            let g:tmru_events = map(g:tmruEvents, "{'load': 0, 'save': v:val}")
        endif
        unlet g:tmruEvents
    else
        let g:tmru_events = {
                    \ 'FocusGained':  {'load': 1, 'save': -1},
                    \ 'FocusLost':    {'load': 0, 'save': 1},
                    \ 'BufWritePost': {'load': 0, 'save': 1},
                    \ 'BufReadPost':  {'load': 0, 'save': 1}, 
                    \ 'BufWinEnter':  {'load': 0, 'save': 1},
                    \ 'BufEnter':     {'load': 0, 'save': 0},
                    \ 'BufDelete':    {'load': 0, 'save': 0}
                    \ }
    endif
endif


if !exists('g:tmru_update_viminfo')
    " If true, load and save the viminfo file on certain events -- see 
    " |g:tmru_events|.
    " This is useful if 'viminfo' includes '!' and |g:tmru_file| is 
    " empty and you run multiple instances of vim.
    let g:tmru_update_viminfo = 0   "{{{2
endif


if !exists("g:tmru_file")
    if stridx(&viminfo, '!') == -1
        " Where to save the file list. The default value is only 
        " effective, if 'viminfo' doesn't contain '!' -- in which case 
        " the 'viminfo' will be used.
        let g:tmru_file = tlib#persistent#Filename('tmru', 'files', 1) "{{{2
    else
        let g:tmru_file = ''
    endif
endif


if !exists("g:tmruExclude") "{{{2
    " Ignore files matching this regexp.
    " :read: let g:tmruExclude = '/te\?mp/\|vim.\{-}/\(doc\|cache\)/\|__.\{-}__$' "{{{2
    if exists('+shellslash')
        let s:PS = &shellslash ? '/' : '\\'
    else
        let s:PS = "/"
    endif
    let g:tmruExclude = s:PS . '[Tt]e\?mp' . s:PS
                \ . '\|' . s:PS . '\(vimfiles\|\.vim\)' . s:PS . '\(doc\|cache\)' . s:PS
                \ . '\|\.tmp$'
                \ . '\|'. s:PS .'.git'. s:PS .'\(COMMIT_EDITMSG\|git-rebase-todo\)$'
                \ . '\|'. s:PS .'quickfix$'
                \ . '\|__.\{-}__$'
                \ . '\|^fugitive:'
                \ . '\|' . substitute(escape(&suffixes, '~.*$^'), '\\\@<!,', '$\\|', 'g') .'$' " &suffixes, ORed (split on (not escaped) comma)
    unlet s:PS
endif


if !exists("g:tmru_ignorecase")
    " If true, ignore case when comparing filenames.
    let g:tmru_ignorecase = !has('fname_case') "{{{2
endif


function! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf


if !exists('g:tmru_world') "{{{2
    let g:tmru_world = {
                \ 'type': 'm',
                \ 'key_handlers': [
                \ {'key': 3,  'agent': 'tlib#agent#CopyItems',        'key_name': '<c-c>', 'help': 'Copy file name(s)'},
                \ {'key': 6,  'agent': s:SNR() .'CheckFilenames',     'key_name': '<c-f>', 'help': 'Check file name(s)'},
                \ {'key': "\<del>", 'agent': s:SNR() .'RemoveItem',   'key_name': '<del>', 'help': 'Remove file name(s)'},
                \ {'key': 9,  'agent': 'tlib#agent#ShowInfo',         'key_name': '<c-i>', 'help': 'Show info'},
                \ {'key': 19, 'agent': 'tlib#agent#EditFileInSplit',  'key_name': '<c-s>', 'help': 'Edit files (split)'},
                \ {'key': 22, 'agent': 'tlib#agent#EditFileInVSplit', 'key_name': '<c-v>', 'help': 'Edit files (vertical split)'},
                \ {'key': 20, 'agent': 'tlib#agent#EditFileInTab',    'key_name': '<c-t>', 'help': 'Edit files (new tab)'},
                \ {'key': 23, 'agent': 'tlib#agent#ViewFile',         'key_name': '<c-w>', 'help': 'View file in window'},
                \ ],
                \ 'allow_suspend': 0,
                \ 'query': 'Select file',
                \ }
                " \ 'filter_format': 'fnamemodify(%s, ":t")',
endif


if !exists('g:tmru_debug')
    " :nodoc:
    let g:tmru_debug = 0   "{{{2
endif


if !exists('g:tmru_check_disk')
    " If TRUE, allow disk checks when adding files to the list by 
    " means of a registered event (see |g:tmru_events|).
    " This may cause annoying slow-downs in certain settings. In this 
    " case, set this variable to 0 in your |vimrc| file.
    let g:tmru_check_disk = 1   "{{{2
endif


function! s:BuildMenu(initial) "{{{3
    if !empty(g:tmruMenu)
        if !a:initial
            silent! exec 'aunmenu '. g:tmruMenu
        endif
        let mru = s:MruRetrieve()
        if g:tmruMenuSize > 0 && len(mru) > g:tmruMenuSize
            let mru = mru[0 : g:tmruMenuSize - 1]
        endif
        for e in mru
            let me = escape(e, '.\ ')
            exec 'amenu '. g:tmruMenu . me .' :call <SID>Edit('. string(e) .')<cr>'
        endfor
    endif
endf


" s:MruRetrieve(?read_data=0)
function! s:MruRetrieve(...)
    let read_data = a:0 >= 1 ? a:1 : 0
    if empty(g:tmru_file)
        if read_data && exists("g:TMRU")
            if g:tmru_update_viminfo
                rviminfo
            endif
        endif
        if !exists("g:TMRU")
            let g:TMRU = ''
        endif
    else
        if read_data
            if exists('s:tmru_mtime') && getftime(g:tmru_file) == s:tmru_mtime
                let read_data = 0
            endif
        elseif !exists("g:TMRU")
            let read_data = 1
        endif
        if read_data
            let data = tlib#persistent#Get(g:tmru_file)
            let g:TMRU = get(data, 'tmru', '')
            let s:tmru_mtime = getftime(g:tmru_file)
        endif
    endif
    let mru = split(g:TMRU, '\n')

    " Canonicalize filename when using &shellslash (Windows)
    if exists('+shellslash')
        if &shellslash
            let mru = map(mru, 'substitute(v:val, ''\\'', ''/'', ''g'')')
        else
            let mru = map(mru, 'substitute(v:val, ''/'', ''\\'', ''g'')')
        endif
    endif

    " TLogVAR mru
    return mru
endf


function! s:MruStore(mru, save)
    " TLogVAR a:save, g:tmru_file
    let g:TMRU = join(a:mru, "\n")
    " TLogVAR g:TMRU
    " echom "DBG s:MruStore" g:tmru_file
    call s:BuildMenu(0)
    if a:save
        if empty(g:tmru_file)
            if g:tmru_update_viminfo
                wviminfo
            endif
        else
            call tlib#persistent#Save(g:tmru_file, {'tmru': g:TMRU})
        endif
    endif
endf


" Return 0 if the file isn't readable/doesn't exist.
" Otherwise return 1.
function! TmruEdit(filename) "{{{3
    let filename = fnamemodify(a:filename, ':p')
    if filename == expand('%:p')
        return 1
    else
        let bn = bufnr(filename)
        " TLogVAR bn
        if bn != -1 && buflisted(bn)
            exec 'buffer '. bn
            return 1
        elseif filereadable(filename)
            try
                let file = tlib#arg#Ex(filename)
                " TLogVAR file
                exec 'edit '. file
            catch
                echohl error
                echom v:errmsg
                echohl NONE
            endtry
            return 1
        else
            echom "TMRU: File not readable: " . filename
            if filename != a:filename
                echom "TMRU: original filename: " . a:filename
            endif
        endif
    endif
    return 0
endf


function! s:SelectMRU()
    " TLogDBG "SelectMRU#1"
    let tmru = s:MruRetrieve()
    if !empty(tmru)
        " TLogDBG "SelectMRU#2"
        " TLogVAR tmru
        let world = tlib#World#New(g:tmru_world)
        call world.Set_display_format('filename')
        " TLogDBG "SelectMRU#3"
        let world.base = copy(tmru)
        " TLogDBG "SelectMRU#4"
        " let bs    = tlib#input#List('m', 'Select file', copy(tmru), g:tmru_handlers)
        let bs    = tlib#input#ListW(world)
        " TLogDBG "SelectMRU#5"
        " TLogVAR bs
        if !empty(bs)
            for bf in bs
                " TLogVAR bf
                if !TmruEdit(bf)
                    let bi = index(tmru, bf)
                    " TLogVAR bi
                    call remove(tmru, bi)
                    call s:MruStore(tmru, 1)
                endif
            endfor
            return 1
        endif
    endif
    return 0
endf


function! s:EditMRU()
    let tmru = s:MruRetrieve()
    let tmru1 = tlib#input#EditList('Edit MRU', tmru)
    if tmru != tmru1
        call s:MruStore(tmru1, 1)
    endif
endf


function! s:AutoMRU(filename, event, props) "{{{3
    " TLogVAR a:filename, a:event, a:props, &buftype
    if g:tmru_debug
        let mru = s:MruRetrieve(a:props.load)
        call tmru#DisplayUnreadableFiles(mru)
    endif
    if a:props.load
        call s:MruRetrieve(a:props.load)
    endif
    if a:props.save >= 0
        if &buflisted && &buftype !~ 'nofile' && fnamemodify(a:filename, ":t") != ''
                    \ && (!g:tmru_check_disk || (filereadable(a:filename) && !isdirectory(a:filename)))
            if a:event == 'BufDelete'
                let mru = s:MruRetrieve()
                let fidx = index(mru, a:filename)
                " TLogVAR fidx
                call s:MruStore(mru, 0)
            endif
            call s:MruRegister(a:filename, a:props.save)
        endif
    endif
    if g:tmru_debug
        let mru = s:MruRetrieve()
        call tmru#DisplayUnreadableFiles(mru)
    endif
    " TLogVAR "exit"
endf


function! s:MruRegister(fname, save)
    let fname = fnamemodify(a:fname, ':p')
    " TLogVAR a:fname, a:save, fname
    if g:tmruExclude != '' && fname =~ g:tmruExclude
        if &verbose | echom "tmru: ignore file" fname | end
        return
    endif
    if exists('b:tmruExclude') && b:tmruExclude
        return
    endif
    let tmru0 = s:MruRetrieve()
    let tmru = copy(tmru0)
    let imru = index(tmru, fname, 0, g:tmru_ignorecase)
    if imru == -1 && len(tmru) >= g:tmruSize
        let imru = g:tmruSize - 1
    endif
    if imru != -1
        call remove(tmru, imru)
    endif
    call insert(tmru, fname)
    if tmru != tmru0
        call s:MruStore(tmru, a:save)
    endif
endf


function! s:RemoveItem(world, selected) "{{{3
    let mru = s:MruRetrieve()
    " TLogVAR a:selected
    let idx = -1
    for filename in a:selected
        let fidx = index(mru, filename)
        if idx < 0
            let idx = fidx
        endif
        " TLogVAR filename, fidx
        if fidx >= 0
            call remove(mru, fidx)
        endif
    endfor
    call s:MruStore(mru, 1)
    call a:world.ResetSelected()
    let a:world.base = copy(mru)
    if idx > len(mru)
        let a:world.idx = len(mru)
    elseif idx >= 0
        let a:world.idx = idx
    endif
    " TLogVAR a:world.idx
    let a:world.state = 'display'
    return a:world
endf


" Validate list of filenames in mru list.
" This checks that files are readable and removes any (canonicalized)
" duplicates.
function! s:CheckFilenames(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let idx = len(mru) - 1
    let uniqdict = {} " used to remove duplicates
    let unreadable = 0
    let dupes = 0
    let normalized = 0
    while idx > 0
        let file_p = fnamemodify(mru[idx], ':p')
        let file = substitute(substitute(file_p, '\\\+', '\', 'g'), '/\+', '/', 'g')
        if !filereadable(file)
            " TLogVAR file
            call remove(mru, idx)
            let unreadable += 1
        elseif get(uniqdict, file)
            " file is a dupe
            let dupes += 1
            call remove(mru, idx)
        else
            " file is OK, add it to dictionary for dupe checking
            let uniqdict[file] = 1
            if file_p != file
                let normalized += 1
                let mru[idx] = file
            endif
        endif
        let idx -= 1
    endwh
    if unreadable > 0 || dupes > 0 || normalized > 0
        call s:MruStore(mru, 1)
        echom "TMRU: Removed" unreadable "unreadable and" dupes "duplicate"
                    \ "files from mru list, and normalized" normalized "entries."
    endif
    let a:world.base = copy(mru)
    let a:world.state = 'reset'
    return a:world
endf


augroup tmru
    autocmd!
    autocmd VimEnter * call s:BuildMenu(1)
    for [s:event, s:props] in items(g:tmru_events)
        exec 'autocmd '. s:event .' * call s:AutoMRU(expand("<afile>:p"), '. string(s:event) .', '. string(s:props) .')'
    endfor
    unlet! s:event s:props
augroup END


" Display the MRU list.
command! TRecentlyUsedFiles call s:SelectMRU()

" Alias for |:TRecentlyUsedFiles|.
command! TMRU TRecentlyUsedFiles

" Edit the MRU list.
command! TRecentlyUsedFilesEdit call s:EditMRU()

