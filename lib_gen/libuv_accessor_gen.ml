(**
   We need to generate a c and h file. It seems the least brittle way to do
   this is to generate them both from this single ml file.
*)

let accessors =
  [
    ["uv_handle_t", "uv_loop_t*", "loop"];
    ["uv_stream_t", "size_t", "write_queue_size"];
    ["uv_fs_t", "uv_loop_t*", "loop"];
    ["uv_fs_t", "ssize_t", "result"]
  ]

let make_header entity typ field =
  (*
  uv_loop_t* get_uv_handle_t_loop (const uv_handle_t* v); *)
  Printf.sprintf "%s get_%s_%s(const %s* v);" typ entity field entity

let make_body entity typ field =
  (* uv_loop_t* get_uv_handle_t_loop (const uv_handle_t* v) { return v->loop; } *)
  Printf.sprintf "%s get_%s_%s(const %s* v) { return v->%s; }"
    typ entity field entity field

let make_header_file () =
  let fmt = Format.formatter_of_out_channel (open_out "src/libuv_accessors.h") in
  let p = (function [e, t, f] -> make_header e t f | _ -> failwith "bad") in
  let strings = List.map p accessors in
  Format.fprintf fmt "#include <uv.h>\n\n";
  List.iter (fun s -> Format.fprintf fmt "%s\n" s) strings

let make_c_file () =
  let fmt = Format.formatter_of_out_channel (open_out "src/libuv_accessors.c") in
  let p = (function [e, t, f] -> make_body e t f | _ -> failwith "bad") in
  let strings = List.map p accessors in
  Format.fprintf fmt "#include \"libuv_accessors.h\"\n\n";
  List.iter (fun s -> Format.fprintf fmt "%s\n" s) strings

let _ =
  make_header_file ();
  make_c_file ()
