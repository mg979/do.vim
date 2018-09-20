""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" do.vim
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if get(g:, 'vimdo_use_default_commands', 1)
  nnoremap dows  :call do#trim_whitespaces()<cr>
  nnoremap dore  :call do#redir_expression()<cr>
  nnoremap dorc  :RedirCommand<space>
  nnoremap dout  :call do#update_tags()<cr>
  nnoremap dovp  :call do#profiling()<cr>
  nnoremap dods  :call do#diff_with_saved()<cr>
  nnoremap dodo  :call do#diff_with_other()<cr>
  nnoremap dodl  :call do#diff_last_revision()<cr>
  nnoremap dossa :call do#syntax_attr()<cr>
  nnoremap dofcr :call do#find_crlf(1, "")<cr>

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

