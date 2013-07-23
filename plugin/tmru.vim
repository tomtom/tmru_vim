" tmru.vim -- Most Recently Used Files
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tlib-mru)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-13.
" @Last Change: 2013-07-16.
" @Revision:    857
" GetLatestVimScripts: 1864 1 tmru.vim

if &cp || exists("loaded_tmru")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 104
    echoerr "tlib >= 1.04 is required"
    finish
endif
let loaded_tmru = 100


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
    "
    " This variable must be set before starting vim.
    let g:tmru_sessions = 9   "{{{2
endif


if !exists('g:tmru#display_relative_filename')
    " If true, display the relative filename. This requires 
    " |g:tlib#input#format_filename| to be set to "r".
    let g:tmru#display_relative_filename = 0   "{{{2
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
    " load ....... Load the external representation from disk
    " register ... Register the current buffer
    " save ....... Save mru list to disk (currently ignored)
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
                    \ 'VimLeave':     {'load': 0, 'register': 0, 'save': g:tmru_single_instance_mode, 'exit': 1},
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


if !exists('g:tmru_check_disk')
    " If TRUE, allow disk checks when adding files to the list by 
    " means of a registered event (see |g:tmru_events|).
    " This may cause annoying slow-downs in certain settings. In this 
    " case, set this variable to 0 in your |vimrc| file.
    let g:tmru_check_disk = 1   "{{{2
endif


function! TmruObj(...) "{{{3
    let tmruobj = {}
    function! tmruobj.Update(...) dict
        let self.mru = call(function('s:MruRetrieve'), a:000)
    endf
    function! tmruobj.GetFilenames() dict
        return map(copy(self.mru), 'v:val[0]')
    endf
    function! tmruobj.Save(...) dict
        return call(function('s:MruStore'), [self.mru] + a:000)
    endf
    function! tmruobj.SetBase(world) dict
        let a:world.base = self.GetFilenames()
        if g:tmru#display_relative_filename
            let basedir = getcwd()
            let a:world.base = map(a:world.base, 'tlib#file#Relative(v:val, basedir)')
        endif
        call s:SetFilenameIndicators(a:world, self.mru)
    endf
    function! tmruobj.FilenameIndex(filenames, filename) "{{{3
        return index(a:filenames, a:filename, 0, g:tmru_ignorecase)
    endf
    call call(tmruobj.Update, a:000, tmruobj)
    return tmruobj
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


function! s:SetFilenameIndicators(world, mru) "{{{3
    let a:world.filename_indicators = {}
    let idx = 0
    for item in a:mru
        let [filename, props] = item
        let indicators = []
        if get(props, 'sticky', 0)
            call add(indicators, "s")
        endif
        let sessions = get(props, 'sessions', [])
        if !empty(sessions)
            call add(indicators, '-'. join(sessions, '-'))
        endif
        if !empty(indicators)
            let fname = g:tmru#display_relative_filename ? a:world.base[idx] : filename
            " TLogVAR fname, indicators
            let a:world.filename_indicators[fname] = join(indicators, '')
        endif
        let idx += 1
    endfor
endf


function! s:BuildMenu(initial) "{{{3
    if !empty(g:tmruMenu)
        if !a:initial
            silent! exec 'aunmenu '. g:tmruMenu
        endif
        let tmruobj = TmruObj()
        let mru = tmruobj.mru
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


function! s:MruStore(mru, ...)
    " TLogVAR g:tmru_file
    let props = a:0 >= 1 ? a:1 : {}
    let tmru_list = s:MruSort(a:mru)[0 : g:tmruSize]
    if get(props, 'exit', 0)
        " echom "DBG tmru_list != s:tmru_list" (tmru_list != s:tmru_list)
        " echom "DBG tmru_list != s:tmru_list" (string(tmru_list) != string(s:tmru_list))
        " echom "DBG tmru_list" string(filter(copy(tmru_list), 'has_key(v:val[1], "sessions")'))
    endif
    if tmru_list != s:tmru_list
        let s:tmru_list = deepcopy(tmru_list)
        " TLogVAR g:TMRU
        " TLogVAR g:tmru_file
        if !get(props, 'exit', 0)
            call s:BuildMenu(0)
        endif
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


let s:last_auto_filename = ''

function! s:RegisterFile(filename, event, props) "{{{3
    " TLogVAR a:filename, a:event, a:props, &buftype
    if !empty(a:filename) && get(a:props, 'register', 1) && s:last_auto_filename != a:filename
        " TLogVAR "Consider", a:filename
        if getbufvar(a:filename, '&buflisted') &&
                    \ getbufvar(a:filename, '&buftype') !~ 'nofile' &&
                    \ (g:tmru_check_disk ?
                    \     (filereadable(a:filename) && !isdirectory(a:filename)) :
                    \     fnamemodify(a:filename, ":t") != '')
            let s:last_auto_filename = a:filename
            call s:MruRegister(a:filename, a:props)
        endif
    endif
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
    let tmruobj = TmruObj(get(a:props, 'load', 0))
    let mru = copy(tmruobj.mru)
    let filenames = tmruobj.GetFilenames()
    let imru = tmruobj.FilenameIndex(filenames, filename)
    " TLogVAR imru
    if imru != 0
        if imru == -1
            let item = [filename, {}]
        else
            let item = remove(mru, imru)
        endif
        " TLogVAR imru, item
        call insert(mru, item)
        if mru != tmruobj.mru
            " TLogVAR mru
            let tmruobj.mru = mru
            call tmruobj.Save(a:props)
        endif
    endif
endf


augroup tmru
    autocmd!
    autocmd VimEnter * call s:BuildMenu(1)
    for [s:event, s:props] in items(g:tmru_events)
        exec 'autocmd '. s:event .' * call s:RegisterFile(expand("<afile>:p"), '. string(s:event) .', '. string(s:props) .')'
    endfor
    unlet! s:event s:props
augroup END

for s:i in range(1, bufnr('$'))
    call s:RegisterFile(bufname(s:i), 'vimstarting', {'register': 1})
endfor
unlet! s:i


" Display the MRU list.
command! TRecentlyUsedFiles call tmru#SelectMRU()

" Alias for |:TRecentlyUsedFiles|.
command! TMRU TRecentlyUsedFiles

" Edit the MRU list.
command! TRecentlyUsedFilesEdit call tmru#EditMRU()

if g:tmru_sessions > 0
    " Open files from a previous session (see |g:tmru_sessions|).
    " This command is only available if g:tmru_sessions > 0.
    command! -nargs=? TRecentlyUsedFilesSessions call tmru#Session(<q-args>, TmruObj().mru)

    autocmd tmru VimLeave * 
                \ let s:tmruobj = TmruObj() |
                \ let s:tmruobj.mru = map(deepcopy(s:tmruobj.mru), 'tmru#SetSessions(v:val)') |
                \ call s:tmruobj.Save({'exit': 1}) |
                \ unlet s:tmruobj

endif

