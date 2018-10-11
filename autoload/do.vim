"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Show all do's command                                           {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#show_all_dos(group, ...)
  call s:init()
  if a:0
    call s:show_all_dos(a:group, a:1, 0, '')
  else
    call s:show_all_dos(a:group, 0, 0, '')
  endif
endfun

fun! do#show_buffer_dos(group, ...)
  call s:init()
  if a:0
    call s:show_all_dos(a:group, a:1, 1, '')
  else
    call s:show_all_dos(a:group, 0, 1, '')
  endif
endfun

"------------------------------------------------------------------------------

fun! s:show_all_dos(group, show_file, buffer, filter)
  if index(['n', 'v', 'V', ''], mode()) < 0
    return
  endif

  let group = has_key(g:vimdo, a:group) ? g:vimdo[a:group] : {}
  let pre = a:group
  let pat = match(pre, '<') == 0 ? pre : fnameescape(pre)

  let sep         = s:repeat_char('-')
  let lab         = has_key(group, 'label') ?  pre."\t\t".group.label : pre
  let mode        = mode() == 'n' ? 'n' : 'x'
  let show_file   = a:show_file ? 1 : get(g:, 'vimdo_show_filename', 0)
  let with_filter = !empty(a:filter)

  " group dictionary options
  let s:compact    = has_key(group, 'compact') && group.compact
  let require_desc = s:compact || (has_key(group, 'require_description')
        \            && group.require_description)
  let interactive  = has_key(group, 'interactive') ?
        \            group.interactive : get(g:, 'vimdo_interactive', 0)
  let s:simple     = has_key(group, 'simple') ?
        \            group.simple : get(g:, 'vimdo_simple', 0)

  " formatting options
  let keys_width = has_key(group, 'keys_width') ?
        \          group.keys_width : get(g:, 'vimdo_keys_width', 16)
  let desc_width = has_key(group, 'desc_width') ?
        \          group.desc_width : get(g:, 'vimdo_desc_width', 40)

  if has_key(group, 'arbitrary') && group.arbitrary
    let dos = s:get_maps(group)
    let pre = ''
    let pat = ''
  else
    redir => dos
    silent! exe mode.'map '.pre
    redir END
    let dos = split(dos, '\n')
  endif

  for i in range(len(dos))
    let dos[i] = substitute(dos[i], 'n  ', '', '')
    let dos[i] = substitute(dos[i], '\s.*', '', '')
  endfor
  call filter(dos, "v:val =~ '^".pat."\\S'")

  " no results
  if empty(dos) | return do#msg("No do's") | endif

  let D = {}
  for do in dos
    let d = s:get_do(group, do, mode)
    let custom = has_key(d, 'custom')
    if (a:buffer && !d.buffer) ||
          \ with_filter && match(d.lhs, '\C^'.pat.a:filter) != 0 ||
          \ interactive && match(d.lhs, '\C^'.pat.s:current) != 0 ||
          \ match(d.rhs, '^:call do#show_') == 0
      continue
    endif

    " flags as :help map-listing
    let flags = ''
    let flags .= d.noremap ? '*' : ''
    let flags .= d.buffer ? '@' : ''

    let key = do[strchars(pre):]
    let file = show_file ? s:get_file(pre.key, mode) : ''
    let desc = !has_key(group, key) ? '' :
          \    custom ? d.description : group[key]

    " group requires description
    if require_desc && empty(desc) | continue | endif

    " finalize dict for display
    let D[key] = [desc, file, flags, custom ? s:get_rhs(d) : d.rhs]

    " interactive: execute the mapping, if it matches the current key
    if interactive && s:current == key
      call feedkeys(custom ? d.rhs : pre.key)
      return
    endif
  endfor

  " interactive: terminate if no matches are found
  if interactive && empty(D) | return do#msg("No matches") | endif

  if s:compact
    let total_space = &columns
    let space_left = total_space
    let column_width = keys_width + desc_width + 2

    echo "\n"
    for do in sort(keys(D))
      if space_left != total_space
        echohl WarningMsg   | echon  s:pad(do, keys_width)
      else
        echohl WarningMsg   | echo  s:pad(do, keys_width)
      endif
      echohl vimdoDesc      | echon s:pad(D[do][0], desc_width).'  '

      let space_left -= column_width
      if space_left <= column_width
        let space_left = total_space
      endif
    endfor
    echo "\n"
  else
    if s:simple
      echohl WarningMsg     | echo lab | echo "\n"
    else
      echohl None           | echo sep
      echohl WarningMsg     | echo lab
      echohl None           | echo sep
    endif
    for do in sort(keys(D))
      echohl WarningMsg   | echo  s:pad(do, keys_width)
      echohl Special      | echon s:pad(D[do][0], desc_width)
      if show_file
        echohl Statement    | echon s:pad(D[do][1], 20)
        echohl Special      | echon s:pad(D[do][2], 3)
        echohl None         | echon s:pad(D[do][3], &columns - 83)
      else
        echohl Statement    | echon s:pad(D[do][2], 3)
        echohl None         | echon s:pad(D[do][3], &columns - 63)
      endif
    endfor
    echohl None             | echo s:simple ? "\n" : sep
  endif
  echohl None

  if interactive
    call s:interactive(a:group, a:show_file, a:buffer)
  else
    call s:loop(a:group, a:show_file, a:buffer)
  endif
endfun

"------------------------------------------------------------------------------

fun! s:loop(group, show_file, buffer)
  if !( s:compact || s:simple )
    echo "Press a key to filter the list,"
          \"<space> to reset, or <cr>/<esc> to exit"
  endif
  let c = getchar()
  if c == 13 || c == 27
    call feedkeys("\<cr>", 'n')
  elseif c == 32
    redraw!
    call s:show_all_dos(a:group, a:show_file, a:buffer, '')
  else
    redraw!
    call s:show_all_dos(a:group, a:show_file, a:buffer, nr2char(c))
  endif
endfun

"------------------------------------------------------------------------------

fun! s:interactive(group, show_file, buffer)
  if !( s:compact || s:simple )
    echo "Press a key to filter the list,"
          \"<space> to reset, or <cr>/<esc> to exit"
  endif
  echo "Current choice:" s:current
  let c = getchar()
  if c == 13 || c == 27
    call feedkeys("\<c-l>", 'n')
  elseif c == 32
    redraw!
    let s:current = ''
    call s:show_all_dos(a:group, a:show_file, a:buffer, '')
  else
    redraw!
    let s:current .= nr2char(c)
    call s:show_all_dos(a:group, a:show_file, a:buffer, '')
  endif
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Helpers                                                         {{{1
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:init()
  let s:current = ''
  if &background == 'light'
    hi link vimdoDesc String
  else
    hi vimdoDesc ctermfg=251 ctermbg=NONE guifg=#c9c6c9
          \ guibg=NONE guisp=NONE cterm=NONE,italic gui=NONE,italic
  endif
endfun

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

fun! s:get_maps(group)
  let remove = ['require_description', 'label', 'arbitrary', 'interactive',
        \       'compact', 'keys_width', 'desc_width']
  return filter(keys(a:group), 'index(remove, v:val) < 0')
endfun

fun! s:get_do(group, do, mode)
  if !has_key(a:group, a:do) || type(a:group[a:do]) == v:t_string
    return maparg(a:do, a:mode, 0, 1)
  else
    return {'noremap': a:group[a:do][1], 'lhs': a:do, 'rhs': a:group[a:do][2],
          \ 'buffer': 0, 'custom': 1, 'description': a:group[a:do][0]}
  endif
endfun

fun! s:get_rhs(d)
  let r = substitute(a:d.rhs, "\<cr>", '<cr>', 'g')
  let r = substitute(r, "\<space>", '<space>', 'g')
  let r = substitute(r, "\<bar>", '<bar>', 'g')
  return r
endfun

fun! do#msg(m, ...)
  if a:0   | echohl Special     | echo a:m
  else     | echohl WarningMsg  | echom a:m | endif
  echohl None
endfun


