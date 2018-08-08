{-# LANGUAGE DeriveGeneric, DeriveAnyClass, DuplicateRecordFields, OverloadedStrings  #-}
module Parser.Expr where
import GHC.Generics hiding (Constructor)
import Parser.Pattern
import Data.Aeson
import Data.Text
import Data.HashMap.Strict
import Prelude hiding (lookup)

-- Cases
data Case = Case { pat :: Pattern, body :: Expr}
    deriving (Show, Eq, Generic, FromJSON)

-- Types TODO: Varidx
data Typ =
    TypArrow { left :: Typ, right :: Typ }
    | TypVar { name :: Text, args :: [Expr] }
    | TypGlob { name :: Text, targs :: [Typ] }
    | TypVaridx { idx :: Int }
    | TypUnknown {}
    | TypDummy {}
    deriving (Show, Eq)

-- Expressions
data Expr = ExprLambda { argnames :: [Text], body :: Expr }
          | ExprCase { expr :: Expr, cases :: [Case] }
          | IndConstructor { name :: Text, argtypes :: [Typ] }
          | ExprConstructor { name :: Text, args :: [Expr] }
          | ExprApply { func :: Expr , args :: [Expr]}
          | ExprCoerce { value :: Expr }
          | ExprRel { name :: Text }
          | ExprGlobal { name :: Text }
          | ExprDummy {}
    deriving (Show, Eq)

instance FromJSON Typ where
  parseJSON (Object v) =
      case (lookup "what" v) of
        Just "type:arrow"       -> TypArrow  <$> v .:  "left"
                                             <*> v .:  "right"
        Just "type:var"         -> TypVar    <$> v .:  "name"
                                             <*> v .:? "args" .!= []
        Just "type:glob"        -> TypGlob   <$> v .:  "name"
                                             <*> v .:? "args" .!= []
        Just "type:varidx"      -> TypVaridx <$> v .:  "name"
        Just "type:unknown"     -> return TypUnknown {}
        Just "type:dummy"       -> return TypDummy {}
        Just s                  -> fail ("Unknown kind: " ++ (show v) ++ " because " ++ (show s))
        Nothing                 -> fail ("No 'what' quantifier for type: " ++ (show v))

instance FromJSON Expr where
  parseJSON (Object v) =
      case (lookup "what" v) of
        Just "expr:lambda"      -> ExprLambda      <$> v .:? "argnames" .!= []
                                                   <*> v .:  "body"
        Just "expr:case"        -> ExprCase        <$> v .:  "expr"
                                                   <*> v .:  "cases"
        Just "expr:constructor" -> ExprConstructor <$> v .:  "name"
                                                   <*> v .:? "args"     .!= []
        Just "expr:apply"       -> ExprApply       <$> v .:  "func"
                                                   <*> v .:? "args"     .!= []
        Just "expr:coerce"      -> ExprCoerce      <$> v .:  "value"
        Just "expr:rel"         -> ExprRel         <$> v .:  "name"
        Just "expr:global"      -> ExprGlobal      <$> v .:  "name"
        Just "expr:dummy"       -> return ExprDummy {}
        Just s                  -> fail ("Unknown expr: " ++ (show v) ++ " because " ++ (show s))
        Nothing                 -> IndConstructor  <$> v .:  "name"
                                                   <*> v .:? "argtypes"     .!= []
