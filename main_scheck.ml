
(*
 * The author disclaims copyright to this source code.  In place of
 * a legal notice, here is a blessing:
 *
 *    May you do good and not evil.
 *    May you find forgiveness for yourself and forgive others.
 *    May you share freely, never taking more than you give.
 *)

open Common

open Ast_php

module Ast = Ast_php
module V = Visitor_php

module S = Scope_code

(*****************************************************************************)
(* Purpose *)
(*****************************************************************************)

(* A lint-like checker for PHP.
 * 
 * By default 'scheck' performs only a local analysis of the files passed
 * on the command line. It is thus quite fast while still detecting a few
 * important bugs like the use of undefined variables. 
 * 
 * 'scheck' can also leverage more expensive global analysis to find more bugs.
 * Doing so requires a PHP code database which is usually very expensive 
 * to build (see pfff_db) and very large disk-wise. Fortunately one can 
 * now build a light database (see pfff_db_light) and use this as a cache.
 * 
 * One could also use the heavy database but this requires to have
 * the program linked with Berkeley DB, adding some dependencies to 
 * the user of the program (and is not very multi-user friendly for now).
 * Fortunately this db can now be built in memory, on the fly.
 * Thanks to the include_require_php.ml analysis, we can
 * build only the db for the files that matters, cutting significantly
 * the time to build the db (going down from 40 000 files to about 1000
 * files on average on facebook code). In a way it is similar
 * to what gcc does when it calls 'cpp' to get the full information for
 * a file. 
 * 
 * Note that scheck is mostly for generic bugs (that sometimes
 * requires global analysis). For API-specific bugs, you can use 'sgrep'.
 * 
 * modes:
 *  - local analysis
 *  - TODO leverage global analysis computed previously by pfff_db_light
 *  - TODO perform global analysis "lazily" by building db on-the-fly
 *    of the relevant included files (configurable via a -depth_limit flag)
 *  - still? leverage global analysis computed by pfff_db
 * 
 * current checks:
 *   - TODO use/def of entities (e.g. use of undefined class/function/constant
 *     a la checkModule)
 *   - TODO variable related (use of undeclared variable, unused variable, etc)
 *   - TODO function call related (wrong number of arguments, bad keyword
 *     arguments, etc)
 *   - TODO class related (use of undefined member)
 *   - TODO dead code (dead function in callgraph, dead block in CFG, 
 *     dead assignement in dataflow)
 *   - TODO include/require and file related (including file that do not
 *     exist anymore)
 *   - TODO type related
 *   - TODO resource related (open/close match)
 *   - TODO security related ??
 *   - TODO require_strict() related (see facebook/.../main_linter.ml)
 * 
 * related: 
 *   - TODO lint_php.ml (small syntactic conventions, e.g. bad defines)
 *   - TODO check_code_php.ml (include/require stuff)
 *   - TODO check_module.ml (require_module() stuff), 
 *   - TODO main_linter.ml (require_strict() stuff), 
 *   - TODO main_checker.ml (flib-aware  checker),
 * 
 * todo: make it possible to take a db in parameter so
 * for other functions, we can also get their prototype.
 * 
 * todo: build info about builtins, so when call to preg_match,
 * know that this function takes things via reference.
 * 
 * later: it could later also check javascript, CSS, sql, etc
 * 
 *)

(*****************************************************************************)
(* Flags *)
(*****************************************************************************)

let verbose = ref false

(* action mode *)
let action = ref ""

let rank = ref true

(* todo: depth_limit is used to stop the expensive recursive includes process.
 *
 * todo: one issue is that some code like facebook uses special 
 *  require/include directives that include_require_php.ml is not aware of.
 *  Maybe we should have a unfacebookizer preprocessor that removes
 *  this sugar. The alternative right now is to copy most of the code
 *  in this file in facebook/qa_code/checker.ml :( and plug in the
 *  special include_require_php.ml hooks. Another alternative is to use
 *  the light_db.json cache.
 *)

(* In strict mode, we are more aggressive regarding scope like in
 * JsLint.
 *
 * is also in Error_php.ml
 *)
let strict_scope = ref false 

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

(* ranking errors, inspired by Engler slides *)
let rank_errors errs =
  errs +> List.map (fun x ->
    x,
    match x with
    | Error_php.UnusedVariable (_, S.Local) -> 10
    | _ -> 0
  ) +> Common.sort_by_val_highfirst +> Common.map fst


let show_10_most_recurssing_unused_variable_names () =

  (* most recurring probably false positif *)
  let hcount_str = Common.hash_with_default (fun() -> 0) in

  !Error_php._errors +> List.iter (fun err ->
    match err with
    | Error_php.UnusedVariable (dname, scope) ->
        let s = Ast.dname dname in
        hcount_str#update s (fun old -> old+1);
    | _ -> ()
  );
  pr2 "top 10 most recurring unused variable names";
  hcount_str#to_list +> Common.sort_by_val_highfirst +> Common.take_safe 10
   +> List.iter (fun (s, cnt) ->
        pr2 (spf " %s -> %d" s cnt)
      );
  ()

(*****************************************************************************)
(* Wrappers *)
(*****************************************************************************)
let pr2_dbg s =
  if !verbose then Common.pr2 s

(*****************************************************************************)
(* Main action *)
(*****************************************************************************)

let check_file ~find_entity file =

  let ast = Parse_php.parse_program file in
  Lib_parsing_php.print_warning_if_not_correctly_parsed ast file;

  Check_variables_php.check_and_annotate_program 
    ~strict_scope:!strict_scope
    ~find_entity
    ast;

  (* TODO:
     Check_unused_var_php.check_program ast;
     Checking_php.check_program ast;
     Check_scope_use_php.check_program ast;
     Check_unused_var_php.check_program ast;
  *)
  ()

let main_action xs =

  let files = Lib_parsing_php.find_php_files_of_dir_or_files xs in

  Flag_parsing_php.show_parsing_error := false;
  Flag_parsing_php.verbose_lexing := false;
  files +> List.iter (fun file ->
    pr2_dbg (spf "processing: %s" file);
    (* TODO *)
    let find_entity = None in

    check_file ~find_entity file;
  );

  let errs = !Error_php._errors +> List.rev in
  let errs = if !rank then rank_errors errs +> Common.take_safe 20 else errs in

  errs +> List.iter (fun err -> pr (Error_php.string_of_error err));
  show_10_most_recurssing_unused_variable_names ();
  pr2 (spf "total errors = %d" (List.length !Error_php._errors));
  ()

(*****************************************************************************)
(* Extra actions *)
(*****************************************************************************)

(*---------------------------------------------------------------------------*)
(* type inference playground *)
(*---------------------------------------------------------------------------*)

let type_inference file =
  let ast = Parse_php.parse_program file in

  (* PHP Intermediate Language *)
  try
    let pil = Pil_build.pil_of_program ast in

    (* todo: how bootstrap this ? need a bottom-up analysis but
     * we could first start with the types of the PHP builtins that
     * we already have (see builtins_php.mli in lang_php/analyze/).
     *)
    let env = () in

    (* works by side effect on the pil *)
    Type_inference_pil.infer_types env pil;

    (* simple pretty printer *)
    let s = Pretty_print_pil.string_of_program pil in
    pr s;

    (* internal representation pretty printer *)
    let s = Pil.string_of_program
      ~config:{Pil.show_types = true; Pil.show_tokens = false}
      pil
    in
    pr s;


  with exn ->
    pr2 "File contain constructions not supported by the PIL; bailing out";
    raise exn

(*---------------------------------------------------------------------------*)
(* Testing *)
(*---------------------------------------------------------------------------*)
let test () =
  let test_files = [
    "tests/php/scheck/variables.php";
  ] 
  in
  let test_files = test_files +> List.map (fun s -> 
    Filename.concat Config.path s) in
  
  let (expected_errors :(Common.filename * int (* line *)) list) =
    test_files +> List.map (fun file ->
      Common.cat file +> Common.index_list_1 +> Common.map_filter 
        (fun (s, idx) -> 
          (* Right now we don't care about the actual error messages. We
           * don't check if they match. We are just happy to check for 
           * correct lines error reporting.
           *)
          if s =~ ".*//ERROR:.*" 
          (* + 1 because the comment is one line before *)
          then Some (file, idx + 1) 
          else None
        )
    ) +> List.flatten
  in

  Error_php._errors := [];

  (* todo *)
  let find_entity = None in

  test_files +> List.iter (check_file ~find_entity);
  !Error_php._errors +> List.iter (fun e -> pr (Error_php.string_of_error e));
  
  let (actual_errors: (Common.filename * int (* line *)) list) = 
    !Error_php._errors +> Common.map_filter (fun err ->
      let info_opt = Error_php.info_of_error err in
      info_opt +> Common.fmap (fun info ->
        (Ast.file_of_info info, Ast.line_of_info info)
      )
    )
  in
  
  (* diff report *)
  let (common, only_in_expected, only_in_actual) = 
    Common.diff_set_eff expected_errors actual_errors in

  only_in_expected |> List.iter (fun (src, l) ->
    pr2 (spf "this one error is missing: %s:%d" src l);
  );
  only_in_actual |> List.iter (fun (src, l) ->
    pr2 (spf "this one error was not expected: %s:%d" src l);
  );

  if not (null only_in_expected && null only_in_actual)
  then failwith "scheck tests failed"
  else pr2 "scheck tests passed OK"


(*---------------------------------------------------------------------------*)
(* the command line flags *)
(*---------------------------------------------------------------------------*)
let scheck_extra_actions () = [
  "-type_inference", " <file>",
  Common.mk_action_1_arg type_inference;

  "-test", " ",
  Common.mk_action_0_arg test;
]

(*****************************************************************************)
(* The options *)
(*****************************************************************************)

let all_actions () =
 scheck_extra_actions()++
 Test_parsing_php.actions()++
 Test_analyze_php.actions()++
 []

let options () =
  [
    "-verbose", Arg.Set verbose,
    " ";
    "-strict", Arg.Set strict_scope,
    " emulate block scope instead of function scope";
     "-no_scrict_scope", Arg.Clear strict_scope, 
     " use function scope (default)";

    "-no_rank", Arg.Clear rank,
    " ";
  ] ++
  Flag_analyze_php.cmdline_flags_verbose () ++
  Common.options_of_actions action (all_actions()) ++
  Common.cmdline_flags_devel () ++
  Common.cmdline_flags_verbose () ++
  Common.cmdline_flags_other () ++
  [
  "-version",   Arg.Unit (fun () ->
    pr2 (spf "scheck version: %s" Config.version);
    exit 0;
  ),
    "  guess what";

  (* this can not be factorized in Common *)
  "-date",   Arg.Unit (fun () ->
    pr2 "version: $Date: 2010/04/25 00:44:57 $";
    raise (Common.UnixExit 0)
    ),
  "   guess what";
  ] ++
  []

(*****************************************************************************)
(* Main entry point *)
(*****************************************************************************)

let main () =

  let usage_msg =
    "Usage: " ^ Common.basename Sys.argv.(0) ^
      " [options] <file or dir> " ^ "\n" ^ "Options are:"
  in
  (* does side effect on many global flags *)
  let args = Common.parse_options (options()) usage_msg Sys.argv in

  (* must be done after Arg.parse, because Common.profile is set by it *)
  Common.profile_code "Main total" (fun () ->

    (match args with

    (* --------------------------------------------------------- *)
    (* actions, useful to debug subpart *)
    (* --------------------------------------------------------- *)
    | xs when List.mem !action (Common.action_list (all_actions())) ->
        Common.do_action !action xs (all_actions())

    | _ when not (Common.null_string !action) ->
        failwith ("unrecognized action or wrong params: " ^ !action)

    (* --------------------------------------------------------- *)
    (* main entry *)
    (* --------------------------------------------------------- *)
    | x::xs ->
        main_action (x::xs)

    (* --------------------------------------------------------- *)
    (* empty entry *)
    (* --------------------------------------------------------- *)
    | [] ->
        Common.usage usage_msg (options());
        failwith "too few arguments"
    )
  )

(*****************************************************************************)
let _ =
  Common.main_boilerplate (fun () ->
      main ();
  )
