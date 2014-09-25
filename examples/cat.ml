open Ctypes
open Foreign

let open_callback (fs : Uv.FS.t) : unit =
  let statbuf = Uv.FS.statbuf fs in
  Printf.printf "Got:  %s%!\n" (Uv.FS.path fs);
  Printf.printf "Size: %d\n" (Int64.to_int statbuf.st_size)

let () =
  let _ = Uv.FS.stat "cat.c" ~cb:open_callback in
  let _ = Uv.Loop.run (Uv.Loop.default_loop ()) RunDefault in
  ()
