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
  call s:init(0)
  let group = empty(a:group) ? get(g:, 'vimdo_default_prefix', 'do') : a:group
  call s:show_all_dos(group, a:0 ? a:1 : 0, '', 0, 'n')
endfun "}}}

fun! do#print(prefix, can_filter, mode) abort
  " Entry point for Nmap command. {{{1
  call s:init(1 + a:can_filter)
  let buf = match(a:prefix, '<buffer>') >= 0
  let pre = substitute(a:prefix, '<buffer>', '', '')
  call s:show_all_dos(pre, buf, '', 0, a:mode)
endfun "}}}

fun! do#menu(menu) abort
  " Can be used as inputlist() replacement.
  call s:init(0)
  return s:show_all_dos(a:menu, 0, '', 1, 'n')
endfun "}}}

""=============================================================================
" Function: s:show_all_dos
" Main function for the ShowDos command
"
" @param group: the requested group or mapping prefix
" @param buffer: only show buffer mappings if 1
" @param filter: the applied filter, when redrawing
""=============================================================================
""
fun! s:show_all_dos(group, buffer, filter, menu, mode)
  " Main function. {{{1
  if a:menu
    let default_label = get(g:, 'vimdo_default_menu_label', 'Choose: ')
    if type(a:group) == v:t_dict
      if has_key(a:group, 'items') && type(a:group.items) == v:t_list
        let group = {}
        let group.label = get(a:group, 'label', default_label)
        for v in a:group.items
          let group[v] = ' '
        endfor
      else
        let group = a:group
      endif
    else
      let group = {}
      for v in a:group
        let group[v] = ' '
      endfor
    endif
    let group.label = get(group, 'label', default_label)
    let pre = ''
  else
    let group = s:get_group(a:group)
    let pre = s:trans_lhs(a:group)
  endif

  let pat = match(pre, '<') == 0 ? pre :
        \ s:winOS ? substitute(pre, '\', '\\\\', '') : fnameescape(pre)
  let pat = s:trans_lhs(pat)

  let sep         = repeat('-', &columns - 10)
  let lab         = has_key(group, 'label') ?  pre."\t\t".group.label : pre
  let show_file   = get(g:, 'vimdo_show_filename', 0)
  let with_filter = !empty(a:filter)

  " menu: will return chosen item
  if a:menu
    let group.arbitrary = 1
    let group.require_description = 1
    let group.interactive = 1
    let group.simple = 1
    let group.show_rhs = 0
    let lab = get(a:group, 'label', '')
  endif

  " just_print: simple display, no interaction
  if s:just_print
    let group.interactive = 0
    let group.simple = 1
    let group.show_rhs = 1
    let group.keys_width = 30
    let group.desc_width = 0
    let lab = ''
    let show_file = 1
  endif

  " group dictionary options
  let s:compact    = has_key(group, 'compact') ?
        \            group.compact : get(g:, 'vimdo_compact', 0)
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
  let full_lhs   = get(g:, 'vimdo_print_full_lhs', 1) && !interactive &&
        \          !get(group, 'arbitrary', 0)

  if has_key(group, 'arbitrary') && group.arbitrary
    let dos = s:get_maps(group)
    let pre = ''
    let pat = ''
    let show_file = 0
  else
    redir => dos
    silent! exe a:mode.'map' pre
    redir END
    let dos = split(dos, '\n')
    for i in range(len(dos))
      let dos[i] = substitute(dos[i], a:mode.'  ', '', '')
      let dos[i] = substitute(dos[i], '\s.*', '', '')
    endfor
    call filter(dos, "v:val =~ '^".pat."'")
    if s:just_print && a:group !~ '\c<plug>'
      " we don't want to show all those <Plug> mappings
      call filter(dos, "v:val !~ '^<Plug>'")
    endif
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
  let max_lhs_width = 0
  for do in dos
    if do ==# 'order' | continue | endif  " not a mapping, it's their order
    let d = s:get_do(group, do, a:mode)
    if empty(d) | continue | endif
    let custom = has_key(d, 'custom')
    if (a:buffer && !d.buffer) ||
          \ with_filter && match(d.lhs, '\C^'.pat.a:filter) != 0 ||
          \ interactive && match(d.lhs, '\C^'.pat.s:current) != 0 ||
          \ match(d.rhs, '^:call do#show_') == 0 ||
          \ match(d.rhs, '^:ShowDos') == 0 ||
          \ ( pre ==# do && d.rhs ==? '<NOP>' )
      continue
    endif

    if strwidth(d.lhs) > max_lhs_width | let max_lhs_width = strwidth(d.lhs) | endif

    " flags as :help map-listing
    let flags = ''
    let flags .= d.noremap ? '*' : ''
    let flags .= d.buffer ? '@' : ''

    let key = do[strchars(pre):]
    let file = show_file ? s:get_file(pre.key, a:mode) : ''
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

  " if some of the LHS would be trimmed, shrink the descriptions instead
  if max_lhs_width > keys_width
    let diff = max_lhs_width - keys_width
    let keys_width = max_lhs_width
    let desc_width = max([0, desc_width - diff])
  endif

  " menu: return nothing if no matches are found
  if a:menu && empty(D) | return '' | endif

  " interactive: terminate if no matches are found
  if interactive && empty(D) | return do#msg("No matches") | endif

  " abort anyway if there's nothing at all
  if empty(a:filter) && empty(D) | return do#msg("Nothing to show.") | endif

  let s = ' '
  if s:compact
    let total_space = &columns - 1
    let space_left = total_space
    let column_width = keys_width + desc_width + 2

    echo "\n"
    for do in s:sort_dos(D, group)
      if !has_key(D, do) | continue | endif
      let K = !a:menu && (s:just_print || full_lhs) ? a:group . do : do
      let K = s:trans_lhs(K)
      if space_left != total_space
        echohl WarningMsg   | echon  s:pad(K, keys_width)
      else
        echohl WarningMsg   | echo  s . s:pad(K, keys_width)
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
      if !( has_key(group, 'label') && interactive ) && !empty(lab)
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
      let K = !a:menu && (s:just_print || full_lhs) ? a:group . do : do
      let K = s:trans_lhs(K)
      echohl WarningMsg   | echo  s . s:pad(K, keys_width)
      echohl Special      | echon s:pad(D[do][0], desc_width)
      if show_file
        echohl Statement    | echon s:pad(D[do][1], 40)
        echohl Special      | echon s:pad(D[do][2], 3)
        echohl None         | echon s:pad(D[do][3], &columns - 103)
      elseif s:show_rhs
        echohl Statement    | echon s:pad(D[do][2], 3)
        echohl None         | echon s:pad(D[do][3], &columns - 63)
      endif
    endfor
    echohl None             | echo s:simple ? "\n" : sep
  endif
  echohl None

  if a:menu
    echo group.label
    return nr2char(getchar())
  elseif interactive
    call s:interactive(a:group, a:buffer, a:mode)
  elseif s:just_print != 1
    call s:loop(a:group, a:buffer, a:mode)
  endif
endfun "}}}




"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:winOS = has('win32') || has('win16') || has('win64')

fun! s:init(just_print)
  " Set vimdoDesc highlight group. {{{1
  let s:current = '' " current typed key
  let s:just_print = a:just_print
  if &background == 'light'
    hi link vimdoDesc String
  else
    hi vimdoDesc ctermfg=251 ctermbg=NONE guifg=#c9c6c9
          \ guibg=NONE guisp=NONE cterm=NONE,italic gui=NONE,italic
  endif
endfun "}}}

fun! s:loop(group, buffer, mode)
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
    call s:show_all_dos(a:group, a:buffer, '', 0, a:mode)
  else
    redraw!
    call s:show_all_dos(a:group, a:buffer, nr2char(c), 0, a:mode)
  endif
endfun "}}}

fun! s:interactive(group, buffer, mode)
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
    call s:show_all_dos(a:group, a:buffer, '', 0, a:mode)
  else
    redraw!
    let s:current .= nr2char(c)
    call s:show_all_dos(a:group, a:buffer, '', 0, a:mode)
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

fun! s:get_group(grp) abort
  if !has_key(g:vimdo, a:grp) | return {} | endif
  let group = g:vimdo[a:grp]
  if a:grp == get(g:, 'vimdo_default_prefix', 'do') &&
        \     get(g:, 'vimdo_use_default_commands', 0)
    call extend(group, do#default_grp(), 'keep')
  endif
  return group
endfun

fun! s:get_file(map, mode)
  " Get file where the mapping is defined. {{{1
  redir => m
  exe "silent! verbose" a:mode."map" a:map
  redir END
  let m = split(m, '\n')
  try
    for i in range(len(m))
      if match(m[i], escape(a:map, '~*\')) == 3
        let m = m[i+1]
        break
      endif
    endfor
    return fnamemodify(m, ':t')
  catch
    return ''
  endtry
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

fun! s:trans_lhs(string) abort
  let ret = substitute(a:string, '<\([^>]\+\)>', '\="<".tolower(submatch(1)).">"', 'g')
  let ret = substitute(ret, '\c<leader>', get(g:, 'mapleader', '\'), 'g')
  let ret = substitute(ret, '<\([^>]\)\([^>]\+\)>', '<\u\1\2>', 'g')
  return ret
endfun

fun! do#msg(m, ...)
  " A message. Without arg, it's a warning. {{{1
  if a:0   | echohl Special     | echo a:m
  else     | echohl WarningMsg  | echom a:m | endif
  echohl None
endfun "}}}

" vim: et sw=2 ts=2 sts=2 fdm=marker
