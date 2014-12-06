#!/bin/bash -e

npm update
grunt

cabal update
cabal sandbox init
cabal install

