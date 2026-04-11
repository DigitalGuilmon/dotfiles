module Scripts.Utils (shellEscape) where

-- Escapa una cadena para uso seguro en shell (single-quote wrapping)
shellEscape :: String -> String
shellEscape s = "'" ++ concatMap esc s ++ "'"
  where esc '\'' = "'\\''"
        esc c    = [c]
