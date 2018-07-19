{-# LANGUAGE DeriveAnyClass, DeriveGeneric, OverloadedStrings, DuplicateRecordFields, TypeSynonymInstances, RecordWildCards, FlexibleInstances  #-}
module Codegen.Func where
import GHC.Generics
import Codegen.Rewrite
import Codegen.Expr
import Codegen.Defs
import Codegen.Utils
import Parser.Decl
import Parser.Fix
import Parser.Expr
import Sema.Pipeline
import Data.Aeson
import Data.Text (Text)
import qualified Data.Text as T

-- C function definition, ie: int main(int argc, char **argv)
data CFunc = CFunc { fname :: Text, ftype :: Text, fargs :: [CDef], fvars :: [Text], fbody :: CExpr }
  deriving (Eq, Generic, ToJSON)

-- Fixpoint declaration to C Function
toCDecl :: Declaration -> CFunc
toCDecl FixDecl { fixlist = [fl] } = toCFunc fl
toCDecl FixDecl { fixlist = f:fl } = toCFunc f

-- Nat -> Nat -> Bool ==> [Nat, Nat, Bool]
getCTypeList :: Typ -> [Text]
getCTypeList TypArrow { left = lt, right = rt } = (getCTypeList lt) ++ (getCTypeList rt)
getCTypeList TypVar { name = n, args = al } = ["<getCTypeLast PLACEHOLDER>"]
getCTypeList TypGlob { name = n } = [toCType n]

-- Get the argument names from lamda definition
getCNames :: Expr -> [Text]
getCNames ExprLambda { argnames = al } = map toCName al
getCNames ExprRel {..} = [toCName name]
getCNames ExprGlobal {..} = [toCName name]

-- Fixpoint declaration to C Function
toCFunc :: Fix -> CFunc
toCFunc Fix { name = Just n, typ = t, value = l@ExprLambda {..} } = CFunc n rettype defs varnames cbody
    where defs = getCDefExtrap args argtypes
          varnames = []
          cbody = translateCNames $ semantics $ toCExpr body
          args = getCNames l
          argtypes = init . getCTypeList $ t
          rettype = last . getCTypeList $ t
toCFunc Fix { name = Nothing, .. } = error "Anonymous Fixpoints not supported"


