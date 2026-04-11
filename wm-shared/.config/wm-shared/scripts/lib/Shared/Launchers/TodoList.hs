module Shared.Launchers.TodoList (todoMenu) where

import XMonad (X)

import Shared.Script (runWmSharedScript)

todoMenu :: X ()
todoMenu = runWmSharedScript "productivity/todo.hs"
