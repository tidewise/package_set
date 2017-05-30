# rock.core package set

This installs the Rock toolchain and associated packages. In an
[autoproj](http://rock-robotics.org/documentation/autoproj) bootstrap, this
package set is selected by adding the following in the `package_sets` section
of `autoproj/manifest`:

```
package_sets:
- github: rock-core/package_set
```

## Note for developers

Part of the Rock behavior is not standard autoproj behavior (flavors, C++11
selection logic, …). Complex logic should be isolated within the `rock/`
folder, and when possible tests should be written in `tests/`

Use `rake test` to run all the tests. To run a single test, one needs to run
from the package set root and add `-I.` to the ruby command line, e.g.

```
ruby -Itest -I. test/cxx11_test.rb
```
