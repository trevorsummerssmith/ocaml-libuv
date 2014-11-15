open OUnit

open Ctypes
open Foreign
module C = Libuv_bindings.C(Libuv_generated)

let mk_tmpfile contents : string =
  let (tmpfile_name, chan) = Filename.open_temp_file "foo" "txt" in
  output_string chan contents;
  close_out chan;
  tmpfile_name

let coatCheck = Coat_check.create ()

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
    let cb fs =
      let _ = Obj.repr data in
      Printf.printf "XXX Called '%s'\n" (C.get_uv_fs_t_path fs)
    in
    let tckt = Coat_check.ticket coatCheck in
    let () = Coat_check.store coatCheck tckt (Obj.repr data) in
    let () = Gc.compact () in
    let _ = C.uv_fs_stat (C.uv_default_loop ()) data filename (Some cb) in
    let () = Gc.compact () in ()
  end in
  assert_raises CallToExpiredClosure (fun () -> Uv.Loop.run RunDefault)

let test_store_callback_and_data () =
  (* This test shows a deconstructed version of how we store
     the data and callback together. *)
  let filename = mk_tmpfile "foo" in
  let data = alloc_uv_fs () in
  let nameRef = ref "" in
  let _ = begin
    let cb fs = nameRef := "XXX"
    in
    let safe = (data, cb) in
    let tckt = Coat_check.ticket coatCheck in
    let () = Coat_check.store coatCheck tckt safe in
    let () = Gc.compact () in
    let ret = C.uv_fs_stat (C.uv_default_loop ()) data filename (Some cb) in
    let () = Gc.compact () in () end
  in
  let _ = Uv.Loop.run RunDefault in
  assert_equal (!nameRef) "XXX"

let test_store_callback_and_data_then_expired () =
  (* Decrement the reference before running and it should not work.
     We use the callback-only again because loosing the uv_fs data causes
     segfaults which we cannot catch as easily :) *)
  let filename = mk_tmpfile "foo" in
  let data = alloc_uv_fs () in
  let nameRef = ref "" in
  let _ = begin
    let cb fs = nameRef := "XXX"
    in
    let safe = (data, cb) in
    let tckt = Coat_check.ticket coatCheck in
    let () = Coat_check.store coatCheck tckt safe in
    let () = Coat_check.forget coatCheck tckt in
    (* Add data back in so we don't segfault *)
    let tckt = Coat_check.ticket coatCheck in
    let () = Coat_check.store coatCheck tckt (Obj.repr data) in
    let () = Gc.compact () in
    let ret = C.uv_fs_stat (C.uv_default_loop ()) data filename (Some cb) in
    let () = Gc.compact () in () end
  in
  assert_raises CallToExpiredClosure (fun () -> Uv.Loop.run RunDefault)

let suite =
  "lifecycle suite">:::
  [
  "test expired callback">::test_expired_callback;
  "test store callback & data">::test_store_callback_and_data;
  "test store callback & data then expired">::test_store_callback_and_data_then_expired;
  ]
