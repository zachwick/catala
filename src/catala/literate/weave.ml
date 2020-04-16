(* This file is part of the Catala compiler, a specification language for tax and social benefits
   computation rules. Copyright (C) 2020 Inria, contributor: Denis Merigoux
   <denis.merigoux@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
   in compliance with the License. You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software distributed under the License
   is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
   or implied. See the License for the specific language governing permissions and limitations under
   the License. *)

(** This modules weaves the source code and the legislative text together into a document that law
    professionals can understand. *)

module A = Ast
module P = Printf
module R = Re.Pcre

let pre_latexify (s : string) =
  let percent = R.regexp "%" in
  let s = R.substitute ~rex:percent ~subst:(fun _ -> "\\%") s in
  let premier = R.regexp "1er" in
  let s = R.substitute ~rex:premier ~subst:(fun _ -> "1\\textsuperscript{er}") s in
  s

let source_file_item_to_latex (i : A.source_file_item) : string =
  match i with
  | A.LawHeading (title, precedence) ->
      P.sprintf "\\%ssection*{%s}"
        (match precedence with 0 -> "" | 1 -> "" | 2 -> "sub" | 3 -> "sub" | _ -> "subsub")
        (pre_latexify title)
  | A.LawText t -> pre_latexify t
  | A.LawArticle a -> P.sprintf "\\paragraph{%s}" (pre_latexify a)
  | A.CodeBlock (_, c) ->
      P.sprintf "\\begin{minted}[firstnumber=%d]{catala}%s\\end{minted}"
        (Pos.get_start_line (Pos.get_position c) + 1)
        (Pos.unmark c)
  | A.MetadataBlock (_, c) ->
      P.sprintf
        "\\begin{tcolorbox}[colframe=OliveGreen, breakable, \
         title=\\textcolor{black}{\\texttt{Métadonnées}},title after \
         break=\\textcolor{black}{\\texttt{Métadonnées}},before skip=1em, after skip=1em]\n\
         \\begin{minted}[frame=none,numbersep=9mm, framesep=0mm, \
         firstnumber=%d]{catala}%s\\end{minted}\n\
         \\end{tcolorbox}"
        (Pos.get_start_line (Pos.get_position c) + 1)
        (Pos.unmark c)
  | A.LawInclude (file, page) ->
      let label = file ^ match page with None -> "" | Some p -> P.sprintf "_page_%d," p in
      P.sprintf
        "\\begin{center}\\textit{Annexe incluse, retranscrite page \\pageref{%s}}\\end{center} \
         \\begin{figure}[p]\\begin{center}\\includegraphics[%swidth=\\textwidth]{%s}\\label{%s}\\end{center}\\end{figure}"
        label
        (match page with None -> "" | Some p -> P.sprintf "page=%d," p)
        file label

let ast_to_latex (file : A.source_file) : string =
  String.concat "\n\n" (List.map (fun i -> source_file_item_to_latex i) file)