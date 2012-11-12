" tmru.vim -- Most Recently Used Files
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tlib-mru)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-13.
" @Last Change: 2012-07-18.
" @Revision:    601
" GetLatestVimScripts: 1864 1 tmru.vim

if &cp || exists("loaded_tmru")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 45
    echoerr "tlib >= 0.45 is required"
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
    if !empty(g:tmru_file)
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
    if empty(g:tmru_file)
        if read_data && exists("g:TMRU")
            if g:tmru_update_viminfo
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
        elseif !exists("s:tmru_list")
            let read_data = 1
        endif
        if read_data
            let data = tlib#persistent#Get(g:tmru_file)
            let s:tmru_mtime = getftime(g:tmru_file)
            if get(data, 'version', 0) == 0
                let s:tmru_list = map(split(get(data, 'tmru', ''), '\n'), '[v:val, {}]')
            else
                let s:tmru_list = get(data, 'tmru', [])
            endif
        endif
    endif

    " Canonicalize filename when using &shellslash (Windows)
    if exists('+shellslash')
        if &shellslash
            let s:tmru_list = map(s:tmru_list, '[substitute(v:val[0], ''\\'', ''/'', ''g''), v:val[1]]')
        else
            let s:tmru_list = map(s:tmru_list, '[substitute(v:val[0], ''/'', ''\\'', ''g''), v:val[1]]')
        endif
    endif

    return s:tmru_list
endf


function! s:MruStore(mru, save)
    " TLogVAR a:save, g:tmru_file
    let s:tmru_list = s:MruSort(a:mru)[0 : g:tmruSize]
    " TLogVAR g:TMRU
    " echom "DBG s:MruStore" g:tmru_file
    call s:BuildMenu(0)
    if a:save
        if empty(g:tmru_file)
            if g:tmru_update_viminfo
                let g:TMRU = join(map(s:tmru_list, 'v:val[0]'), "\n")
                wviminfo
            endif
        else
            call tlib#persistent#Save(g:tmru_file, {'version': 1, 'tmru': s:tmru_list})
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
            exec 'buffer '. bn
            return 1
        elseif filereadable(filename)
            try
                let file = tlib#arg#Ex(filename)
                " TLogVAR file
                exec 'edit '. file
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
    let tmru = s:MruRetrieve()
    if !empty(tmru)
        " TLogDBG "SelectMRU#2"
        " TLogVAR tmru
        let world = tlib#World#New(g:tmru_world)
        call world.Set_display_format('filename')
        " TLogDBG "SelectMRU#3"
        let world.base = s:GetFilenames(tmru)
        " TLogDBG "SelectMRU#4"
        " let bs    = tlib#input#List('m', 'Select file', copy(tmru), g:tmru_handlers)
        let bs    = tlib#input#ListW(world)
        " TLogDBG "SelectMRU#5"
        " TLogVAR bs
        if !empty(bs)
            for bf in bs
                " TLogVAR bf
                if !TmruEdit(bf)
                    let bi = s:FindIndex(tmru, bf)
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


function! s:GetFilenames(mru)
    return map(copy(a:mru), 'v:val[0]')
endf


function! s:AList2Dict(mru)
    let props = {}
    for item in a:mru
        let props[item[0]] = item[1]
    endfor
endf


function! s:FindIndex(mru, filename)
    let i = 0
    for item in a:mru
        if item[0] == a:filename
            return i
        endif
        let i += 1
    endif
    return -1
endf


function! s:EditMRU()
    let tmru = s:MruRetrieve()
    let filenames0 = s:GetFilenames(tmru)
    let properties = s:AList2Dict(tmru)
    let filenames1 = tlib#input#EditList('Edit MRU', s:GetFilenames(filenames0))
    if filenames0 != filenames1
        let tmru1 = map(filenames1, '[v:val, get(properties, v:val, {})]')
        call s:MruStore(tmru1, 1)
    endif
endf


function! s:AutoMRU(filename, event, props) "{{{3
    " TLogVAR a:filename, a:event, a:props, &buftype
    if g:tmru_debug
        let mru = s:MruRetrieve(a:props.load)
        call tmru#DisplayUnreadableFiles(s:GetFilenames(mru))
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
                call remove(mru, fidx)
                call s:MruStore(mru, 0)
            endif
            call s:MruRegister(a:filename, a:props.save)
        endif
    endif
    if g:tmru_debug
        let mru = s:MruRetrieve()
        call tmru#DisplayUnreadableFiles(s:GetFilenames(mru))
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
    let filenames = s:GetFilenames(tmru)
    let imru = index(filenames, fname, 0, g:tmru_ignorecase)
    if imru == -1
        let item = [fname, {}]
    else
        let item = remove(tmru, imru)
    endif
    " TLogVAR imru, item
    call insert(tmru, [fname, item[1]])
    if tmru != tmru0
        " TLogVAR tmru
        if g:tmru_debug
            let filenames = s:GetFilenames(tmru)
            TLogVAR a:fname, index(filenames,a:fname)
        endif
        call s:MruStore(tmru, a:save)
        if g:tmru_debug
            let filenames = s:GetFilenames(s:MruRetrieve())
            TLogVAR index(filenames,a:fname)
        endif
    endif
endf


function! s:UnsetPersistent(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let filenames = s:GetFilenames(mru)
    for filename in a:selected
        let fidx = index(filenames, filename)
        " TLogVAR filename, fidx
        if fidx >= 0
            let mru[fidx][1]['sticky'] = 0
        endif
    endfor
    call s:MruStore(mru, 1)
    let a:world.base = s:GetFilenames(mru)
    let a:world.state = 'reset'
    return a:world
endf


function! s:TogglePersistent(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let filenames = s:GetFilenames(mru)
    let msgs = []
    for filename in a:selected
        let fidx = index(filenames, filename)
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
    call s:MruStore(mru, 1)
    let a:world.base = s:GetFilenames(mru)
    let a:world.state = 'reset'
    return a:world
endf


function! s:RemoveItem(world, selected) "{{{3
    let mru = s:MruRetrieve()
    let filenames = s:GetFilenames(mru)
    " TLogVAR a:selected
    let idx = -1
    for filename in a:selected
        let fidx = index(filenames, filename)
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
        call s:MruStore(mru, 1)
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

