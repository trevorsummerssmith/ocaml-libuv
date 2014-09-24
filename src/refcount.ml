type 'a t = RefCount of ('a, int) Hashtbl.t;;

let create () = RefCount (Hashtbl.create 1000)

let incr (RefCount t) s =
    if Hashtbl.mem t s then
        Hashtbl.replace t s ((Hashtbl.find t s) + 1)
    else
        Hashtbl.add t s 0

let decr (RefCount t) s =
    let count = Hashtbl.find t s in
    if count > 0 then
        Hashtbl.replace t s (count - 1)
    else
        Hashtbl.remove t s
