open Uv

let fd_ref = ref 0

let rec read_callback fs =
  match FS.result fs with
    r when r < Int64.zero -> Printf.printf "ok"
  | r when r = Int64.zero -> let _ = FS.close !fd_ref in ()
  | r ->
     let buf = FS.buf fs in
     let buf2 = Bigarray.Array1.sub buf 0 (Int64.to_int r) in
     let _ = FS.write 1 buf2 ~cb:write_callback in ()
and write_callback fs =
  if FS.result fs < Int64.zero then
    Printf.fprintf stderr "Write error\n"
  else
    let _ = FS.read !fd_ref ~cb:read_callback in ()

let open_callback fs =
  let fd = Int64.to_int (FS.result fs) in
  let _ = fd_ref := fd in
  let _ = FS.read fd ~cb:read_callback in
  ()

let () =
  if Array.length Sys.argv != 2 then
    Printf.fprintf stderr "Usage: %s <filename>\n" Sys.argv.(0)
  else
    let _ = FS.openfile Sys.argv.(1) ~cb:open_callback 0 in
    let _ = Loop.run (Loop.default_loop ()) RunDefault in
    ()
