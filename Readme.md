## do.vim
------------------------------------------------------------------------------

The concept is to have a group of commands that `do something`, in a way that
it makes it easy to remember their mappings, and that you can show by running
a command.

There is a default prefix (`do`) with a set of commands that you can activate,
but it will work with any of your mappings.

What's the difference between this and just typing `:nmap ...`?

- you can set descriptions for each mapping, and the output is more readable.
- you can filter entries by pressing a key.
- it can show the files where mappings are defined.
- it can be run in interactive mode.



## Quick start
------------------------------------------------------------------------------

Use the main command to show all mappings that start with a prefix:
 
    :ShowDos g
 
you don't need any customization for this. But if you want to add some
description to your custom mappings?

Say you have a bunch of mappngs that start with `g`, and you want to add some
description, so that it will show up when you run the command above.
You create a group for `g`, and you write the descriptions inside:
 
    let g:vimdo = {}
    let g:vimdo.g = {}
    let g:vimdo.g.cc = 'comment line toggle'
    let g:vimdo.g.ot = 'open terminal at current file position'

Where the keys inside the `g` group are the mappings `gcc`, `got`, etc.

If some of these mappings are `buffer` mappings (for example you defined them
in a `ftplugin`), you can call the command with a `bang`, and it will only
show `buffer` mappings:
 
    :ShowDos! g

That's it for a basic usage.




## Installation and usage
------------------------------------------------------------------------------

With vim-plug:
    
    Plug 'mg979/do.vim'

Documentation: `:help do.vim`




## Is this similar to...
------------------------------------------------------------------------------

[vim-leader-guide](https://github.com/hecal3/vim-leader-guide): *do.vim* can be
run in interactive mode, but not by default. Its main purpose is to provide a
quick reference for commands, in a readable and informative way, not to run the
command themselves. And it doesn't even need to be configured, for its most
basic usage.

[vim-unimpaired](https://github.com/tpope/vim-unimpaired): it's somewhat
inspired by it, but it doesn't define mappings, it just shows them. You could
use them together.



## Examples
------------------------------------------------------------------------------

A compact and interactive group with [git commands](https://github.com/mg979/do.vim/blob/b5c51e9046d3a122cfb90b0610febdc672ab6b21/doc/do-vim.txt#L264)

![Imgur](https://i.imgur.com/GeBhWNA.png)

Filtering a group:

![Imgur](https://i.imgur.com/D5H2aEg.gif)

Normal non-interactive groups:

![Imgur](https://i.imgur.com/niOSxSr.png)
![Imgur](https://i.imgur.com/QZvCr1p.png)
![Imgur](https://i.imgur.com/7UkOYZI.png)

More examples in the [wiki](https://github.com/mg979/do.vim/wiki).

