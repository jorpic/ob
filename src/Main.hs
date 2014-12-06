
module Main where

import Control.Applicative
import Control.Monad
import Control.Monad.IO.Class
import Control.Concurrent (forkIO)

import Control.Concurrent.Chan
import Data.IORef

import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

import Data.Map (Map)
import qualified Data.Map as Map

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



data ServerState = ServerState
  { liveJobs :: IORef (Map UUID (Chan Msg))
  }

data Msg = EOF | Msg Text


main :: IO ()
main = getArgs >>= \case
  [configFile] -> do
    conf <- Config.load [Config.Required configFile]
    ss   <- ServerState <$> newIORef Map.empty
    void $ forkIO $ wsServer conf ss
    httpServer conf ss
  _ -> error "Usage: ob <config>"


data BangQuery = BangQuery { url :: Text }
$(deriveFromJSON defaultOptions ''BangQuery)


httpServer :: Config -> ServerState -> IO ()
httpServer conf ss = do
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
      -- store job id in server state
      liftIO $ do
        ch <- newChan
        atomicModifyIORef' (liveJobs ss) (\lj -> (Map.insert uuid ch lj, ()))

      -- forkIO $ runTank

      json $ Aeson.object
        ["job" .= UUID.toString uuid
        ,"ws_port" .= (wsockPort :: Int)
        ]


wsServer :: Config -> ServerState -> IO ()
wsServer conf ss = do
  Just wsPort <- Config.lookup conf "websocket.port"
  WS.runServer "0.0.0.0" wsPort $ \req -> do
    let uuid = UUID.fromString
          . T.unpack . T.tail -- drop leading slash
          . T.decodeUtf8
          . WS.requestPath $ WS.pendingRequest req

    lj <- readIORef $ liveJobs ss
    case uuid >>= flip Map.lookup lj of
      Nothing -> WS.rejectRequest req "Job is finished or never existed"
      Just jobCh -> do
        conn <- WS.acceptRequest req
        ch   <- dupChan jobCh
        let loop = readChan ch >>= \case
              -- FIXME: wait for close msg from peer
              EOF -> WS.sendClose conn ("bye" :: Text)
              Msg msg -> WS.sendTextData conn msg >> loop
        -- FIXME: sendCollected data
        loop


runTank :: Config -> UUID -> Text -> IO ()
runTank conf uuid url = do
--  Just graphitePort <- Config.lookup conf "graphite.port"
  Just tankDir <- Config.lookup conf "tank.data_dir"
  createDirectory (tankDir ++ "/" ++ UUID.toString uuid) 0o777
  -- create tank.ini
  -- spawn thread: run tank >> report end of job
