
module Common where

import Control.Applicative
import Control.Concurrent.Chan
import Data.Text (Text)
import Data.ByteString.Lazy (ByteString)
import Data.IORef
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Aeson as Aeson
import Data.UUID


data Config = Config
  { httpPort     :: Int
  , wsPort       :: Int
  , graphitePort :: Int
  , tankDir      :: String
  , maxRps       :: Int
  , testDur      :: Int
  }

data ServerState = ServerState
  { liveJobs :: IORef (Map UUID (Chan Msg))
  }


data Msg = EOF | Msg ByteString

mkMsg :: Text -> Int -> Double -> Msg
mkMsg key tm val
  = Msg
  $ Aeson.encode $ object
    [ "key" .= key
    , "time" .= tm
    , "value" .= val
    ]


emptyServerState :: IO ServerState
emptyServerState = ServerState <$> newIORef Map.empty


addJob :: UUID -> ServerState -> IO (Chan Msg)
addJob uuid ServerState{..} = do
  ch <- newChan
  atomicModifyIORef' liveJobs (\lj -> (Map.insert uuid ch lj, ch))


getJob :: UUID -> ServerState -> IO (Maybe (Chan Msg))
getJob uuid ServerState{liveJobs}
  = Map.lookup uuid <$> readIORef liveJobs


finishJob :: UUID -> ServerState -> IO ()
finishJob uuid ServerState{..}
  = atomicModifyIORef' liveJobs (\lj -> (Map.delete uuid lj, ()))
