"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Diff commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! do#diff#other()
  " Diff with next window in tab.
  let bufs = tabpagebuflist()
  if len(bufs) < 2
    return do#msg("There must be at least 2 buffers in the tab page")
  endif
  let f1 = fnameescape(resolve(expand("%:p")))
  wincmd w
  let f2 = fnameescape(resolve(expand("%:p")))
  wincmd p
  if f1 ==# f2
    return do#msg("Same file")
  endif
  exe (tabpagenr()-1)."tabedit" f2
  diffthis
  exe 'vsplit' f1
  diffthis
  redraw!
endfun


fun! do#diff#saved()
  " Diff with actual saved file.
  let [ f, ft ] = [ fnameescape(resolve(expand("%:p"))), &ft ]
  exe (tabpagenr()-1)."tabedit" f
  diffthis
  vnew | exe "0r" f
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . ft
  setlocal statusline=%#Search#\ Saved\ file
  diffthis
  wincmd x
  redraw!
endfun


fun! do#diff#last_revision(head)
  " Diff with last git revision.
  if !exists('g:loaded_fugitive') | return do#msg("vim-fugitive is needed.") | endif
  let f = resolve(expand("%:p"))

  if empty(FugitiveStatusline()) | return do#msg("not a git repo.")
  elseif !s:is_tracked(f)        | return do#msg("not a tracked file.") | endif

  exe (tabpagenr()-1)."tabedit" fnameescape(f)
  if a:head
    Gvdiff
    setlocal statusline=%#ErrorMsg\ HEAD
  else
    Gvdiff HEAD^
    setlocal statusline=%#ErrorMsg\ HEAD^
  endif
  if expand("%:p") != f
    wincmd x
  endif
  redraw!
endfun


fun! s:is_tracked(file)
  " Check if file is tracked in repository.
  call system(fugitive#repo().git_command('ls-files', '--error-unmatch', a:file))
  return !v:shell_error
endfun


" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
