(* Tests for sml-test, the test framework itself.

   We exercise the framework using the legacy `Harness` (so the meta-tests do
   not depend on the thing under test). Assertions are checked by confirming a
   passing assertion is silent and a failing one raises `Test.TestFailure`;
   `run` is checked by invoking it on small in-memory suites and inspecting the
   returned boolean. *)

structure TestTests =
struct
  open Harness
  structure P = Test.Prop

  fun isPass (P.Passed _) = true
    | isPass _ = false
  fun isFail (P.Failed _) = true
    | isFail _ = false

  fun run () =
    let
      val () = section "assert / assertMsg"
      val () = checkRaises "assert false raises" (fn () => Test.assert false)
      val () = check "assert true is silent"
                 ((Test.assert true; true) handle _ => false)
      val () = checkRaises "assertMsg false raises"
                 (fn () => Test.assertMsg "boom" false)
      val () = check "assertMsg true is silent"
                 ((Test.assertMsg "ok" true; true) handle _ => false)

      val () = section "assertEq / assertNeq"
      val () = check "assertEq equal is silent"
                 ((Test.assertEq (3, 3); true) handle _ => false)
      val () = checkRaises "assertEq differing raises"
                 (fn () => Test.assertEq (3, 4))
      val () = check "assertNeq differing is silent"
                 ((Test.assertNeq (3, 4); true) handle _ => false)
      val () = checkRaises "assertNeq equal raises"
                 (fn () => Test.assertNeq (3, 3))

      val () = section "assertNear"
      val () = check "near within epsilon is silent"
                 ((Test.assertNear (1.0, 1.05, 0.1); true) handle _ => false)
      val () = checkRaises "near outside epsilon raises"
                 (fn () => Test.assertNear (1.0, 1.5, 0.1))
      val () = check "near exact boundary is silent"
                 ((Test.assertNear (1.0, 1.5, 0.5); true) handle _ => false)

      val () = section "assertRaises"
      val () = check "assertRaises on raising thunk is silent"
                 ((Test.assertRaises (fn () => raise Fail "x"); true)
                  handle _ => false)
      val () = checkRaises "assertRaises on non-raising thunk raises"
                 (fn () => Test.assertRaises (fn () => 1))

      val () = section "run: pass/fail accounting"
      val allPass =
        Test.run [Test.suite "ok-suite"
                    [ Test.test "t1" (fn () => Test.assert true)
                    , Test.test "t2" (fn () => Test.assertEq (1, 1)) ]]
      val () = checkBool "run returns true when all pass" (true, allPass)

      val withFail =
        Test.run [Test.suite "mixed-suite"
                    [ Test.test "good" (fn () => Test.assert true)
                    , Test.test "bad"  (fn () => Test.assert false) ]]
      val () = checkBool "run returns false when one fails" (false, withFail)

      val raisesOther =
        Test.run [Test.suite "throws-suite"
                    [ Test.test "boom" (fn () => raise Fail "kaboom") ]]
      val () = checkBool "run returns false on non-TestFailure exn"
                 (false, raisesOther)

      val () = section "Prop: passing properties"
      val rPass = P.check P.defaultSeed
                    (P.forAll (P.Gen.intRange (0, 100)) (fn n => n >= 0))
      val () = check "true property passes" (isPass rPass)

      val rPassList =
        P.check P.defaultSeed
          (P.forAll (P.Gen.list (P.Gen.intRange (0, 9)))
             (fn xs => List.length (List.rev xs) = List.length xs))
      val () = check "list-reverse-length property passes" (isPass rPassList)

      val () = section "Prop: failing properties + reproducibility"
      (* Property that is false for some ints: n < 50 fails once n >= 50. *)
      val badProp = P.forAll (P.Gen.intRange (0, 1000)) (fn n => n < 50)
      val r1 = P.check P.defaultSeed badProp
      val r2 = P.check P.defaultSeed badProp
      val () = check "false property fails" (isFail r1)
      val () = check "same seed reproduces same counterexample"
                 (case (r1, r2) of
                      (Test.Prop.Failed a, Test.Prop.Failed b) =>
                        #counterexample a = #counterexample b
                    | _ => false)

      val () = section "Prop: shrinking"
      (* shrink an int counterexample toward the minimal failing value (50). *)
      val () = check "int counterexample shrinks to boundary"
                 (case r1 of
                      Test.Prop.Failed a => #counterexample a = "50"
                    | _ => false)

      (* A list property: "every list has length <= 2". The minimal failing
         counterexample is a length-3 list. *)
      val badList =
        P.forAll (P.Gen.list (P.Gen.intRange (0, 5)))
          (fn xs => List.length xs <= 2)
      val rL = P.check P.defaultSeed badList
      val () = check "list counterexample shrinks to minimal length"
                 (case rL of
                      Test.Prop.Failed a => #counterexample a = "[0,0,0]"
                    | _ => false)

      val () = section "Prop: propTest integration"
      val passingViaRun =
        Test.run [Test.suite "prop-suite"
                    [ Test.propTest "non-negative squares"
                        (P.forAll (P.Gen.intRange (0, 100))
                           (fn n => n * n >= 0)) ]]
      val () = checkBool "propTest passes inside run" (true, passingViaRun)
      val failingViaRun =
        Test.run [Test.suite "prop-fail-suite"
                    [ Test.propTest "always-false"
                        (P.forAll (P.Gen.intRange (0, 10)) (fn _ => false)) ]]
      val () = checkBool "failing propTest fails inside run" (false, failingViaRun)
    in
      ()
    end
end
