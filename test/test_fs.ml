open OUnit
open Ctypes
open Uv

let assert_not_equal = assert_equal ~cmp:( <> )

let ( !! ) r = ok_exn r

let run () = !! (Loop.run Loop.RunDefault)

let mk_tmpfile contents : string =
  let (tmpfile_name, chan) = Filename.open_temp_file "foo" "txt" in
  output_string chan contents;
  close_out chan;
  tmpfile_name

let mkdtemp () : string =
  let tmpdir = Filename.temp_file "foo" ".tmp" in
  Unix.unlink tmpdir;
  Unix.mkdir tmpdir 0o755;
  tmpdir

let test_fs_stat _ =
  let filename = mk_tmpfile "hello" in
  let cb fs stats =
    assert_equal stats.st_size (Int64.of_int 5);
    (* Hard to say what the create time of the file is but it shouldn't be 0. *)
    assert_not_equal stats.st_birthtim.tv_sec Int64.zero;
    assert_equal (Uv.FS.path fs) filename;
    Unix.unlink filename
  in
  !! (Uv.FS.stat filename ~cb:cb);
  run ()

let test_fs_fstat _ =
  let filename = mk_tmpfile "boo" in
  let fd = ref 0 in
  let rec open_callback request =
    fd := !!(Uv.FS.result request);
    !!(Uv.FS.fstat !fd ~cb:fstat_callback)
  and fstat_callback request stats =
    assert_equal stats.st_size (Int64.of_int 3);
    !!(Uv.FS.close !fd ~cb:close_callback)
  and close_callback _ =
    Unix.unlink filename
  in
  !!(Uv.FS.openfile filename 0 ~cb:open_callback);
  run ()

let test_fs_lstat _ =
  let filename = mk_tmpfile "boo" in
  let tmpdir = mkdtemp () in
  let linkpath = (Filename.concat tmpdir "link") in
  Unix.symlink filename linkpath;
  let lstat_callback request stats =
    assert_not_equal stats.st_size (Int64.of_int 3);
    assert_equal (Uv.FS.path request) linkpath;
    Unix.unlink linkpath;
    Unix.rmdir tmpdir;
    Unix.unlink filename
  in
  !!(Uv.FS.lstat linkpath ~cb:lstat_callback);
  run ()

let test_fs_read _ =
  let test_string = "test" in
  let filename = mk_tmpfile test_string in
  let fd = ref 0 in
  let rec open_callback request =
    fd := !! (Uv.FS.result request);
    !!(Uv.FS.read !fd ~cb:read_callback)
  and read_callback request =
    let buf = Uv.FS.buf request in
    !!(Uv.FS.close !fd ~cb:(fun _ -> Unix.unlink filename));
    assert_equal (Util.of_bigarray buf) "test"
  in
  !!(Uv.FS.openfile filename 0 ~cb:open_callback);
  run ()

(* TODO: put these somewhere more appropriate *)
let o_creat = 0o100
let o_wronly = 0o1
let o_trunc = 0o1000

let test_fs_write _ =
  let filename = mk_tmpfile "" in
  let fd = ref 0 in
  let rec open_callback request =
    let () = fd := !! (Uv.FS.result request) in
    let buf = (Util.to_bigarray "test") in
    !!(Uv.FS.write !fd buf ~cb:write_callback)
  and write_callback _ =
    !!(Uv.FS.close !fd ~cb:close_callback)
  and close_callback _ =
    let input_channel = open_in filename in
    let data = input_line input_channel in
    assert_equal "test" data;
    Unix.unlink filename
  in
  let flags = (o_creat lor o_wronly lor o_trunc) in
  !!(Uv.FS.openfile filename flags ~cb:open_callback);
  run ()

let test_fs_unlink _ =
  let filename = mk_tmpfile "" in
  let unlink_callback _ =
    assert_bool "File exists after unlink" (not (Sys.file_exists filename));
  in
  !!(Uv.FS.unlink filename ~cb:unlink_callback);
  run ()

let test_fs_mkdir _ =
  let temp_dir = mkdtemp () in
  let target_dir_path = (Filename.concat temp_dir "test_dir") in
  let mkdir_callback _ =
    assert_bool "Dir" (Sys.file_exists target_dir_path &&
                       Sys.is_directory target_dir_path);
    Unix.rmdir target_dir_path;
    Unix.rmdir temp_dir
  in
  !!(Uv.FS.mkdir target_dir_path ~cb:mkdir_callback);
  run ()

let test_fs_mkdtemp _ =
  let temp_dir = mkdtemp () in
  let template = (Filename.concat temp_dir "lalaXXXXXX") in
  let mkdtemp_callback request =
    let dir_path = Uv.FS.path request in
    assert_bool "is dir" (Sys.file_exists dir_path &&
                          Sys.is_directory dir_path);
    let prefix_len = (String.length template) - 6 in
    let prefix str = Str.first_chars str prefix_len in
    assert_bool "dir name" (prefix dir_path = prefix template);
    Unix.rmdir dir_path;
    Unix.rmdir temp_dir
  in
  !!(Uv.FS.mkdtemp template ~cb:mkdtemp_callback);
  run ()

let test_fs_rmdir _ =
  let temp_dir = mkdtemp () in
  let rmdir_callback _ =
    assert_bool "dir gone" (not (Sys.file_exists temp_dir))
  in
  !!(Uv.FS.rmdir temp_dir ~cb:rmdir_callback);
  run ()

let test_fs_rename _ =
  let temp_dir = mkdtemp () in
  let sourcepath = mk_tmpfile "test" in
  let destpath = Filename.concat temp_dir "target" in
  let rename_callback _ =
    assert_bool "original file gone" (not (Sys.file_exists sourcepath));
    assert_bool "new file present" (Sys.file_exists destpath);
    let input_channel = open_in destpath in
    let data = input_line input_channel in
    assert_equal "test" data;
    Unix.unlink destpath;
    Unix.rmdir temp_dir
  in
  !!(Uv.FS.rename sourcepath destpath ~cb:rename_callback);
  run ()

(* I worry that these tests for fsync/fdatasync don't work on all systems, since
 * frequently write updates metadata *)
let test_fs_fsync _ =
  let filename = mk_tmpfile "test" in
  let fs_before = Unix.stat filename in
  let fd = ref 0 in
  let rec open_callback request =
    let () = fd := !! (Uv.FS.result request) in
    let buf = (Util.to_bigarray "testfsync") in
    !! (Uv.FS.write !fd buf ~cb:write_callback)
  and write_callback _ =
    !! (Uv.FS.fsync !fd ~cb:fsync_callback)
  and fsync_callback _ =
    let fs_after = Unix.stat filename in
    assert_bool "size updated" (not (fs_before.st_size = fs_after.st_size));
    !! (Uv.FS.close !fd ~cb:(fun _ -> Unix.unlink filename))
  in
  let flags = (o_creat lor o_wronly lor o_trunc) in
  !!(Uv.FS.openfile filename ~cb:open_callback flags);
  run ()

(* TODO: test fdatasync-specific properties *)
let test_fs_fdatasync _ =
  let filename = mk_tmpfile "test" in
  let fs_before = Unix.stat filename in
  let fd = ref 0 in
  let rec open_callback request =
    let () = fd := !! (Uv.FS.result request) in
    let buf = (Util.to_bigarray "testfdatasync") in
    !!(Uv.FS.write !fd buf ~cb:write_callback)
  and write_callback _ =
    !!(Uv.FS.fdatasync !fd ~cb:fdatasync_callback)
  and fdatasync_callback _ =
    let fs_after = Unix.stat filename in
    assert_bool "size updated" (not (fs_before.st_size = fs_after.st_size));
    !!(Uv.FS.close !fd ~cb:(fun _ -> Unix.unlink filename))
  in
  let flags = (o_creat lor o_wronly lor o_trunc) in
  !!(Uv.FS.openfile filename ~cb:open_callback flags);
  run ()

let test_fs_ftruncate _ =
  let filename = mk_tmpfile "test" in
  let fd = ref 0 in
  let rec open_callback request =
    let () = fd := !! (Uv.FS.result request) in
    !!(Uv.FS.ftruncate !fd 2 ~cb:ftruncate_callback)
  and ftruncate_callback _ =
    !!(Uv.FS.close !fd ~cb:close_callback)
  and close_callback _ =
    let input_channel = open_in filename in
    let data = input_line input_channel in
    assert_equal "te" data;
    Unix.unlink filename
  in
  !!(Uv.FS.openfile filename o_wronly ~cb:open_callback);
  run ()

let test_fs_sendfile _ =
  let filename = mk_tmpfile "test" in
  let tempdir = mkdtemp () in
  let target_path = Filename.concat tempdir "target" in
  let source_fd = ref 0 in
  let dest_fd = ref 0 in
  let rec open_source_callback request =
    let fd = !! (Uv.FS.result request) in
    source_fd := fd;
    let flags = o_creat lor o_wronly lor o_trunc in
    !!(Uv.FS.openfile target_path flags ~cb:open_dest_callback)
  and open_dest_callback request =
    Printf.printf ""; (* TODO: this makes this test pass for some reason *)
    dest_fd := !! (Uv.FS.result request);
    !!(Uv.FS.sendfile !dest_fd !source_fd 4 ~cb:sendfile_callback)
  and sendfile_callback _ =
    !!(Uv.FS.close !source_fd ~cb:close_source_callback)
  and close_source_callback _ =
    !!(Uv.FS.close !dest_fd ~cb:close_dest_callback)
  and close_dest_callback _ =
    let input_channel = open_in target_path in
    let data = input_line input_channel in
    assert_equal "test" data;
    Unix.unlink filename;
    Unix.unlink target_path;
    Unix.rmdir tempdir
  in
  !!(Uv.FS.openfile filename 0 ~cb:open_source_callback);
  run ()

let test_fs_chmod _ =
  let filename = mk_tmpfile "test" in
  Unix.chmod filename 0o777;
  Unix.access filename [R_OK; W_OK; X_OK];
  let chmod_callback _ =
    let call () = Unix.access filename [R_OK; W_OK; X_OK] in
    assert_raises (Unix.Unix_error(Unix.EACCES, "access", filename)) call
  in
  !!(Uv.FS.chmod filename 0o000 ~cb:chmod_callback);
  run ()

let suite =
  "fs_suite">:::
    [
      "fs_stat">::test_fs_stat;
      "fs_fstat">::test_fs_fstat;
      "fs_lstat">::test_fs_lstat;
      "fs_read">::test_fs_read;
      "fs_write">::test_fs_write;
      "fs_unlink">::test_fs_unlink;
      "fs_mkdir">::test_fs_mkdir;
      "fs_mkdtemp">::test_fs_mkdtemp;
      "fs_rmdir">::test_fs_rmdir;
      "fs_rename">::test_fs_rename;
      "fs_fsync">::test_fs_fsync;
      "fs_ftruncate">::test_fs_ftruncate;
      "fs_sendfile">::test_fs_sendfile;
      "fs_chmod">::test_fs_chmod;
    ]
