#- Version::Semverish -----------------------------------------------------------
class Version::Semverish:ver<0.0.1>:auth<zef:lizmat> {
    has @.version     is List;
    has @.pre-release is List;
    has @.build       is List;

    method has-illegal-chars(Str:D $target) {
        $target.contains(/ <-[a..z 0..9 .]> /)
    }
    method parts(Str:D $target) {
        $target.split(".")
    }

    multi method new(Version::Semverish: Str:D $spec is copy) {
        my %args = %_;

        $spec .= substr(1) if $spec.starts-with("v");  # semver 1.0 compat

        # Generic pre-release / build parsing logic
        my sub parse($type, $index? --> Nil) {
            my $target;
            with $index {
                $target := $spec.substr($index + 1);
                $spec = $spec.substr(0, $index);
            }
            else {
                $target = $spec;
            }

            die "$type.tc() info contains illegal characters"
              if self.has-illegal-chars($target);

            my @parts is List = self.parts($target);
            die "$type.tc() info may not contain empty elements"
              with @parts.first(* eq '');
            die "$type.tc() info may not contain leading zeroes"
              if @parts.first: { .starts-with("0") && .Int }

            %args{$type} := @parts.map({ .Int // $_ }).List;
        }

        # Parse from end to front
        parse('build', $_)       with $spec.index("+");
        parse('pre-release', $_) with $spec.index("-");

        $spec
          ?? parse('version')
          !! die "Version can not be empty";

        self.bless(|%args)
    }

    method inc(Version::Semverish:D: UInt:D $part = @!version.end) {
        my @version = @!version;
        die "Part $part is not a valid index for incrementing"
          if $part >= @version.elems;

        @version[$part]++;
        self.bless(:version(@version[0..$part]), |%_)
    }

    method major(Version::Semverish:D:) { @!version[0]        }
    method minor(Version::Semverish:D:) { @!version[1] // Nil }
    method patch(Version::Semverish:D:) { @!version[2] // Nil }

    multi method Str(Version::Semverish:D:) {
        "@!version.join('.')"
          ~ ("-@!pre-release.join('.')" if @!pre-release)
          ~ ("+@!build.join('.')"       if @!build)
    }
    multi method raku(Version::Semverish:D:) {
        self.^name ~ '.new(' ~ self.Str.raku ~ ')'
    }

    method cmp(Version::Semverish:D: Version::Semverish:D $other --> Order) {
        self!compare(@!version, $other.version, Less)
          || self!compare(@!pre-release, $other.pre-release, Less)
          || self!compare(@!build, $other.build, More)
    }

    method eqv(Version::Semverish:D: Version::Semverish:D $other) {
        self.cmp($other) == Same
    }

    method !compare(@lefts, @rights, $default) {

        # at least one piece of data on the right
        if @rights {

            # at least one on left
            if @lefts {
                my int $i;
                for @lefts -> $left {
                    with @rights[$i++] -> $right {
                        if $left cmp $right -> $diff {
                            return $diff;  # UNCOVERABLE
                        }
                    }
                    else {
                        return More;
                    }
                }

                # right not exhausted yet?
                $i <= @rights.end ?? $default !! Same
            }

            # data right, not on left
            else {
                $default == Less ?? More !! Less
            }
        }

        # no info on right
        else {
            @lefts ?? $default !! Same
        }
    }

    multi method ACCEPTS(Version::Semverish:D: Version::Semverish:D $other) {
        self.eqv($other)
    }

    method as-generic-range(Version::Semverish:U:
      Str:D $spec,
           *%args
    --> Slip:D) {

        my sub slip-one(Str:D $version, Str:D $comparator = '==') {
            ($comparator, Version::Semverish.new($version, |%args)).Slip
        }

        $spec.split(/ <[ \s | ]>+ /, :skip-empty).map(-> $version is copy {
            if $version.starts-with('==' | '<=' | '>=' | '!=') {
                slip-one($version.substr(2), $version.substr(0,2))
            }
            elsif $version.starts-with('<' | '>') {  # UNCOVERABLE
                slip-one($version.substr(1), $version.substr(0,1))
            }
            elsif $version.starts-with('=') {  # UNCOVERABLE
                slip-one($version.substr(1))
            }
            else {
                slip-one($version)
            }
        }).Slip
    }
}

#- infixes ---------------------------------------------------------------------
my multi sub infix:<cmp>(
  Version::Semverish:D $a, Version::Semverish:D $b
--> Order:D) is export {
    $a.cmp($b)
}

my multi sub infix:<eqv>(
  Version::Semverish:D $a, Version::Semverish:D $b
--> Bool:D) is export {
    $a.eqv($b)
}

my multi sub infix:<==>(
  Version::Semverish:D $a, Version::Semverish:D $b
--> Bool:D) is export {
    $a.cmp($b) == Same
}

my multi sub infix:<!=>(
  Version::Semverish:D $a, Version::Semverish:D $b
--> Bool:D) is export {
    $a.cmp($b) != Same
}

my multi sub infix:«<» (
  Version::Semverish:D $a, Version::Semverish:D $b
--> Bool:D) is export {
    $a.cmp($b) == Less
}

my multi sub infix:«<=» (
  Version::Semverish:D $a, Version::Semverish:D $b
--> Bool:D) is export {
    $a.cmp($b) != More
}

my multi sub infix:«>» (
  Version::Semverish:D $a, Version::Semverish:D $b
--> Bool:D) is export {
    $a.cmp($b) == More
}

my multi sub infix:«>=» (
  Version::Semverish:D $a, Version::Semverish:D $b
--> Bool:D) is export {
    $a.cmp($b) != Less
}

#- other infix methods ---------------------------------------------------------
# Note that this is a bit icky, but it allows for a direct mapping of the
# infix op name to a method for comparison with the $a."=="($b) syntax,
# without having to have the above infixes to be imported
BEGIN {
    Version::Semverish.^add_method: "==", { $^a.cmp($^b) == Same }  # UNCOVERABLE
    Version::Semverish.^add_method: "!=", { $^a.cmp($^b) != Same }  # UNCOVERABLE
    Version::Semverish.^add_method: "<",  { $^a.cmp($^b) == Less }  # UNCOVERABLE
    Version::Semverish.^add_method: "<=", { $^a.cmp($^b) != More }  # UNCOVERABLE
    Version::Semverish.^add_method: ">",  { $^a.cmp($^b) == More }  # UNCOVERABLE
    Version::Semverish.^add_method: ">=", { $^a.cmp($^b) != Less }  # UNCOVERABLE

    Version::Semverish.^add_method: "~~", { $^b.ACCEPTS($^a) }  # UNCOVERABLE
}

# vim: expandtab shiftwidth=4
