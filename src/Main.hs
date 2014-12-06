
module Main where

import Control.Monad.IO.Class

import Data.Monoid
import qualified Data.Aeson as Aeson

import System.Environment (getArgs)
import qualified Data.Configurator as Config
import Data.Configurator.Types (Config)

import Web.Scotty
import Network.Wai.Middleware.Static (staticPolicy, noDots, addBase)



main :: IO ()
main = getArgs >>= \case
  [configFile] -> do
    Config.load [Config.Required configFile]
      >>= startEngines
  _ -> error "Usage: ob <config>"


startEngines :: Config -> IO ()
startEngines conf = do
  Just httpPort  <- Config.lookup conf "http.port"
--  Just wsoskPort <- Config.lookup conf "websock.port"
--  Just graphPort <- Config.lookup conf "graphite.port"

  scotty httpPort $ do
    middleware $ staticPolicy (noDots <> addBase "static")

    get "/" $ do
      setHeader "Content-Type" "text/html"
      file "static/index.html"

    post "/test" $ do
      x <- jsonData
      -- get url
      -- gen uuid
      -- create tmp dir
      -- create tank.ini
      -- spawn thread: run tank >> report end of job
      -- return uuid
      json (x :: Aeson.Value)
