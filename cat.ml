open Ctypes
open Foreign

let open_callback (req : Uv.uv_fs structure ptr) : unit =
  let result = getf (!@req) Uv.result in
  Printf.printf "Got: %u\n" result

let () =
  let req : Uv.uv_fs structure = make Uv.uv_fs in
  let req_ptr = addr req in
  let looper = Uv.uv_default_loop () in
  let i = Uv.uv_fs_open looper req_ptr "cat.c" 0 0 open_callback in
  let i = Uv.uv_run looper 0 in
  Printf.printf "ok: %u\n" i
