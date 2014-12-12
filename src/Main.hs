
module Main where

import Control.Applicative
import Control.Monad (void)
import Control.Concurrent (forkIO)

import System.Environment (getArgs)
import qualified Data.Configurator as Config

import Common
import HTTP
import WS
import Graphite



main :: IO ()
main = getArgs >>= \case
  [configFile] -> do
    cfg <- Config.load [Config.Required configFile]
    conf <- Config
        <$> Config.require cfg "http.port"
        <*> Config.require cfg "websocket.port"
        <*> Config.require cfg "graphite.port"
        <*> Config.require cfg "tank.data_dir"
        <*> Config.require cfg "tank.max_rps"
        <*> Config.require cfg "tank.duration"
    ss   <- emptyServerState
    void $ forkIO $ wsServer conf ss
    void $ forkIO $ graphiteServer conf ss
    httpServer conf ss
  _ -> error "Usage: ob <config>"
