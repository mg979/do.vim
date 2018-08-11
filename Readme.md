
## vim-do
------------------------------------------------------------------------------

This plugin is more an idea than anything else. There are only a couple of
included commands, but you can start with an empty set.

It is essentially a bunch of remaps that start with `do`. Predefined commands
are:

|||
|-|-|
|dods | do diff with saved|
|dorc | do redir command (command output to new buffer)|
|dore | do redir echo (echo       ,,     ,,  ,,  ,,   )|
|dows | do trim whitespaces|
|dovp | do vim profiling (first time activates, second time stops and quits)|

`dO`   ->  show all do's

The concept is to have a group of commands that `do something`, in a way that
you don't need to remember abstruse mappings, and that you can show by typing `dO`.


## Configure
------------------------------------------------------------------------------

If you don't want the default commands:

	let g:vimdo_use_default_commands = 0

If you want to make <Plug> mappings:

	let g:vimdo_make_plugs = 1

If you want to add/override commands, make a new dictionary:

	let g:vimdo = {
	\ ...
	\}

This is the dict with the default commands. If you don't want defaults, but
want some of them, add them to your `g:vimdo` dict:

	let g:vimdo = {
		\ 'ws': ['trim whitespaces', ':call do#trim_whitespaces()<cr>' ],
		\ 're': ['redir expression',       ':call do#redir_expression()<cr>'       ],
		\ 'rc': ['redir command',        ':call do#redir_cmd()<cr>'        ],
		\ 'vp': ['profiling',        ':call do#profiling()<cr>'        ],
		\ 'ds': ['diff with saved',  ':call do#diff_with_saved()<cr>'  ],
		\}

These are some extra commands I use:

	let g:vimdo.sa = ['select all',       'ggVG']
	let g:vimdo.ca = ['copy all',         ':%y+<cr>']
	let g:vimdo.rf = ['reindent file',    'mzgg=G`z']


## Define mappings
------------------------------------------------------------------------------

This is the structure of the g:vimdo dictionary:

    let g:vimdo = {
        \ trigger: [name, rhs, options],
        \ ...
        \}

|||
|-|-|
|trigger | the mapping after 'do' |
|name    | the string for `show all do's`, and how the plug will be named |
|rhs     | the {rhs} of the generated mapping. |
|options | optional, and is a string |

`options` is a sequence of characters and can contain:
  * `r` -> mapping is recursive
  * `e` -> is `<expr>`
  * `s` -> is `<silent>`
  * `m` -> is `map` and not `nmap`
  * `x` -> is `xmap`
  * `v` -> is `vmap`
  * `o` -> is `omap`

Without `options`, mappings are generated like:

    nnoremap <trigger> <plugname> <rhs>

If 'options' were `xres`, mapping wuold be:

    xmap <trigger> <silent><expr> <plugname> <rhs>




