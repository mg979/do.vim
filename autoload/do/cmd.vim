"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Miscellaneous commands                                          {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#cmd#redir_expression(...)
  if a:0 | let var = a:1
  else   | let var = input('RedirExpression > ', '', 'expression') | endif
  call s:redir(var, 1)
endfun

fun! do#cmd#redir_cmd(...)
  let cmd = join(a:000, ' ')
  call s:redir(cmd, 0)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#cmd#profiling()
  for b in range(1, bufnr('$'))
    if getbufvar(b, '&modified')
      return do#msg("There are unsaved buffers, aborting.")
    endif
  endfor
  if !exists('s:profiling_active')
    call do#msg("Profiling activated", 1)
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

fun! do#cmd#trim_whitespaces()
  let pos = getpos(".")
  keeppatterns silent! %s/\s\+$//e
  call setpos('.', pos)
  call do#msg("Trimmed trailing whitespaces", 1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#cmd#update_tags()
  let error = system("ctags -R .")
  if empty(error)
    call do#msg("Tags updated.", 1)
  else
    call do#msg(error)
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#cmd#find_crlf(bang, dir)
  let dir = empty(a:dir) ? '.' : a:dir
  if !isdirectory(dir)
    return do#msg("Invalid Directory")
  elseif fnamemodify('.', ":p") == expand("~") && confirm("This is your home directory!", "&Yes\n&No", 2) != 1
    return
  endif
  let files = systemlist("file $(find . -type f) | grep 'with CRLF' | sed 's#\./##' | sed 's/:.*//'")
  if empty(files) | return do#msg("No results.") | endif
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

fun! do#cmd#syntax_attr()
  """Edited from Gary Holloway version:
  """https://www.vim.org/scripts/script.php?script_id=383

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
  silent! call repeat#set(":\<c-u>call do#cmd#syntax_attr()\<cr>", 1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Helpers                                                         {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:store_reg()
  let s:oldreg = [getreg("\""), getregtype("\"")]
endfun

fun! s:restore_reg()
  call setreg("\"", s:oldreg[0], s:oldreg[1])
endfun

fun! s:redir(input, is_var)
  if empty(a:input) | return do#msg('Canceled.') | endif
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
  call do#msg("q: close buffer", 1)
endfun

