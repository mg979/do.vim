"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Show all do's command
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""=============================================================================
" Function: do#show
" Show mappings that belong to the group, with description if it has been set

" @param group: the requested group or mapping prefix
" @param ...: (BANG) show buffer mappings if given
""=============================================================================
""
fun! do#show(group, ...)
  " Entry point for ShowDos command. {{{1
  if empty(a:group) &&
        \ ( !exists('g:vimdo_default_prefix') || empty(g:vimdo_default_prefix) )
    echo '[do.vim] you must enter a mapping prefix'
    return
  endif
  call s:init()
  let group = empty(a:group) ? get(g:, 'vimdo_default_prefix', 'do') : a:group
  call s:show_all_dos(group, a:0 ? a:1 : 0, '', 0)
endfun "}}}

fun! do#menu(menu) abort
  call s:init()
  return s:show_all_dos(a:menu, 0, '', 1)
endfun

""=============================================================================
" Function: s:show_all_dos
" Main function for the ShowDos command
"
" @param group: the requested group or mapping prefix
" @param buffer: only show buffer mappings if 1
" @param filter: the applied filter, when redrawing
""=============================================================================
""
fun! s:show_all_dos(group, buffer, filter, menu)
  " Main function. {{{1
  if index(['n', 'v', 'V', ''], mode()) < 0
    return
  endif

  if a:menu
    let group = a:group
    let pre = ''
  else
    let group = has_key(g:vimdo, a:group) ? g:vimdo[a:group] : {}
    let pre = a:group
  endif

  let pat = match(pre, '<') == 0 ? pre :
        \ s:winOS ? substitute(pre, '\', '\\\\', '') : fnameescape(pre)

  let sep         = repeat('-', &columns - 10)
  let lab         = has_key(group, 'label') ?  pre."\t\t".group.label : pre
  let mode        = mode() == 'n' ? 'n' : 'x'
  let show_file   = get(g:, 'vimdo_show_filename', 0)
  let with_filter = !empty(a:filter)

  " menu: will return chosen item
  if a:menu
    let group.arbitrary = 1
    let group.require_description = 1
    let group.interactive = 1
    let group.simple = 1
    let group.show_rhs = 0
    let group.label = get(a:group, 'label', '')
  endif

  " group dictionary options
  let s:compact    = has_key(group, 'compact') && group.compact
  let require_desc = s:compact || (has_key(group, 'require_description')
        \            && group.require_description)
  let interactive  = has_key(group, 'interactive') ?
        \            group.interactive : get(g:, 'vimdo_interactive', 0)
  let s:simple     = has_key(group, 'simple') ?
        \            group.simple : get(g:, 'vimdo_simple', 0)
  let s:show_rhs   = has_key(group, 'show_rhs') ?
        \            group.show_rhs : get(g:, 'vimdo_show_rhs', 1)

  " formatting options
  let keys_width = has_key(group, 'keys_width') ?
        \          group.keys_width : get(g:, 'vimdo_keys_width', 16)
  let desc_width = has_key(group, 'desc_width') ?
        \          group.desc_width : get(g:, 'vimdo_desc_width', 40)

  if has_key(group, 'arbitrary') && group.arbitrary
    let dos = s:get_maps(group)
    let pre = ''
    let pat = ''
    let show_file = 0
  else
    redir => dos
    silent! exe mode.'map '.pre
    redir END
    let dos = split(dos, '\n')
    let pre = substitute(pre, '\c<leader>', get(g:, 'mapleader', '\'), 'g')
    let pat = substitute(pat, '\c<leader>', get(g:, 'mapleader', '\'), 'g')
    let pat = substitute(pat, '<\([^>]\+\)>', '<\U\1>', 'g')
    for i in range(len(dos))
      let dos[i] = substitute(dos[i], 'n  ', '', '')
      let dos[i] = substitute(dos[i], '\s.*', '', '')
    endfor
    call filter(dos, "v:val =~ '^".pat."'")
  endif

  " no results
  if empty(dos) | return do#msg("No do's") | endif

  " at this point, 'dos' is a list with all mappings that start with 'pre'
  " we must iterate this list and build the lines to show, but first we must
  " filter out some unwanted mappings:
  "
  " 1. we're filtering? exclude those that don't start with the filter
  " 2. interactive mode? similarly
  " 3. remove vimdo's own command
  " 4. also remove the prefix itself, if it's mapped to <NOP>

  let D = {}
  for do in dos
    if do ==# 'order' | continue | endif  " not a mapping, it's their order
    let d = s:get_do(group, do, mode)
    let custom = has_key(d, 'custom')
    if (a:buffer && !d.buffer) ||
          \ with_filter && match(d.lhs, '\C^'.pat.a:filter) != 0 ||
          \ interactive && match(d.lhs, '\C^'.pat.s:current) != 0 ||
          \ match(d.rhs, '^:call do#show_') == 0 ||
          \ match(d.rhs, '^:ShowDos') == 0 ||
          \ ( pre ==# do && d.rhs ==? '<NOP>' )
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

  " menu: return nothing if no matches are found
  if a:menu && empty(D) | return '' | endif

  " interactive: terminate if no matches are found
  if interactive && empty(D) | return do#msg("No matches") | endif

  let s = ' '
  if s:compact
    let total_space = &columns - 1
    let space_left = total_space
    let column_width = keys_width + desc_width + 2

    echo "\n"
    for do in s:sort_dos(D, group)
      if !has_key(D, do) | continue | endif
      if space_left != total_space
        echohl WarningMsg   | echon  s:pad(do, keys_width)
      else
        echohl WarningMsg   | echo  s . s:pad(do, keys_width)
      endif
      echohl vimdoDesc      | echon s:pad(D[do][0], desc_width) . s

      let space_left -= column_width
      if space_left <= column_width
        let space_left = total_space
      endif
    endfor
    echo "\n"
  else
    if s:simple
      if !( has_key(group, 'label') && interactive )
        echo s.lab
      endif
      echo "\n"
    else
      echohl None           | echo sep
      echohl WarningMsg     | echo s.lab
      echohl None           | echo sep
    endif
    for do in s:sort_dos(D, group)
      if !has_key(D, do) | continue | endif
      echohl WarningMsg   | echo  s . s:pad(do, keys_width)
      echohl Special      | echon s:pad(D[do][0], desc_width)
      if show_file
        echohl Statement    | echon s:pad(D[do][1], 20)
        echohl Special      | echon s:pad(D[do][2], 3)
        echohl None         | echon s:pad(D[do][3], &columns - 83)
      elseif s:show_rhs
        echohl Statement    | echon s:pad(D[do][2], 3)
        echohl None         | echon s:pad(D[do][3], &columns - 63)
      endif
    endfor
    echohl None             | echo s:simple ? "\n" : sep
  endif
  echohl None

  if a:menu
    echo group.label . ': '
    return nr2char(getchar())
  elseif interactive
    call s:interactive(a:group, a:buffer)
  else
    call s:loop(a:group, a:buffer)
  endif
endfun "}}}




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:winOS = has('win32') || has('win16') || has('win64')

fun! s:init()
  " Set vimdoDesc highlight group. {{{1
  let s:current = '' " current typed key
  if &background == 'light'
    hi link vimdoDesc String
  else
    hi vimdoDesc ctermfg=251 ctermbg=NONE guifg=#c9c6c9
          \ guibg=NONE guisp=NONE cterm=NONE,italic gui=NONE,italic
  endif
endfun "}}}

fun! s:loop(group, buffer)
  " Get character from user, use it as filter or redraw/exit. {{{1
  " Same parameters as for the main command.
  if !( s:compact || s:simple )
    echo 'Press a key to filter the list, <C-L> to reset, or <ESC> to exit'
  endif
  let c = getchar()
  if c == 27
    call feedkeys("\<Esc>", 'n')
  elseif c == 12
    redraw!
    call s:show_all_dos(a:group, a:buffer, '', 0)
  else
    redraw!
    call s:show_all_dos(a:group, a:buffer, nr2char(c), 0)
  endif
endfun "}}}

fun! s:interactive(group, buffer)
  " Interactive mode: try to run a command for the matching entered key. "{{{1
  " Same parameters as for the main command.
  if !( s:compact || s:simple )
    echo 'Press a key to filter the list, <C-L> to reset, or <ESC> to exit'
    echo "Current choice:" s:current
  elseif has_key(g:vimdo[a:group], 'label')
    echo g:vimdo[a:group].label.":" s:current
  else
    echo "Current choice:" s:current
  endif
  let c = getchar()
  if c == 27
    call feedkeys("\<cr>", 'n')
  elseif c == 12
    redraw!
    call s:show_all_dos(a:group, a:buffer, '', 0)
  else
    redraw!
    let s:current .= nr2char(c)
    call s:show_all_dos(a:group, a:buffer, '', 0)
  endif
endfun "}}}

fun! s:pad(s, n)
  " Pad a string 's' to a max of 'n' characters. {{{1
  if a:n <= 0
    return ''
  elseif len(a:s) > a:n
    return a:s[:a:n]."…"
  else
    let spaces = a:n - len(a:s)
    let spaces = printf("%".spaces."s", "")
    return a:s.spaces
  endif
endfun "}}}

fun! s:get_file(map, mode)
  " Get file where the mapping is defined. {{{1
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
  return fnamemodify(m, ':t')
endfun "}}}

fun! s:get_maps(group)
  " Get actual mappings for the requested group. {{{1
  "
  " Since the mappings descriptions reside in the same dictionary as the group
  " options, the latter must be removed.
  "
  " @param group: the requested group or mapping prefix
  " Returns: the group dictionary, without the options, only the mappings

  let remove = ['require_description', 'label', 'arbitrary', 'interactive',
        \       'compact', 'keys_width', 'desc_width', 'simple', 'show_rhs',
        \       'menu']
  return filter(keys(a:group), 'index(remove, v:val) < 0')
endfun "}}}

fun! s:sort_dos(dos, group)
  " Sort the mappings. {{{1
  "
  " The order can be arbitrary if the group has an 'order' key, otherwise it's
  " alphanumeric.
  "
  " @param dos: the mappings
  " @param group: the requested group or mapping prefix
  " Returns: the sorted mappings

  if !empty(s:current) || !has_key(a:group, 'order')
    return sort(keys(a:dos), 'i')
  else
    let order = copy(a:group.order)
    let all = sort(keys(a:dos), 'i')
    for k in all
      if index(order, k) < 0 && k != 'order'
        call add(order, k)
      endif
    endfor
    return order
  endif
endfun "}}}

fun! s:get_do(group, do, mode)
  " Get mapping from group. {{{1
  "
  " If it's an arbitrary group, the mapping must be defined in the group,
  " otherwise nothing will be returned. If it's a normal mapping prefix, use
  " maparg() to see if the mapping exists.
  "
  " @param group: the requested group or mapping prefix
  " @param do: the requested mapping
  " @param mode: the mode (only normal mode seems to be supported right now...)
  " Returns: a dict like the one returned by maparg()

  if !has_key(a:group, a:do)
    " not a custom dictionary, check for a mapped key
    return maparg(a:do, a:mode, 0, 1)

  elseif type(a:group[a:do]) == v:t_string
    if !s:show_rhs
      " we don't want to show the rhs, it's a custom dictionary
      return {'noremap': 0, 'lhs': a:do, 'rhs': '',
            \ 'buffer': 0, 'custom': 1, 'description': a:group[a:do]}
    else
      " it's an entry for an existing mapping
      return maparg(a:do, a:mode, 0, 1)
    endif

  else
    " it's an arbitrary group with custom rhs
    let ret = {'lhs': a:do, 'rhs': a:group[a:do][1],
          \    'buffer': 0, 'custom': 1, 'description': a:group[a:do][0]}
    let ret.noremap = !( len(a:group[a:do]) > 2 && a:group[a:do][2] )
    return ret
  endif
endfun "}}}

fun! s:get_rhs(d)
  " Convert some special keys for visualization. {{{1
  " @param d: the map dictionary
  " Returns: the converted mapping

  let r = substitute(a:d.rhs, "\<cr>", '<cr>', 'g')
  let r = substitute(r, "\<space>", '<space>', 'g')
  let r = substitute(r, "\<bar>", '<bar>', 'g')
  return r
endfun "}}}

fun! do#msg(m, ...)
  " A message. Without arg, it's a warning. {{{1
  if a:0   | echohl Special     | echo a:m
  else     | echohl WarningMsg  | echom a:m | endif
  echohl None
endfun "}}}

" vim: et sw=2 ts=2 sts=2 fdm=marker
