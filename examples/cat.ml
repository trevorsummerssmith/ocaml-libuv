open Uv

let fd_ref = ref 0

let rec read_callback fs =
  match ok_exn (FS.result fs) with
    r when r < 0 -> Printf.printf "ok"
  | r when r = 0 -> ok_exn(FS.close !fd_ref ~cb:(fun _ -> ()))
  | r ->
     let buf = FS.buf fs in
     let buf2 = Bigarray.Array1.sub buf 0 r in
     let _ = FS.write 1 buf2 ~cb:write_callback in ()
and write_callback fs =
  if ok_exn(FS.result fs) < 0 then
    Printf.fprintf stderr "Write error\n"
  else
    let _ = FS.read !fd_ref ~cb:read_callback in ()

let open_callback fs =
  let fd = ok_exn (FS.result fs) in
  let _ = fd_ref := fd in
  let _ = FS.read fd ~cb:read_callback in
  ()

let () =
  if Array.length Sys.argv != 2 then
    Printf.fprintf stderr "Usage: %s <filename>\n" Sys.argv.(0)
  else
    let () = ok_exn (FS.openfile Sys.argv.(1) ~cb:open_callback 0) in
    let ret = Loop.run Loop.RunDefault in
    match ret with
      Ok _ -> exit 0
    | Error e -> failwith (error_to_string e)
