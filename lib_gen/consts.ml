external output_consts : string -> unit = "output_consts"

let main () =
    let outf =
        if Array.length Sys.argv < 2 then ""
        else if Sys.argv.(1) = "" then ""
        else if Sys.argv.(1) = "-" then ""
        else Sys.argv.(1) in
    output_consts outf

let () = main ()
