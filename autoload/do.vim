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
  let show_file = get(g:, 'vimdo_show_filename', 0)

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
    let file = s:get_file(pre.key, mode)
    if empty(desc) && require_desc | continue | endif
    let D[key] = [desc, file, flags, d.rhs]
  endfor
  echohl None           | echo sep
  echohl WarningMsg     | echo lab
  echohl None           | echo sep
  for do in sort(keys(D))
    echohl WarningMsg   | echo  s:pad(do, 16)
    echohl Special      | echon s:pad(D[do][0], 40)
    if show_file
      echohl Statement    | echon s:pad(D[do][1], 20)
      echohl Special      | echon s:pad(D[do][2], 3)
      echohl None         | echon s:pad(D[do][3], &columns - 83)
    else
      echohl Statement    | echon s:pad(D[do][2], 3)
      echohl None         | echon s:pad(D[do][3], &columns - 63)
    endif
  endfor
  echo sep
endfun

" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:pad(t, n)
  if a:n <= 0
    return ''
  elseif len(a:t) > a:n
    return a:t[:a:n]."…"
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

fun! s:get_file(map, mode)
  if !get(g:, 'vimdo_show_filename', 0) | return '' | endif
  redir => m
  exe "silent! verbose ".a:mode."map ".a:map
  redir END
  let m = split(m, '\n')
  for i in range(len(m))
    if match(m[i], escape(a:map, '\')) == 3
      let m = m[i+1]
      break
    endif
  endfor
  let m = substitute(m, '.*\s', '', '')
  return fnamemodify(m, ':t')
endfun

fun! do#msg(m, ...)
  if a:0   | echohl Special     | echo a:m
  else     | echohl WarningMsg  | echom a:m | endif
  echohl None
endfun

