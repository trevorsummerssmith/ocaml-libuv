open OUnit

let assert_not_equal a b = assert_equal ~cmp:( <> ) a b

let test_same_object_different_ids _ =
  let check = Coat_check.create () in
  let tckt1 = Coat_check.ticket check in
  let tckt2 = Coat_check.ticket check in
  Coat_check.store check tckt1 "foo";
  Coat_check.store check tckt2 "foo";
  (* Not testing the collision didn't happen *)
  assert_not_equal tckt1 tckt2

let test_polymorphic _ =
  let check = Coat_check.create () in
  let tckt1 = Coat_check.ticket check in
  let tckt2 = Coat_check.ticket check in
  Coat_check.store check tckt1 "foo";
  Coat_check.store check tckt2 1;
  assert_not_equal tckt1 tckt2

let suite =
  "coat check">:::
  [
    "same object different tickets">::test_same_object_different_ids;
    "is not weakly polymorphic">::test_polymorphic;
  ]
