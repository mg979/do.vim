
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
- it can show the files where mappings are defined (not by default).

But you're not limited to the `do` keyword, you can do the same with any other
mapping prefix.


## Installation and usage
------------------------------------------------------------------------------

With vim-plug:
    
    Plug 'mg979/do.vim'

Documentation: `:help do-vim`


## Is this similar to...
------------------------------------------------------------------------------

[vim-leader-guide](https://github.com/hecal3/vim-leader-guide): no, it's not
interactive, but it can be more readable and informative. It is meant to be
used as a quick reference for commands, not to run the command themselves. And
it doesn't even need to be configured, for its most basic usage.

[vim-unimpaired](https://github.com/tpope/vim-unimpaired): it's somewhat
inspired by it, but it doesn't define mappings, it just shows them. You can
use them together.


## Examples
------------------------------------------------------------------------------

![Imgur](https://i.imgur.com/niOSxSr.png)
![Imgur](https://i.imgur.com/QZvCr1p.png)
![Imgur](https://i.imgur.com/7UkOYZI.png)
