
module Common where

import Control.Applicative
import Control.Concurrent.Chan
import Data.Text (Text)
import Data.IORef
import Data.Map (Map)
import qualified Data.Map as Map
import Data.UUID


data Config = Config
  { httpPort     :: Int
  , wsPort       :: Int
  , graphitePort :: Int
  , tankDir      :: String
  }

data ServerState = ServerState
  { liveJobs :: IORef (Map UUID (Chan Msg))
  }

data Msg = EOF | Msg Text

emptyServerState :: IO ServerState
emptyServerState = ServerState <$> newIORef Map.empty

addJob :: UUID -> ServerState -> IO (Chan Msg)
addJob uuid ServerState{..} = do
  ch <- newChan
  atomicModifyIORef' liveJobs (\lj -> (Map.insert uuid ch lj, ch))

finishJob :: UUID -> ServerState -> IO ()
finishJob uuid ServerState{..}
  = atomicModifyIORef' liveJobs (\lj -> (Map.delete uuid lj, ()))
