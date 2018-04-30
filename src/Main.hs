module Main where
import Data.Aeson
import Prelude hiding (readFile, writeFile)
import System.Environment
import System.IO hiding (readFile, writeFile)
import Data.ByteString.Lazy.Char8 (ByteString, writeFile, readFile)
import Data.Text as T
import Data.Text.Prettyprint.Doc
import Data.Text.Prettyprint.Doc.Render.Text
import Parser.Mod
import Codegen.File

-- Calls codegen and prints errors
cppWritter :: String -> Either String ByteString -> IO ()
cppWritter fn (Right cpp) = writeFile fn cpp
cppWritter _ (Left s) = hPutStrLn stderr s

-- Parse JSON file into a Module
parse :: ByteString -> Either String Module
parse buffer = eitherDecode buffer :: Either String Module

dbgModule :: Module -> Either String ByteString
-- dbgModule mod = Left . show . pretty . toCFile $ mod

dbgModule mod = Left $ (unpack . renderStrict . layoutPretty layoutOptions . pretty . toCFile) mod
    where layoutOptions = LayoutOptions { layoutPageWidth = AvailablePerLine 180 1 }

main :: IO ()
main = do
  argv <- getArgs
  mapM_ (\arg -> do
    json <- readFile arg
    let cpp = parse json >>= dbgModule
    cppWritter "foo.cpp" cpp) argv

