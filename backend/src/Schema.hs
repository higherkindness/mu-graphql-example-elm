{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Schema where

import Data.Int (Int64)
import qualified Data.Text as T
import Database.Persist.Sqlite (BackendKey (SqlBackendKey), toSqlKey)
import Database.Persist.TH
  ( mkMigrate,
    mkPersist,
    persistLowerCase,
    share,
    sqlSettings,
  )
import GHC.Generics (Generic)
import Mu.GraphQL.Quasi (graphql)
import Mu.Schema (FromSchema)

#if __GHCIDE__
graphql "Library" "backend/library.graphql"
#else
graphql "Library" "library.graphql" -- Let all the magic happen! 🪄🎩
#endif

share
  [mkPersist sqlSettings, mkMigrate "migrateAll"]
  [persistLowerCase|
Author json
  name T.Text
  UniqueName name
  deriving Show Generic
Book json
  title T.Text
  imageUrl T.Text
  author AuthorId
  UniqueTitlePerAuthor title author
  deriving Show Generic
|]

toAuthorId :: Int64 -> AuthorId
toAuthorId = toSqlKey

newtype NewAuthor = NewAuthor {name :: T.Text}
  deriving stock (Eq, Show, Generic)
  deriving anyclass (FromSchema LibrarySchema "NewAuthor")

data NewBook = NewBook {title :: T.Text, authorId :: Integer, imageUrl :: T.Text}
  deriving stock (Eq, Show, Generic)
  deriving anyclass (FromSchema LibrarySchema "NewBook")
