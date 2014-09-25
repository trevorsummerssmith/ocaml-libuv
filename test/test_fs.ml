open OUnit
open Ctypes

let assert_not_equal = assert_equal ~cmp:( <> )

let mk_tmpfile contents : string =
  let (tmpfile_name, chan) = Filename.open_temp_file "foo" "txt" in
  output_string chan contents;
  close_out chan;
  tmpfile_name

let test_fs_stat _ =
  let cb fs =
    let stats : Uv.stat = Uv.FS.statbuf fs in
    assert_equal stats.st_size (Int64.of_int 5);
    (* Hard to say what the create time of the file is but it shouldn't be 0. *)
    assert_not_equal stats.st_birthtim.tv_sec Int64.zero
  in
  let filename = mk_tmpfile "hello" in
  let fs = Uv.FS.stat filename ~cb:cb in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  assert_equal (Uv.FS.path fs) filename

let test_blocking_fs_stat _ =
  (* Same as above, but make sure that sync call works *)
  let filename = mk_tmpfile "boo" in
  let fs = Uv.FS.stat filename in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  let stats = Uv.FS.statbuf fs in
  assert_equal stats.st_size (Int64.of_int 3);
  assert_equal (Uv.FS.path fs) filename

let suite =
  "fs_suite">:::
    [
      "fs_stat">::test_fs_stat;
      "blocking_fs_stat">::test_blocking_fs_stat;
    ]
