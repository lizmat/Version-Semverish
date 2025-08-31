[![Actions Status](https://github.com/lizmat/Version-Semverish/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Version-Semverish/actions) [![Actions Status](https://github.com/lizmat/Version-Semverish/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Version-Semverish/actions) [![Actions Status](https://github.com/lizmat/Version-Semverish/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Version-Semverish/actions)

NAME
====

Version::Semverish - Implement Semverish-like Version logic

SYNOPSIS
========

```raku
use Version::Semverish;

my $left  = Version::Semverish.new("1.0");
my $right = Version::Semverish.new("1.a");

# method interface
say $left.cmp($right);  # Less
say $left."<"($right);  # True

# infix interface
say $left cmp $right;  # Less
say $left < $right;    # True
```

DESCRIPTION
===========

The `Version::Semverish` distribution provides a `Version::Semverish` class which encapsulates the logic for creating a [`Version::Semver`](https://raku.land/zef:lizmat/Version::Semver)-like object with semantics loosely matching [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

It is mostly intended to serve as a base class for any version logic that is loosely based on semver semantics.

Semverish extends the semver specification to any number of digits, and also allows to include lowercase letters in it. Note that the semver standard does not apply any ordering to build-data, but Semverish does, with the same logic that is used to order the main version and the pre-releases.

CONFIGURATION METHODS
=====================

has-illegal-characters
----------------------

```raku
say Version::Semverish.has-illegal-characters("1.2.3");  # False
say Version::Semverish.has-illegal-characters("1.A.3");  # True
```

The `has-illegal-characters` method is supposed to return a `Bool` indicating whether the given version string (excluding any "pre-release" or "build" information) contains any characters that are not allowed in a version speciffication.

By default only `a..z 0..9 .` are allowed.

parts
-----

```raku
say Version::Semverish.parts("1.2.3");  # (1 2 3)
```

The `parts` method is supposed to return an <Iterable> with all of the separate version parts for the given version string.

By default it will split the version string on `"."`.

as-generic-range
----------------

```raku
say Version::Semverish.as-generic-range('1.2');      # (== 1.2)
say Version::Semverish.as-generic-range('>1.2');     # (> 1.2)
say Version::Semverish.as-generic-range('!=2.2.1);   # (!= 2.2.1)
say Version::Semverish.as-generic-range('1.2 1.3');  # (== 1.2 == 1.3)
```

The `as-generic-range` method is supposed to convert a version range specification to a generic range specification, consisting of a `Slip` with a string representing a comparator ("!=", "==", ">", ">=", "<", "<=") and a `Version::Semverish` object, possibly repeated of more than one range was specified.

By default it will split the version range specification on spaces, and test for any of ("!=", "=", "==", ">", ">=", "<", "<=") as comparators, and assuming "==" if no comparator was recognized.

INSTANTIATION
=============

```raku
my $sv = Version::Semverish.new("1.2.3-pre.release+build.data");
```

The basic instantion of a `Version::Semverish` object is done with the `new` method, taking the version string as a positional argument.

ACCESSORS
=========

major
-----

```raku
my $sv = Version::Semverish.new("1.2.3");
say $sv.major;  # 1
```

Returns the major version value.

minor
-----

```raku
my $sv = Version::Semverish.new("1.2.3");
say $sv.minor;  # 2
```

Returns the minor version value.

patch
-----

```raku
my $sv = Version::Semverish.new("1.2.3");
say $sv.patch;  # 3
```

Returns the patch value.

version
-------

```raku
my $sv = Version::Semverish.new("1.2.3.4");
say $sv.version;  # (1 2 3 4)
```

Returns the constituent parts of the version specification.

pre-release
-----------

```raku
my $sv = Version::Semverish.new("1.2.3-foo.bar");
say $sv.pre-release;  # (foo bar)
```

Returns a `List` with the pre-release tokens.

build
-----

```raku
my $sv = Version::Semverish.new("1.2.3+build.data");
say $sv.build;  # (build data)
```

Returns a `List` with the build tokens.

OTHER METHODS
=============

inc
---

```raku
say Version::Semverish.new("1.0").inc;     # Version::Semverish.new("1.1")
say Version::Semverish.new("1.0").inc(0);  # Version::Semverish.new("2")
```

Returns a newly instantiated `Version::Semverish` object with the indicated part of the version information incremented, starting with "0" for the major version part, "1" for the minor, etc. Defaults to the highest possible part. Removes any lower version parts, and any pre-release or build information.

```raku
my $v = Version::Semverish.new("1.0.2-pre+build");
say $v.inc(:pre-release($v.pre-release), :build($v.build));
# Version::Semverish.new("1.1-pre+build");
```

Optionally takes `:pre-release` and `:build` arguments to add.

cmp
---

```raku
my $left  = Version::Semverish.new("1.0");
my $right = Version::Semverish.new("1.a");

say $left.cmp($left);   # Same
say $left.cmp($right);  # Less
say $right.cmp($left);  # More
```

The `cmp` method returns the `Order` of a comparison of the invocant and the positional argument, which is either `Less`, `Same`, or `More`. This method is the workhorse for comparisons.

eqv
---

```raku
my $left  = Version::Semverish.new("1.0.0");
my $right = Version::Semverish.new("1.0.0");

say $left.eqv($right);  # True
```

The `eqv` method returns whether the internal state of two `Version::Semverish` objects is identical.

== != < <= > >=
---------------

```raku
my $left  = Version::Semverish.new("1.2.3");
my $right = Version::Semverish.new("1.2.4");

say $left."=="($left);  # True
say $left."<"($right);  # True
```

These oddly named methods provide the same functionality as their infix counterparts. Please note that you **must** use the `"xx"()` syntax, because otherwise the Raku compiler will assume you've made a syntax error.

EXPORTED INFIXES
================

The following `infix` candidates handling `Version::Semverish` are exported:

  * cmp (returns `Order`)

  * eqv == != < <= > >= (returns `Bool`)

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Version-Semverish . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

