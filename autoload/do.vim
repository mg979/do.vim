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

fun! s:get_current_file()
  let s:T = tabpagenr()
  let f = expand("%:p")
  let s:filetype = &ft
  return f
endfun

fun! s:put_current()
  call s:store_reg()
  %y"
  tabnew
  put = @"
  normal! 1Gdd
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . s:filetype
  nnoremap <buffer><silent><nowait> q :tabclose<cr>:exe "normal! ".<sid>Tab()."gt"<cr>
  diffthis
endfun

fun! do#diff_with_saved()
  let f = s:get_current_file()
  call s:put_current()
  vnew | exe "r" f | normal! 1Gdd
  diffthis
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . s:filetype
  nnoremap <buffer><silent><nowait> q :tabclose<cr>:exe "normal! ".<sid>Tab()."gt"<cr>
  call s:restore_reg()
  redraw!
  call s:msg("q: go back", 1)
endfun

fun! do#diff_last_revision()
  if !exists('g:loaded_fugitive') | return s:msg("vim-fugitive is needed.") | endif
  let f = s:get_current_file()

  if empty(FugitiveHead()) | return s:msg("not a git repo.")
  elseif !s:is_tracked(f)  | return s:msg("not a tracked file.") | endif

  exe "tabedit" f
  nnoremap <buffer><silent><nowait> q :tabclose<cr>:exe "normal! ".<sid>Tab()."gt"<cr>
  Gvdiff
  wincmd x
  nnoremap <buffer><silent><nowait> q :tabclose<cr>:exe "normal! ".<sid>Tab()."gt"<cr>

  redraw!
  call s:msg("q: go back", 1)
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

fun! do#show_all_dos(...)
  """Show all do commands."""
  let sep = s:repeat_char('-')
  let dos = a:0 && has_key(g:vimdo_groups, a:1) ? g:vimdo_groups[a:1] : g:vimdo
  echo sep
  for do in sort(keys(dos))
    echohl WarningMsg | echo do."\t"
    echohl Special    | echon s:pad(dos[do][0], 40)
    echohl None       | echon dos[do][1]
  endfor
  echo sep
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
  if a:0   | echohl Special
  else     | echohl WarningMsg | endif
  echo a:m | echohl None
endfun

fun! s:Tab()
  return s:T
endfun

