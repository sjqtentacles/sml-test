(* demo.sml - exercise the assertion combinators, a direct Prop.check call,
   and a full suite run (TAP-style output). Deterministic: propTest always
   checks Prop.numTests cases from the fixed Prop.defaultSeed, so results and
   the "ok"/"not ok" report are identical on every run and both compilers. *)

structure T = Test

val () = print "=== sml-test demo ===\n\n"

val () = print "-- direct property check (Prop.check) --\n"
val nonNegProp =
  T.Prop.forAll (T.Prop.Gen.intRange (0, 100)) (fn n => n >= 0)
val () =
  case T.Prop.check T.Prop.defaultSeed nonNegProp of
      T.Prop.Passed n => print ("passed " ^ Int.toString n ^ " cases\n")
    | T.Prop.Failed { counterexample, shrinks, ... } =>
        print ("failed: " ^ counterexample ^ " (" ^ Int.toString shrinks ^ " shrinks)\n")

val () = print "\n-- suite run (assertions + a property test) --\n"

val arithmetic = T.suite "arithmetic" [
  T.test "addition"      (fn () => T.assertEq (4, 2 + 2)),
  T.test "assertMsg"     (fn () => T.assertMsg "should be positive" (3 > 0)),
  T.test "assertNeq"     (fn () => T.assertNeq (1, 2)),
  T.test "assertRaises"  (fn () => T.assertRaises (fn () => 1 div 0)),
  T.test "assertNear"    (fn () => T.assertNear (3.14159, 3.14160, 0.001))
]

val properties = T.suite "properties" [
  T.propTest "reverse twice is identity"
    (T.Prop.forAll (T.Prop.Gen.list T.Prop.Gen.int)
       (fn xs => List.rev (List.rev xs) = xs)),
  T.propTest "append length adds"
    (T.Prop.forAll (T.Prop.Gen.tuple2 (T.Prop.Gen.list T.Prop.Gen.int,
                                        T.Prop.Gen.list T.Prop.Gen.int))
       (fn (xs, ys) => List.length (xs @ ys) = List.length xs + List.length ys))
]

val allPassed = T.run [arithmetic, properties]
val () = print ("\nall passed? " ^ Bool.toString allPassed ^ "\n")
