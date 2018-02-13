# ExGHPR

[![Build Status](https://travis-ci.org/ymtszw/ex_ghpr.svg?branch=master)](https://travis-ci.org/ymtszw/ex_ghpr)

`ghpr` command to work with GitHub Pull Request.

Inspired by [github/hub](https://github.com/github/hub) CLI. Written in Elixir.

## Features

- Open Pull Request
    - Automatically push, put title, write issue URL in description
    - Also, copy resultant Pull Request URL to clipboard
    - You can configure issue tracker URL and identities **per repository**
        - This is my original intension for this tool over `hub`!
- Search Pull Requests related to a SHA hash or file name

## Installation

0. Require Git (1.8+)
1. Install [Erlang](http://erlang.org/) and [Elixir](http://elixir-lang.org/)
    - Personally recommend [asdf](https://github.com/asdf-vm/asdf) with
    [asdf-erlang](https://github.com/asdf-vm/asdf-erlang)/[asdf-elixir](https://github.com/asdf-vm/asdf-elixir)
    - If you install via compiled binary, the only dependency is Erlang
    - If you want to build by yourself, Elixir and `mix` required
2. Install by either:
    - `mix`
        - Commands:
        ```
        $ mix escript.install hex ex_ghpr
        ```
        - Installed binary should be `~/.mix/escripts/ghpr`
        - Add `~/.mix/escripts` to your `PATH` env var (default escript installation path from Elixir 1.3)
    - downloading compiled binary from [here](https://github.com/ymtszw/ex_ghpr/releases/latest)

## Usage

    $ ghpr

This will do:

- Push your current branch to your `origin` repository
    - Just calling system's `git` command
    - That means, you should name a repository from which you send PR, as `origin`
    - Implicitly sets upstream by `--set-upstream` option on push
- Open Pull Request of the branch to the repository
    - Remote, base, title, description, fork user can be set with options
    - See below for default behaviors
- `pbcopy` (OSX) or `clip` (Windows) the resultant Pull Request URL
    - If neither exist, just print the URL

### Sub-commands and options

- `$ ghpr create`
    - Explicitly create Pull Request (to differentiate from `search`)
    - Always request to pull the current branch
- Options for `create`
    - `$ ghpr {-t|--title} <title>`
        - Manually set title of the Pull Request
        - Defaults to branch name
    - `$ ghpr {-m|--message} <description>`
        - Manually set description of the Pull Request
        - Defaults to issue URL (if issue tracker URL is set
        and the branch name starts with issue number)
        - If issue tracker URL is not set, no description will be attached
            - In Github, *"No description provided"* message will be shown
    - `$ ghpr {-r|--remote} <remote>`
        - Change target repository
        - `<remote>` must exist as `git remote` in the repository
        - Defaults to `origin`
    - `$ ghpr {-b|--base} <base>`
        - Change Pull Request target reference
        - Defaults to `master`. Can be branch name or tag
    - `$ ghpr --fork <username>`
        - Specify fork user for Cross-repository Pull Request
        - In API call, `head` parameter will become `<username>:<current_branch>`
        - Obviously, you need to fork the original repository first,
        if you are not authorized to push to it
    - `$ ghpr {-c|--configure} {local|global}`
        - Re-configuration
- `$ ghpr search <sha_hash>`
    - Search Pull Request related to a SHA hash, then open it in your browser
    - If no Pull Request found for that commit hash, nothing happens
- Options for `search`
    - `$ ghpr search {-l|--line} <number> <file_name>`
        - Blame specified line of the file, then search Pull Request related to the SHA hash
        - When you specify `--line`, `file_name` must be a valid file
    - `$ ghpr search {-r|--remote} <sha_hash>`
        - Change target repository
        - `<remote>` must exist as `git remote` in the repository
        - Defaults to `origin`


## Configuration

- On the first invocation of `$ ghpr`, it should ask you:
    - Your Github username and username
        - Used to acquire a [personal access token](https://github.com/blog/1509-personal-api-tokens)
        for `ex_ghpr` application, with `repo` access scope
        - You can always revoke access token via [Github web console](https://github.com/settings/tokens)
- On the first invocation of `$ ghpr` from the current git repo directory, it should ask you:
    - Whether you want to use the default user, or different user for that repo
    - Your issue tracker URL for the repo
    (will be used to build an issue URL. Must not end with `/`)
- Configurations and tokens will be stored in `~/.config/ghpr` as JSON format
- Configurations are held per local repository

## License

BSD-3-Clause
