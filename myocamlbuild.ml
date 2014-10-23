open Ocamlbuild_plugin;;

let uv_consts_build () =
    dep [ "link"; "ocaml"; "link_consts_stub" ] [ "lib_gen/consts_stub.o" ];
    dep [ "uv_consts" ] [ "src/uv_consts.ml" ];
    rule "uv_consts: consts.byte -> uv_consts.ml"
    ~dep:"lib_gen/consts.byte"
    ~prod:"src/uv_consts.ml"
    begin fun env build ->
        let enums = env "support/consts.byte" in
        let prod = env "src/uv_consts.ml" in
        Cmd (S [A enums; A prod])
    end;
;;

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
      flag ["ocaml"; "link"; "use_libuv"] (S[A"-cclib"; A"-luv"]);
      uv_consts_build ()
  | _ -> ()
end
