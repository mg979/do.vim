
## do.vim
------------------------------------------------------------------------------

The concept is to have a group of commands that `do something`, in a way that
it makes it easy to remember their mappings, and that you can show by typing `dO`.

There is a set of commands that you can activate, but it will work with any of
your mappings. All you need to do, is to define some mappings that start with
`do`, and they will be shown when you type `dO`.

What's the difference between this and just typing `:nmap do`?

- you can set descriptions for each mapping, and the output is more readable.
- you can filter entries.
- it can show the files where mappings are defined.
- it can be run in interactive mode.

But you're not limited to the `do` keyword, you can do the same with any other
mapping prefix, or create custom groups.


## Installation and usage
------------------------------------------------------------------------------

With vim-plug:
    
    Plug 'mg979/do.vim'

Documentation: `:help do-vim`


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

A compact and interactive group with [git commands](https://github.com/mg979/do.vim/blob/9ba9ee011f11902c411d348ea5142266ae085d78/doc/do-vim.txt#L253):

![Imgur](https://i.imgur.com/GeBhWNA.png)

Filtering a group:

![Imgur](https://i.imgur.com/D5H2aEg.gif)

Normal non-interactive groups:

![Imgur](https://i.imgur.com/niOSxSr.png)
![Imgur](https://i.imgur.com/QZvCr1p.png)
![Imgur](https://i.imgur.com/7UkOYZI.png)

