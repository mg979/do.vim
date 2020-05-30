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
