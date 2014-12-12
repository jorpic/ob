
module Tank (runTank) where

import Control.Monad (void)
import Data.UUID as UUID
import Network.URI
import Text.Printf
import System.Process
import System.Posix (createDirectory)

import Common


runTank :: Config -> UUID -> URI -> IO ()
runTank
  Config{graphitePort, tankDir, maxRps, testDur}
  uuid URI{..} = do
    let jobDir = tankDir ++ "/" ++ UUID.toString uuid
    createDirectory jobDir 0o777

    let Just auth = uriAuthority
    let ini = unlines
          [ "[tank]"
          , "plugin_web="
          , "plugin_console="
          , "plugin_loadosophia="
          , "plugin_monitoring="
          , "plugin_report=" -- maybe use it?
          , "[graphite]"
          , "address=127.0.0.1"
          , printf "port=%d" graphitePort
          , printf "prefix=%s" (UUID.toString uuid)
          , "[phantom]"
          , printf "rps_schedule=line(1,%d,%d)" maxRps testDur
          , printf "address=%s%s" (uriRegName auth) (uriPort auth)
          -- FIXME: check if empty
          , "uris=" ++ uriPath ++ uriQuery
          ]
    writeFile (jobDir ++ "/load.ini") ini
    let tank = (proc "yandex-tank" ["--ignore-lock"])
          {cwd = Just jobDir}
    (_,_,_,h) <- createProcess tank
    void $ waitForProcess h
