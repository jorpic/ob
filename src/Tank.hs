
module Tank (runTank) where

import Control.Monad (void)
import Control.Concurrent
import Data.UUID as UUID
import Network.URI
import Text.Printf
import System.Process
import System.Exit (ExitCode(..))
import System.Posix (createDirectory)

import Common


runTank :: Config -> ServerState -> UUID -> URI -> IO ()
runTank
  Config{graphitePort, tankDir, maxRps, testDur}
  ss uuid URI{..} = do
    let jobDir = tankDir ++ "/" ++ UUID.toString uuid
    createDirectory jobDir 0o777

    let Just auth = uriAuthority
    let ini = unlines
          [ "[tank]"
          , "plugin_web="
          , "plugin_console="
          , "plugin_loadosophia="
          , "plugin_monitoring="
          , "plugin_report="
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
    void $ forkIO $ do
      threadDelay $ testDur*2*10^(6::Int)
      terminateProcess h -- FIXME: should be SIGINT instead of SIGTERM

    ch <- getJob uuid ss >>= \case
      Nothing -> error "BUG! in runTank"
      Just ch -> dupChan ch

    res <- waitForProcess h
    writeChan ch . mkErrMsg $ case res of
      ExitSuccess -> Nothing
      ExitFailure err
        -> Just $ printf "Tank finished unexpectedly with status %d" err
