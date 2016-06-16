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
    - `hub` command must be useable from your current shell
2. Clone this repository
  ```
  $ hub clone YuMatsuzawa/ex_openpr
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
- Open Pull Request of the branch in the repository
    - Add the branch name as title
    - If the branch name start with `<digits>_`, use the `<digits>` as an issue number,
    and add `<your_issue_tracker_url>/<digits>` as description
- If OSX, `pbcopy` the resultant Pull Request URL, then `open <your_issue_tracker_url>/<digits>`
    - Using `:os.type/0` to tell if the OS is OSX, with matching against `{:unix, :darwin}`.
    Obviously this makes another distributions to be falsely recognized as OSX
    - If the issue tracker is Github issue, Pull Request auto-link should already be there
    - Otherwise, you better post your Pull Request URL to the issue!

## Configuration

- On the first invocation of `$ openpr`, it should ask Your issue tracker URL
(will be used to build an issue URL. So must not end with `/`)
- Configurations will be stored in `~/.config/openpr` as JSON format
- Configurations are held per local repository
- For `hub` command, you need to configure it by yourself:
    - On first invocation of `hub`, it should ask your Github username and password
    - It authenticate you to Github, then put your oauth token in `~/.config/hub`
    - Due to the fact that `hub` cannot use multiple identities,
    Pull Requests are always opened on behalf of the authenticated user above,
    regardless of repository owner or latest committer of branch, etc.
        - So the command will fail if the `hub` user does not have privilege to see the repository

## Features

- Nothing else! Help welcomed :)
- Especially:
    - Change push target and Pull Request target repository
        - e.g. Push the branch to your fork, then PR to the upstream
    - Customize Pull Request title and description
    - Post resultant Pull Request URL to other issue trackers like Redmine/JIRA, via API
        - Obviously, storing issue tracker type and API credentials is required
