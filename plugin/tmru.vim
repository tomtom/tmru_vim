" tmru.vim -- Most Recently Used Files
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tlib-mru)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-13.
" @Last Change: 2012-11-27.
" @Revision:    740
" GetLatestVimScripts: 1864 1 tmru.vim

if &cp || exists("loaded_tmru")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 104
    echoerr "tlib >= 1.04 is required"
    finish
endif
let loaded_tmru = 12


if !exists("g:tmruMenu")
    " The menu's prefix. If the value is "", the menu will be disabled.
    let g:tmruMenu = 'File.M&RU.' "{{{2
endif


if !exists("g:tmruMenuSize")
    " The number of recently edited files that are displayed in the 
    " menu.
    let g:tmruMenuSize = 20 "{{{2
endif


if !exists('g:tmru_sessions')
    " If greater than zero, make tmru to save the file list opened when 
    " closing vim. Save at most information for N sessions.
    "
    " Setting this variable to 0, disables this feature.
    let g:tmru_sessions = 10   "{{{2
endif


if !exists('g:tmru_drop')
    " If true, use |:drop| to edit loaded buffers.
    let g:tmru_drop = 1   "{{{2
endif


if !exists('g:tmru_single_instance_mode')
    " If true, work as if only one instance of vim is running. This 
    " results in reading and writing the mru list less frequently 
    " from/to disk. The list won't be synchronized across multiple 
    " instances of vim running in parallel.
    let g:tmru_single_instance_mode = 0   "{{{2
endif


if !exists('g:tmru_update_viminfo')
    " If true, load and save the viminfo file on certain events -- see 
    " |g:tmru_events|.
    " This is useful if 'viminfo' includes '!' and |g:tmru_file| is 
    " empty and you run multiple instances of vim.
    let g:tmru_update_viminfo = !g:tmru_single_instance_mode   "{{{2
endif


if !exists("g:tmru_events")
    " A dictionary of {EVENT: ACTION = BOOL, ...}, where ACTION is one 
    " of the following:
    "
    " LOAD ....... Load the external representation from disk
    " REGISTER ... Register the current buffer
    " SAVE ....... Save mru list to disk
    "
    " :read: let g:tmru_events = {...} "{{{2
    if exists('g:tmruEvents')  " backwards compatibility
        if type(g:tmruEvents) == 1
            let g:tmru_events = {}
            for s:ev in g:tmruEvents
                let g:tmru_events[s:ev] = {'load': 0, 'register': 1, 'save': 1}
            endfor
            unlet s:ev
        else
            let g:tmru_events = map(g:tmruEvents, "{'load': 0, 'register': 1, 'save': v:val}")
        endif
        unlet g:tmruEvents
    else
        let g:tmru_events = {
                    \ 'VimLeave':     {'load': 0, 'register': 0, 'save': g:tmru_single_instance_mode},
                    \ 'FocusGained':  {'load': 1, 'register': 0, 'save': !g:tmru_single_instance_mode},
                    \ 'FocusLost':    {'load': 0, 'register': 0, 'save': !g:tmru_single_instance_mode},
                    \ 'BufWritePost': {'load': 0, 'register': 1, 'save': !g:tmru_single_instance_mode},
                    \ 'BufReadPost':  {'load': 0, 'register': 1, 'save': !g:tmru_single_instance_mode}, 
                    \ 'BufWinEnter':  {'load': 0, 'register': 1, 'save': !g:tmru_single_instance_mode},
                    \ 'BufEnter':     {'load': 0, 'register': 1, 'save': !g:tmru_single_instance_mode},
                    \ 'BufDelete':    {'load': 0, 'register': 1, 'save': !g:tmru_single_instance_mode}
                    \ }
    endif
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


if !exists("g:tmruSize")
    " The number of recently edited files that are registered.
    " The size is smaller if viminfo is used (see |g:tmru_file|).
    let g:tmruSize = empty(g:tmru_file) ? 50 : 500 "{{{2
endif


if !exists("g:tmruExclude") "{{{2
    if exists('+shellslash')
        let s:PS = &shellslash ? '/' : '\\'
    else
        let s:PS = "/"
    endif
    " Ignore files matching this regexp.
    " :read: let g:tmruExclude = '/te\?mp/\|vim.\{-}/\(doc\|cache\)/\|__.\{-}__$' "{{{2
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
                \ 'scratch': '__TMRU__',
                \ 'key_handlers': [
                \ {'key': 3,  'agent': 'tlib#agent#CopyItems',        'key_name': '<c-c>', 'help': 'Copy file name(s)'},
                \ {'key': 6,  'agent': s:SNR() .'CheckFilenames',     'key_name': '<c-f>', 'help': 'Check file name(s)'},
                \ {'key': "\<del>", 'agent': s:SNR() .'RemoveItem',   'key_name': '<del>', 'help': 'Remove file name(s)'},
                \ {'key': "\<c-cr>", 'agent': s:SNR() .'Drop',        'key_name': '<c-cr>', 'help': 'Drop to file name'},
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
    if !empty(g:tmru_file)
        if g:tmru_sessions > 0
            call add(g:tmru_world.key_handlers,
                        \ {'key': 12, 'agent': s:SNR() .'PreviousSession',    'key_name': '<c-l>', 'help': 'Open files from a previous session'})
        endif
        call add(g:tmru_world.key_handlers,
                    \ {'key': 16, 'agent': s:SNR() .'TogglePersistent',   'key_name': '<c-p>', 'help': 'Toggle a file''s persistent mark'})
        call add(g:tmru_world.key_handlers,
                    \ {'key': 21, 'agent': s:SNR() .'UnsetPersistent',   'key_name': '<c-u>', 'help': 'Unset a file''s persistent mark'})
    endif
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
        for item in mru
            let e = item[0]
            let me = escape(e, '.\ ')
            exec 'amenu '. g:tmruMenu . me .' :call <SID>Edit('. string(e) .')<cr>'
        endfor
    endif
endf


" s:MruRetrieve(?read_data=0)
function! s:MruRetrieve(...)
    let read_data = a:0 >= 1 ? a:1 : 0
    " TLogVAR read_data
    if empty(g:tmru_file)
        if read_data && exists("g:TMRU")
            if g:tmru_update_viminfo
                " TLogVAR read_data, g:tmru_update_viminfo
                rviminfo
            endif
        endif
        if !exists("g:TMRU")
            let g:TMRU = ''
        endif
        let s:tmru_list = map(split(g:TMRU, '\n'), '[v:val, {}]')
    else
        if read_data
            if exists('s:tmru_mtime') && getftime(g:tmru_file) == s:tmru_mtime
                let read_data = 0
            endif
        elseif !exists('s:tmru_mtime') || getftime(g:tmru_file) != s:tmru_mtime
            let read_data = 1
        endif
        if read_data
            " TLogVAR read_data, g:tmru_file
            let data = tlib#persistent#Get(g:tmru_file)
            let s:tmru_mtime = getftime(g:tmru_file)
            if get(data, 'version', 0) == 0
                let s:tmru_list = map(split(get(data, 'tmru', ''), '\n'), '[v:val, {}]')
            else
                let s:tmru_list = get(data, 'tmru', [])
            endif
        endif
    endif
    if read_data
        let s:last_auto_filename = ''
    endif
    return s:tmru_list
endf


function! s:NormalizeFilename(filename) "{{{3
    let filename = fnamemodify(a:filename, ':p')
    if exists('+shellslash')
        if &shellslash
            let filename = substitute(filename, '\\', '/', 'g')
        else
            let filename = substitute(filename, '/', '\\', 'g')
        endif
    endif
    return filename
endf


function! s:MruStore(mru, props)
    " TLogVAR g:tmru_file
    let tmru_list = s:MruSort(a:mru)[0 : g:tmruSize]
    let save = get(a:props, 'save', 1)
    if save == 2 || (save && tmru_list != s:tmru_list)
        let s:tmru_list = tmru_list
        " TLogVAR g:TMRU
        " TLogVAR g:tmru_file
        call s:BuildMenu(0)
        if empty(g:tmru_file)
            if g:tmru_update_viminfo
                let g:TMRU = join(map(s:tmru_list, 'v:val[0]'), "\n")
                wviminfo
            endif
        else
            call tlib#persistent#Save(g:tmru_file, {'version': 1, 'tmru': s:tmru_list})
            let s:tmru_mtime = getftime(g:tmru_file)
        endif
    endif
endf


function! s:MruSort(mru) "{{{3
    let s:mru_pos = 0
    call map(a:mru, 's:SetPos(v:val)')
    unlet s:mru_pos
    " TLogVAR a:mru
    let mru = sort(a:mru, 's:MruSorter')
    " TLogVAR mru
    return mru
endf


function! s:SetPos(item) "{{{3
    let a:item[1].pos = s:mru_pos
    " TLogVAR a:item
    let s:mru_pos += 1
    return a:item
endf


function! s:MruSorter(i1, i2) "{{{3
    let s1 = get(a:i1[1], 'sticky', 0)
    let s2 = get(a:i2[1], 'sticky', 0)
    let p1 = get(a:i1[1], 'pos')
    let p2 = get(a:i2[1], 'pos')
    return s1 == s2 ? (p1 == p2 ? 0 : p1 > p2 ? 1 : -1) : s1 > s2 ? -1 : 1
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
            if g:tmru_drop
                exec 'drop' fnameescape(filename)
            else
                exec 'buffer' bn
            endif
            return 1
        elseif filereadable(filename)
            try
                let file = tlib#arg#Ex(filename)
                " TLogVAR file
                exec 'edit' file
            catch /E325/
                " swap file exists, let the user handle it
            catch
                echohl error
                echom v:exception
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
    let mru = s:MruRetrieve()
    if !empty(mru)
        " TLogDBG "SelectMRU#2"
        " TLogVAR mru
        let world = tlib#World#New(g:tmru_world)
        call world.Set_display_format('filename')
        " TLogDBG "SelectMRU#3"
        let world.base = s:GetFilenames(mru)
        call s:SetFilenameIndicators(world, mru)
        " TLogDBG "SelectMRU#4"
        " let bs    = tlib#input#List('m', 'Select file', copy(mru), g:tmru_handlers)
        let bs    = tlib#input#ListW(world)
        " TLogDBG "SelectMRU#5"
        " TLogVAR bs
        if !empty(bs)
            let modified_mru = 0
            for bf in bs
                " TLogVAR bf
                if !TmruEdit(bf)
                    if modified_mru == 0
                        let mru0 = s:MruRetrieve()
                        let filenames0 = s:GetFilenames(mru0)
                    endif
                    let modified_mru += 1
                    let bi = s:FilenameIndex(filenames0, bf)
                    " TLogVAR bi
                    if bi != -1
                        call remove(mru0, bi)
                    endif
                endif
            endfor
            " TLogVAR modified_mru
            if modified_mru > 0
                call s:MruStore(mru0, {'save': 2})
            endif
            return modified_mru < len(bs)
        endif
    endif
    return 0
endf


function! s:SetFilenameIndicators(world, mru) "{{{3
    let a:world.filename_indicators = {}
    for item in a:mru
        let [filename, props] = item
        let indicators = []
        if get(props, 'sticky', 0)
            call add(indicators, "s")
        endif
        let session = get(props, 'session', 0)
        if session > 0
            call add(indicators, '-'. session)
        endif
        if !empty(indicators)
            let a:world.filename_indicators[filename] = join(indicators, '')
        endif
    endfor
endf


function! s:GetFilenames(mru)
    return map(copy(a:mru), 'v:val[0]')
endf


function! s:AList2Dict(mru)
    let props = {}
    for item in a:mru
        let props[item[0]] = item[1]
    endfor
endf


function! s:EditMRU()
    let mru = s:MruRetrieve()
    let filenames0 = s:GetFilenames(mru)
    let properties = s:AList2Dict(mru)
    let filenames1 = tlib#input#EditList('Edit MRU', s:GetFilenames(filenames0))
    if filenames0 != filenames1
        let mru1 = map(filenames1, '[v:val, get(properties, v:val, {})]')
        call s:MruStore(mru1, {})
    endif
endf


let s:last_auto_filename = ''

function! s:RegisterFile(filename, event, props) "{{{3
    " TLogVAR a:filename, a:event, a:props, &buftype
    if empty(a:filename)
        return
    endif
    if a:props.load
        call s:MruRetrieve(a:props.load)
    endif
    if g:tmru_debug
        let mru = s:MruRetrieve()
        call tmru#DisplayUnreadableFiles(s:GetFilenames(mru))
    endif
    if get(a:props, 'register', 1) && s:last_auto_filename != a:filename
        " TLogVAR "Consider", a:filename
        if &buflisted && &buftype !~ 'nofile' &&
                    \ (g:tmru_check_disk ?
                    \     (filereadable(a:filename) && !isdirectory(a:filename)) :
                    \     fnamemodify(a:filename, ":t") != '')
            let s:last_auto_filename = a:filename
            call s:MruRegister(a:filename, a:props)
        endif
    endif
    if g:tmru_debug
        let mru = s:MruRetrieve()
        call tmru#DisplayUnreadableFiles(s:GetFilenames(mru))
    endif
    " TLogVAR "exit"
endf


function! s:FilenameIndex(filenames, filename) "{{{3
    return index(a:filenames, a:filename, 0, g:tmru_ignorecase)
endf


function! s:MruRegister(filename, props)
    " TLogVAR a:filename
    let filename = s:NormalizeFilename(a:filename)
    if g:tmruExclude != '' && filename =~ g:tmruExclude
        if &verbose | echom "tmru: ignore file" filename | end
        return
    endif
    if exists('b:tmruExclude') && b:tmruExclude
        return
    endif
    let mru0 = s:MruRetrieve()
    let mru = copy(mru0)
    let filenames = s:GetFilenames(mru)
    let imru = s:FilenameIndex(filenames, filename)
    " TLogVAR imru
    if imru != 0
        if imru == -1
            let item = [filename, {}]
        else
            let item = remove(mru, imru)
        endif
        " TLogVAR imru, item
        call insert(mru, item)
        if mru != mru0
            " TLogVAR mru
            if g:tmru_debug
                let filenames = s:GetFilenames(mru)
                " TLogVAR filename, index(filenames,filename)
            endif
            call s:MruStore(mru, a:props)
            if g:tmru_debug
                let filenames = s:GetFilenames(s:MruRetrieve())
                " TLogVAR index(filenames,filename)
            endif
        endif
    endif
endf


function! s:UnsetPersistent(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let filenames = s:GetFilenames(mru)
    for filename in a:selected
        let fidx = s:FilenameIndex(filenames, filename)
        " TLogVAR filename, fidx
        if fidx >= 0
            let mru[fidx][1]['sticky'] = 0
        endif
    endfor
    call s:MruStore(mru, {'save': 2})
    let a:world.base = s:GetFilenames(mru)
    call s:SetFilenameIndicators(a:world, mru)
    let a:world.state = 'reset'
    return a:world
endf


function! s:TogglePersistent(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let filenames = s:GetFilenames(mru)
    let msgs = []
    for filename in a:selected
        let fidx = s:FilenameIndex(filenames, filename)
        " TLogVAR filename, fidx
        if fidx >= 0
            let props = mru[fidx][1]
            let props['sticky'] = !get(props, 'sticky', 0)
            call add(msgs, printf('Mark %ssticky: %s', props.sticky ? '' : 'not ', filename))
            let mru[fidx][1] = props
        endif
    endfor
    if !empty(msgs)
        echom join(msgs, "\n")
        echohl MoreMsg
        call input("Press ENTER to continue")
        echohl NONE
    endif
    call s:MruStore(mru, {'save': 2})
    let a:world.base = s:GetFilenames(mru)
    call s:SetFilenameIndicators(a:world, mru)
    let a:world.state = 'reset'
    return a:world
endf


function! s:RemoveItem(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let filenames = s:GetFilenames(mru)
    " TLogVAR a:selected
    let idx = -1
    for filename in a:selected
        let fidx = s:FilenameIndex(filenames, filename)
        if idx < 0
            let idx = fidx
        endif
        " TLogVAR filename, fidx
        if fidx >= 0
            call remove(mru, fidx)
        endif
    endfor
    call s:MruStore(mru, {'save': 2})
    call a:world.ResetSelected()
    let a:world.base = s:GetFilenames(mru)
    if idx > len(mru)
        let a:world.idx = len(mru)
    elseif idx >= 0
        let a:world.idx = idx
    endif
    " TLogVAR a:world.idx
    let a:world.state = 'display'
    return a:world
endf


function! s:Drop(world, selected) "{{{3
    let filename = a:selected[0]
    if bufnr(filename) != -1
        exec 'drop' fnameescape(filename)
    else
        call TmruEdit(filename)
    endif
    let a:world.state = 'exit'
    return a:world
endf


" Validate list of filenames in mru list.
" This checks that files are readable and removes any (canonicalized)
" duplicates.
function! s:CheckFilenames(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let filenames = s:GetFilenames(mru)
    let idx = len(mru) - 1
    let uniqdict = {} " used to remove duplicates
    let unreadable = 0
    let dupes = 0
    let normalized = 0
    while idx > 0
        let file_p = fnamemodify(filenames[idx], ':p')
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
                let mru[idx][0] = file
            endif
        endif
        let idx -= 1
    endwh
    if unreadable > 0 || dupes > 0 || normalized > 0
        call s:MruStore(mru, {'save': 2})
        echom "TMRU: Removed" unreadable "unreadable and" dupes "duplicate"
                    \ "files from mru list, and normalized" normalized "entries."
    endif
    let a:world.base = s:GetFilenames(mru)
    let a:world.state = 'reset'
    return a:world
endf


augroup tmru
    autocmd!
    autocmd VimEnter * call s:BuildMenu(1)
    for [s:event, s:props] in items(g:tmru_events)
        exec 'autocmd '. s:event .' * call s:RegisterFile(expand("<afile>:p"), '. string(s:event) .', '. string(s:props) .')'
    endfor
    unlet! s:event s:props
augroup END


" Display the MRU list.
command! TRecentlyUsedFiles call s:SelectMRU()

" Alias for |:TRecentlyUsedFiles|.
command! TMRU TRecentlyUsedFiles

" Edit the MRU list.
command! TRecentlyUsedFilesEdit call s:EditMRU()

if g:tmru_sessions > 0
    " Open files from a previous session (see |g:tmru_sessions|).
    " This command is only available if g:tmru_sessions > 0.
    command! -nargs=? TRecentlyUsedFilesSessions call tmru#Session(<q-args>, s:MruRetrieve())

    autocmd tmru VimLeave * call s:MruStore(map(s:MruRetrieve(), 'tmru#SetSessions(v:val)'), {'save': 2})

    function! s:PreviousSession(world, selected) "{{{3
        let session = input('Session number: ', 1)
        if session > 0
            call a:world.CloseScratch()
            exec 'TRecentlyUsedFilesSessions' session
            let a:world.state = 'exit'
        else
            let a:world.state = 'redisplay'
        endif
        return a:world
    endf
endif

