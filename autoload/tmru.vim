" tmru.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2011-04-10.
" @Last Change: 2014-07-07.
" @Revision:    322


if !exists('g:tmru#set_filename_indicators')
    let g:tmru#set_filename_indicators = 1   "{{{2
endif


if !exists('g:tmru#sessions_len')
    " Remember at most N sessions per file.
    let g:tmru#sessions_len = 3   "{{{2
endif


if !exists('g:tmru#world') "{{{2
    "                                       *g:tmru_world* *b:tmru_world*
    " If the variables b:tmru_world or g:tmru_world exist, they are used 
    " to extend the value of g:tmru#world.
    let g:tmru#world = {
                \ 'type': 'm',
                \ 'scratch': '__TMRU__',
                \ 'key_handlers': [
                \ {'key': 3,  'agent': 'tlib#agent#CopyItems',        'key_name': '<c-c>', 'submenu': 'Edit', 'help': 'Copy file name(s)'},
                \ {'key': 6,  'agent': 'tmru#CheckFilenames',     'key_name': '<c-f>', 'submenu': 'Edit', 'help': 'Check file name(s)'},
                \ {'key': "\<del>", 'agent': 'tmru#RemoveItem',   'key_name': '<del>', 'submenu': 'Edit', 'help': 'Remove file name(s)'},
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
            let g:tmru#world.key_handlers += [
                        \ {'key': 12, 'agent': 'tmru#PreviousSession',    'key_name': '<c-l>', 'submenu': 'Sessions', 'help': 'Open files from a session'},
                        \ {'key': '<2-12>', 'agent': 'tmru#OpenNamedSession',  'key_name': '<c-s-l>', 'submenu': 'Sessions', 'help': 'Open a named session'},
                        \ {'key': 28, 'agent': 'tmru#SelectNamedSession',  'key_name': '<c-#>', 'submenu': 'Sessions', 'help': '(Un-)Select a named session'},
                        \ {'key': 29, 'agent': 'tmru#AddNamedSession',    'key_name': '<c-+>', 'submenu': 'Sessions', 'help': 'Add files to a session'},
                        \ {'key': 31, 'agent': 'tmru#RemoveNamedSession', 'key_name': '<c-->', 'submenu': 'Sessions', 'help': 'Remove files from a session'},
                        \ {'key': 5,  'agent': 'tmru#EditNamedSessions',  'key_name': '<c-e>', 'submenu': 'Sessions', 'help': 'Edit named sessions'},
                        \ ]
        endif
        call add(g:tmru#world.key_handlers,
                    \ {'key': 16, 'agent': 'tmru#TogglePersistent',   'key_name': '<c-p>', 'submenu': 'Sticky', 'help': 'Toggle a file''s persistent mark'})
        call add(g:tmru#world.key_handlers,
                    \ {'key': 21, 'agent': 'tmru#UnsetPersistent',   'key_name': '<c-u>', 'submenu': 'Sticky', 'help': 'Unset a file''s persistent mark'})
    endif
    if exists('g:tmru_world')
        let g:tmru#world = extend(g:tmru#world, g:tmru_world)
    endif
endif


if !exists('g:tmru_select_filter')
    " If non-empty, an expression to |filter()| the list of files.
    " Can also be buffer-local.
    let g:tmru_select_filter = ''   "{{{2
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
        let w0 = exists('b:tmru_world') ? extend(copy(g:tmru#world), b:tmru_world) : g:tmru#world
        let world = tlib#World#New(w0)
        call world.Set_display_format('filename')
        " TLogDBG "SelectMRU#3"
        call tmruobj.SetBase(world)
        let select_filter = tlib#var#Get('tmru_select_filter', 'bg')
        if !empty(select_filter)
            let world.base = filter(world.base, select_filter)
        endif
        let stickyn = len(filter(copy(tmruobj.mru), 'get(v:val[1], "sticky", 0)'))
        if stickyn < len(tmruobj.mru)
            let stickyn += 1
        endif
        let world.initial_index = stickyn
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
        " TLogVAR a:filenames
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
    " TLogVAR a:filenames
    let modified_list = 0
    if !empty(a:filenames)
        let tmruobj = a:0 >= 1 ? a:1 : TmruObj()
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


function! s:IsNamedSession(session) "{{{3
    return a:session =~ '\D'
endf


function! tmru#Session(session_no, mru) "{{{3
    if empty(a:session_no)
        let session = 1
        let opt = 'sessions'
    elseif s:IsNamedSession(a:session_no)
        let session = a:session_no
        let opt = 'sessionnames'
    else
        let session = str2nr(a:session_no)
        let opt = 'sessions'
    endif
    " TLogVAR a:session_no, session, opt
    if !empty(session)
        let filenames = []
        for [filename, props] in a:mru
            " TLogVAR filename, props
            if index(get(props, opt, []), session) != -1
                call add(filenames, filename)
            endif
        endfor
        " TLogVAR filenames
        call tmru#EditFiles(filenames)
    endif
endf


function! tmru#Leave() "{{{3
    let tmruobj = TmruObj()
    let filenames = tmruobj.GetFilenames()
    let mru = deepcopy(tmruobj.mru)
    let modified = []
    for bufnr in range(1, bufnr('$'))
        if buflisted(bufnr)
            let bufname = fnamemodify(bufname(bufnr), ':p')
            let [idx, item] = tmruobj.Find(bufname)
            if idx != -1
                let item1 = s:SetSessions(item, 1)
                let mru[idx] = item1
                " TLogVAR item1
                call add(modified, idx)
            endif
        endif
    endfor
    " TLogVAR modified
    for idx in range(len(filenames))
        if index(modified, idx) == -1
            let mru[idx] = s:SetSessions(mru[idx], 0)
        endif
    endfor
    let tmruobj.mru = mru
    call tmruobj.Save({'exit': 1})
endf


function! s:SetSessions(item, buflisted) "{{{3
    let [filename, props] = a:item
    let sessions = get(props, 'sessions', [])
    if !empty(sessions)
        let sessions = map(sessions, 'v:val + 1')
        let sessions = filter(sessions, 'v:val <= g:tmru_sessions')
    endif
    if a:buflisted
        let sessions = insert(sessions, 1)
    endif
    if g:tmru#sessions_len > 0
        let sessions = sessions[0 : g:tmru#sessions_len - 1]
    endif
    if !empty(sessions)
        let a:item[1].sessions = sessions
    elseif has_key(props, 'sessions')
        call remove(a:item[1], 'sessions')
    endif
    return a:item
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
        " TLogVAR filename
        call tmru#EditFiles([filename])
    endif
    let a:world.state = 'exit'
    return a:world
endf


function! tmru#UnsetPersistent(world, selected) "{{{3
    let tmruobj = TmruObj()
    let mru = tmruobj.mru
    let filenames = tmruobj.GetFilenames()
    for filename in a:selected
        let [oldpos, item] = TmruGetItem(tmruobj, filename)
        let item[1]['sticky'] = 0
        let [must_update, tmruobj.mru] = TmruInsert(tmruobj, oldpos, item)
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
        let [oldpos, item] = TmruGetItem(tmruobj, filename)
        let item[1]['sticky'] = !get(item[1], 'sticky', 0)
        call add(msgs, printf('Mark %ssticky: %s', item[1]['sticky'] ? '' : 'not ', filename))
        let [must_update, tmruobj.mru] = TmruInsert(tmruobj, oldpos, item)
        let fidx = tmruobj.FilenameIndex(filenames, filename)
        " TLogVAR filename, fidx
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
            if has_key(props, 'sessions') || has_key(props, 'sessionnames')
                let sessions = get(props, 'sessions', []) + get(props, 'sessionnames', [])
                " TLogVAR sessions
                let sessions = filter(sessions, 'index(sessions_done, v:val) == -1')
                " TLogVAR sessions
                if empty(sessions)
                    let session = 0
                elseif len(sessions) == 1
                    let session = sessions[0]
                else
                    let session = tlib#input#List('s', 'Select session:', sessions)
                endif
                " TLogVAR session
                if !empty(session)
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


function! tmru#SelectNamedSession(world, selected) "{{{3
    let sessionnames = tmru#SessionNames()
    let session = tlib#input#List('s', 'Select session:', sessionnames)
    if !empty(session)
        let tmruobj = TmruObj()
        let filenames = []
        for item in tmruobj.mru
            let names = get(get(item, 1, {}), 'sessionnames', [])
            if index(names, session) != -1
                call add(filenames, item[0])
            endif
        endfor
        " TLogVAR filenames
        if !empty(filenames)
            call a:world.SelectItemsByNames('toggle', filenames)
        endif
        let a:world.state = 'display'
    else
        let a:world.state = 'redisplay'
    endif
    return a:world
endf


function! tmru#OpenNamedSession(world, selected) "{{{3
    let sessionnames = tmru#SessionNames()
    let session = tlib#input#List('s', 'Select session:', sessionnames)
    if !empty(session)
        call a:world.CloseScratch()
        exec 'TRecentlyUsedFilesSessions' session
        let a:world.state = 'exit'
    else
        let a:world.state = 'redisplay'
    endif
    return a:world
endf


function! tmru#SessionNames(...) "{{{3
    if a:0 == 3
        let [ArgLead, CmdLine, CursorPos] = a:000
    else
        let [ArgLead, CmdLine, CursorPos] = ['', '', 0]
    endif
    let tmruobj = TmruObj()
    let filenames = exists('s:sessionnames_filenames') ? s:sessionnames_filenames : []
    let mru = tmruobj.mru
    if empty(mru)
        let sessionnames = []
    else
        if empty(filenames)
            let sessionnames = map(range(len(mru)), 'get(get(mru[v:val], 1, {}), "sessionnames", [])')
        else
            let items = filter(copy(mru), 'index(filenames, v:val[0]) != -1')
            let sessionnames = map(items, 'get(get(v:val, 1, {}), "sessionnames", [])')
        endif
        let sessionnames = tlib#list#Flatten(sessionnames)
        let sessionnames = tlib#list#Uniq(sessionnames)
        if !empty(ArgLead)
            let sessionnames = filter(sessionnames, 'stridx(v:val, ArgLead) != -1')
        endif
    endif
    return sessionnames
endf


function! tmru#AddNamedSession(world, selected) "{{{3
    let sessionname = input('Add session name(s): ', '', 'customlist,tmru#SessionNames')
    if !empty(sessionname)
        let tmruobj = TmruObj()
        let add_sessionnames = split(sessionname, '\s*,\s*')
        let tmruobj.mru = map(tmruobj.mru, 's:AddOrRemoveNamedSession(v:val, a:selected, add_sessionnames, [])')
        call tmruobj.Save()
        call tmruobj.SetBase(a:world)
        let a:world.state = 'reset'
    else
        let a:world.state = 'redisplay'
    endif
    return a:world
endf


function! tmru#RemoveNamedSession(world, selected) "{{{3
    let s:sessionnames_filenames = a:selected
    try
        let sessionname = input('Remove session name(s): ', '', 'customlist,tmru#SessionNames')
    finally
        unlet s:sessionnames_filenames
    endtry
    if !empty(sessionname)
        let tmruobj = TmruObj()
        let remove_sessionnames = split(sessionname, '\s*,\s*')
        let tmruobj.mru = map(tmruobj.mru, 's:AddOrRemoveNamedSession(v:val, a:selected, [], remove_sessionnames)')
        call tmruobj.Save()
        call tmruobj.SetBase(a:world)
        let a:world.state = 'reset'
    else
        let a:world.state = 'redisplay'
    endif
    return a:world
endf


function! s:AddOrRemoveNamedSession(item, filenames, add_sessionnames, remove_sessionnames) "{{{3
    if index(a:filenames, a:item[0]) != -1
        let props = get(a:item, 1, {})
        let sessionnames0 = get(props, 'sessionnames', [])
        let sessionnames1 = tlib#list#Uniq(sessionnames0 + a:add_sessionnames)
        for name in a:remove_sessionnames
            let idx = index(sessionnames1, name)
            if idx != -1
                call remove(sessionnames1, idx)
            endif
        endfor
        if empty(sessionnames1)
            if has_key(props, 'sessionnames')
                call remove(props, 'sessionnames')
                let a:item[1] = props
            endif
        elseif sessionnames1 != sessionnames0
            let props.sessionnames = sessionnames1
            let a:item[1] = props
        endif
    endif
    return a:item
endf


function! tmru#EditNamedSessions(world, selected) "{{{3
    let tmruobj = TmruObj()
    let tmruobj.mru = map(tmruobj.mru, 's:EditNamedSessions(v:val, a:selected)')
    call tmruobj.Save()
    call tmruobj.SetBase(a:world)
    let a:world.state = 'reset'
    return a:world
endfun


function! s:EditNamedSessions(item, filenames) "{{{3
    if index(a:filenames, a:item[0]) != -1
        let filename = fnamemodify(a:item[0], ':t')
        let props = get(a:item, 1, {})
        let sessionnames0 = get(props, 'sessionnames', [])
        let sessionnames = join(sessionnames0, ', ')
        let prompt = printf("%s session names: ", filename)
        let sessionnames = input(prompt, sessionnames)
        if empty(sessionnames) && has_key(props, 'sessionnames')
            call remove(props, 'sessionnames')
        else
            let props.sessionnames = split(sessionnames, '\s*,\s*')
        endif
        let a:item[1] = props
    endif
    return a:item
endf


function! tmru#SetFilenameIndicators(world, mru) "{{{3
    if g:tmru#set_filename_indicators
        let a:world.filename_indicators = {}
        let idx = 0
        for item in a:mru
            let [filename, props] = item
            let indicators = []
            if get(props, 'sticky', 0)
                call add(indicators, "s")
            endif
            let sessions = get(props, 'sessions', []) + get(props, 'sessionnames', [])
            if !empty(sessions)
                call add(indicators, '-'. join(sessions, g:tmru_sessions < 10 ? '' : '-'))
            endif
            if !empty(indicators)
                let fname = g:tmru#display_relative_filename ? a:world.base[idx] : filename
                " TLogVAR fname, indicators
                let a:world.filename_indicators[fname] = join(indicators, '')
            endif
            let idx += 1
        endfor
    endif
endf


