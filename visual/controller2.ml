(*s: controller2.ml *)
(*s: Facebook copyright *)
(* Yoann Padioleau
 * 
 * Copyright (C) 2010 Facebook
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1 as published by the Free Software Foundation, with the
 * special exception on linking described in file license.txt.
 * 
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
 * license.txt for more details.
 *)
(*e: Facebook copyright *)

let _refresh_da = ref (fun () ->
  failwith "_refresh_da not defined"
)
let _refresh_legend = ref (fun () ->
  failwith "_refresh_legend not defined"
)

let current_rects_to_draw = ref []

let current_r = ref None

let paint_content_maybe_refresher = ref None

let current_motion_refresher = ref None

let dw_stack = ref []



let _go_back = ref (fun dw_ref ->
  failwith "_go_back not defined"
)

let _go_dirs_or_file = ref 
 (fun ?(current_entity=None) ?(current_grep_query=None)  dw_ref paths ->
  failwith "_go_dirs_or_file not defined"
)

let _statusbar_addtext = ref (fun s ->
  failwith "_statusbar_addtext not defined"
)
let _set_title = ref (fun s ->
  failwith "_set_title not defined"
)

let title_of_path s = "CodeMap: " ^ s

(*e: controller2.ml *)
