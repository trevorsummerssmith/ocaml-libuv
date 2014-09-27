open Ocamlbuild_plugin;;

dispatch begin function
  | After_rules ->
      rule "cstubs: src/x_bindings.ml -> x_stubs.c, x_stubs.ml"
        ~prods:["src/%_stubs.c"; "src/%_generated.ml"]
        ~deps: ["lib_gen/%_bindgen.byte"]
        (fun env build ->
          Cmd (A(env "lib_gen/%_bindgen.byte")));
      copy_rule "cstubs: lib_gen/x_bindings.ml -> src/x_bindings.ml"
        "lib_gen/%_bindings.ml" "src/%_bindings.ml";
      dep ["link"; "ocaml"; "needs_libuv_stubs"] ["libuv_stubs.o"];
      pdep ["link"] "linkdep" (fun param -> [param])
  | _ -> ()
end
