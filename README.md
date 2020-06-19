# MasterToMain

`MasterToMain` lets you change an old default branch on github or github
enterprise to a new branch. For example, if you wanted to change `master` to
`main`.

While `master` does have meanings that connote expertise or original record, it also
has meanings that have much more oppressive and violent histories. Whether or not the 
original meaning of `master` branch was in reference to original record or slave
matters less than what it may mean to a reader who doesn't want to bother with the
history of git.

Per the twitter thread below, maybe we can just think of it as:

> Agreed. All it does is make the world a tiny bit more welcoming.

Thanks to [@shanselman](https://github.com/shanselman) for [the
suggestion](https://twitter.com/shanselman/status/1269838158650195968).

## Functionality

`MasterToMain` has 2 actions for now:

1. `github`
2. `update_local`

## `github`

### Usage

```
master_to_main github
```

After filling out the relevant prompts you will be able to:

1. Create a new branch (e.g. `main`) if it does not exist.
1. Clone all branch protections from an old branch.
   - Caveat: This does not include the signed commit requirement
1. Change the default branch of your repository
1. Rebase all pull requests based on your old branch to your new branch
1. Change the local `origin` remote value in github.

You will be prompted for:

1. Your "github" (e.g. "github.com" or "github.mycompany.com", default is based
on Fetch URL of `origin` or "github.com")
1. Your user (default is based on Fetch URL of `origin` or `whoami`)
1. The repository you want to update (default is based on Fetch URL of `origin`
or `pwd`)
1. The current default branch (default is `master`)
1. The desired default branch (default is `main`)
1. Your personal access token (instructions for settings one can be found [here](https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line))

## `update_local`

### Usage

```
master_to_main update_local
```

This will perform the following (assuming "master" and "main")

```
$ git checkout master
$ git branch -m master main
$ git fetch
$ git branch --unset-upstream
$ git branch -u origin/main
$ git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
```

All credit for this goes to "Brad from XUnit.net!" per [Scott's
Blog](https://www.hanselman.com/blog/EasilyRenameYourGitDefaultBranchFromMasterToMain.aspx).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'master_to_main'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install master_to_main

## TODO

- Testing would be nice

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dewyze/master_to_main. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the MasterToMain project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/master_to_main/blob/master/CODE_OF_CONDUCT.md).
