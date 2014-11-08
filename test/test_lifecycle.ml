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

let alloc_uv_fs () =
  let memory = allocate_n char ~count:Uv_consts.size_of_uv_fs_t in
  coerce (ptr char) (ptr C.uv_fs) memory

let test_expired_callback () =
  (* Pass a callback to libuv. Keep a reference to the data we allocate so
     it doesn't crash. We do NOT keep anything to prevent the callback's closure
     from getting gc'd. Callback references a variable so the closure gets
     allocated. We should get a expired closure exception.
  *)
  let filename = mk_tmpfile "hello" in
  let data = alloc_uv_fs () in
  let _ = begin
    let cb fs = let _ = Obj.repr data in Printf.printf "XXX Called '%s'\n" (C.get_uv_fs_t_path fs) in
    let _ = Refcount.incr dataTable data in
    let _ = Gc.compact () in
    let _ = C.uv_fs_stat (C.uv_default_loop ()) data filename (Some cb) in
    let _ = Gc.compact () in ()
  end in
  assert_raises CallToExpiredClosure (fun () -> Uv.Loop.run RunDefault)

let suite =
  "lifecycle suite">:::
  [
  "test expired callback">::test_expired_callback
  ]
