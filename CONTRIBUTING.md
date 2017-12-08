Your contribution flow should look like:

```sh
$ git clone git+ssh://github.com/your-fork/pljson.git
$ cd pljson
$ git checkout -b name-for-your-feature-or-fix
$ git commit # your changes
$ git push -u origin name-for-your-feature-or-fix
```

Once your feature branch is synchronized to your fork on GitHub, you can use
the web interface to create a pull request agains the "master" branch of the
PL/JSON repository.

## Stay Synchronized

Prior to submitting your pull request, make sure your local copy is
synchronized. In fact, it would be wise to make sure the synchronization is
done prior to finishing your feature:

```sh
$ git remote add upstream https://github.com/pljson/pljson.git
$ git checkout master
$ git pull upstream master
$ git checkout name-for-your-feature-or-fix
$ git merge master
$ git push
```

## General Guidelines

+ Follow the code style:
  + spaces for tabs
  + 2 spaces per tab
  + all lower case
+ Name SQL files according to the following rules:
  1. Self-contained package declaration and body implementation:
     `pljson_<feature>.package.sql`. So if your feature is "foo", and all of
     its source code is in one file, you would name that file:
     `pljson_foo.package.sql`.
  2. Split declaration and implementation files: `pljson_<feature>.<kind>.decl.sql`
     and `pljson_<feature>.<kind>.impl.sql` where `<kind>` is the type of
     database object, e.g. `type` or `package`. For example, a type "foo"
     that separates its declaration from implementation would have files:
     `pljson_foo.type.decl.sql` and `pljson_foo.type.impl.sql`.
+ Add an example if your have added a completely new feature
+ Make sure unit tests pass
+ Add/update unit tests to cover your change
+ Add/update documentation to cover your change. Documentation should be
  added to the `decl` file using PLDOC syntax. See
  [http://pldoc.sourceforge.net/maven-site/docs/Users_Guide/index.html](http://pldoc.sourceforge.net/maven-site/docs/Users_Guide/index.html)
  for details on PLDOC.
