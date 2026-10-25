# Prebuilt tree-sitter parsers from the binary cache, so a fresh machine
# doesn't compile LazyVim's ensure_installed list. They go where
# nvim-treesitter's own installer puts them (stdpath("data")/site), and
# nvim-treesitter itself is pinned to the nixpkgs build so the queries match
# the parsers. Languages not listed here still install (and compile) with
# :TSInstall.
{ lib, pkgs, ... }:
let
  treesitter = pkgs.vimPlugins.nvim-treesitter;

  # LazyVim's default ensure_installed, plus its lang.nix extra.
  languages = [
    "bash"
    "c"
    "diff"
    "html"
    "javascript"
    "jsdoc"
    "json"
    "lua"
    "luadoc"
    "luap"
    "markdown"
    "markdown_inline"
    "printf"
    "python"
    "query"
    "regex"
    "toml"
    "tsx"
    "typescript"
    "vim"
    "vimdoc"
    "xml"
    "yaml"
    "nix"
  ];
in
{
  xdg.dataFile = lib.mergeAttrsList (
    map (lang: {
      "nvim/site/parser/${lang}.so".source = "${treesitter.grammarPlugins.${lang}}/parser/${lang}.so";
      "nvim/site/queries/${lang}".source = "${treesitter}/runtime/queries/${lang}";
    }) languages
  );

  # build = false: LazyVim's build hook runs :TSUpdate, which would rebuild
  # the linked parsers.
  xdg.configFile."nvim/lua/plugins/nix.lua".text = ''
    return {
      {
        "nvim-treesitter/nvim-treesitter",
        dir = "${treesitter}",
        pin = true,
        build = false,
      },
    }
  '';
}
