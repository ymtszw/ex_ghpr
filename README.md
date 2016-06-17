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
    - Change push target and Pull Request target repository
        - e.g. Push the branch to your fork, then PR to the upstream
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
- Open Pull Request of the branch in the repository
    - Add the branch name as title
    - You can input arbitrary message as description. Without message given, `ghpr` will either:
        - add `<your_issue_tracker_url>/<issue_number>` as description if the branch name start with `<issue_number>_`
        - put nothing. In Github, *No description provided* message will be shown
- If OSX, `pbcopy` the resultant Pull Request URL, then `open <your_issue_tracker_url>/<issue_number>`
    - If the system does not have `pbcopy` command, just print the URL then exit
    - If the issue tracker is Github issue, Pull Request auto-link should already be there
    - Otherwise, it is good practice to post your Pull Request URL to the issue!

### Commands and options

- Explicitly call Create Pull Request command (to differentiate from `search`)
```
$ ghpr create
```
- Put description in Pull Request
```
$ ghpr -m <description>
```
- Change target repository (note: `<remote>` must exist as `git-remote` in the repository)
```
$ ghpr -r <remote>
```
- Re-configuration
```
$ ghpr -c {local|global}
```
- Search Pull Request related to a SHA hash (NYI)
```
$ ghpr search <sha_hash>
```
    - `-r` option also works


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
