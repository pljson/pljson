PL/JSON development follows the [git flow][flow-blog] branching model. A
plugin for git is available to facilitate this model:
https://github.com/nvie/gitflow

So, with the plugin installed, your contribution flow should look like:

```sh
$ git clone git+ssh://github.com/your-fork/pljson.git
$ cd pljson
$ git flow init # use default for everything except version prefix which is 'v'
$ # you should now be on the 'develop' branch
$ git flow feature start your-feature-name
$ # do your work while adding commits
$ git flow feature finish your-feature-name
$ git push # the feature was merged into the 'develop' branch
```

[flow-blog]: http://nvie.com/posts/a-successful-git-branching-model/

## Creating Your Pull Request

When creating your pull request, make sure you are targeting the 'develop'
branch of the official repository. Pull requests that target the 'master'
branch **will not** be accepted until they have been re-targeted at the
'develop' branch.

## Stay Synchronized

Prior to submitting your pull request, make sure your local copy is
synchronized. In fact, it would be wise to make sure the synchronization is
done prior to finishing your feature:

```sh
$ git remote add upstream https://github.com/pljson/pljson.git
$ git pull upstream develop
$ git merge develop # while on your feature branch
```

## General Guidelines

+ Follow the code style:
  + spaces for tabs
  + 2 spaces per tab
  + all lower case
+ Add an example if your have added a completely new feature
+ Make sure unit tests pass
+ Add/update unit tests to cover your change
+ Add/update documentation to cover your change
