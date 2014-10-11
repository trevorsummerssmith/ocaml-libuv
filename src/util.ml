let to_bigarray s =
  let len = String.length s in
  let t = Bigarray.(Array1.create char c_layout len) in
  for i = 0 to len - 1 do t.{i} <- s.[i] done;
  t

let of_bigarray ba =
  let len = Bigarray.Array1.dim ba in
  let b = Bytes.create len in
  for i = 0 to len - 1 do Bytes.set b i ba.{i} done;
  Bytes.to_string b
