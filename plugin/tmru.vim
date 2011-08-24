" tmru.vim -- Most Recently Used Files
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tlib-mru)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-13.
" @Last Change: 2011-04-20.
" @Revision:    401
" GetLatestVimScripts: 1864 1 tmru.vim

if &cp || exists("loaded_tmru")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 28
    echoerr "tlib >= 0.28 is required"
    finish
endif
let loaded_tmru = 9

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
if !exists("g:tmruEvents")
    " A dictionary of {EVENT: SAVE}. If SAVE evaluates to true, the list is 
    " saved for those |{event}|.
    "
    " Old format: A comma-separated list of events that trigger buffer 
    " registration.
    let g:tmruEvents = {'BufWritePost': 1, 'BufReadPost': 1, 'BufWinEnter': 0, 'BufEnter': 0, 'BufDelete': 0} "{{{2
endif
if !exists("g:tmru_file")
    if stridx(&viminfo, '!') == -1
        " Where to save the file list. The default value is only 
        " effective, if 'viminfo' doesn't contain '!' -- in which case 
        " the 'viminfo' will be used.
        let g:tmru_file = tlib#cache#Filename('tmru', 'files', 1) "{{{2
    else
        let g:tmru_file = ''
    endif
endif


" Don't change the value of this variable.
if !exists("g:TMRU")
    if empty(g:tmru_file)
        let g:TMRU = ''
    else
        let g:TMRU = get(tlib#cache#Get(g:tmru_file), 'tmru', '')
    endif
endif


if !exists("g:TMRU_METADATA")
    if empty(g:tmru_file)
        let g:TMRU_METADATA = ''
    else
        let g:TMRU_METADATA = get(tlib#cache#Get(g:tmru_file), 'metadata', '')
    endif
endif
if empty(g:TMRU_METADATA)
    let g:TMRU_METADATA = join(repeat(['{}'], len(split(g:TMRU, '\n'))), "\n")
endif
" let s:did_increase_sessions = 0


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


function! s:BuildMenu(initial) "{{{3
    if !empty(g:tmruMenu)
        if !a:initial
            silent! exec 'aunmenu '. g:tmruMenu
        endif
        let [mru, metadata] = s:MruRetrieve()
        if g:tmruMenuSize > 0 && len(mru) > g:tmruMenuSize
            let mru = mru[0 : g:tmruMenuSize - 1]
        endif
        for e in mru
            let me = escape(e, '.\ ')
            exec 'amenu '. g:tmruMenu . me .' :call <SID>Edit('. string(e) .')<cr>'
        endfor
    endif
endf


function! s:MruRetrieve()
    let mru = split(g:TMRU, '\n')
    let metadata = map(split(g:TMRU_METADATA, '\n'), 'eval(v:val)')
    " if !s:did_increase_sessions
    "     for metaidx in range(len(metadata))
    "         let metaitem = metadata[metaidx]
    "         if type(metaitem) != 4
    "             echohl ErrorMsg
    "             echom "TMRU: metaitem is not a dictionary" string(metaitem)
    "             echohl NONE
    "             unlet metaitem
    "             let metaitem = {}
    "         endif
    "         let metaitem.sessions = get(metaitem, 'sessions', -1) + 1
    "         let metadata[metaidx] = metaitem
    "     endfor
    "     let s:did_increase_sessions = 1
    "     " echom "DBG s:MruStore" string(metadata)
    " endif

    " Canonicalize filename when using &shellslash (Windows)
    if exists('+shellslash')
        if &shellslash
            let mru = map(mru, 'substitute(v:val, ''\\'', ''/'', ''g'')')
        else
            let mru = map(mru, 'substitute(v:val, ''/'', ''\\'', ''g'')')
        endif
    endif

    " make it relative to $HOME internally
    " let mru = map(mru, 'fnamemodify(v:val, ":~")')

    " TLogVAR mru
    return [mru, metadata]
endf


function! s:MruStore(mru, metadata, save)
    " TLogVAR a:save, g:tmru_file
    let g:TMRU = join(a:mru, "\n")
    let metadata = a:metadata
    let g:TMRU_METADATA = join(map(metadata, 'string(v:val)'), "\n")
    " TLogVAR g:TMRU
    " echom "DBG s:MruStore" g:tmru_file
    call s:BuildMenu(0)
    if a:save && !empty(g:tmru_file)
        call tlib#cache#Save(g:tmru_file, {'tmru': g:TMRU, 'metadata': g:TMRU_METADATA})
    endif
endf


function! s:Metadata(filename, metadata) "{{{3
    if !empty(a:filename)
        let a:metadata.timestamp = localtime()
    endif
    return a:metadata
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
    let [tmru, metadata] = s:MruRetrieve()
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
                call remove(metadata, bi)
                call s:MruStore(tmru, metadata, 1)
            endif
        endfor
        return 1
    endif
    return 0
endf


function! s:EditMRU()
    let [tmru, metadata] = s:MruRetrieve()
    let tmru1 = tlib#input#EditList('Edit MRU', tmru)
    if tmru != tmru1
        let metadata1 = []
        for fname in tmru1
            let idx = index(tmru, fname)
            if idx == -1
                call add(metadata1, s:Metadata(fname, {}))
            else
                call add(metadata1, metadata[idx])
            endif
        endfor
        call s:MruStore(tmru1, metadata1, 1)
    endif
endf


function! s:AutoMRU(filename, event, save) "{{{3
    " if &buftype !~ 'nofile' && fnamemodify(a:filename, ":t") != '' && filereadable(fnamemodify(a:filename, ":t"))
    " TLogVAR a:filename, a:event, a:save, &buftype
    if g:tmru_debug
        let [mru, metadata] = s:MruRetrieve()
        call tmru#DisplayUnreadableFiles(mru)
    endif
    if &buflisted && &buftype !~ 'nofile' && fnamemodify(a:filename, ":t") != ''
        if a:event == 'BufDelete'
            let [mru, metadata] = s:MruRetrieve()
            let fidx = index(mru, a:filename)
            " TLogVAR fidx
            " let metadata[fidx].sessions = get(metadata[fidx], 'sessions', -1) + 1
            call s:MruStore(mru, metadata, 0)
        endif
        call s:MruRegister(a:filename, a:save)
    endif
    if g:tmru_debug
        let [mru, metadata] = s:MruRetrieve()
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
    let [tmru0, metadata0] = s:MruRetrieve()
    let tmru = copy(tmru0)
    let metadata = copy(metadata0)
    let imru = index(tmru, fname, 0, g:tmru_ignorecase)
    if imru == -1 && len(tmru) >= g:tmruSize
        let imru = g:tmruSize - 1
    endif
    let fmeta = {}
    if imru != -1
        call remove(tmru, imru)
        call remove(metadata, imru)
    endif
    call insert(tmru, fname)
    call insert(metadata, s:Metadata(fname, fmeta))
    if tmru != tmru0
        call s:MruStore(tmru, metadata, a:save)
    endif
endf


function! s:RemoveItem(world, selected) "{{{3
    let [mru, metadata] = s:MruRetrieve()
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
            call remove(metadata, fidx)
        endif
    endfor
    call s:MruStore(mru, metadata, 1)
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
    let [mru, metadata] = s:MruRetrieve()
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
            call remove(metadata, idx)
            let unreadable += 1
        elseif get(uniqdict, file)
            " file is a dupe
            let dupes += 1
            call remove(mru, idx)
            call remove(metadata, idx)
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
        call s:MruStore(mru, metadata, 1)
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
    if type(g:tmruEvents) == 1
        exec 'autocmd '. g:tmruEvents .' * call s:AutoMRU(expand("<afile>:p"), "", 1)'
    else
        for [s:event, s:save] in items(g:tmruEvents)
            exec 'autocmd '. s:event .' * call s:AutoMRU(expand("<afile>:p"), '. string(s:event) .', '. s:save .')'
        endfor
        unlet! s:event s:save
    endif
augroup END

" Display the MRU list.
command! TRecentlyUsedFiles call s:SelectMRU()

" Edit the MRU list.
command! TRecentlyUsedFilesEdit call s:EditMRU()

" :display: :{count}TMRUSession
" Open files from a previous session. By default, use the last session.
" command! -count TMRUSession call tmru#Session(s:MruRetrieve(), <count>)

