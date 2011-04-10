" tmru.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2011-04-10.
" @Last Change: 2011-04-10.
" @Revision:    5


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


