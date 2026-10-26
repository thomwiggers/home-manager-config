# Prebuilt tree-sitter parsers from the binary cache, so a fresh machine
# doesn't compile LazyVim's ensure_installed list. They go where
# nvim-treesitter's own installer puts them (stdpath("data")/site), and
# nvim-treesitter itself is pinned to the nixpkgs build so the queries match
# the parsers. Languages not listed here still install (and compile) with
# :TSInstall.
{
  config,
  lib,
  pkgs,
  ...
}:
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

  # :TSUpdate reinstalls a parser whose parser-info/<lang>.revision differs
  # from parsers.lua, so record the revisions this nvim-treesitter expects.
  revisions = pkgs.runCommand "nvim-treesitter-revisions" { nativeBuildInputs = [ pkgs.luajit ]; } ''
    mkdir $out
    luajit ${pkgs.writeText "revisions.lua" ''
      local parsers = dofile("${treesitter}/lua/nvim-treesitter/parsers.lua")
      for _, lang in ipairs(arg) do
        local f = assert(io.open(os.getenv("out") .. "/" .. lang .. ".revision", "w"))
        f:write(parsers[lang].install_info.revision)
        f:close()
      end
    ''} ${lib.escapeShellArgs languages}
  '';
in
{
  xdg.dataFile = lib.mergeAttrsList (
    map (lang: {
      "nvim/site/parser/${lang}.so".source = "${treesitter.grammarPlugins.${lang}}/parser/${lang}.so";
      "nvim/site/parser-info/${lang}.revision".source = "${revisions}/${lang}.revision";
      "nvim/site/queries/${lang}".source = "${treesitter}/runtime/queries/${lang}";
    }) languages
  );

  # nvim-treesitter's installer replaces the links with real files and
  # directories (and did before this module existed). They are build output,
  # so remove them rather than have checkLinkTargets refuse to clobber them.
  home.activation.nvimTreesitterUnlink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for f in ${
      lib.escapeShellArgs (
        lib.concatMap (lang: [
          "${config.xdg.dataHome}/nvim/site/parser/${lang}.so"
          "${config.xdg.dataHome}/nvim/site/parser-info/${lang}.revision"
          "${config.xdg.dataHome}/nvim/site/queries/${lang}"
        ]) languages
      )
    }; do
      if [[ -e $f && ! -L $f ]]; then
        run rm -rf $VERBOSE_ARG "$f"
      fi
    done
  '';

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
