module Standalone.Command
    ( NamedCommand (..)
    , namedCommand
    , parseNamedCommand
    , usageForCommands
    ) where

import Data.List (intercalate)

data NamedCommand a = NamedCommand
    { namedCommandName :: String
    , namedCommandValue :: a
    }

namedCommand :: String -> a -> NamedCommand a
namedCommand = NamedCommand

parseNamedCommand :: [NamedCommand a] -> String -> Maybe a
parseNamedCommand commands input =
    lookup input (map (\command -> (namedCommandName command, namedCommandValue command)) commands)

usageForCommands :: String -> [NamedCommand a] -> String
usageForCommands program commands =
    "Uso: " ++ program ++ " [" ++ intercalate "|" (map namedCommandName commands) ++ "]"
