#!/usr/bin/env sh
#if 0
script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script_root="$script_dir"
while [ ! -d "$script_root/lib" ] && [ "$script_root" != "/" ]; do
    script_root=$(dirname "$script_root")
done
exec runhaskell -XCPP -i"$script_root/lib" "$0" "$@"
#endif

import System.Process (readProcess, spawnProcess, callCommand)
import System.Directory (getHomeDirectory)
import System.FilePath ((</>))
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
    -- 1. Definir el directorio
    home <- getHomeDirectory
    let dir = home </> "Videos/Wallpapers/Universe"
    
    -- 2. Buscar videos usando find (replicando la lógica de tu bash)
    -- Usamos ( ) para agrupar las condiciones de nombre
    files <- readProcess "find" [dir, "-type", "f", "(", "-name", "*.mp4", "-o", "-name", "*.webm", ")"] ""
    let videoList = lines files

    -- 3. Comprobar si hay videos
    if null videoList
        then do
            hPutStrLn stderr "❌ No hay videos en la carpeta Universe."
            hPutStrLn stderr "Usa yt-dlp para descargar uno primero."
            exitFailure
        else do
            -- 4. Seleccionar un video aleatorio usando shuf
            selected <- readProcess "shuf" ["-n", "1"] (unlines videoList)
            let videoPath = head (lines selected)
            
            -- 5. Limpiar procesos previos
            -- Usamos '|| true' para que no falle si no hay procesos activos
            _ <- callCommand "pkill mpvpaper || true"
            
            putStrLn $ "🚀 Iniciando mpvpaper con: " ++ videoPath
            
            -- 6. Ejecutar mpvpaper optimizado para AMD (VAAPI)
            let mpvOpts = "--hwdec=vaapi --vo=libmpv --loop-playlist --no-audio --msg-level=all=no"
            _ <- spawnProcess "mpvpaper" ["-o", mpvOpts, "*", videoPath]
            
            return ()
