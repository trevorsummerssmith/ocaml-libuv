open OUnit
open Ctypes

let mk_tmpfile contents : string =
  let (tmpfile_name, chan) = Filename.open_temp_file "foo" "txt" in
  output_string chan contents;
  close_out chan;
  tmpfile_name

(*let test_fs_stat _ =
  let req = make Uv.uv_fs in
  let req_ptr = addr req in
  let loop = Uv.Loop.default_loop () in
  let filename = mk_tmpfile "hello" in
  let ret = Uv.uv_fs_stat loop req_ptr filename (fun _ -> ()) in
  let run_ret = Uv.Loop.run loop RunDefault in
  (* Assert that the structure looks ok *)
  (* TODO add checks to assert all structure fields are correct *)
  let path = getf req Uv.path in
  assert_equal ret 0;
  assert_equal run_ret 0;
  assert_equal path filename*)

let test_fs_stat _ =
  let filename = mk_tmpfile "hello" in
  let fs = Uv.FS.stat filename (fun _ -> ()) in
  assert_equal (Uv.FS.path fs) filename

let suite =
  "fs_suite">:::
    [
      "fs_stat">::test_fs_stat;
    ]
