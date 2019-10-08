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

let g:vimdo = get(g:, 'vimdo', {})

command! -nargs=? -bang ShowDos call do#show_all_dos(<q-args>, <bang>0)

if get(g:, 'vimdo_use_default_commands', 0)
  let g:vimdo_default_prefix = get(g:, 'vimdo_default_prefix', 'do')
  let s:p = g:vimdo_default_prefix

  exe 'nnoremap          '.s:p.'cf  :call do#cmd#copy_file()<cr>'
  exe 'nnoremap <silent> '.s:p.'dh  :call do#diff#last_revision(1)<cr>'
  exe 'nnoremap <silent> '.s:p.'dl  :call do#diff#last_revision(0)<cr>'
  exe 'nnoremap <silent> '.s:p.'do  :call do#diff#other()<cr>'
  exe 'nnoremap <silent> '.s:p.'ds  :call do#diff#saved()<cr>'
  exe 'nnoremap <silent> '.s:p.'ec  :call do#color#echo()<cr>'
  exe 'nnoremap <silent> '.s:p.'fT  :call do#cmd#open_ftplugin(1)<cr>'
  exe 'nnoremap <silent> '.s:p.'fcr :call do#cmd#find_crlf(1, "")<cr>'
  exe 'nnoremap <silent> '.s:p.'ft  :call do#cmd#open_ftplugin()<cr>'
  exe 'nnoremap <silent> '.s:p.'re  :call do#cmd#redir_expression()<cr>'
  exe 'nnoremap <silent> '.s:p.'sn  :call do#cmd#snippets()<cr>'
  exe 'nnoremap <silent> '.s:p.'ssa :call do#cmd#syntax_attr()<cr>'
  exe 'nnoremap <silent> '.s:p.'sw  :call do#cmd#delete_swap()<cr>'
  exe 'nnoremap <silent> '.s:p.'ut  :call do#cmd#update_tags()<cr>'
  exe 'nnoremap <silent> '.s:p.'vp  :call do#cmd#profiling()<cr>'
  exe 'nnoremap <silent> '.s:p.'ws  :call do#cmd#trim_whitespaces()<cr>'

  exe 'nnoremap '.s:p.'rc  :RedirCommand<space>'
  exe 'nnoremap '.s:p.'    <NOP>'

  if g:vimdo_default_prefix ==# 'do'
    nnoremap dO  :ShowDos<cr>
    nnoremap doB :ShowDos!<cr>
  else
    exe 'nnoremap '.s:p.'? :ShowDos<cr>'
    exe 'nnoremap '.s:p.'@ :ShowDos!<cr>'
  endif

  command! -nargs=* -complete=command RedirCommand call do#cmd#redir_cmd(<f-args>)

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
endif

"------------------------------------------------------------------------------

let &cpo = s:save_cpo
unlet s:save_cpo
