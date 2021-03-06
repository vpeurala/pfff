(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_io
 * Copyright (C) 2009 Jérémie Dimino
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

(** Buffered byte channels *)

(** A {b channel} is a high-level object for performing IOs. It allow
    to read/write things from/to the outside worlds in an efficient
    way, by minimising the number of system calls.

    An {b output channel} is a channel that can be used to send data
    and an {b input channel} is a channel that can used to receive
    data.

    If you are familiar with buffered channels you may be familiar too
    with the {b flush} operation. Note that byte channles of this
    modules are automatically flushed when there is nothing else to do
    (i.e. before the program goes into idle), so this means that you
    no longer have to write:

    {[
      eprintf "log message\n";
      flush stderr;
    ]}

    to have you messages displayed.

    Note about errors: input functions of this module raise
    [End_of_file] when the end-of-file is reached (i.e. when the read
    function returns [0]). Other exceptions are ones caused by the
    backend read/write functions, such as [Unix.Unix_error].
*)

exception Channel_closed of string
  (** Exception raised when a channel is closed. The parameter is a
      description of the channel. *)

(** {6 Types} *)

type 'mode channel
  (** Type of buffered byte channels *)

type input
  (** Input mode *)

type output
  (** Output mode *)

(** Channel mode *)
type 'a mode =
    private
  | Input
  | Output

val input : input mode
  (** [input] input mode representation *)

val output : output mode
  (** [output] output mode representation *)

(* With GADTs:

   type 'a mode =
     | Input : input mode
     | Output : output mode
*)

type input_channel = input channel
    (** Type of input channels *)

type output_channel = output channel
    (** Type of output channels *)

val mode : 'a channel -> 'a mode
  (** [mode ch] returns the mode of a channel *)

(** {6 Well-known instances} *)

val stdin : input_channel
  (** The standard input, it reads data from {!Lwt_unix.stdin} *)

val stdout : output_channel
  (** The standard output, it writes data to {!Lwt_unix.stdout} *)

val stderr : output_channel
  (** The standard output for error messages, it writes data to
      {!Lwt_unix.stderr} *)

val zero : input_channel
  (** Inputs which returns always ['\x00'] *)

val null : output_channel
  (** Output which drops everything *)

(** {6 Channels creation/manipulation} *)

val pipe : ?buffer_size : int -> unit -> input_channel * output_channel
  (** [pipe ?buffer_size ()] creates a pipe using {!Lwt_unix.pipe} and
      makes two channels from the two returned file descriptors *)

val make :
  ?buffer_size : int ->
  ?close : (unit -> unit Lwt.t) ->
  ?seek : (int64 -> Unix.seek_command -> int64 Lwt.t) ->
  mode : 'mode mode ->
  (Lwt_bytes.t -> int -> int -> int Lwt.t) -> 'mode channel
  (** [make ?buffer_size ?close ~mode perform_io] is the
      main function for creating new channels.

      @param buffer_size size of the internal buffer. It must be
      between 16 and [Sys.max_string_length]

      @param close close function of the channel. It defaults to
      [Lwt.return]

      @param seek same meaning as [Unix.lseek]

      @param mode either {!input} or {!output}

      @param perform_io is the read or write function. It is called
      when more input is needed or when the buffer need to be
      flushed. *)

val of_bytes : mode : 'mode mode -> Lwt_bytes.t -> 'mode channel
  (** Create a channel from a byte array. Reading/writing is done
      directly on the provided array. *)

val of_fd : ?buffer_size : int -> ?close : (unit -> unit Lwt.t) -> mode : 'mode mode -> Lwt_unix.file_descr -> 'mode channel
  (** [of_fd ?buffer_size ?close ~mode fd] creates a channel from a
      file descriptor.

      @param close defaults to closing the file descriptor. *)

val of_unix_fd : ?buffer_size : int -> ?close : (unit -> unit Lwt.t) -> mode : 'mode mode -> Unix.file_descr -> 'mode channel
  (** [of_unix_fd ?buffer_size ?close ~mode fd] is a short-hand for:

      [of_fd ?buffer_size ?close (Lwt_unix.of_unix_file_descr fd)] *)

val close : 'a channel -> unit Lwt.t
  (** [close ch] closes the given channel. If [ch] is an output
      channel, it performs all pending actions, flush it and close
      it. If [ch] is an input channel, it just close it immediatly.

      [close] returns the result of the close function of the
      channel. Multiple calls to [close] will return exactly the same
      value.

      Note: you cannot use [close] on channel obtained with an
      {!atomic}. *)

val abort : 'a channel -> unit Lwt.t
  (** [abort ch] abort current operations and close the channel
      immediatly. *)

val atomic : ('a channel -> 'b Lwt.t) -> ('a channel -> 'b Lwt.t)
  (** [atomic f] transforms a sequence of io operations into one
      single atomic io operation.

      Note:
      - the channel passed to [f] is invalid after [f] terminates
      - [atomic] can be called inside another [atomic] *)

val file_length : string -> int64 Lwt.t
  (** Returns the length of a file *)

val buffered : 'a channel -> int
  (** [buffered oc] returns the number of bytes in the buffer *)

val flush : output_channel -> unit Lwt.t
  (** [flush oc] performs all pending writes on [oc] *)

val buffer_size : 'a channel -> int
  (** Returns the size of the internal buffer. *)

val resize_buffer : 'a channel -> int -> unit Lwt.t
  (** Resize the internal buffer to the given size *)

val is_busy : 'a channel -> bool
  (** [is_busy channel] returns whether the given channel is currently
      busy. A channel is busy when there is at least one job using it
      that has not yet terminated. *)

(** {6 Random access} *)

val position : 'a channel -> int64
  (** [position ch] Returns the current position in the channel. *)

val set_position : 'a channel -> int64 -> unit Lwt.t
  (** [set_position ch pos] Sets the position in the output channel. This
      does not work if the channel do not support random access. *)

val length : 'a channel -> int64 Lwt.t
  (** Returns the length of the channel in bytes *)

(** {6 Reading} *)

(** Note: except for functions dealing with streams ({!read_chars} and
    {!read_lines}) all functions are {b atomic}. *)

val read_char : input_channel -> char Lwt.t
  (** [read_char ic] reads the next character of [ic].

      @raise End_of_file if the end of the file is reached *)

val read_char_opt : input_channel -> char option Lwt.t
  (** Same as {!read_byte} but does not raises [End_of_file] on end of
      input *)

val read_chars : input_channel -> char Lwt_stream.t
  (** [read_chars ic] returns a stream holding all characters of
      [ic] *)

val read_line : input_channel -> string Lwt.t
  (** [read_line ic] reads one complete line from [ic] and returns it
      without the end of line. End of line is either ["\n"] or
      ["\r\n"].

      If the end of line is reached before reading any character,
      [End_of_file] is raised. If it is reached before reading an end
      of line but characters have already been read, they are
      returned. *)

val read_line_opt : input_channel -> string option Lwt.t
  (** Same as {!read_line} but do not raise [End_of_file] on end of
      input. *)

val read_lines : input_channel -> string Lwt_stream.t
  (** [read_lines ic] returns a stream holding all lines of [ic] *)

val read : ?count : int -> input_channel -> string Lwt.t
  (** [read ?count ic] reads at most [len] characters from [ic]. It
      returns [""] if the end of input is reached. If [count] is not
      specified, it reads all bytes until the end of input. *)

val read_into : input_channel -> string -> int -> int -> int Lwt.t
  (** [read_into ic buffer offset length] reads up to [length] bytes,
      stores them in [buffer] at offset [offset], and returns the
      number of bytes read.

      Note: [read_into] does not raise [End_of_file], it returns a
      length of [0] instead. *)

val read_into_exactly : input_channel -> string -> int -> int -> unit Lwt.t
  (** [read_into_exactly ic buffer offset length] reads exactly
      [length] bytes and stores them in [buffer] at offset [offset].

      @raise End_of_file on end of input *)

val read_value : input_channel -> 'a Lwt.t
  (** [read_value ic] reads a marshaled value from [ic] *)

(** {6 Writing} *)

(** Note: as for reading functions, all functions except
    {!write_chars} and {!write_lines} are {b atomic}.

    For example if you use {!write_line} in to different threads, the
    two operations will be serialized, and lines cannot be mixed.
*)

val write_char : output_channel -> char -> unit Lwt.t
  (** [write_char oc char] writes [char] on [oc] *)

val write_chars : output_channel -> char Lwt_stream.t -> unit Lwt.t
  (** [write_chars oc chars] writes all characters of [chars] on
      [oc] *)

val write : output_channel -> string -> unit Lwt.t
  (** [write oc str] writes all characters of [str] on [oc] *)

val write_line : output_channel -> string -> unit Lwt.t
  (** [write_line oc str] writes [str] on [oc] followed by a
      new-line. *)

val write_lines : output_channel -> string Lwt_stream.t -> unit Lwt.t
  (** [write_lines oc lines] writes all lines of [lines] to [oc] *)

val write_from : output_channel -> string -> int -> int -> int Lwt.t
  (** [write_from oc buffer offset length] writes up to [length] bytes
      to [oc], from [buffer] at offset [offset] and returns the number
      of bytes actually written *)

val write_from_exactly : output_channel -> string -> int -> int -> unit Lwt.t
  (** [write_from_exactly oc buffer offset length] writes all [length]
      bytes from [buffer] at offset [offset] to [oc] *)

val write_value : output_channel -> ?flags : Marshal.extern_flags list -> 'a -> unit Lwt.t
  (** [write_value oc ?flags x] marshals the value [x] to [oc] *)

(** {6 Printing} *)

(** These functions are basically helpers. Also you may prefer the
    using the name {!printl} rather than {!write_line} because it is
    shorter.

    The general name of a printing function is [<prefix>print<suffixes>].

    Where [<prefix>] is one of:
    - ['f'], which means that the function takes as argument a channel
    - nothing, which means that the function prints on {!stdout}
    - ['e'], which means that the function prints on {!stderr}

    and [<suffixes>] is a combination of:
    - ['l'] which means that a new-line character is printed after the message
    - ['f'] which means that the function takes as argument a {b format} instead
    of a string
*)

val fprint : output_channel -> string -> unit Lwt.t
val fprintl : output_channel -> string -> unit Lwt.t
val fprintf : output_channel -> ('a, unit, string, unit Lwt.t) format4 -> 'a
val fprintlf : output_channel -> ('a, unit, string, unit Lwt.t) format4 -> 'a
val print : string -> unit Lwt.t
val printl : string -> unit Lwt.t
val printf : ('a, unit, string, unit Lwt.t) format4 -> 'a
val printlf : ('a, unit, string, unit Lwt.t) format4 -> 'a
val eprint : string -> unit Lwt.t
val eprintl : string -> unit Lwt.t
val eprintf : ('a, unit, string, unit Lwt.t) format4 -> 'a
val eprintlf : ('a, unit, string, unit Lwt.t) format4 -> 'a

(** {6 Utilities} *)

val hexdump_stream : output_channel -> char Lwt_stream.t -> unit Lwt.t
  (** [hexdump_stream oc byte_stream] produces the same output as the
      command [hexdump -C]. *)

val hexdump : output_channel -> string -> unit Lwt.t
  (** [hexdump oc str = hexdump_stream oc (Lwt_stream.of_string str)] *)

(** {6 File utilities} *)

type file_name = string
    (** Type of file names *)

val open_file :
  ?buffer_size : int ->
  ?flags : Unix.open_flag list ->
  ?perm : Unix.file_perm ->
  mode : 'a mode ->
  file_name -> 'a channel Lwt.t
  (** [open_file ?buffer_size ?flags ?perm ~mode filename] open the
      file with name [filename] and returns a channel for
      reading/writing it.

      @raise Unix.Unix_error on error.
  *)

val with_file :
  ?buffer_size : int ->
  ?flags : Unix.open_flag list ->
  ?perm : Unix.file_perm ->
  mode : 'a mode ->
  file_name -> ('a channel -> 'b Lwt.t) -> 'b Lwt.t
  (** [with_file ?buffer_size ?flags ?perm ~mode filename f] open a
      file and passes the channel to [f]. It is ensured that the
      channel is closed when [f ch] terminates (even if it fails). *)

val open_connection : ?buffer_size : int -> Unix.sockaddr -> (input_channel * output_channel) Lwt.t
  (** [open_connection ?buffer_size ~mode addr] open a connection to
      the given address and returns two channels for using it.

      The connection is completly closed when you close both
      channels.

      @raise Unix.Unix_error on error.
  *)

val with_connection : ?buffer_size : int -> Unix.sockaddr -> (input_channel * output_channel -> 'a Lwt.t) -> 'a Lwt.t
  (** [with_connection ?buffer_size ~mode addr f] open a connection to
      the given address and passes the channels to [f] *)

type server
  (** Type of a server *)

val establish_server : ?buffer_size : int -> ?backlog : int -> Unix.sockaddr -> (input_channel * output_channel -> unit) -> server
  (** [establich_server ?buffer_size ?backlog sockaddr f] creates a
      server which will listen for incomming connections. New
      connections are passed to [f]. Note that [f] must not raise any
      exception.

      [backlog] is the argument passed to [Lwt_unix.listen] *)

val shutdown_server : server -> unit
  (** Shutdown the given server *)

val lines_of_file : file_name -> string Lwt_stream.t
  (** [lines_of_file name] returns a stream of all lines of the file
      with name [name]. The file is automatically closed when all
      lines have been read. *)

val lines_to_file : file_name -> string Lwt_stream.t -> unit Lwt.t
  (** [lines_to_file name lines] writes all lines of [lines] to
      [files] *)

val chars_of_file : file_name -> char Lwt_stream.t
  (** [chars_of_file name] returns a stream of all characters of the
      file with name [name]. As for {!lines_of_file} the file is
      closed when all characters have been read. *)

val chars_to_file : file_name -> char Lwt_stream.t -> unit Lwt.t
  (** [chars_to_file name chars] writes all characters of [chars] to
      [name] *)

(** {6 Input/output of integers} *)

(** Common interface for reading/writing integers in binary *)
module type NumberIO = sig

  (** {8 Reading} *)

  val read_int : input_channel -> int Lwt.t
    (** Reads a 32-bits integer as an ocaml int *)

  val read_int16 : input_channel -> int Lwt.t
  val read_int32 : input_channel -> int32 Lwt.t
  val read_int64 : input_channel -> int64 Lwt.t

  val read_float32 : input_channel -> float Lwt.t
    (** Reads an IEEE single precision floating point value *)

  val read_float64 : input_channel -> float Lwt.t
    (** Reads an IEEE double precision floating point value *)

  (** {8 Writing} *)

  val write_int : output_channel -> int -> unit Lwt.t
    (** Writes an ocaml int as a 32-bits integer *)

  val write_int16 : output_channel -> int -> unit Lwt.t
  val write_int32 : output_channel -> int32 -> unit Lwt.t
  val write_int64 : output_channel -> int64 -> unit Lwt.t

  val write_float32 : output_channel -> float -> unit Lwt.t
    (** Writes an IEEE single precision floating point value *)

  val write_float64 : output_channel -> float -> unit Lwt.t
    (** Writes an IEEE double precision floating point value *)
end

module LE : NumberIO
  (** Reading/writing of integers in little-endian *)

module BE : NumberIO
  (** Reading/writing of integers in big-endian *)

(** Type of byte order *)
type byte_order = Little_endian | Big_endian

val system_byte_order : byte_order
  (** The byte order used by the computer running the program *)

(** {6 Low-level access to the internal buffer} *)

val block : 'a channel  -> int -> (Lwt_bytes.t -> int -> 'b Lwt.t) -> 'b Lwt.t
  (** [block ch size f] pass to [f] the internal buffer and an
      offset. The buffer contains [size] chars at [offset]. [f] may
      reads or writes these chars.  [size] must verify [0 <= size <=
      16] *)

(** Informations for accessing directly to the internal buffer of a
    channel *)
type direct_access = {
  da_buffer : Lwt_bytes.t;
  (** The internal buffer *)
  mutable da_ptr : int;
  (** The pointer to:
      - the beginning of free space for output channels
      - the beginning of data for input channels *)
  mutable da_max : int;
  (** The maximum offset *)
  da_perform : unit -> int Lwt.t;
  (** - for input channels:
        refill the buffer and returns how many bytes have been read
      - for output channels:
        flush partially the buffer and returns how many bytes have been written *)
}

val direct_access : 'a channel -> (direct_access -> 'b Lwt.t) -> 'b Lwt.t
  (** [direct_access ch f] pass to [f] a {!direct_access}
      structure. [f] must use it and update [da_ptr] to reflect how
      many bytes have been read/written. *)

(** {6 Misc} *)

val default_buffer_size : unit -> int
  (** Return the default size for buffers. Channels that are created
      without specific size use this one. *)

val set_default_buffer_size : int -> unit
  (** Change the default buffer size.

      @raise Invalid_argument if the given size is smaller than [16]
      or greater than [Sys.max_string_length] *)

(**/**)

val of_string : mode : 'mode mode -> string -> 'mode channel
  (* Deprecated *)
