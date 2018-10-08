" ========================================================================///
" Author:      Gianmaria Bajo <mg1979.git@gmail.com>
" Description: do something with 'do' mappings
" Mantainer:   Gianmaria Bajo <mg1979.git@gmail.com>
" Url:         https://github.com/mg979/do.vim
" License:     The MIT License (MIT)
" Created:     lun 08 ottobre 2018 17:12:17
" Modified:    lun 08 ottobre 2018 17:12:17
" ========================================================================///

if get(g:, 'vimdo_use_default_commands', 0)
  nnoremap dows  :call do#cmd#trim_whitespaces()<cr>
  nnoremap dore  :call do#cmd#redir_expression()<cr>
  nnoremap dout  :call do#cmd#update_tags()<cr>
  nnoremap dovp  :call do#cmd#profiling()<cr>
  nnoremap dods  :call do#diff#saved()<cr>
  nnoremap dodo  :call do#diff#other()<cr>
  nnoremap dodl  :call do#diff#last_revision()<cr>
  nnoremap dossa :call do#cmd#syntax_attr()<cr>
  nnoremap dofcr :call do#cmd#find_crlf(1, "")<cr>
  nnoremap doec  :call do#color#echo()<cr>

  nnoremap dorc  :RedirCommand<space>
  command! -nargs=* -complete=command RedirCommand call do#cmd#redir_cmd(<f-args>)
endif

let g:vimdo_default_prefix = get(g:, 'vimdo_default_prefix', 'do')
let g:vimdo = get(g:, 'vimdo', {})
let g:vimdo[g:vimdo_default_prefix] = extend({ 'label': 'do...',
      \ 'ws':  'trim whitespaces',
      \ 're':  'redir expression',
      \ 'rc':  'redir command',
      \ 'ut':  'update tags',
      \ 'vp':  'profiling',
      \ 'ds':  'diff saved',
      \ 'do':  'diff other',
      \ 'ec':  'echo color',
      \ 'dl':  'diff last revision',
      \ 'ssa': 'show syntax attributes',
      \ 'fcr': 'find files with CRLF endings',
      \}, get(g:vimdo, g:vimdo_default_prefix, {}))

if g:vimdo_default_prefix == 'do'
  nnoremap dO  :call do#show_all_dos('do')<cr>
  nnoremap doB :call do#show_buffer_dos('do')<cr>
endif

command! -nargs=? -bang ShowDos exe call('do#show_all_dos', <bang>0 ? [<q-args>, 1] : [<q-args>])

