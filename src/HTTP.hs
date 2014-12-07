{-# LANGUAGE TemplateHaskell #-}

module HTTP (httpServer) where

import Control.Monad
import Control.Monad.IO.Class
import Control.Exception (finally)
import Control.Concurrent (forkIO)
import Control.Concurrent.Chan

import Data.Text (Text)
import Data.Monoid
import Data.Aeson.TH
import Data.Aeson ((.=))
import qualified Data.Aeson as Aeson

import Data.UUID as UUID
import Data.UUID.V4 as UUID
import Web.Scotty
import Network.Wai.Middleware.Static (staticPolicy, noDots, addBase)
import Network.URI

import Common
import Tank


data BangQuery = BangQuery { url :: String }
$(deriveFromJSON defaultOptions ''BangQuery)

httpServer :: Config -> ServerState -> IO ()
httpServer conf@(Config{httpPort, wsPort}) ss
  = scotty httpPort $ do
    middleware $ staticPolicy (noDots <> addBase "static")

    get "/" $ do
      setHeader "Content-Type" "text/html"
      file "static/index.html"

    post "/bang" $ do
      BangQuery{url} <- jsonData -- TODO: check url => ssl, port, url
      case parseAbsoluteURI url of
        Nothing  -> json $ Aeson.object ["error" .= ("invalid url" :: Text)]
        Just uri -> do
          uuid <- liftIO UUID.nextRandom
          liftIO $ do -- store job id in the server state
            ch <- addJob uuid ss
            void $ forkIO $ do
              finally (runTank conf uuid uri) $ do
                writeChan ch EOF -- FIXME: dupChan is required here
                finishJob uuid ss

          json $ Aeson.object
            ["job" .= UUID.toString uuid
            ,"ws_port" .= wsPort
            ]
