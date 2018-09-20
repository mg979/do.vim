" Show all do's command
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
  if empty(dos) | return do#msg("No do's") | endif
  let D = {}
  for do in dos
    let d = maparg(do, mode, 0, 1)
    if match(d.rhs, '^:call do#show_all_dos') == 0
      continue
    endif
    let flags = ''
    let flags .= d.noremap ? '*' : ''
    let flags .= d.buffer ? '@' : ''
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
    echohl Statement    | echon s:pad(flags, 3)
    echohl None         | echon s:pad(D[do][1], &columns - 63)
  endfor
  echo sep
endfun

" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:pad(t, n)
  if len(a:t) > a:n
    return a:t."…"
  else
    let spaces = a:n - len(a:t)
    let spaces = printf("%".spaces."s", "")
    return a:t.spaces
  endif
endfun

fun! s:repeat_char(c)
  let s = ''
  for i in range(&columns - 10)
    let s .= a:c
  endfor
  return s
endfun

fun! do#msg(m, ...)
  if a:0   | echohl Special     | echo a:m
  else     | echohl WarningMsg  | echom a:m | endif
  echohl None
endfun

