" tmru.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2011-04-10.
" @Last Change: 2011-08-24.
" @Revision:    10


function! tmru#Session(defs, session_no) "{{{3
    " TLogVAR a:session_no
    let [mru, metadata] = a:defs
    for idx in range(len(mru))
        let metaitem = metadata[idx]
        let session_no = get(metaitem, 'sessions', -1)
        " TLogVAR idx, session_no
        if session_no == a:session_no
            let filename = mru[idx]
            call TmruEdit(filename)
        endif
    endfor
endf


function! tmru#DisplayUnreadableFiles(mru) "{{{3
    " TLogVAR a:mru
    for file in a:mru
        if !filereadable(file)
            echohl WarningMsg
            echom "DBG TMRU: unreadable file:" file
            echohl NONE
        endif
    endfor
endf

