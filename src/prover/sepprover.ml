(********************************************************
   This file is part of coreStar
        src/prover/sepprover.ml
   Release
        $Release$
   Version
        $Rev$
   $Copyright$

   coreStar is distributed under a BSD license,  see,
      LICENSE.txt
 ********************************************************)

(*F#
namespace Microsoft.Research.Vcc2
F#*)

open Debug
open Format
open Psyntax


    (*****************************************
       Internal formula operations
     *****************************************)

    type inner_form = Clogic.ts_formula

    let check_inner_form = Clogic.check_ts_formula

    let inner_truth =
      Clogic.mk_ts_form (Cterm.new_ts ()) Clogic.truth

    let inner_falsum =
      let form,ts = Clogic.convert_sf false (Cterm.new_ts ()) Clogic.false_sform in
      Clogic.mk_ts_form ts form

    let convert form =
      try Clogic.convert_with_eqs false form
      with Contradiction -> inner_falsum

    (* Deprecated: Use [convert] instead. *)
    let convert_opt form =
        try Some (Clogic.convert_with_eqs false form)
        with Contradiction -> None

    type inner_logic = Clogic.logic
	
    let convert_logic = Clogic.convert_logic

    let conjoin : form -> inner_form -> inner_form
      = fun form inner_form -> Clogic.conjoin false inner_form (Clogic.convert_to_inner form)

    let conjoin_inner f1 f2 =
      try
          Clogic.conjoin_inner f1 f2
      with Contradiction -> begin
(*         printf "Contradiction in conjoin_inner@\n@?";  (* DBG *) *)
        inner_falsum
      end

    let kill_var : var -> inner_form -> inner_form
      = fun v inner_form ->
        Clogic.kill_var inner_form v

    let freshen_exists = Clogic.freshen_exists

    let update_var_to v e f = Clogic.update_var_to f v e

    let string_inner_form = Clogic.pp_ts_formula

    (******************************************
       Entailment operations
     ******************************************)

    let implies = Prover.check_implication

    let inconsistent logic f =
     try Prover.check_inconsistency logic f with Contradiction -> true

    let inconsistent_opt : inner_logic -> inner_form option -> bool
      = fun logic inner_form1 ->
	match inner_form1 with
	  None -> true
	| Some inner_form1 -> Prover.check_inconsistency logic inner_form1
(*
    let frame : inner_logic -> inner_form -> form -> inner_form list option
      = fun logic inner_form1 form2 ->
	Prover.check_implication_frame_pform logic inner_form1 form2

    let frame_opt : inner_logic -> inner_form option -> form -> inner_form list option
	= fun logic inner_form1 form2 ->
	  match inner_form1 with
	    None -> Some []
	  | Some inner_form1 ->
	      Prover.check_implication_frame_pform logic inner_form1 form2
*)
    let frame_inner (l : inner_logic) (i1 : inner_form) (i2 : inner_form) : inner_form list option =
      Prover.check_frame l i1 i2

    let abduct_inner = Prover.abduct

    let abs : inner_logic -> inner_form -> inner_form list
      = Prover.abs

    let abs_opt : inner_logic -> inner_form option -> inner_form list
      = fun l form -> match form with None -> [] | Some form -> Prover.abs l form

    let implies_list : inner_form list -> form -> bool
      = Prover.check_implies_list

    (* operations related to equalities *)

    let get_equals_pvar_free v form =
      Cterm.get_equals_pvar_free form.Clogic.ts v

    let get_pvars : inner_form -> Psyntax.var list
      = fun form ->
        Cterm.get_pvars form.Clogic.ts

    let make_equal (t1, t2) form =
      let ts = form.Clogic.ts in
      let t1, ts = Cterm.add_term false t1 ts in
      let t2, ts = Cterm.add_term false t2 ts in
      let ts = Cterm.make_equal ts t1 t2 in
      { form with Clogic.ts }


   let pprint_counter_example = Prover.pprint_counter_example
   let print_counter_example = Prover.print_counter_example
   let get_counter_example = Prover.get_counter_example

   let purify_inner = Clogic.purify_ts_form
