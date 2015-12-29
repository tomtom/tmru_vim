" tmru.vim -- Most Recently Used Files
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tlib-mru)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-12-29.
" @Revision:    1056
" GetLatestVimScripts: 1864 1 tmru.vim

if &cp || exists("loaded_tmru")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 114
    echoerr "tlib >= 1.14 is required"
    finish
endif
let loaded_tmru = 104

let s:save_cpo = &cpo
set cpo&vim


if has('clientserver') && exists('v:servername')
    if !exists('g:tmruIgnoreServernamesRx')
        " Don't load the tmru plugin for VIM servers (requires 
        " |clientserver|) matching this |regexp|.
        let g:tmruIgnoreServernamesRx = '^_LIKELYCOMPLETE_$'   "{{{2
    endif
    if v:servername =~ g:tmruIgnoreServernamesRx
        let loaded_tmru = -1
        finish
    endif
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


if !exists('g:tmru_sessions')
    " If greater than zero, make tmru to save the file list opened when 
    " closing vim. Save at most information for the N latest sessions.
    "
    " Setting this variable to 0, disables this feature.
    "
    " This variable must be set before starting vim.
    let g:tmru_sessions = 9   "{{{2
endif


if !exists('g:tmru#display_relative_filename')
    " If true, display the relative filename.
    "
    " If this options is used with |g:tlib#input#format_filename| set to 
    " "l", |g:tlib_inputlist_filename_indicators| doesn't work.
    let g:tmru#display_relative_filename = 0   "{{{2
endif


if !exists('g:tmru_single_instance_mode')
    " If true, work as if only one instance of vim is running. This 
    " results in reading and writing the mru list less frequently 
    " from/to disk. The list won't be synchronized across multiple 
    " instances of vim running in parallel.
    let g:tmru_single_instance_mode = 0   "{{{2
endif


if !exists('g:tmru_eager_save')
    " If true, save the mru list more often.
    "
    " If you run multiple instances of vim, synchronization of mru lists 
    " relies on |FocusGained| and |FocusLost| events but this probably 
    " does not work in all circumstances.
    let g:tmru_eager_save = !g:tmru_single_instance_mode && !has('gui_running')   "{{{2
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
    " save ....... If true, save mru list to disk
    "
    " :read: let g:tmru_events = {...} "{{{2
    if exists('g:tmruEvents')  " backwards compatibility
        if type(g:tmruEvents) == 1
            let g:tmru_events = {}
            for s:ev in g:tmruEvents
                let g:tmru_events[s:ev] = {'load': 0, 'register': 1, 'save': 0}
            endfor
            unlet s:ev
        else
            let g:tmru_events = map(g:tmruEvents, "{'load': 0, 'register': 1, 'save': v:val}")
        endif
        unlet g:tmruEvents
    else
        let g:tmru_events = {
                    \ 'VimLeave':     {'load': 0, 'register': 0, 'save': 1, 'exit': 1},
                    \ 'FocusGained':  {'load': !g:tmru_single_instance_mode, 'register': 0, 'save': 0},
                    \ 'FocusLost':    {'load': 0, 'register': 0, 'save': !g:tmru_single_instance_mode},
                    \ 'BufWritePost': {'load': 0, 'register': 1, 'save': g:tmru_eager_save},
                    \ 'BufReadPost':  {'load': 0, 'register': 1, 'save': g:tmru_eager_save},
                    \ 'BufWinEnter':  {'load': 0, 'register': 1, 'save': g:tmru_eager_save},
                    \ 'BufEnter':     {'load': 0, 'register': 1, 'save': g:tmru_eager_save},
                    \ 'BufDelete':    {'load': 0, 'register': 1, 'save': g:tmru_eager_save}
                    \ }
    endif
endif


if !exists('g:tmru_resolve_method')
    " When running multiple instances of vim, there is a possibility of 
    " synchronization conflicts when two instances want to update the 
    " mru list.
    "
    " Possible values:
    "
    "   write .... The current instance of vim overwrites the mru list.
    "   read ..... The current instance of vim reads the mru list from 
    "              disk.
    "
    " If empty, query the user what to do.
    let g:tmru_resolve_method = 'write'   "{{{2
endif


if !exists("g:tmru_file")
    " Where to save the file list. The default value is only 
    " effective, if 'viminfo' doesn't contain '!' -- in which case 
    " the 'viminfo' will be used.
    "
    " CAUTION: The use of viminfo may result in various problems 
    " when you run several instances of vim at once.
    let g:tmru_file = tlib#persistent#Filename('tmru', 'files', 1) "{{{2
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
    " This includes 'wildignore'.
    " :read: let g:tmruExclude = '/te\?mp/\|vim.\{-}/\(doc\|cache\)/\|__.\{-}__$' "{{{2
    let g:tmruExclude = s:PS . '[Tt]e\?mp' . s:PS
                \ . '\|' . s:PS . '\(vimfiles\|\.vim\)' . s:PS . '\(doc\|cache\)' . s:PS
                \ . '\|\.tmp$'
                \ . '\|'. s:PS .'.git'. s:PS .'\(COMMIT_EDITMSG\|git-rebase-todo\)$'
                \ . '\|'. s:PS .'quickfix$'
                \ . '\|__.\{-}__$'
                \ . '\|^fugitive:'
                \ . '\|/truecrypt\d\+/'
                \ . '\|\(\~\|\.o\|\.swp\|\.obj\)$'  " based on Vim's default for 'suffixes'.
                \ . '\|' . substitute(escape(&wildignore, '~.*$^'), '\\\@<!,', '$\\|', 'g') .'$' " &wildignore, ORed (split on (not escaped) comma).
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


let s:tmru_must_save = 0
let s:tmruobj_prototype = {}


function! s:tmruobj_prototype.MustLoad(...) dict
    let must_load = a:0 >= 1 ? a:1 : 0
    " TLogVAR 1, must_load
    if !empty(g:tmru_file)
        if must_load
            if exists('s:tmru_mtime') && getftime(g:tmru_file) == s:tmru_mtime
                let must_load = 0
            endif
        elseif !exists('s:tmru_mtime') || getftime(g:tmru_file) != s:tmru_mtime
            let must_load = 1
        endif
    endif
    if must_load && s:tmru_must_save
        let resolve = g:tmru_resolve_method
        if empty(resolve)
            echom "TMRU: Another instance of VIM updated the mru list"
            let resolvei = inputlist('Resolve synchronization conflict:', '1. Write', '2. read')
            let resolve = resolvei == 2 ? 'r' : 'w'
        endif
        if g:tmru_resolve_method =~ '^w\%[rite]$'
            let must_load = 0
            call self.Save()
        elseif g:tmru_resolve_method =~ '^r\%[ead]$'
            let s:tmru_must_save = 0
            " echom "DBG MustLoad tmru_must_save" s:tmru_must_save
        endif
    endif
    " TLogVAR 2, must_load
    return must_load
endf


function! s:tmruobj_prototype.Load() dict
    " TLogDBG "Load"
    if empty(g:tmru_file)
        if exists("g:TMRU")
            if g:tmru_update_viminfo
                " TLogVAR g:tmru_update_viminfo
                rviminfo
            endif
        endif
        if !exists("g:TMRU")
            let g:TMRU = ''
        endif
        let s:tmru_list = map(split(g:TMRU, '\n'), '[v:val, {}]')
    else
        " TLogVAR g:tmru_file
        if s:tmru_must_save
            echohl WarningMsg
            echohl "TMRU: Internal error: Synchronization error (Please report)"
            echohl NONE
        endif
        let data = tlib#persistent#Get(g:tmru_file)
        let s:tmru_mtime = getftime(g:tmru_file)
        if get(data, 'version', 0) == 0
            let s:tmru_list = map(split(get(data, 'tmru', ''), '\n'), '[v:val, {}]')
        else
            let s:tmru_list = get(data, 'tmru', [])
        endif
    endif
    let s:last_auto_filename = ''
    " echom "DBG Load tmru_must_save" s:tmru_must_save
    let s:tmru_must_save = 0
    let self.mru = s:tmru_list
endf


function! s:tmruobj_prototype.GetFilenames() dict
    return map(copy(self.mru), 'v:val[0]')
endf


function! s:tmruobj_prototype.Save(...) dict
    let props = a:0 >= 1 ? a:1 : {}
    " TLogVAR props
    let tmru_list = self.mru
    " echom "DBG Save must_save" s:tmru_must_save
    if s:tmru_must_save || get(props, 'must_update', 0)
        if len(tmru_list) > g:tmruSize
            let tmru_list = tmru_list[0 : g:tmruSize - 1]
        endif
        let s:tmru_list = deepcopy(tmru_list)
        " TLogVAR g:tmru_file
        if empty(g:tmru_file)
            " TLogVAR g:TMRU
            if g:tmru_update_viminfo
                let g:TMRU = join(map(s:tmru_list, 'v:val[0]'), "\n")
                wviminfo
            endif
        else
            call tlib#persistent#Save(g:tmru_file, {'version': 1, 'tmru': s:tmru_list})
            let s:tmru_mtime = getftime(g:tmru_file)
            " echom "DBG Save tmru_mtime" s:tmru_mtime
        endif
        let s:tmru_must_save = 0
    endif
endf


function! s:tmruobj_prototype.Find(filename) dict
    let filename = s:NormalizeFilename(a:filename)
    let idx = 0
    for item in self.mru
        if item[0] == filename
            return [idx, item]
        endif
        let idx += 1
    endfor
    return [-1, []]
endf


function! s:tmruobj_prototype.Set(idx, item) dict
    let self.mru[a:idx] = a:item
endf


function! s:tmruobj_prototype.Get(idx) dict
    return self.mru[a:idx]
endf


function! s:tmruobj_prototype.SetBase(world) dict
    let a:world.base = self.GetFilenames()
    if g:tmru#display_relative_filename
        let basedir = getcwd()
        let a:world.base = map(a:world.base, 'tlib#file#Relative(v:val, basedir)')
    endif
    call tmru#SetFilenameIndicators(a:world, self.mru)
endf


function! s:tmruobj_prototype.FilenameIndex(filenames, filename) "{{{3
    return index(a:filenames, a:filename, 0, g:tmru_ignorecase)
endf


function! TmruObj(...) "{{{3
    if !exists('s:tmruobj_global')
        let s:tmruobj_global = copy(s:tmruobj_prototype)
        let must_load = 1
    else
        let must_load = call(s:tmruobj_global.MustLoad, a:000, s:tmruobj_global)
    endif
    if must_load
        call s:tmruobj_global.Load()
    endif
    return s:tmruobj_global
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
            exec 'amenu '. g:tmruMenu . me .' :call tlib#file#Edit('. string(e) .')<cr>'
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


let s:last_auto_filename = ''

function! s:HandleEvent(filename, event, props) "{{{3
    " TLogVAR a:filename, a:event, a:props, &buftype
    let tmruobj = TmruObj(get(a:props, 'load', 0))
    if !empty(a:filename)
        " TLogVAR a:filename, a:event, a:props, &buftype
        " echom "DBG register" get(a:props, 'register', 1) (s:last_auto_filename != a:filename)
        if get(a:props, 'register', 1) && s:last_auto_filename != a:filename
            " TLogVAR "Consider", a:filename
            if getbufvar(a:filename, '&buflisted') &&
                        \ getbufvar(a:filename, '&buftype') !~ 'nofile' &&
                        \ (g:tmru_check_disk ?
                        \     (filereadable(a:filename) && !isdirectory(a:filename)) :
                        \     fnamemodify(a:filename, ":t") != '')
                let s:last_auto_filename = a:filename
                call s:MruRegister(tmruobj, a:filename, a:props)
            endif
        endif
        " echom "DBG HandleEvent must_save" s:tmru_must_save
    endif
    " echom "DBG HandleEvent" get(a:props, 'save', 1) s:tmru_must_save
    if s:tmru_must_save
        if !get(a:props, 'exit', 0)
            call s:BuildMenu(0)
        endif
        if get(a:props, 'save', 1)
            call tmruobj.Save(a:props)
        endif
    endif
endf


function! s:MruRegister(tmruobj, filename, props)
    " TLogVAR a:filename, a:props
    let filename = s:NormalizeFilename(a:filename)
    if g:tmruExclude != '' && filename =~ g:tmruExclude
        if &verbose | echom "tmru: ignore file" filename | end
        return
    endif
    if exists('b:tmruExclude') && b:tmruExclude
        return
    endif
    let [oldpos, item] = TmruGetItem(a:tmruobj, filename)
    let [must_save, mru] = TmruInsert(a:tmruobj, oldpos, item)
    " TLogVAR must_save
    if must_save
        let a:tmruobj.mru = mru
        let s:tmru_must_save = 1
        " echom "DBG MruRegister tmru_must_save" s:tmru_must_save
    endif
endf


function! TmruGetItem(tmruobj, filename) "{{{3
    " TLogVAR a:filename
    let filenames = a:tmruobj.GetFilenames()
    let imru = a:tmruobj.FilenameIndex(filenames, a:filename)
    " TLogVAR imru
    if imru == -1
        let item = [a:filename, {}]
    else
        let item = get(a:tmruobj.mru, imru)
    endif
    " TLogVAR imru, item
    return [imru, item]
endf


function! TmruInsert(tmruobj, oldpos, item) "{{{3
    " TLogVAR a:oldpos, a:item
    " echom "DBG" get(a:item[1], "sticky", 0)
    let newpos = 0
    if !get(a:item[1], 'sticky', 0)
        for mruitem in a:tmruobj.mru
            " TLogVAR mruitem
            if get(mruitem[1], 'sticky', 0)
                let newpos += 1
            elseif mruitem[0] == a:item[0]
            else
                break
            endif
        endfor
    endif
    " TLogVAR newpos
    if a:oldpos == newpos
        return [0, a:tmruobj.mru]
    else
        let mru = copy(a:tmruobj.mru)
        if a:oldpos != -1
            if mru[a:oldpos] != a:item
                throw 'TMRU: Inconsistent state'
            endif
            call remove(mru, a:oldpos)
        endif
        call insert(mru, a:item, newpos)
        " TLogVAR imru
        return [mru != a:tmruobj.mru, mru]
    endif
endf


augroup tmru
    autocmd!
    if has('vim_starting')
        autocmd VimEnter * call s:BuildMenu(1)
        autocmd SessionLoadPost * call s:HandleEvent('', 'SessionLoadPost', {'load': 1})
    else
        call s:BuildMenu(1)
    endif
    for [s:event, s:props] in items(g:tmru_events)
        exec 'autocmd '. s:event .' * call s:HandleEvent(expand("<afile>:p"), '. string(s:event) .', '. string(s:props) .')'
    endfor
    unlet! s:event s:props
augroup END

for s:i in range(1, bufnr('$'))
    call s:HandleEvent(bufname(s:i), 'vimstarting', {'register': 1})
endfor
unlet! s:i


" Display the MRU list.
command! Tmru call tmru#SelectMRU()

" Edit the MRU list.
command! Tmruedit call tmru#EditMRU()

" (Re-)Load the MRU list.
command! Tmruload call s:HandleEvent('', 'Tmruload', {'load': 1})

" Save the MRU list to disk.
command! Tmrusave let s:tmru_must_save = 1 | call s:HandleEvent('', 'Tmrusave', {'save': 1})

if g:tmru_sessions > 0
    " Open files from a previous session (see |g:tmru_sessions|).
    " This command is only available if g:tmru_sessions > 0.
    "
    " With the optional bang [!], close (|:bdelete|) all previously 
    " opened buffers / windows / tabs.
    command! -nargs=? -bar -bang -complete=customlist,tmru#SessionNames Tmrusession call tmru#Session(<q-args>, TmruObj().mru, !empty("<bang>"))

    autocmd tmru VimLeave * call tmru#Leave()
endif


let &cpo = s:save_cpo
unlet s:save_cpo
