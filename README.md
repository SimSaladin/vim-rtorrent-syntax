# `vim-rtorrent-syntax`: Enhanced rTorrent (`rtorrent.rc`) syntax highlighting

This plugin implements syntax highlighting for modern `rtorrent.rc`. Includes:

- Syntax highlighting of `rtorrent.rc` statements.
  - Nested parentheses are displayed with different colors (up to 4 levels by
    default).
  - Commands that are written as string literals are also highlighted in
    many places.
- Folding by the way of `foldmethod=syntax` (enabled automatically).
- Indentation by the way of a custom `indentexpr` (enabled automatically).
- Further links:
  - [Standard rtorrent methods](https://github.com/rakshasa/rtorrent/wiki/Command%E2%80%90Reference%E2%80%90Complete#dynamic-method-commands-method)

## Screenshot

![Example `rtorrent.rc`](./docs/demo.svg#1232)

## Installation

Install this plugin with a preferred Vim plugin manager.

### Dein Example

```toml
[[plugins]]
repo = 'SimSaladin/vim-rtorrent-syntax'
```

### Manual Example

```bash
cd ~/.vim/pack/git-plugins/start
git clone https://github.com/SimSaladin/vim-rtorrent-syntax
```

Install in Vim with: `:packadd vim-rtorrent-syntax`.

## License

Distributed under the same terms as Vim itself. See `:help license`.
