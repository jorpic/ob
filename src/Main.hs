
module Main where

import Control.Monad
import Control.Monad.IO.Class
import Control.Concurrent (forkIO)

import Data.Text (Text)
import qualified Data.Text.Encoding as T
import qualified Data.Text.IO as T

import Data.Monoid
import Data.Aeson ((.=))
import qualified Data.Aeson as Aeson
import Data.Aeson.TH

import System.Environment (getArgs)
import System.Posix (createDirectory)
import qualified Data.Configurator as Config
import Data.Configurator.Types (Config)

import Data.UUID as UUID
import Data.UUID.V4 as UUID
import Web.Scotty
import Network.Wai.Middleware.Static (staticPolicy, noDots, addBase)

import qualified Network.WebSockets as WS



main :: IO ()
main = getArgs >>= \case
  [configFile] -> do
    conf <- Config.load [Config.Required configFile]
    void $ forkIO $ wsServer conf
    httpServer conf
  _ -> error "Usage: ob <config>"


httpServer :: Config -> IO ()
httpServer conf = do
  Just httpPort  <- Config.lookup conf "http.port"
  Just wsockPort <- Config.lookup conf "websocket.port"

  scotty httpPort $ do
    middleware $ staticPolicy (noDots <> addBase "static")

    get "/" $ do
      setHeader "Content-Type" "text/html"
      file "static/index.html"

    post "/bang" $ do
      BangQuery{url} <- jsonData -- TODO: check url => ssl, port, url
      uuid <- liftIO UUID.nextRandom
      json $ Aeson.object
        ["job" .= UUID.toString uuid
        ,"ws_port" .= (wsockPort :: Int)
        ]


wsServer :: Config -> IO ()
wsServer conf = do
  Just wsPort <- Config.lookup conf "websocket.port"
  WS.runServer "0.0.0.0" wsPort $ \req -> do
    let url = T.decodeUtf8 $ WS.requestPath $ WS.pendingRequest req
    T.putStrLn url
    -- check if == uuid
    conn <- WS.acceptRequest req
    -- send allData
    WS.sendTextData conn ("hello" :: Text)
    -- loop sendNewData `finally` disconnect
    WS.sendClose conn ("bye" :: Text) -- FIXME: wait for close from peer




runTank :: Config -> UUID -> Text -> IO ()
runTank conf uuid url = do
--  Just graphitePort <- Config.lookup conf "graphite.port"
  Just tankDir <- Config.lookup conf "tank.data_dir"
  createDirectory (tankDir ++ "/" ++ UUID.toString uuid) 0o777
  -- create tank.ini
  -- spawn thread: run tank >> report end of job

data BangQuery = BangQuery { url :: Text }
$(deriveFromJSON defaultOptions ''BangQuery)
