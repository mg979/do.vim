"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Diff commands                                                   {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:diffed_buffers = []

fun! do#diff#other()
  let bufs = tabpagebuflist()
  if len(bufs) < 2
    return do#msg("There must be at least 2 buffers in the tab page")
  endif
  if !&diff
    diffthis
    nnoremap <buffer><silent><nowait> q :<c-u>call <sid>unmap()<cr>
  endif
  wincmd w
  if !&diff
    diffthis
    nnoremap <buffer><silent><nowait> q :<c-u>call <sid>unmap()<cr>
  endif
  wincmd p
  redraw!
  call do#msg("q: diffoff", 1)
endfun

fun! s:unmap()
  nunmap <buffer> q
  let w = winnr()
  if &diff
    windo diffoff
    exe w.'wincmd w'
  else
    call feedkeys('q')
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#diff#saved()
  let f = s:get_current_file()
  let g:xtabline.Vars.tab_properties = {'locked':1}
  exe "tabedit" f
  call s:diff_map()
  vnew | exe "r" f | normal! 1Gdd
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . s:filetype
  let b:XTbuf = {'name': 'Saved file', 'special': 1}
  call s:diff_map()
  wincmd x
  redraw!
  call do#msg("q: back", 1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#diff#last_revision(head)
  if !exists('g:loaded_fugitive') | return do#msg("vim-fugitive is needed.") | endif
  let f = s:get_current_file()

  if empty(FugitiveStatusline()) | return do#msg("not a git repo.")
  elseif !s:is_tracked(f)        | return do#msg("not a tracked file.") | endif

  exe "tabedit" f
  call s:diff_map()
  if a:head
    Gvdiff
  else
    Gvdiff HEAD^
  endif
  wincmd w
  call s:diff_map()
  wincmd h
  if expand("%:p") != f
    wincmd x
  endif
  redraw!
  call do#msg("q: back", 1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Helpers                                                         {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:get_current_file()
  let s:T = tabpagenr()
  let f = resolve(expand("%:p"))
  let s:filetype = &ft
  return escape(f, ' ')
endfun

fun! s:Tab()
  call s:diff_unmap()
  tabclose
  return s:T
endfun

fun! s:diff_map()
  diffthis
  call add(s:diffed_buffers, ([bufnr("%"), &cursorline]))
  setlocal nocursorline
  nnoremap <buffer><silent><nowait> <leader>q   :exe "normal! ".<sid>Tab()."gt"<cr>
  nnoremap <buffer><silent><nowait> q           :exe "normal! ".<sid>Tab()."gt"<cr>
endfun

fun! s:diff_unmap()
  for buf in s:diffed_buffers
    let &cursorline = buf[1]
    silent! exe "b ".buf[0]
    silent! unmap <buffer> <leader>q
    silent! unmap <buffer> q
    diffoff
  endfor
  let s:diffed_buffers = []
endfun

fun! s:is_tracked(file)
  call system(fugitive#repo().git_command('ls-files', '--error-unmatch', a:file))
  return !v:shell_error
endfun

