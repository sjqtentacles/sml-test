# sml-test

A small, dependency-free test framework for the `sjqtentacles` Standard ML
libraries. It replaces the hand-rolled `Harness` that each library used to
carry: tests are first-class values grouped into named suites, assertions
raise a distinguished `TestFailure`, and `run` executes everything, prints
TAP-style output, and returns whether all tests passed.

The output is plain text and **deterministic** -- byte-for-byte identical
across MLton and Poly/ML -- so runs under the two compilers can be diffed
directly.

The `Prop` substructure adds QuickCheck-style property testing on top of a
self-contained, splittable **SplitMix64** generator (no external RNG
dependency). A failing property shrinks its counterexample toward a minimal
failing case and prints the seed, so failures reproduce exactly.

## Layout

```
lib/github.com/sjqtentacles/sml-test/
  test.sig        signature TEST (incl. the Prop / Gen pieces)
  test.sml        implementation (Test :> TEST)
  sources.mlb     basis + sig/sml in dependency order
  sml-test.mlb    public basis re-export
test/             the framework's own test suite
```

The sole exported interface is the `Test` structure, ascribed opaquely
(`:>`) to `signature TEST`.

## Building / testing

```
make test        # build + run under MLton
make test-poly   # build + run under Poly/ML (via tools/polybuild)
make all-tests   # run under both
make clean
```

## Usage

```sml
val suites =
  [ Test.suite "arithmetic"
      [ Test.test "addition" (fn () =>
          Test.assertEq (4, 2 + 2))
      , Test.test "near" (fn () =>
          Test.assertNear (1.0, 1.0 + 1.0e~9, 1.0e~6))
      , Test.test "throws" (fn () =>
          Test.assertRaises (fn () => raise Fail "boom"))
      ]

  (* A property: reversing a list twice is the identity. *)
  , Test.suite "properties"
      [ Test.propTest "rev . rev = id"
          (Test.Prop.forAll
             (Test.Prop.Gen.list (Test.Prop.Gen.intRange (0, 100)))
             (fn xs => List.rev (List.rev xs) = xs))
      ]
  ]

val ok = Test.run suites   (* prints TAP output; returns true iff all pass *)
```

Sample output:

```
# Suite: arithmetic
ok 1 - addition
ok 2 - near
ok 3 - throws
# Suite: properties
ok 4 - rev . rev = id

4 passed, 0 failed
```

When a property fails, the (shrunk) counterexample and seed are reported:

```
not ok 5 - bounded # property falsified: 50 (after 6 shrinks, seed 853C49E6748FEA9B)
```

## Property testing (`Prop`)

`Prop.Gen` provides composable generators -- `int`, `intRange`, `real`,
`bool`, `char`, `string`, `list`, `tuple2`, `oneof`, `choose`, plus `map`,
`bind`, and `pure`. Each primitive generator carries a shrinker, so failures
of properties over ints, lists, and strings are minimised automatically.

`Prop.forAll gen pred` builds a `property`; `Prop.check seed prop` runs it
over `Prop.numTests` cases from a given seed and returns a `result`
(`Passed n` or `Failed { counterexample, seed, shrinks }`). `propTest` wraps
a property as a `test` using the fixed `Prop.defaultSeed` for reproducibility.

## Example

`make example` builds and runs [`examples/demo.sml`](examples/demo.sml), which
runs a direct `Prop.check`, then a suite of assertion tests and a property
test through `run` (output is byte-identical under MLton and Poly/ML):

```
=== sml-test demo ===

-- direct property check (Prop.check) --
passed 100 cases

-- suite run (assertions + a property test) --
# Suite: arithmetic
ok 1 - addition
ok 2 - assertMsg
ok 3 - assertNeq
ok 4 - assertRaises
ok 5 - assertNear
# Suite: properties
ok 6 - reverse twice is identity
ok 7 - append length adds

7 passed, 0 failed

all passed? true
```

## License

MIT. See [LICENSE](LICENSE).
