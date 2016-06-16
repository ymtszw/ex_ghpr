# ExOpenpr

Simple CLI tool to open Github Pull Request.

It adds your issue tracker URL in Pull Request description,
and optionally post the resultant PR url back into your issue.

Written in Elixir and wrapping [github/hub](https://github.com/github/hub) CLI.

## Installation

0. Install [Erlang](http://erlang.org/) and [Elixir](http://elixir-lang.org/)
    - Personally recommend [asdf](https://github.com/asdf-vm/asdf) with
    [asdf-erlang](https://github.com/asdf-vm/asdf-erlang)/[asdf-elixir](https://github.com/asdf-vm/asdf-elixir)
    - The only actual dependency for the script is Erlang, but install Elixir for `mix`
1. Install [github/hub](https://github.com/github/hub) CLI
    - Instal via Homebrew if OSX, otherwise download binary, or clone & build
2. Clone this repository

      $ hub clone YuMatsuzawa/ex_openpr

3. Build (`mix` should be installed with Elixir)

      $ cd ex_openpr
      $ mix deps.get
      $ mix escript.build

Installed binary should be `~/.mix/escripts/openpr`.
Add `~/.mix/escripts` to your `PATH` env var (this is default escript installation path coming in Elixir 1.3).

## Usage

    $ openpr
