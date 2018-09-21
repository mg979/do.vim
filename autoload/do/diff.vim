" Diff commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:diffed_buffers = []

fun! do#diff#other()
  let bufs = tabpagebuflist()
  if len(bufs) < 2
    return do#msg("There must be at least 2 buffers in the tab page")
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
  call do#msg("q: back, ]: next change, [: previous change, do: diffget, dp: diffput", 1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#diff#saved()
  let f = s:get_current_file()
  exe "tabedit" f
  call s:diff_map()
  vnew | exe "r" f | normal! 1Gdd
  exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . s:filetype
  call s:diff_map()
  wincmd x
  redraw!
  call do#msg("q: back, ]: next change, [: previous change", 1)
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#diff#last_revision()
  if !exists('g:loaded_fugitive') | return do#msg("vim-fugitive is needed.") | endif
  let f = s:get_current_file()

  if empty(FugitiveStatusline()) | return do#msg("not a git repo.")
  elseif !s:is_tracked(f)        | return do#msg("not a tracked file.") | endif

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
  call do#msg("q: back, ]: next change, [: previous change, do: diffget, dp: diffput", 1)
endfun

" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

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

fun! s:is_tracked(file)
  call system(fugitive#repo().git_command('ls-files', '--error-unmatch', a:file))
  return !v:shell_error
endfun
