""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" do.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:default = get(g:, 'vimdo_use_default_commands', 1) ? {
      \ 'ws': ['trim whitespaces',      ':call do#trim_whitespaces()<cr>'  ],
      \ 're': ['redir expression',      ':call do#redir_expression()<cr>'  ],
      \ 'rc': ['redir command',         ':RedirCommand<space>'             ],
      \ 'vp': ['profiling',             ':call do#profiling()<cr>'         ],
      \ 'ds': ['diff saved',            ':call do#diff_with_saved()<cr>'   ],
      \ 'do': ['diff other',            ':call do#diff_with_other()<cr>'   ],
      \ 'dl': ['diff last revision',    ':call do#diff_last_revision()<cr>'],
      \} : {}

let g:vimdo = extend(s:default, get(g:, 'vimdo', {}))
let g:vimdo_groups = get(g:, 'vimdo_groups', {})

nnoremap dO :call do#show_all_dos()<cr>

command! -nargs=* -complete=command RedirCommand call do#redir_cmd(<f-args>)

fun! s:map(K, k, prefix)
  let [K, k] = [a:K, a:k]
  let nrm = 'nore' | let lhs = '' | let m   = 'n'
  let opt = split(get(K, 2, ''), '\zs')
  if !empty(opt)
    for op in opt
      if     op == 'r' | let nrm = ''
      elseif op == 'e' | let lhs .= '<expr>'
      elseif op == 's' | let lhs .= '<silent>'
      elseif op == 'm' | let m = ''
      elseif op == 'x' | let m = 'x'
      elseif op == 'o' | let m = 'o'
      elseif op == 'v' | let m = 'v'
      endif
    endfor
  endif

  if get(g:, 'vimdo_make_plugs', 0)
    let p = substitute(K[0], '\s', '-', 'g')
    let plug = '<Plug>(Do-'.p.')'
    exe "nmap ".a:prefix.k plug
    exe m.nrm."map" lhs plug K[1]
  else
    exe m.nrm."map" lhs a:prefix.k K[1]
  endif
endfun

for k in keys(g:vimdo)
  call s:map(g:vimdo[k], k, get(g:, 'vimdo_prefix', 'do'))
endfor

for g in sort(keys(g:vimdo_groups))
  let prefix = has_key(g:vimdo_groups[g], 'prefix') ? g:vimdo_groups[g].prefix : 'do'
  for k in keys(g:vimdo_groups[g])
    if k ==? 'prefix' || k ==? 'show_cmd' | continue | endif
    call s:map(g:vimdo_groups[g][k], k, prefix)
  endfor
  if has_key(g:vimdo_groups[g], 'show_cmd') |
    exe "nnoremap" g:vimdo_groups[g].show_cmd ":call do#show_all_dos('".g."')\<cr>"
  endif
endfor
