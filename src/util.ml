let to_bigarray s =
  let len = String.length s in
  let t = Bigarray.(Array1.create char c_layout len) in
  for i = 0 to len - 1 do t.{i} <- s.[i] done;
  t

let c_len ba =
  (* Return length of a bigarray representing a null terminated c string
     Returns the length of the bigarray if there is no null. *)
  let len = ref (Bigarray.Array1.dim ba) in
  begin
    try
      for i = 0 to (!len - 1) do
        if ba.{i} = '\000' then
          (len := i; raise Exit)
      done
    with Exit -> ()
  end;
  !len

let of_bigarray ba =
  let len = c_len ba in
  let b = Bytes.create len in
  for i = 0 to len - 1 do Bytes.set b i ba.{i} done;
  Bytes.to_string b
