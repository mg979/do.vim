" Redir {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:redir(input, is_var)
  if empty(a:input) | return s:msg('Canceled.') | endif
  call s:store_reg()
  redir @"
  if a:is_var
    silent! exe "echo ".a:input
  else
    silent! exe a:input
  endif
  redir END
  let out = copy(@")
  new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  silent! put! = out
  call s:restore_reg()
  nnoremap <buffer><nowait><silent> q :quit<cr>:redraw!<cr>
  call s:msg("q: close buffer", 1)
endfun

fun! do#redir_expression(...)
  if a:0 | let var = a:1
  else   | let var = input('RedirExpression > ', '', 'expression') | endif
  call s:redir(var, 1)
endfun

fun! do#redir_cmd(...)
  let cmd = join(a:000, ' ')
  call s:redir(cmd, 0)
endfun


" Diff commands {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:diffed_buffers = []

fun! s:get_current_file()
  let s:T = tabpagenr()
  let f = expand("%:p")
  let s:filetype = &ft
  return f
endfun

fun! s:Tab()
  call s:diff_unmap()
  tabclose
  return s:T
endfun

fun! s:diff_map()
  diffthis
  call add(s:diffed_buffers, (bufnr("%")))
  nnoremap <buffer><silent><nowait> q :exe "normal! ".<sid>Tab()."gt"<cr>
  nnoremap <buffer><silent><nowait> ] ]c
  nnoremap <buffer><silent><nowait> [ [c
  nnoremap <buffer><silent><nowait> do do
  nnoremap <buffer><silent><nowait> dp dp
endfun

fun! s:diff_unmap()
  for buf in s:diffed_buffers
    silent! exe "b ".buf
    silent! unmap <buffer> q
    silent! unmap <buffer> ]
    silent! unmap <buffer> [
    silent! unmap <buffer> do
    silent! unmap <buffer> dp
    diffoff
  endfor
  let s:diffed_buffers = []
endfun

fun! do#diff_with_other()
  let bufs = tabpagebuflist()
  if len(bufs) < 2
    return s:msg("There must be at least 2 buffers in the tab page")
  endif
  let f = s:get_current_file()
  let buf1 = bufnr("%")
  wincmd w
  let f2 = s:get_current_file()
  let buf2 = bufnr("%")
  wincmd p
  if f == f2
    return do#diff_with_saved()
  endif
  let was_left = index(bufs, buf1) < index(bufs, buf2)
  exe "tabedit" f
  call s:diff_map()
  exe ( was_left ? "rightbelow " : "" ) . "vs " . f2
  call s:diff_map()
  wincmd p
  redraw!
  call s:msg("q: back, ]: next change, [: previous change, do: diffget, dp: diffput", 1)
endfun

fun! do#diff_last_revision()
  if !exists('g:loaded_fugitive') | return s:msg("vim-fugitive is needed.") | endif
  let f = s:get_current_file()

  if empty(FugitiveStatusline()) | return s:msg("not a git repo.")
  elseif !s:is_tracked(f)        | return s:msg("not a tracked file.") | endif

  exe "tabedit" f
  call s:diff_map()
  Gvdiff
  wincmd w
  call s:diff_map()
  wincmd h
  if expand("%:p") != f
    wincmd x
  endif
  redraw!
  call s:msg("q: back, ]: next change, [: previous change, do: diffget, dp: diffput", 1)
endfun

fun! do#diff_with_saved()
  let f = s:get_current_file()
  exe "tabedit" f
  call s:diff_map()
  vnew | exe "r" f | normal! 1Gdd
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . s:filetype
  call s:diff_map()
  wincmd x
  redraw!
  call s:msg("q: back, ]: next change, [: previous change", 1)
endfun


" Other {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#profiling()
  for b in range(1, bufnr('$'))
    if getbufvar(b, '&modified')
      return s:msg("There are unsaved buffers, aborting.")
    endif
  endfor
  if !exists('s:profiling_active')
    call s:msg("Profiling activated", 1)
    let s:profiling_active = 1
    if has('nvim')
      profile start nprofile.log
    else
      profile start profile.log
    endif
    profile func *
    profile file *
  else
    profile pause
    noautocmd qall
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#trim_whitespaces()
  let pos = getpos(".")
  keeppatterns silent! %s/\s\+$//e
  call setpos('.', pos)
  call s:msg("Trimmed trailing whitespaces", 1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#update_tags()
  let error = system("ctags -R .")
  if empty(error)
    call s:msg("Tags updated.", 1)
  else
    call s:msg(error)
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#show_all_dos(...)
  if index(['n', 'v', 'V', ''], mode()) < 0
    return
  endif

  if !a:0 || empty(a:1)         "default group (do...)
    let group = g:vimdo.do
    let pre = 'do'
    let pat = 'do'

  else                          "other groups
    let group = has_key(g:vimdo, a:1) ? g:vimdo[a:1] : {}
    let pre = a:1
    let pat = escape(pre, '\')
    let pat = escape(pat, '\')
  endif

  let sep = s:repeat_char('-')
  let lab = has_key(group, 'label') ?  pre."\t\t".group.label : pre
  let mode = mode() == 'n' ? 'n' : 'x'
  let cmd = mode.'map '.pre
  let require_desc = has_key(group, 'require_description') && group.require_description

  redir => dos
  silent! exe cmd
  redir END

  let dos = split(dos, '\n')
  for i in range(len(dos))
    let dos[i] = substitute(dos[i], 'n  ', '', '')
    let dos[i] = substitute(dos[i], '\s.*', '', '')
  endfor
  call filter(dos, 'v:val =~ "^'.pat.'\\S"')
  if empty(dos) | return s:msg("No do's") | endif
  let D = {}
  for do in dos
    let d = maparg(do, mode, 0, 1)
    if match(d.rhs, '^:call do#show_all_dos') == 0
      continue
    endif
    let key = do[strchars(pre):]
    let desc = has_key(group, key) ? group[key] : ''
    if empty(desc) && require_desc | continue | endif
    let D[key] = [desc, d.rhs]
  endfor
  echohl None           | echo sep
  echohl WarningMsg     | echo lab
  echohl None           | echo sep
  for do in sort(keys(D))
    echohl WarningMsg   | echo  s:pad(do, 16)
    echohl Special      | echon s:pad(D[do][0], 40)
    echohl None         | echon s:pad(D[do][1], &columns - 60)
  endfor
  echo sep
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#find_crlf(bang, dir)
  let dir = empty(a:dir) ? '.' : a:dir
  if !isdirectory(dir)
    return s:msg("Invalid Directory")
  elseif fnamemodify('.', ":p") == expand("~") && confirm("This is your home directory!", "&Yes\n&No", 2) != 1
    return
  endif
  let files = systemlist("file $(find . -type f) | grep 'with CRLF' | sed 's#\./##' | sed 's/:.*//'")
  if empty(files) | return s:msg("No results.") | endif
  let list = []
  for file in files
    call add(list, {'filename': file, 'text': system("file ".file." | sed 's/.*:/ /'"), 'lnum': 1, 'col':1})
  endfor
  call setqflist(list)
  if a:bang && confirm("Autoconvert to LF?", "&Yes\n&No", 2) == 1
    cfdo set fileformat=unix
    if confirm("Save all?", "&Yes\n&No", 1) == 1
      wall
    endif
    return
  endif
  copen
  cfirst
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#syntax_attr()
  """Created by Gary Holloway: https://www.vim.org/scripts/script.php?script_id=383

  let synid = ""
  let guifg = ""
  let guibg = ""
  let gui   = ""

  let id1  = synID(line("."), col("."), 1)
  let tid1 = synIDtrans(id1)

  if synIDattr(id1, "name") != ""
    let synid = synIDattr(id1, "name")
    if (tid1 != id1)
      let synid = synid . ' -> ' . synIDattr(tid1, "name")
    endif
    let id0 = synID(line("."), col("."), 0)
    if (synIDattr(id1, "name") != synIDattr(id0, "name"))
      let synid = synid .  " (" . synIDattr(id0, "name")
      let tid0 = synIDtrans(id0)
      if (tid0 != id0)
        let synid = synid . ' -> ' . synIDattr(tid0, "name")
      endif
      let synid = synid . ")"
    endif
  endif

  " Use the translated id for all the color & attribute lookups; the linked id yields blank values.
  if (synIDattr(tid1, "fg") != "" )
    let guifg = " guifg=" . synIDattr(tid1, "fg") . "(" . synIDattr(tid1, "fg#") . ")"
  endif
  if (synIDattr(tid1, "bg") != "" )
    let guibg = " guibg=" . synIDattr(tid1, "bg") . "(" . synIDattr(tid1, "bg#") . ")"
  endif
  if (synIDattr(tid1, "bold"     ))
    let gui   = gui . ",bold"
  endif
  if (synIDattr(tid1, "italic"   ))
    let gui   = gui . ",italic"
  endif
  if (synIDattr(tid1, "reverse"  ))
    let gui   = gui . ",reverse"
  endif
  if (synIDattr(tid1, "inverse"  ))
    let gui   = gui . ",inverse"
  endif
  if (synIDattr(tid1, "underline"))
    let gui   = gui . ",underline"
  endif
  if (gui != ""                  )
    let gui   = substitute(gui, "^,", " gui=", "")
  endif

  let message = synid . guifg . guibg . gui
  if message == ""
    echohl WarningMsg
    echo "<no syntax group here>"
  else
    redir => vv
    silent! verbose exe "hi" synIDattr(synIDtrans(id0), "name")
    redir END
    let setby = split(split(vv, "\n")[-1])[-1]
    let setby = setby != 'cleared' ? setby : ''
    echohl Title
    echo synid
    echohl None
    echon "\t".guifg . guibg . gui
    echohl Label
    echon "\t".setby
    exe "hi" synIDattr(synIDtrans(id0), "name")
  endif
  echohl None
  silent! call repeat#set(":\<c-u>call do#syntax_attr()\<cr>", 1)
endfun

" Helpers {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:store_reg()
  let s:oldreg = [getreg("\""), getregtype("\"")]
endfun

fun! s:restore_reg()
  call setreg("\"", s:oldreg[0], s:oldreg[1])
endfun

fun! s:pad(t, n)
  if len(a:t) > a:n
    return a:t[:(a:n-1)]."…"
  else
    let spaces = a:n - len(a:t)
    let spaces = printf("%".spaces."s", "")
    return a:t.spaces
  endif
endfun

fun! s:repeat_char(c)
  let s = ''
  for i in range(&columns - 20)
    let s .= a:c
  endfor
  return s
endfun

fun! s:is_tracked(file)
  call system(fugitive#repo().git_command('ls-files', '--error-unmatch', a:file))
  return !v:shell_error
endfun

fun! s:msg(m, ...)
  if a:0   | echohl Special     | echo a:m
  else     | echohl WarningMsg  | echom a:m | endif
  echohl None
endfun

