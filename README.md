# ExGHPR

`ghpr` command to work with GitHub Pull Request.

Inspired by [github/hub](https://github.com/github/hub) CLI. Written in Elixir.

## Features

- Open Pull Request
    - Automatically push, put title, write issue URL in description
    - Also, copy resultant Pull Request URL to clipboard, open issue URL in browser
    - You can configure issue tracker URL and identities **per repository**
        - This is my original intension for this tool over `hub`!
- Search Pull Requests related to a SHA hash (NYI)
- Help welcomed!! Especially:
    - Automatically create fork if the user is not authorized to push to the target repository
    - Post resultant Pull Request URL to other issue trackers like Redmine/JIRA, via API
        - Obviously, storing issue tracker type and API credentials is required
    - Support Multi Factor Authentication

## Installation

0. Require Git
1. Install [Erlang](http://erlang.org/) and [Elixir](http://elixir-lang.org/)
    - Personally recommend [asdf](https://github.com/asdf-vm/asdf) with
    [asdf-erlang](https://github.com/asdf-vm/asdf-erlang)/[asdf-elixir](https://github.com/asdf-vm/asdf-elixir)
    - If you install via compiled binary, the only dependency is Erlang
    - If you want to build by yourself, Elixir and `mix` required
2. Install by either:
    - self building
        - Commands:
        ```
        $ git clone https://github.com/YuMatsuzawa/ex_ghpr
        $ cd ex_ghpr
        $ mix deps.get
        $ mix escript.build
        ```
        - Installed binary should be `~/.mix/escripts/ghpr`
        - Add `~/.mix/escripts` to your `PATH` env var
            - This will be the default escript installation path coming in Elixir 1.3
    - downloading compiled binary from [here](https://github.com/YuMatsuzawa/ex_ghpr/releases/latest)

## Usage

    $ ghpr

This will do:

- Push your current branch to your `origin` repository
    - Just calling system's `git` command
- Open Pull Request of the branch to the repository
    - Remote, base, title, description, fork user can be set with options
    - See bellow for default behaviors
- `pbcopy` (OSX) or `clip` (Windows) the resultant Pull Request URL
    - If neither exist, just print the URL
- `open` (OSX) or `cmd /c start` (Windows) the issue URL
    - If the issue tracker is Github issue, Pull Request auto-link should already be there
    - Otherwise, it is good practice to post your Pull Request URL to the issue!

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
    - Search Pull Request related to a SHA hash **(NYI)**
    - `-r` option also works. Useful for forked repositories


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
