API Design
----------
0. This is a low level api meant for other frameworks to use to provide
   blocking and/or not blocking system calls.
1. Don't expose the blocking functionality -- only the non-blocking.
   The entire point of this library is to get the non-blocking functionality.
2. Errors are with a return type -- no exceptions are thrown.
   This library is meant for framework creators to build on top of.
   Frameworks will need to make an explicit decision of how they deal with
   errors.
3. Threading. We assume that only fs, getaddrinfo, getnameinfo and
   user specified work use other threads. We need to call
   caml_c_thread_register () _once_ on each of the threads in the
   internal thread pool. However, there is no mechanism exposed to allow
   one to run initialization code on the threads. So we make a call to
   caml_c_thread_register before _any_ callback that can be running in another
   thread. This is more expensive than needs be, however it gets the job done,
   and (from looking at the implementation of caml_c_thread_register) it appears
   that it is pretty cheap to call this subsequent times.
   See http://docs.libuv.org/en/v1.x/design.html
   See http://caml.inria.fr/pub/docs/manual-ocaml-4.00/manual033.html#toc151
   See https://github.com/ocaml/ocaml/blob/4.02/otherlibs/systhreads/st_stubs.c#L544
4. Callback arguments. We tried to add type safety where reasonable.
   TODO once we get some feedback add thoughts.

* As few dependencies as possible (no Core).

Questions
---------
* Should we try and use the Unix.sockaddr for sockaddr? or try and use the libuv methods?
  eg see the tcp_echo_server example.
  let make_sockaddr port : Unix.sockaddr =
  let open Unix in
  let host = gethostbyname "localhost" in
  let inet_addr = host.h_addr_list.(0) in
  ADDR_INET(inet_addr, port)