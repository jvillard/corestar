(******************************************************************
 JStar: Separation logic verification tool for Java.  
 Copyright (c) 2007-2008,
    Dino Distefano <ddino@dcs.qmul.ac.uk>
    Matthew Parkinson <Matthew.Parkinson@cl.cam.ac.uk>
 All rights reserved. 
*******************************************************************)
open Jparsetree

let program_file_name = ref ""
let logic_file_name = ref ""
let spec_file_name = ref ""
let absrules_file_name = ref ""

let set_logic_file_name n = 
  logic_file_name := n 

let set_spec_file_name n = 
  spec_file_name := n 

let set_absrules_file_name n = 
  absrules_file_name := n 


let set_program_file_name n = 
  program_file_name := n 

let set_verbose () = 
  Config.verbose := true 

let set_quiet () =
  Support_symex.sym_debug := false

let set_specs_template_mode () = 
  Config.specs_template_mode := true 

let set_dotty_flag () = 
  Config.dotty_print := true 


let arg_list =[ 
("-v", Arg.Unit(set_verbose ), "run in verbose mode" );
("-q", Arg.Unit(set_quiet ), "run in quiet mode" );
  ("-template", Arg.Unit(set_specs_template_mode ), "create empty specs template" );
("-f", Arg.String(set_program_file_name ), "program file name" );
("-l", Arg.String(set_logic_file_name ), "logic file name" );
("-s", Arg.String(set_spec_file_name ), "spec file name" );
("-a", Arg.String(set_absrules_file_name ), "abstraction rules file name" );
("-dot", Arg.Unit(set_dotty_flag ), "print heaps in dotty format for every node of cfg (default=false) " );
 ]


(*
let parse_one_class cname =
  let cname= !path_class_files ^ cname ^".jimple" in
  Printf.printf "Start parsing class file %s...\n" cname;
  let s = string_of_file cname  in
  let parsed_class_file  = Jparser.file Jlexer.token (Lexing.from_string s) 
  in Printf.printf "Parsing %s... done!\n" cname;
  Printf.printf "\n\n\n%s" (Pprinter.jimple_file2str parsed_class_file);
  parsed_class_file
*)


let parse_program () =
  if !Support_symex.sym_debug then Printf.printf "Parsing program file  %s...\n" !program_file_name;
  let s = System.string_of_file !program_file_name  in
  let program =Jparser.file Jlexer.token (Lexing.from_string s)
  in if !Support_symex.sym_debug then Printf.printf "Program Parsing... done!\n";
  (* Replace specialinvokes of <init> after news with virtual invokes of <init>*)
  let program = program in 
  let rec spec_to_virt x = match x with 
      DOS_stm(Assign_stmt(x,New_simple_exp(y)))
    ::DOS_stm(Invoke_stmt(Invoke_nostatic_exp(Special_invoke,b,(Method_signature (c1,c2,Identifier_name "<init>",c4)),d)))
    ::ys 
    when x=Var_name b && y=Class_name c1
    ->
      DOS_stm(Assign_stmt(x,New_simple_exp(y)))
      ::DOS_stm(Invoke_stmt(Invoke_nostatic_exp(Virtual_invoke,b,(Method_signature (c1,c2,Identifier_name "<init>",c4)),d)))
      ::(spec_to_virt ys)
    | x::ys -> x::(spec_to_virt ys)
    | [] -> [] in  
  match program with 
    JFile(a,b,c,d,e,f) -> 
      JFile(a,b,c,d,e,List.map 
	      (function 
		  Method (a,b,c,d,e,Some (f,g)) 
		  -> Method(a,b,c,d,e,Some(spec_to_virt f,g))
		| x -> x) f )

let parse_program () =
  if !Support_symex.sym_debug then Printf.printf "Parsing program file  %s...\n" !program_file_name;
  let s = System.string_of_file !program_file_name  in
  let program =Jparser.file Jlexer.token (Lexing.from_string s)
  in if !Support_symex.sym_debug then Printf.printf "Program Parsing... done!\n";
  (* Replace specialinvokes of <init> after news with virtual invokes of <init>*)
  let program = program in 
  let rec spec_to_virt x maps = match x with 
    DOS_stm(Assign_stmt(x,New_simple_exp(y)))::xs -> 
      DOS_stm(Assign_stmt(x,New_simple_exp(y)))::(spec_to_virt xs ((x,y)::maps))  
  | DOS_stm(Invoke_stmt(Invoke_nostatic_exp(Special_invoke,b,(Method_signature (c1,c2,Identifier_name "<init>",c4)),d)))
    ::xs 
    when List.mem (Var_name b,Class_name c1) maps
    ->
      DOS_stm(Invoke_stmt(Invoke_nostatic_exp(Virtual_invoke,b,(Method_signature (c1,c2,Identifier_name "<init>",c4)),d)))
      ::(spec_to_virt xs (List.filter (fun x -> fst x <> Var_name b) maps))
    | x::xs -> x::(spec_to_virt xs maps)
    | [] -> [] in  
  match program with 
    JFile(a,b,c,d,e,f) -> 
      JFile(a,b,c,d,e,List.map 
	      (function 
		  Method (a,b,c,d,e,Some (f,g)) 
		  -> Method(a,b,c,d,e,Some(spec_to_virt f [],g))
		| x -> x) f )
 


let main () =
  let usage_msg="Usage: -l <logic_file_name>  -a <abstraction_file_name>  -s <spec_file_name>  -f <class_file_program>" in 
  Arg.parse arg_list (fun s ->()) usage_msg;
  Debug.debug_ref:=!Config.verbose;

  if !program_file_name="" then
    Printf.printf "Program file name not specified. Can't continue....\n %s \n" usage_msg
   else 
     let program=parse_program () in
     if !logic_file_name="" && not !Config.specs_template_mode then
       Printf.printf "Logic file name not specified. Can't continue....\n %s \n" usage_msg
     else if !spec_file_name="" && not !Config.specs_template_mode then
       Printf.printf "Specification file name not specified. Can't continue....\n %s \n" usage_msg
     else if !absrules_file_name="" && not !Config.specs_template_mode then
       Printf.printf "Abstraction rules file name not specified. Can't continue....\n %s \n" usage_msg
     else if  !Config.specs_template_mode then 
       (Printf.printf "\nCreating empty specs template for class  %s... \n" !program_file_name;
	Mkspecs.print_specs_template program
       )
     else 
       at_exit Symexec.pp_dotty_transition_system;
       try 
	 let logic = 
	     Load_logic.load_logic  (System.getenv_dirlist "JSTAR_LOGIC_LIBRARY") !logic_file_name
	 in 
	
	 let abs_rules = Load_logic.load_logic  (System.getenv_dirlist "JSTAR_LOGIC_LIBRARY") !absrules_file_name in
	 
	 let s = System.string_of_file !spec_file_name 
	 in if !Support_symex.sym_debug then Printf.printf "Start parsing specs in %s...\n" !spec_file_name;
	 let spec_list  = Jparser.spec_file Jlexer.token (Lexing.from_string s) 
	 in if !Support_symex.sym_debug then Printf.printf "Specs Parsing... done!\n";
	 let apfmap,logic = Specification.spec_file_to_classapfmap logic spec_list in
	 let (static_method_specs,dynamic_method_specs) = Specification.spec_file_to_method_specs spec_list apfmap in
	 
	 if !Support_symex.sym_debug then Printf.printf "\n\n Starting symbolic execution...";
	 Classverification.verify_class program static_method_specs dynamic_method_specs apfmap logic abs_rules ;
	   (*Symexec.compute_fixed_point program apfmap logic abs_rules static_method_specs dynamic_method_specs*)
  Symexec.pp_dotty_transition_system () 
       with Assert_failure (e,l,c) -> Printf.printf "Error!!! Assert failure %s line %d character %d\n" e l c
let _ = main ()