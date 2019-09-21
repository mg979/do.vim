" ========================================================================///
" Author:      Gianmaria Bajo <mg1979.git@gmail.com>
" Description: do something with 'do' mappings
" Mantainer:   Gianmaria Bajo <mg1979.git@gmail.com>
" Url:         https://github.com/mg979/do.vim
" License:     The MIT License (MIT)
" Created:     lun 08 ottobre 2018 17:12:17
" Modified:    lun 27 maggio 2019 19:40:12
" ========================================================================///

let s:save_cpo = &cpo
set cpo&vim

"------------------------------------------------------------------------------

if exists('g:loaded_vimdo')
  finish
endif
let g:loaded_vimdo = 1

if get(g:, 'vimdo_use_default_commands', 0)
  nnoremap          docf  :call do#cmd#copy_file()<cr>
  nnoremap <silent> dodh  :call do#diff#last_revision(1)<cr>
  nnoremap <silent> dodl  :call do#diff#last_revision(0)<cr>
  nnoremap <silent> dodo  :call do#diff#other()<cr>
  nnoremap <silent> dods  :call do#diff#saved()<cr>
  nnoremap <silent> doec  :call do#color#echo()<cr>
  nnoremap <silent> dofT  :call do#cmd#open_ftplugin(1)<cr>
  nnoremap <silent> dofcr :call do#cmd#find_crlf(1, "")<cr>
  nnoremap <silent> doft  :call do#cmd#open_ftplugin()<cr>
  nnoremap <silent> dore  :call do#cmd#redir_expression()<cr>
  nnoremap <silent> dosn  :call do#cmd#snippets()<cr>
  nnoremap <silent> dossa :call do#cmd#syntax_attr()<cr>
  nnoremap <silent> dosw  :call do#cmd#delete_swap()<cr>
  nnoremap <silent> dout  :call do#cmd#update_tags()<cr>
  nnoremap <silent> dovp  :call do#cmd#profiling()<cr>
  nnoremap <silent> dows  :call do#cmd#trim_whitespaces()<cr>

  nnoremap dorc  :RedirCommand<space>
  nnoremap do    <NOP>
  command! -nargs=* -complete=command RedirCommand call do#cmd#redir_cmd(<f-args>)
endif

let g:vimdo_default_prefix = get(g:, 'vimdo_default_prefix', 'do')
let g:vimdo = get(g:, 'vimdo', {})
let g:vimdo[g:vimdo_default_prefix] = extend({ 'label': 'do...',
      \ 'cf':  'copy file',
      \ 'dh':  'diff with HEAD',
      \ 'dl':  'diff last revision',
      \ 'do':  'diff other',
      \ 'ds':  'diff saved',
      \ 'sw':  'delete swap',
      \ 'ec':  'echo color',
      \ 'fT':  'ftplugin file (default)',
      \ 'fcr': 'find files with CRLF endings',
      \ 'ft':  'ftplugin file',
      \ 'rc':  'redir command',
      \ 're':  'redir expression',
      \ 'sn':  'open snippets file',
      \ 'ssa': 'show syntax attributes',
      \ 'ut':  'update tags',
      \ 'vp':  'profiling',
      \ 'ws':  'trim whitespaces',
      \}, get(g:vimdo, g:vimdo_default_prefix, {}))

if g:vimdo_default_prefix == 'do'
  nnoremap dO  :call do#show_all_dos('do')<cr>
  nnoremap doB :call do#show_buffer_dos('do')<cr>
endif

command! -nargs=? -bang ShowDos call do#show_all_dos(<q-args>, <bang>0)

"------------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo
