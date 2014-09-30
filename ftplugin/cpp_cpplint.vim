"
" C++ filetype plugin for running cpplint.py
" Language:     C++ (ft=cpp)
" Maintainer:   Thomas Chen <funorpain@gmail.com>
" Version:      Vim 7 (may work with lower Vim versions, but not tested)
"
" Code is borrowed from vim-flake8 and slightly modified.
"
" Only do this when not done yet for this buffer
"
" Running the Google cpplint.py code to validate the style according to:
" http://google-styleguide.googlecode.com/svn/trunk/cppguide.html
"
if exists("b:loaded_cpplint_ftplugin")
    finish
endif
let b:loaded_cpplint_ftplugin=1

let s:cpplint_cmd="cpplint.py"

" extensions

let s:cpplint_extensions="cc,h,cpp,cu,cuh"

if exists("g:cpplint_extensions")
    let s:cpplint_extensions=g:cpplint_extensions
endif

let s:cpplint_cmd_opts = ' --extensions=' . s:cpplint_extensions . ' '

if exists('g:cpplint_line_length')
    let s:cpplint_cmd_opts = s:cpplint_cmd_opts . ' --linelength=' . g:cpplint_line_length . ' '
endif

if !exists("*Cpplint()")
    function Cpplint()
        if !executable(s:cpplint_cmd)
            echoerr "File " . s:cpplint_cmd . " not found. Please install it first."
            return
        endif

        set lazyredraw   " delay redrawing
        cclose           " close any existing cwindows

        " store old grep settings (to restore later)
        let l:old_gfm=&grepformat
        let l:old_gp=&grepprg

        " write any changes before continuing
        if &readonly == 0
            update
        endif

        " perform the grep itself
        let &grepformat="%f:%l: %m"
        let &grepprg=s:cpplint_cmd . s:cpplint_cmd_opts . ' '
        silent! grep! %
        let has_results=1
        for va in getqflist()
            if va.text =~ "Total errors found: 0"
                let has_results=0
                break
            endif
        endfor

        " restore grep settings
        let &grepformat=l:old_gfm
        let &grepprg=l:old_gp

        " open cwindow
        if has_results
            execute 'belowright copen'
            setlocal wrap
            nnoremap <buffer> <silent> c :cclose<CR>
            nnoremap <buffer> <silent> q :cclose<CR>
        endif

        set nolazyredraw
        redraw!

        if has_results == 0
            " Show OK status
            hi Green ctermfg=green
            echohl Green
            echon "cpplint.py check OK (status: " . has_results . ')'
            echohl
        endif
    endfunction
endif

" Add mappings, unless the user didn't want this.
" The default mapping is registered under to <F7> by default, unless the user
" remapped it already (or a mapping exists already for <F7>)
if !exists("no_plugin_maps") && !exists("no_cpplint_maps")
    if !hasmapto('Cpplint(')
        noremap <buffer> <F7> :call Cpplint()<CR>
        noremap! <buffer> <F7> :call Cpplint()<CR>
    endif
endif
