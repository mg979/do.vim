"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Miscellaneous commands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! do#cmd#profiling()
  "{{{1
  for b in range(1, bufnr('$'))
    if getbufvar(b, '&modified')
      return do#msg("There are unsaved buffers, aborting.")
    endif
  endfor
  if !exists('s:profiling_active')
    call do#msg("Profiling activated", 1)
    let s:profiling_active = 1
    if has('nvim')
      profile start nprofile.log
    else
      profile start profile.log
    endif
    profile func *
    profile file *
  else
    profile pause
    noautocmd qall
  endif
endfun "}}}

fun! do#cmd#reindent_file()
  " {{{1
  let view = winsaveview()
  keepjumps normal! gg=G
  call winrestview(view)
endfun "}}}

fun! do#cmd#copy_file()
  "{{{1
  let [ base, ext, n ] = [ expand('%:r'), expand('%:e'), 1 ]
  let go_left = repeat("\<Left>",len(ext)+1)
  let new = base . "_copy"
  while filereadable(new . "." . ext)
    let n += 1
    let new = base . "_copy" . n
  endwhile
  call feedkeys(":saveas ". fnameescape(new) . "." . ext . go_left, 'n')
endfun "}}}

fun! do#cmd#open_ftplugin(...)
  "{{{1
  let sl = has('win32') ? '\\' : '/'
  let scripts = filter(split(execute('scriptnames'), "\n"),
        \              'v:val =~ '''.sl.'ftplugin'.sl.&ft.'\.vim''')
  call map(scripts, 'substitute(v:val, ''^\s*\d\+:\s\+'', "", "")')
  let pat = has('win32') ?
        \     has('nvim') ? '\\share\\nvim' : escape($VIM, '\')
        \   : has('nvim') ? '\/share\/nvim' : 'vim\/vim\d\d'
  let default = filter(copy(scripts), 'v:val =~ '''.pat.'''')
  if a:0
    call filter(scripts, 'v:val !~ '''.pat.'''')
    call extend(scripts, default)
  else
    let valid = has('win32') ?
          \ ['~\vimfiles\after', '~\vimfiles\ftplugin'] :
          \ ['~/.vim/after',     '~/.vim/ftplugin']
    call map(valid, 'resolve(fnamemodify(v:val, ":p"))')
    call map(scripts, 'resolve(fnamemodify(v:val, ":p"))')
    let ok = []
    for path in valid
      for script in scripts
        if stridx(script, path) != -1
          call add(ok, script)
        endif
      endfor
    endfor
    let scripts = copy(ok)
  endif
  let ok = 0

  for script in scripts
    try
      if !ok
        exe "leftabove vs" script
        setfiletype vim
      else
        exe "rightbelow sp" script
        setfiletype vim
      endif
      let ok = 1
    catch
      continue
    endtry
  endfor

  if ok | return | endif
  try
    exe "leftabove vs" default[0]
    setfiletype vim
  catch
    call do#msg('No ftplugin file in standard locations')
  endtry
endfun "}}}

fun! do#cmd#snippets()
  "{{{1
  if exists(':UltiSnipsEdit')
    UltiSnipsEdit
  elseif exists(':SnipMateOpenSnippetFiles')
    SnipMateOpenSnippetFiles
  elseif exists(':VsnipOpenVsplit!')
    VsnipOpenVsplit!
  elseif exists(':Snippets')
    Snippets
  else
    echo "[do.vim] No snippets plugin detected."
  endif
endfun "}}}

fun! do#cmd#update_tags()
  "{{{1
  if filereadable('./tags')
        \ || confirm('tags not found. Generate?', "&Yes\n&No", 2) == 1
    let f = './tags'
    let cmd = get(b:, 'ctags_cmd',
          \   get(g:, 'fzf_tags_command',
          \   executable('ctags-universal') ? 'ctags-universal -R' : 'ctags -R'))
    let error = system(cmd)
  else
    redraw!
    return do#msg("Tags not updated.")
  endif
  if empty(error)
    call do#msg("Tags in ".f." updated.", 1)
  else
    call do#msg(error)
  endif
endfun "}}}

fun! do#cmd#find_crlf(bang, dir)
  "{{{1
  if has('win32') && (!executable('fd') || !executable('file') || !executable('grep') || !executable('sed'))
    return do#msg('executables needed: fd, file, grep, sed')
  endif
  let dir = empty(a:dir) ? '.' : a:dir
  if !isdirectory(dir)
    return do#msg("Invalid Directory")
  elseif fnamemodify('.', ":p") == expand("~") &&
        \ confirm("This is your home directory!", "&Yes\n&No", 2) != 1
    return
  endif
  if has('win32')
    let files = map(systemlist('fd . -t f -x file {} | grep "with CRLF" | sed "s#\./##" | sed "s/[:;].*//"'), 'substitute(v:val, "\r", "", "")')
  elseif executable('fd')
    let files = systemlist("fd . -t f -x file {} | grep 'with CRLF' | sed 's#\./##' | sed 's/:.*//'")
  else
    let files = systemlist("file $(find . -type f) | grep 'with CRLF' | sed 's#\./##' | sed 's/:.*//'")
  endif
  if empty(files) | return do#msg("No results.") | endif
  let list = []
  for file in files
    call add(list, {'filename': file,
          \         'text': has('win32') ? file : system("file ".file." | sed 's/.*:/ /'"),
          \         'lnum': 1, 'col':1})
  endfor
  call setqflist(list)
  if a:bang && confirm("Autoconvert to LF?", "&Yes\n&No", 2) == 1
    cfdo set fileformat=unix
    if confirm("Save all?", "&Yes\n&No", 1) == 1
      wall
    endif
    return
  endif
  copen
  cfirst
endfun "}}}

fun! do#cmd#syntax_attr()
  "{{{1
  "Edited from Gary Holloway version:
  "https://www.vim.org/scripts/script.php?script_id=383

  let synid = ""
  let guifg = ""
  let guibg = ""
  let gui   = ""

  let id1  = synID(line("."), col("."), 1)
  let tid1 = synIDtrans(id1)

  if synIDattr(id1, "name") != ""
    let synid = synIDattr(id1, "name")
    if (tid1 != id1)
      let synid = synid . ' -> ' . synIDattr(tid1, "name")
    endif
    let id0 = synID(line("."), col("."), 0)
    if (synIDattr(id1, "name") != synIDattr(id0, "name"))
      let synid = synid .  " (" . synIDattr(id0, "name")
      let tid0 = synIDtrans(id0)
      if (tid0 != id0)
        let synid = synid . ' -> ' . synIDattr(tid0, "name")
      endif
      let synid = synid . ")"
    endif
  endif

  " Use the translated id for all the color & attribute lookups; the linked id yields blank values.
  if (synIDattr(tid1, "fg") != "" )
    let guifg = " guifg=" . synIDattr(tid1, "fg") . "(" . synIDattr(tid1, "fg#") . ")"
  endif
  if (synIDattr(tid1, "bg") != "" )
    let guibg = " guibg=" . synIDattr(tid1, "bg") . "(" . synIDattr(tid1, "bg#") . ")"
  endif
  if (synIDattr(tid1, "bold"     ))
    let gui   = gui . ",bold"
  endif
  if (synIDattr(tid1, "italic"   ))
    let gui   = gui . ",italic"
  endif
  if (synIDattr(tid1, "reverse"  ))
    let gui   = gui . ",reverse"
  endif
  if (synIDattr(tid1, "inverse"  ))
    let gui   = gui . ",inverse"
  endif
  if (synIDattr(tid1, "underline"))
    let gui   = gui . ",underline"
  endif
  if (gui != ""                  )
    let gui   = substitute(gui, "^,", " gui=", "")
  endif

  let message = synid . guifg . guibg . gui
  if message == ""
    echohl WarningMsg
    echo "<no syntax group here>"
  else
    redir => vv
    silent! verbose exe "hi" synIDattr(synIDtrans(id0), "name")
    redir END
    let setby = split(split(vv, "\n")[-1])[-1]
    let setby = setby != 'cleared' ? setby : ''
    echohl Title
    echo synid
    echohl None
    echon "\t".guifg . guibg . gui
    echohl Label
    echon "\t".setby
    exe "hi" synIDattr(synIDtrans(id0), "name")
  endif
  echohl None
  silent! call repeat#set(":\<c-u>call do#cmd#syntax_attr()\<cr>", 1)
endfun "}}}

fun! do#cmd#colortw()
  "{{{1
  if exists('w:ccmatch')
    call matchdelete(w:ccmatch)
    unlet w:ccmatch
    if exists('s:ccsearch')
      if @/ == s:ccsearch
        let @/ = s:ccoldsearch
      endif
      unlet s:ccoldsearch
      unlet s:ccsearch
    endif
  else
    let w:ccmatch = matchadd('Error', '\%>'. &tw .'c.*.$')
    if !exists('s:ccoldsearch')
      let s:ccoldsearch = @/
    endif
    let s:ccsearch = '\%>'. &tw .'c.*.$'
    let @/ = s:ccsearch
    normal! n
  endif
endfun "}}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Section: Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:store_reg() "{{{1
  let s:oldreg = [getreg("\""), getregtype("\"")]
endfun

fun! s:restore_reg() "{{{1
  call setreg("\"", s:oldreg[0], s:oldreg[1])
endfun

"}}}


" vim: et sw=2 ts=2 sts=2 fdm=marker
