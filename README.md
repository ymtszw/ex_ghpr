# ExGHPR

CLI tool to work with Github Pull Request.

Inspired by [github/hub](https://github.com/github/hub) CLI. Written in Elixir.

## Features

- Open Pull Request
    - It adds your issue URL in Pull Request description,
    and open the issue with resultant Pull Request URL copied to clipboard (only available in OSX)
    - You can configure issue tracker URL and user **per repository**
        - This is my original intension for this tool over `hub`!
- Search Pull Requests related to a SHA hash (NYI)
- Help welcomed :) Especially:
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
    - If you build by yourself, Elixir and `mix` required
2. Install by either:
    - self building
    ```
    $ git clone https://github.com/YuMatsuzawa/ex_ghpr
    $ cd ex_ghpr
    $ mix deps.get
    $ mix escript.build
    ```
        - Installed binary should be `~/.mix/escripts/ghpr`
        - Add `~/.mix/escripts` to your `PATH` env var
            - (this is default escript installation path coming in Elixir 1.3)
    - downloading compiled binary (TBD)

## Usage

    $ ghpr

This will do:

- Push your current branch to your `origin` repository
    - Just calling system's `git` command
- Open Pull Request of the branch to the repository
    - Remote, base, title, description, fork user can be set with options
    - See bellow for default behaviors
- If OSX, `pbcopy` the resultant Pull Request URL, then `open <your_issue_tracker_url>/<issue_number>`
    - If the system does not have `pbcopy` command, just print the URL then exit
    - If the issue tracker is Github issue, Pull Request auto-link should already be there
    - Otherwise, it is good practice to post your Pull Request URL to the issue!

### Sub-commands and options

- Explicitly create Pull Request (to differentiate from `search`)
```
$ ghpr create
```
    - Always request to pull the current branch
- Options for `create`
    - Manually set title of the Pull Request
    ```
    $ ghpr {-t|--title} <title>
    ```
        - Defaults to branch name
    - Manually set description of the Pull Request
    ```
    $ ghpr {-m|--message} <description>
    ```
        - Defaults to issue URL (if issue tracker URL is set
        and the branch name starts with issue number)
        - If issue tracker URL is not set, no description will be attached
            - In Github, *No description provided* message will be shown
    - Change target repository
    ```
    $ ghpr {-r|--remote} <remote>
    ```
        - `<remote>` must exist as `git remote` in the repository
        - Defaults to `origin`
    - Change base reference to be pulled
    ```
    $ ghpr {-b|--base} <base>
    ```
        - Defaults to `master`. Can be branch name or tag
    - Specify fork user for Cross-repository Pull Request
    ```
    $ ghpr --fork <username>
    ```
        - In API call, `head` parameter will become `<username>:<current_branch>`
        - Obviously, you need to fork the original repository first,
        to request pull if you are not authorized to push
        - You can create Pull Request only from the repository itself, or forked repositories
    - Re-configuration
    ```
    $ ghpr {-c|--configure} {local|global}
    ```
- Search Pull Request related to a SHA hash (NYI)
```
$ ghpr search <sha_hash>
```
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
