"------------------------------------------------------------------------------

fun! do#git#blame_line(cmline, ...)
  if !executable('awk')
    return do#msg('awk executable is needed')
  endif
  let file = expand("%")
  let line = line('.').",".line('.')
  let short = a:cmline ? '-s --abbrev-commit ' : ''
  let format = a:0 ? a:1 : short
  let str = system("git show " . format . "$(git blame " .
        \ file . " -L " . line . " | awk '{print $1}')")
  if a:cmline || v:shell_error
    call s:echo_blame(str)
  else
    let line = '\V'.escape(getline('.'), '\')
    new
    wincmd H
    put = str
    setf git
    normal! ggdd
    nnoremap <buffer><nowait><silent> q :q!<cr>:nohlsearch<cr>
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    set foldmethod=syntax
    keeppatterns let @/ = line
    call matchadd('Search', line)
    silent! normal! zmnzogg
  endif
endfun

"------------------------------------------------------------------------------

fun! s:echo_blame(str)
  let msg = split(a:str, '\n')
  if match(msg[0], 'fatal') == 0
    echohl ErrorMsg | echo 'fatal'
    echohl None     | echon msg[0][6:]
    return
  endif
  for l in msg[:2]
    let first = match(l, '\s\|:') - 1
    echohl PreProc  | echo l[:first]
    echohl None     | echon l[first+1:]
  endfor
  echo "\n"
  for l in msg[3:]
    echo l
  endfor
  echo ""
endfun

