open Calculus
open Corestar_std
open Format

(* Checks:
  - if pattern variables occuring in subgoals also occur in goal
  - if ?x patterns (for formulas and terms) don't mix up formulas and terms
 *)
let is_rule_schema_ok _ = failwith "TODO: CalculusOps.is_rule_schema_ok"

let pp_sequent f { frame; hypothesis; conclusion } =
  fprintf f "@[<2>@[%a@]@ | @[%a@]@ ⊢ @[%a@]@]"
    Syntax.pp_expr frame Syntax.pp_expr hypothesis Syntax.pp_expr conclusion

let pp_rule_schema f { schema_name; goal_pattern; subgoal_pattern } =
  fprintf f "@[<2>rule %s:@ @[%a@]@ if @[%a@];@]@\n"
    schema_name
    pp_sequent goal_pattern
    (pp_list_sep ", " pp_sequent) subgoal_pattern
