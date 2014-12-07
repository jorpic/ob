
module Graphite (graphiteServer, parseMsg) where

import Control.Applicative
import Control.Monad
import Control.Concurrent
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Read as T
import Data.UUID as UUID
import System.IO
import Network
import Common


graphiteServer :: Config -> ServerState -> IO ()
graphiteServer Config{graphitePort} ss
  = withSocketsDo $ do
    let port = PortNumber $ fromIntegral graphitePort
    sock <- listenOn port
    forever $ do
      (h, _, _) <- accept sock
      hSetBuffering h LineBuffering
      let loop = hIsEOF h >>= \case
            True -> return ()
            False -> parseMsg <$> hGetLine h >>= \case
              Nothing -> loop -- Skip malformed messages
              Just (uuid, path, val, tm) -> do
                putStrLn $ show (uuid, path, val, tm)
                loop
      forkIO loop



parseMsg :: String -> Maybe (UUID, Text, Double, Int)
parseMsg str = do
  [path, val, tm]   <- pure $ T.words $ T.pack str
  uuidTxt:prefix    <- pure $ T.splitOn "." path
  uuid <- UUID.fromString $ T.unpack uuidTxt
  Right (value, "") <- pure $ T.signed T.double val
  Right (time, "")  <- pure $ T.decimal tm
  return (uuid, T.intercalate "." prefix, value, time)
