open Ocamlbuild_plugin;;

let make_accessors () =
  (* Create the accessor wrapper c and h files.
  1) Compile the ocaml script that generates these two files
  2) Run it
  3) Compile the c file into an object file
  4) Add dependencies *)
  flag ["compile"; "use_accessor_headers"] (S[A"-I"; Px ("../src")]);
  flag ["compile"; "use_ctypes_c_headers"] (S[A"-I"; Px ("../src")]);
  rule "generate libuv_accessors.{c,h}"
    ~prods:["src/libuv_accessors.c"; "src/libuv_accessors.h"]
    ~deps: ["lib_gen/libuv_accessor_gen.byte"]
    (fun _ _ -> Cmd (S[P"lib_gen/libuv_accessor_gen.byte"]));
  flag ["ocaml"; "compile"; "use_accessors"] (S[Px"src/libuv_accessors.o"]);
  dep ["ocaml"; "use_accessors"] ["src/libuv_accessors.o"]
;;

let uv_consts_build () =
    dep [ "link"; "ocaml"; "link_consts_stub" ] [ "lib_gen/consts_stub.o" ];
    dep [ "use_uv_consts" ] [ "src/uv_consts.ml" ];
    rule "uv_consts: consts_gen.byte -> uv_consts.ml"
    ~dep:"lib_gen/consts_gen.byte"
    ~prod:"src/uv_consts.ml"
    begin fun env build ->
      (* This is brittle! The generation file outputs to src/filename.ml
         depending on the order the ocamlbuild's execution that dir will
         or won't exist. The mkdir line below obviously ensures it exists.
         Probably a better way to go about doing this. *)
        let enums = env "lib_gen/consts_gen.byte" in
        let prod = env "src/uv_consts.ml" in
        let ensure_src = Cmd (Sh "mkdir -p src") in
        let generate = Cmd (S [A enums; A prod]) in
        Seq [ensure_src; generate]
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
      flag ["compile"; "use_ctypes_c_headers"] (S[A"-I"; Px ("../lib_gen")]);
      flag ["ocaml"; "compile"; "use_libuv_generated_stubs"] (S[Px"src/libuv_generated_stubs.o"]);
      dep ["ocaml"; "use_accessors"] ["src/libuv_accessors.o"];
      dep ["ocaml"; "use_libuv_generated_stubs"] ["src/libuv_generated_stubs.o"];
      flag ["ocaml"; "link"; "use_libuv"] (S[A"-cclib"; A"-luv"]);
      uv_consts_build ();
      make_accessors ()
  | _ -> ()
end
