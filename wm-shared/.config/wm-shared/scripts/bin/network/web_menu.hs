#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import Common.UrlMenus (webBookmarks)
import Standalone.UrlMenu (runNamedUrlMenu)

main :: IO ()
main = runNamedUrlMenu "hypr-web-menu" "🌐 Ir a" ["--new-window"] webBookmarks
