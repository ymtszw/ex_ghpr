# ExOpenpr

Simple CLI tool to open Github Pull Request.

It adds your issue URL in Pull Request description,
and open the issue with resultant Pull Request URL copied to clipboard (only available in OSX).

Inspired by [github/hub](https://github.com/github/hub) CLI. Written in Elixir.

## Installation

0. Require Git
1. Install [Erlang](http://erlang.org/) and [Elixir](http://elixir-lang.org/)
    - Personally recommend [asdf](https://github.com/asdf-vm/asdf) with
    [asdf-erlang](https://github.com/asdf-vm/asdf-erlang)/[asdf-elixir](https://github.com/asdf-vm/asdf-elixir)
    - The only actual dependency for the script is Erlang, but install Elixir for `mix`
2. Clone this repository
  ```
  $ git clone https://github.com/YuMatsuzawa/ex_openpr
  ```

3. Build (`mix` should be installed with Elixir)
  ```
  $ cd ex_openpr
  $ mix deps.get
  $ mix escript.build
  ```

Installed binary should be `~/.mix/escripts/openpr`.
Add `~/.mix/escripts` to your `PATH` env var (this is default escript installation path coming in Elixir 1.3).

## Usage

    $ openpr

This will do:

- Push your current branch to your `origin` repository
    - Just calling system's `git` command
- Open Pull Request of the branch in the repository
    - Add the branch name as title
    - You can input arbitrary message as description. Without message given, `openpr` will either:
        - add `<your_issue_tracker_url>/<digits>` as description if the branch name start with `<digits>_`
        - put nothing. In Github, *No description provided* message will be shown
- If OSX, `pbcopy` the resultant Pull Request URL, then `open <your_issue_tracker_url>/<digits>`
    - Using `:os.type/0` to tell if the OS is OSX, with matching against `{:unix, :darwin}`.
    Obviously this makes another distributions to be falsely recognized as OSX
    - If the issue tracker is Github issue, Pull Request auto-link should already be there
    - Otherwise, it is good practice to post your Pull Request URL to the issue!

## Configuration

- On the first invocation of `$ openpr`, it should ask you:
    - Your Github username and username
        - Used to acquire a [personal access token](https://github.com/blog/1509-personal-api-tokens)
        for `ex_openpr` application, with `repo` access scope
        - You can always revoke access token via [Github web console](https://github.com/settings/tokens)
- On the first invocation of `$ openpr` from the current git repo directory, it should ask you:
    - Whether you want to use the default user, or different user for that repo
    - Your issue tracker URL for the repo
    (will be used to build an issue URL. So must not end with `/`)
- Configurations and tokens will be stored in `~/.config/openpr` as JSON format
- Configurations are held per local repository
    - So **you can use different identities per repository**
    - This is a clear advantage over `hub`!

## Features

- Nothing else! Help welcomed :)
- Especially:
    - Change push target and Pull Request target repository
        - e.g. Push the branch to your fork, then PR to the upstream
    - Customize Pull Request title and description
    - Post resultant Pull Request URL to other issue trackers like Redmine/JIRA, via API
        - Obviously, storing issue tracker type and API credentials is required
