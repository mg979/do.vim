"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Diff commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


fun! do#diff#other()
  " Diff with next window in tab.
  if len(tabpagebuflist()) < 2
    return do#msg("There must be at least 2 buffers in the tab page")
  endif
  if !&diff
    diffthis
    wincmd w
    diffthis
    wincmd p
  else
    diffoff
    wincmd w
    diffoff
    wincmd p
  endif
  redraw!
endfun


fun! do#diff#saved()
  " Diff with actual saved file.
  if !filereadable(@%) | return do#msg('File is not readable.') | endif

  " current file to new tab
  let ft = &ft
  exe (tabpagenr()-1)."tabedit %"
  diffthis

  " new vertical buffer with content read from  disk
  vsplit | enew | exe "r #" | 1d _
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . ft
  setlocal statusline=%#Search#\ Saved\ file
  diffthis

  " set wincolor and autodelete temp buffer if last in tab
  call s:wincolor()
  au BufEnter <buffer> if len(tabpagebuflist()) == 1 | bwipeout | diffoff | endif
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


fun! s:wincolor()
  " Set window background color, if supported
  if &bg == 'dark'
    hi DoWinColor guibg=#303030 ctermbg=236
  else
    hi DoWinColor guibg=#dadada ctermbg=7
  endif
  if has('patch-8.1.1391')
    set wincolor=DoWinColor
  elseif has('nvim')
    set winhighlight=Normal:DoWinColor
  endif
endfun


" vim: et sw=2 ts=2 sts=2 fdm=indent fdn=1
