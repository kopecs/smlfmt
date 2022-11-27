(** Copyright (c) 2022 Sam Westrick
  *
  * See the file LICENSE for details.
  *)

structure PrettierSig:
sig
  val showSpec: Ast.Sig.spec PrettierUtil.shower
  val showSigExp: Ast.Sig.sigexp PrettierUtil.shower
  val showSigDec: Ast.Sig.sigdec PrettierUtil.shower
end =
struct

  open TabbedTokenDoc
  open PrettierUtil
  open PrettierTy
  infix 2 ++
  fun x ++ y = concat (x, y)

  (* ======================================================================= *)

  fun sigExpWantsSameTabAsDec e =
    let
      open Ast.Sig
    in
      case e of
        Ident _ => false
      | _ => true
    end

  (* ======================================================================= *)

  fun showSpec tab spec =
    let
      open Ast.Sig
    in
      case spec of
        EmptySpec => empty

      | Val {vall, elems, delims} =>
          let
            fun showOne first (starter, {vid, colon, ty}) =
              (if first then empty else at tab)
              ++ token starter ++ token vid ++ token colon ++ withNewChild showTy tab ty
          in
            Seq.iterate op++
              (showOne true (vall, Seq.nth elems 0))
              (Seq.zipWith (showOne false) (delims, Seq.drop elems 1))
          end

      | Type {typee, elems, delims} =>
          let
            fun showOne first (starter, {tyvars, tycon}) =
              (if first then empty else at tab)
              ++ token starter
              ++ showSyntaxSeq tab tyvars token
              ++ token tycon
          in
            Seq.iterate op++
              (showOne true (typee, Seq.nth elems 0))
              (Seq.zipWith (showOne false) (delims, Seq.drop elems 1))
          end

      | TypeAbbreviation {typee, elems, delims} =>
          let
            fun showOne first (starter, {tyvars, tycon, eq, ty}) =
              (if first then empty else at tab)
              ++ token starter
              ++ showSyntaxSeq tab tyvars token
              ++ token tycon
              ++ token eq
              ++ withNewChild showTy tab ty
          in
            Seq.iterate op++
              (showOne true (typee, Seq.nth elems 0))
              (Seq.zipWith (showOne false) (delims, Seq.drop elems 1))
          end

      | Multiple {elems, delims} =>
          let
            fun showOne first (elem: spec, delim: Token.t option) =
              (if first then empty else at tab)
              ++ showSpec tab elem
              ++ showOption (fn d => nospace ++ token d) delim

            val things = Seq.zip (elems, delims)
          in
            Seq.iterate op++
              (showOne true (Seq.nth things 0))
              (Seq.map (showOne false) (Seq.drop things 1))
          end

      | _ => text "<spec>"
    end


  and showSigExp tab sigexp =
    let
      open Ast.Sig
    in
      case sigexp of
        Ident id =>
          token id

      | Spec {sigg, spec, endd} =>
          newTabWithStyle tab (Indented, fn inner =>
            token sigg
            ++ at inner
            ++ showSpec inner spec
            ++ cond inner {inactive = empty, active = at tab}
            ++ token endd)

      | _ => text "<sigexp>"
    end


  and showSigDec tab (Ast.Sig.Signature {signaturee, elems, delims}) =
    let
      fun showOne first (starter, {ident, eq, sigexp}) =
        (if first then empty else at tab)
        ++ token starter
        ++ token ident
        ++ token eq
        ++ (if sigExpWantsSameTabAsDec sigexp then
              at tab ++ showSigExp tab sigexp
            else
              withNewChild showSigExp tab sigexp)
    in
      Seq.iterate op++
        (showOne true (signaturee, Seq.nth elems 0))
        (Seq.zipWith (showOne false) (delims, Seq.drop elems 1))
    end

end
