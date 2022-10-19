(* This file is part of the Catala compiler, a specification language for tax
   and social benefits computation rules. Copyright (C) 2020 Inria, contributor:
   Denis Merigoux <denis.merigoux@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   License for the specific language governing permissions and limitations under
   the License. *)

(** Typing for the default calculus. Because of the error terms, we perform type
    inference using the classical W algorithm with union-find unification. *)

open Definitions

module Env : sig
  type 'e t

  val empty : 'e t
  val add_var : 'e Var.t -> typ -> 'e t -> 'e t
  val add_scope_var : ScopeVar.t -> typ -> 'e t -> 'e t
  val add_scope : ScopeName.t -> typ ScopeVarMap.t -> 'e t -> 'e t
end

val expr :
  decl_ctx ->
  ?env:'e Env.t ->
  ?typ:typ ->
  (('a, 'm mark) gexpr as 'e) ->
  ('a, typed mark) boxed_gexpr
(** Infers and marks the types for the given expression. If [typ] is provided,
    it is assumed to be the outer type and used for inference top-down.

    If the input expression already has type annotations, the full inference is
    still done, but with unification with the existing annotations at every
    step. This can be used for double-checking after AST transformations and
    filling the gaps ([TAny]) if any. Use [Expr.untype] first if this is not
    what you want. *)

val program : ('a, 'm mark) gexpr program -> ('a, typed mark) gexpr program
(** Typing on whole programs (as defined in Shared_ast.program, i.e. for the
    later dcalc/lcalc stages.

    Any existing type annotations are checked for unification. Use
    [Program.untype] to remove them beforehand if this is not the desired
    behaviour. *)
