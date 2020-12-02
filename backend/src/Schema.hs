{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Schema where

import qualified Data.Text as T
import Database.Persist.Sqlite (BackendKey (SqlBackendKey))
import Database.Persist.TH (mkMigrate, mkPersist, persistLowerCase, share, sqlSettings)
import GHC.Generics (Generic)
import Mu.GraphQL.Quasi (graphql)
import Mu.Schema (FromSchema)

graphql "Library" "library.graphql"

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

newtype NewAuthor = NewAuthor
  { name :: T.Text
  }
  deriving stock (Eq, Show, Generic)
  deriving anyclass (FromSchema LibrarySchema "NewAuthor")

data NewBook = NewBook
  { title :: T.Text,
    authorId :: Integer,
    imageUrl :: T.Text
  }
  deriving stock (Eq, Show, Generic)
  deriving anyclass (FromSchema LibrarySchema "NewBook")
