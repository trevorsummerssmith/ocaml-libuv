(*
   This file runs the consts_stubs generation.
   This file only exists because it is easier to have
   ocamlbuild generate an ocaml executable. If I could
   figure out how to make it generate a c executable
   then this file would not exist.
*)

external output_consts : string -> unit = "output_consts"

let main () =
    let outf =
        if Array.length Sys.argv < 2 then ""
        else if Sys.argv.(1) = "" then ""
        else if Sys.argv.(1) = "-" then ""
        else Sys.argv.(1) in
    output_consts outf

let () = main ()
