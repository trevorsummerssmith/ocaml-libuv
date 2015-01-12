(*
 * Copyright (c) 2014-2015 Trevor Summers Smith <trevorsummerssmith@gmail.com>,
 *                         Zachary Newman <znewman01@gmail.com>
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

open OUnit

let () =
  let suites = [
    Test_fs.suite;
    Test_handle.suite;
    Test_lifecycle.suite;
    Test_consts.suite;
    Test_coat_check.suite;
  ] in
  let _ = List.map (fun s -> run_test_tt_main s) suites in
  (* We don't need the results *)
  ()
