" tmru.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2011-04-10.
" @Last Change: 2011-08-24.
" @Revision:    25


function! tmru#Session(session_no, mru) "{{{3
    " TLogVAR a:session_no
    let session_no = empty(a:session_no) ? 1 : str2nr(a:session_no)
    if session_no > 0
        for [filename, props] in a:mru
            " TLogVAR filename, props
            if get(props, 'session', 0) == session_no
                call TmruEdit(filename)
            endif
        endfor
    endif
endf


function! tmru#SetSessions(def) "{{{3
    let [filename, props] = a:def
    let session = get(props, 'session', 0)
    if buflisted(filename)
        let session += 1
    endif
    if session > 0 && session <= g:tmru_sessions
        let a:def[1].session = session
    elseif has_key(props, 'session')
        call remove(a:def[1], 'session')
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

