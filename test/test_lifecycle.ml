open OUnit

open Ctypes
open Foreign
module C = Libuv_bindings.C(Libuv_generated)

let mk_tmpfile contents : string =
  let (tmpfile_name, chan) = Filename.open_temp_file "foo" "txt" in
  output_string chan contents;
  close_out chan;
  tmpfile_name

let dataTable = Refcount.create ()

let test_it () =
  (* Pass a callback to libuv. Keep a reference to the data we allocate so
     it doesn't crash. We do NOT keep anything to prevent the callback's closure
     from getting gc'd. Yet this works. *)
  let filename = mk_tmpfile "hello" in
  let data = addr (make C.uv_fs) in
  let _ = begin
    let cb fs = Printf.printf "XXX Called '%s'\n" (getf !@fs C._path) in
    let _ = Refcount.incr dataTable data in
    let _ = Gc.compact () in
    let _ = C.uv_fs_stat (C.uv_default_loop ()) data filename (Some cb) in
    let _ = Gc.compact () in ()
  end in
  let _ = Uv.Loop.run RunDefault in
  ()

let suite =
  "lifecycle suite">:::
  [
  "test it">::test_it
  ]
