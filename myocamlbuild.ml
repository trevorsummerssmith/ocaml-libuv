open Ocamlbuild_plugin;;

dispatch begin function
  | Before_options ->
      Options.use_ocamlfind := true
  | After_rules ->
      rule "generated c & ml"
        ~prods:["src/libuv_generated_stubs.c"; "src/libuv_generated.ml"]
        ~deps: ["lib_gen/libuv_bindgen.byte"]
        (fun _ _ -> Cmd (S[P"lib_gen/libuv_bindgen.byte"]));
      let ctypes = Findlib.query "ctypes" in
      flag ["compile"; "use_ctypes_c_headers"] (S[A"-I"; Px (ctypes.Findlib.location ^ "/..")]);
      flag ["ocaml"; "compile"; "use_libuv_generated_stubs"] (S[Px"src/libuv_generated_stubs.o"]);
      dep ["ocaml"; "use_libuv_generated_stubs"] ["src/libuv_generated_stubs.o"];
      flag ["ocaml"; "link"; "use_libuv"] (S[A"-cclib"; A"-luv"])
  | _ -> ()
end
