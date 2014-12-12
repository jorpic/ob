
module WS (wsServer) where

import Control.Concurrent.Chan
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Data.Aeson as Aeson
import Data.UUID as UUID
import qualified Network.WebSockets as WS

import Common


wsServer :: Config -> ServerState -> IO ()
wsServer Config{wsPort, testDur, maxRps} ss
  = WS.runServer "0.0.0.0" wsPort $ \req -> do
    let uuid = UUID.fromString
          . T.unpack . T.tail -- drop leading slash
          . T.decodeUtf8
          . WS.requestPath $ WS.pendingRequest req

    case uuid of
      Nothing -> WS.rejectRequest req "Invalid UUID"
      Just jobId -> getJob jobId ss >>= \case
        Nothing -> WS.rejectRequest req "Job is finished or never existed"
        Just jobCh -> do
          conn <- WS.acceptRequest req
          let conf = Aeson.encode $ object
                ["config" .= object
                  ["duration" .= testDur
                  ,"maxRps" .= maxRps
                  ]
                ]
          WS.sendTextData conn conf -- share config
          ch   <- dupChan jobCh
          let loop = readChan ch >>= \case
                -- FIXME: we can loop forever if EOF is lost, better check
                -- liveJobs instead  of EOF
                -- FIXME: wait for close msg from peer
                EOF -> WS.sendClose conn $ T.pack "bye"
                Msg msg -> WS.sendTextData conn msg >> loop
          -- FIXME: sendCollected data
          loop
