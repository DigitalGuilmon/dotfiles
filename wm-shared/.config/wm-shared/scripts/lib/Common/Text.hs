module Common.Text
    ( shellEscape
    , splitOn
    , trimTrailingNewlines
    , trimWhitespace
    ) where

import Data.Char (isSpace)
import Data.List (dropWhileEnd)

shellEscape :: String -> String
shellEscape s = "'" ++ concatMap escapeChar s ++ "'"
  where
    escapeChar '\'' = "'\\''"
    escapeChar c = [c]

splitOn :: Char -> String -> [String]
splitOn delimiter input =
    case break (== delimiter) input of
        (chunk, []) -> [chunk]
        (chunk, _:rest) -> chunk : splitOn delimiter rest

trimWhitespace :: String -> String
trimWhitespace = dropWhileEnd isSpace . dropWhile isSpace

trimTrailingNewlines :: String -> String
trimTrailingNewlines = reverse . dropWhile (== '\n') . reverse
