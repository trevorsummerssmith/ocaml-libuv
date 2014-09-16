open Ctypes
open Foreign

let open_callback (req : Uv.uv_fs structure ptr) : unit =
  (*let result = getf (!@req) Uv.result in*)
  let path = getf (!@req) Uv.path in
  Printf.printf "Got:  %s%!\n" path
  (*Printf.printf "Got: %d and %s%!\n" (Signed.Long.to_int result) path*)

let ok_callback req =
  let stat = getf (!@req) Uv.statbuf in
  let size : int64 = Unsigned.UInt64.to_int64 (getf stat Uv.st_size) in
  let result = coerce PosixTypes.ssize_t int64_t (getf (!@req) Uv.result) in
  Printf.printf "ok! size: %u\n" (Int64.to_int size);
  Printf.printf "result: %d\n" (Int64.to_int result)

let () =
  let req : Uv.uv_fs structure = make Uv.uv_fs in
  let req_ptr = addr req in
  (*let ret1 = Uv.uv_fs_open looper req_ptr "cat.c" 0 0 open_callback in*)
  let looper = Uv.uv_default_loop () in
  let ret1 = Uv.uv_fs_stat looper req_ptr "cat.c" open_callback in
  let i = Uv.uv_run looper 0 in
  Printf.printf "open: %d\n" ret1;
  Printf.printf "ok: %u\n" i
