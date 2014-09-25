type 'a t = ('a, int) Hashtbl.t

let create () = Hashtbl.create 10 (* TODO figure out what this should be *)

let incr t s =
    if Hashtbl.mem t s then
        Hashtbl.replace t s ((Hashtbl.find t s) + 1)
    else
        Hashtbl.add t s 0

let decr t s =
    let count = Hashtbl.find t s in
    if count > 0 then
        Hashtbl.replace t s (count - 1)
    else
        Hashtbl.remove t s
