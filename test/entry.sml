fun runAllSuites () =
  ( Harness.reset ()
  ; TestTests.run ()
  ; Harness.run () )

fun main () =
  OS.Process.exit
    (if runAllSuites () then OS.Process.success else OS.Process.failure)
