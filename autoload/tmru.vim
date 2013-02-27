" tmru.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2011-04-10.
" @Last Change: 2012-11-29.
" @Revision:    87


if !exists('g:tmru#world') "{{{2
    let g:tmru#world = {
                \ 'type': 'm',
                \ 'scratch': '__TMRU__',
                \ 'key_handlers': [
                \ {'key': 3,  'agent': 'tlib#agent#CopyItems',        'key_name': '<c-c>', 'help': 'Copy file name(s)'},
                \ {'key': 6,  'agent': 'tmru#CheckFilenames',     'key_name': '<c-f>', 'help': 'Check file name(s)'},
                \ {'key': "\<del>", 'agent': 'tmru#RemoveItem',   'key_name': '<del>', 'help': 'Remove file name(s)'},
                \ {'key': "\<c-cr>", 'agent': 'tmru#Drop',        'key_name': '<c-cr>', 'help': 'Drop to file name'},
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
            call add(g:tmru#world.key_handlers,
                        \ {'key': 12, 'agent': 'tmru#PreviousSession',    'key_name': '<c-l>', 'help': 'Open files from the selected session'})
        endif
        call add(g:tmru#world.key_handlers,
                    \ {'key': 16, 'agent': 'tmru#TogglePersistent',   'key_name': '<c-p>', 'help': 'Toggle a file''s persistent mark'})
        call add(g:tmru#world.key_handlers,
                    \ {'key': 21, 'agent': 'tmru#UnsetPersistent',   'key_name': '<c-u>', 'help': 'Unset a file''s persistent mark'})
    endif
    if exists('g:tmru_world')
        let g:tmru#world = extend(g:tmru#world, g:tmru_world)
    endif
endif


if !exists('g:tmru#drop')
    " If true, use |:drop| to edit loaded buffers (only available with GUI).
    let g:tmru#drop = has('gui')   "{{{2
endif


if !exists('g:tmru#auto_remove_unreadable')
    " If true, automatically remove unreadable files from the mru list, 
    " when trying to edit them.
    let g:tmru#auto_remove_unreadable = 1   "{{{2
endif


function! tmru#SelectMRU()
    " TLogDBG "SelectMRU#1"
   let tmruobj = TmruObj()
    if !empty(tmruobj.mru)
        " TLogDBG "SelectMRU#2"
        let world = tlib#World#New(g:tmru#world)
        call world.Set_display_format('filename')
        " TLogDBG "SelectMRU#3"
        call tmruobj.SetBase(world)
        " TLogDBG "SelectMRU#4"
        let bs    = tlib#input#ListW(world)
        " TLogDBG "SelectMRU#5"
        " TLogVAR bs
        call tmru#EditFiles(bs, tmruobj)
    endif
    return 0
endf


function! tmru#EditMRU()
    let tmruobj = TmruObj()
    let filenames0 = tmruobj.GetFilenames()
    let properties = s:AList2Dict(tmruobj.mru)
    let filenames1 = tlib#input#EditList('Edit MRU', filenames0)
    if filenames0 != filenames1
        let tmruobj.mru = map(filenames1, '[v:val, get(properties, v:val, {})]')
        call tmruobj.Save()
    endif
endf


function! s:AList2Dict(mru)
    let props = {}
    for item in a:mru
        let props[item[0]] = item[1]
    endfor
    return props
endf


function! tmru#EditFiles(filenames, ...) "{{{3
    if !empty(a:filenames)
        let tmruobj = a:0 >= 1 ? a:1 : TmruObj()
        let remove_files = []
        for bf in a:filenames
            " TLogVAR bf
            if !s:Edit(bf)
                call add(remove_files, bf)
            endif
        endfor
        if g:tmru#auto_remove_unreadable && !empty(remove_files)
            return !s:RemoveItems(remove_files, tmruobj)
        endif
    endif
    return 1
endf


" Return 0 if the file isn't readable/doesn't exist.
" Otherwise return 1.
function! s:Edit(filename) "{{{3
    let filename = fnamemodify(a:filename, ':p')
    if filename == expand('%:p')
        return 1
    else
        let bn = bufnr(filename)
        " TLogVAR bn
        if bn != -1 && buflisted(bn)
            if g:tmru#drop
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


function! s:RemoveItems(filenames, ...) "{{{3
    let modified_list = 0
    if !empty(a:filenames)
        let tmruobj = a:0 >= 1 ? a:1 : TmruObj()
        call tmruobj.Update()
        let filenames = tmruobj.GetFilenames()
        for bf in a:filenames
            let bi = tmruobj.FilenameIndex(filenames, bf)
            " TLogVAR bi
            if bi != -1
                call remove(tmruobj.mru, bi)
                let modified_list = 1
            endif
        endfor
        if modified_list
            call tmruobj.Save()
        endif
    endif
    return modified_list
endf


function! tmru#Session(session_no, mru) "{{{3
    " TLogVAR a:session_no
    let session_no = empty(a:session_no) ? 1 : str2nr(a:session_no)
    if session_no > 0
        let filenames = []
        for [filename, props] in a:mru
            " TLogVAR filename, props
            if index(get(props, 'sessions', []), session_no) != -1
                call add(filenames, filename)
            endif
        endfor
        call tmru#EditFiles(filenames)
    endif
endf


function! tmru#SetSessions(def) "{{{3
    let [filename, props] = a:def
    let sessions = get(props, 'sessions', [])
    if !empty(sessions)
        let sessions = map(sessions, 'v:val + 1')
        let sessions = filter(sessions, 'v:val <= g:tmru_sessions')
    endif
    if buflisted(filename)
        let sessions = insert(sessions, 1)
    endif
    if !empty(sessions)
        let a:def[1].sessions = sessions
    elseif has_key(props, 'sessions')
        call remove(a:def[1], 'sessions')
    endif
    return a:def
endf


function! tmru#DisplayUnreadableFiles(mru) "{{{3
    " TLogVAR a:mru
    for file in a:mru
        if !filereadable(file)
            echohl WarningMsg
            " echom "DBG TMRU: unreadable file:" file
            echohl NONE
        endif
    endfor
endf


" Validate list of filenames in mru list.
" This checks that files are readable and removes any (canonicalized)
" duplicates.
function! tmru#CheckFilenames(world, selected) "{{{3
    let tmruobj = TmruObj()
    let filenames = tmruobj.GetFilenames()
    let idx = len(tmruobj.mru) - 1
    let uniqdict = {} " used to remove duplicates
    let unreadable = 0
    let dupes = 0
    let normalized = 0
    while idx > 0
        let file_p = fnamemodify(filenames[idx], ':p')
        let file = substitute(substitute(file_p, '\\\+', '\', 'g'), '/\+', '/', 'g')
        if !filereadable(file)
            " TLogVAR file
            call remove(tmruobj.mru, idx)
            let unreadable += 1
        elseif get(uniqdict, file)
            " file is a dupe
            let dupes += 1
            call remove(tmruobj.mru, idx)
        else
            " file is OK, add it to dictionary for dupe checking
            let uniqdict[file] = 1
            if file_p != file
                let normalized += 1
                let tmruobj.mru[idx][0] = file
            endif
        endif
        let idx -= 1
    endwh
    if unreadable > 0 || dupes > 0 || normalized > 0
        call tmruobj.Save()
        echom "TMRU: Removed" unreadable "unreadable and" dupes "duplicate"
                    \ "files from mru list, and normalized" normalized "entries."
    endif
    call tmruobj.SetBase(a:world)
    let a:world.state = 'reset'
    return a:world
endf


function! tmru#RemoveItem(world, selected) "{{{3
    let tmruobj = TmruObj()
    let filenames = tmruobj.GetFilenames()
    " TLogVAR a:selected
    let idx = -1
    for filename in a:selected
        let fidx = tmruobj.FilenameIndex(filenames, filename)
        if idx < 0
            let idx = fidx
        endif
        " TLogVAR filename, fidx
        if fidx >= 0
            call remove(tmruobj.mru, fidx)
        endif
    endfor
    call tmruobj.Save()
    call a:world.ResetSelected()
    let a:world.base = tmruobj.GetFilenames()
    if idx > len(tmruobj.mru)
        let a:world.idx = len(tmruobj.mru)
    elseif idx >= 0
        let a:world.idx = idx
    endif
    " TLogVAR a:world.idx
    let a:world.state = 'display'
    return a:world
endf


function! tmru#Drop(world, selected) "{{{3
    let filename = a:selected[0]
    if bufnr(filename) != -1
        exec 'drop' fnameescape(filename)
    else
        call tmru#EditFiles([filename])
    endif
    let a:world.state = 'exit'
    return a:world
endf


function! tmru#UnsetPersistent(world, selected) "{{{3
    let tmruobj = TmruObj()
    let filenames = tmruobj.GetFilenames()
    for filename in a:selected
        let fidx = tmruobj.FilenameIndex(filenames, filename)
        " TLogVAR filename, fidx
        if fidx >= 0
            let tmruobj.mru[fidx][1]['sticky'] = 0
        endif
    endfor
    call tmruobj.Save()
    call tmruobj.SetBase(a:world)
    let a:world.state = 'reset'
    return a:world
endf


function! tmru#TogglePersistent(world, selected) "{{{3
    let tmruobj = TmruObj()
    let filenames = tmruobj.GetFilenames()
    let msgs = []
    for filename in a:selected
        let fidx = tmruobj.FilenameIndex(filenames, filename)
        " TLogVAR filename, fidx
        if fidx >= 0
            let props = tmruobj.mru[fidx][1]
            let props['sticky'] = !get(props, 'sticky', 0)
            call add(msgs, printf('Mark %ssticky: %s', props.sticky ? '' : 'not ', filename))
            let tmruobj.mru[fidx][1] = props
        endif
    endfor
    if !empty(msgs)
        echom join(msgs, "\n")
        echohl MoreMsg
        call input("Press ENTER to continue")
        echohl NONE
    endif
    call tmruobj.Save()
    call tmruobj.SetBase(a:world)
    let a:world.state = 'reset'
    return a:world
endf


function! tmru#PreviousSession(world, selected) "{{{3
    let sessions_done = []
    let tmruobj = TmruObj()
    let filenames = tmruobj.GetFilenames()
    for filename in a:selected
        let fidx = tmruobj.FilenameIndex(filenames, filename)
        if fidx >= 0
            let props = tmruobj.mru[fidx][1]
            if has_key(props, 'sessions')
                let sessions = copy(props.sessions)
                let sessions = filter(sessions, 'index(sessions_done, v:val) == -1')
                if empty(sessions)
                    let session = 0
                elseif len(sessions) == 1
                    let session = sessions[0]
                else
                    let session = tlib#input#List('s', 'Select session:', sessions)
                endif
                if session > 0
                    if empty(sessions_done)
                        call a:world.CloseScratch()
                    endif
                    call add(sessions_done, session)
                    exec 'TRecentlyUsedFilesSessions' session
                endif
            endif
        endif
    endfor
    if empty(sessions_done)
        let a:world.state = 'redisplay'
    else
        let a:world.state = 'exit'
    endif
    return a:world
endf



