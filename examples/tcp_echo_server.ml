open Uv

let default_backlog = 128;;
let server_port = 7889

let echo_write _req status =
  if status == -1 then
    failwith "Error!"
  else
    () (* Nothing free memory. *)

let echo_read (client : 'a Stream.t) nread buf =
  match nread with
  | -4095 -> Printf.fprintf stderr "Error reading! "; Handle.close client
  | -1 -> Handle.close client
  | 0 -> ()
  | _ -> 
    (* All good. Write back what we read. *)
    let _ = Stream.write ~cb:echo_write client buf in
    Printf.printf "Received and wrote back '%s'\n%!" (Util.of_bigarray buf)

let on_new_conn (server : 'a Stream.t) (status : int) : unit =
  if status = -1 then
    failwith "Error!"
  else
    let client = TCP.init () in
    match Stream.accept server client with
    | _ -> Stream.read_start ~cb:echo_read client
    (* TODO: handle exceptions *)

let make_sockaddr () = ip4_addr "0.0.0.0" server_port

let () =
  let _ = Printf.printf "(^_^) Server listening on localhost:%d\n%!" server_port in
  let _ = Printf.printf "      Try `echo -n 'hello' | nc localhost %d`\n%!" server_port in
  let server = TCP.init () in
  let sockaddr = make_sockaddr () in
  let _ = TCP.bind server sockaddr 0 in
  let _ = Stream.listen ~cb:on_new_conn server default_backlog in
  let _ = Loop.run Loop.RunDefault in
  ()
