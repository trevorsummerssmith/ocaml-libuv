open OUnit

let () =
  let suites = [Test_fs.suite; Test_handle.suite; Test_lifecycle.suite] in
  let _ = List.map (fun s -> run_test_tt_main s) suites in
  (* We don't need the results *)
  ()
