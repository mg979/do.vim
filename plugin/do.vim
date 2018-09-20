""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" do.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if get(g:, 'vimdo_use_default_commands', 1)
  nnoremap dows  :call do#cmd#trim_whitespaces()<cr>
  nnoremap dore  :call do#cmd#redir_expression()<cr>
  nnoremap dorc  :RedirCommand<space>
  nnoremap dout  :call do#cmd#update_tags()<cr>
  nnoremap dovp  :call do#cmd#profiling()<cr>
  nnoremap dods  :call do#diff#saved()<cr>
  nnoremap dodo  :call do#diff#other()<cr>
  nnoremap dodl  :call do#diff#last_revision()<cr>
  nnoremap dossa :call do#cmd#syntax_attr()<cr>
  nnoremap dofcr :call do#cmd#find_crlf(1, "")<cr>

  command! -nargs=* -complete=command RedirCommand call do#redir_cmd(<f-args>)
endif

let s:default = get(g:, 'vimdo_use_default_commands', 1) ? { 'label': 'do...',
      \ 'ws':  'trim whitespaces',
      \ 're':  'redir expression',
      \ 'rc':  'redir command',
      \ 'ut':  'update tags',
      \ 'vp':  'profiling',
      \ 'ds':  'diff saved',
      \ 'do':  'diff other',
      \ 'dl':  'diff last revision',
      \ 'ssa': 'show syntax attributes',
      \ 'fcr': 'find files with CRLF endings',
      \} : {}

let g:vimdo = get(g:, 'vimdo', {})
let g:vimdo.do = extend(s:default, get(g:vimdo, 'do', {}))

nnoremap dO :call do#show_all_dos()<cr>

command! -nargs=?                   ShowDos      call do#show_all_dos(<q-args>)

