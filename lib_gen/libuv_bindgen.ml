open Ctypes

let _ =
  let fmt = Format.formatter_of_out_channel (open_out "src/libuv_stubs.c") in
  Format.fprintf fmt "#include <caml/mlvalues.h>@.";
  Format.fprintf fmt "#include <uv.h>@."; (* TODO might need a lot more *)
  Cstubs.write_c fmt ~prefix:"caml_" (module Libuv_bindings.C);

  let fmt = Format.formatter_of_out_channel (open_out "src/libuv_generated.ml") in
  Cstubs.write_ml fmt ~prefix:"caml_" (module Libuv_bindings.C)
