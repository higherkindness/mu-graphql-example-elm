{-# LANGUAGE DataKinds #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Main where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Logger (LoggingT, logInfoN, runStderrLoggingT)
import Data.Conduit (ConduitT, Void, runConduit, (.|))
import Data.Conduit.Combinators (yieldMany)
import Data.Maybe (fromJust)
import qualified Data.Text as T
import Database.Persist.Sqlite
import Mu.Adapter.Persistent (runDb)
import Mu.GraphQL.Server (graphQLApp, liftServerConduit)
import Mu.Instrumentation.Prometheus (initPrometheus, prometheus)
import Mu.Schema (Mapping ((:->)), Proxy (Proxy))
import Mu.Server
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.AddHeaders (addHeaders)
import Schema

main :: IO ()
main = do
  -- Setup CORS
  let hm =
        addHeaders
          [ ("Access-Control-Allow-Origin", "*"),
            ("Access-Control-Allow-Headers", "Content-Type")
          ]
  p <- initPrometheus "library"
  runStderrLoggingT $
    withSqliteConn ":memory:" $ \conn -> do
      runDb conn $ runMigration migrateAll
      insertSeedData conn
      logInfoN "starting GraphQL server on port 8000"
      liftIO $
        run 8000 $
          hm $
            graphQLApp
              (prometheus p $ libraryServer conn)
              (Proxy @('Just "Query"))
              (Proxy @('Just "Mutation"))
              (Proxy @('Just "Subscription"))

-- | Inserts demo data to make this example valueable for testing with different clients
--   Returns Nothing in case of any failure, including attempts to insert non-unique values
insertSeedData :: SqlBackend -> LoggingT IO (Maybe ())
insertSeedData conn =
  sequence_
    <$> traverse
      (uncurry $ insertAuthorAndBooks conn)
      [ ( Author "Robert Louis Stevenson",
          [ Book "Treasure Island" "https://m.media-amazon.com/images/I/51C6NXR94gL.jpg",
            Book "Strange Case of Dr Jekyll and Mr Hyde" "https://m.media-amazon.com/images/I/51e8pkDxjfL.jpg"
          ]
        ),
        ( Author "Immanuel Kant",
          [Book "Critique of Pure Reason" "https://m.media-amazon.com/images/I/51h+rBXrYeL.jpg"]
        ),
        ( Author "Michael Ende",
          [ Book "The Neverending Story" "https://m.media-amazon.com/images/I/51AnD2Fki3L.jpg",
            Book "Momo" "https://m.media-amazon.com/images/I/61AuiRa4nmL.jpg"
          ]
        ),
        ( Author "Alejandro Serrano",
          [ Book "Practical Haskell" "https://m.media-amazon.com/images/I/61j3IHmnqvL.jpg",
            Book "Book of Monads" "https://m.media-amazon.com/images/I/51x-SNjPKjL.jpg"
          ]
        ),
        ( Author "Graham Hutton",
          [Book "Programming in Haskell" "https://m.media-amazon.com/images/I/61Fo+7epgQL.jpg"]
        ),
        ( Author "Chris Allen & Julie Moronuki",
          [Book "Haskell Programming from First Principles" "https://haskellbook.com/img/book-cover-front.png"]
        )
      ]

-- | Inserts Author and Books
--   Returns Nothing in case of any failure, including attempts to insert non-unique values
insertAuthorAndBooks :: SqlBackend -> Author -> [Key Author -> Book] -> LoggingT IO (Maybe ())
insertAuthorAndBooks conn author books =
  runDb conn . fmap sequence_ $ do
    authorResult <- insertUnique author
    case authorResult of
      Just authorId -> traverse (\kBook -> insertUnique (kBook authorId)) books
      Nothing -> pure [Nothing]

type ObjectMapping =
  '[ "Book" ':-> Entity Book,
     "Author" ':-> Entity Author
   ]

libraryServer :: SqlBackend -> ServerT ObjectMapping i Library ServerErrorIO _
libraryServer conn =
  resolver
    ( object @"Book"
        ( field @"id" bookId,
          field @"title" bookTitle,
          field @"author" bookAuthor,
          field @"imageUrl" bookImage
        ),
      object @"Author"
        ( field @"id" authorId,
          field @"name" authorName,
          field @"books" authorBooks
        ),
      object @"Query"
        ( method @"authors" allAuthors,
          method @"books" allBooks
        ),
      object @"Mutation"
        ( method @"newAuthor" newAuthor,
          method @"newBook" newBook
        ),
      object @"Subscription"
        (method @"allBooks" allBooksConduit)
    )
  where
    bookId :: Entity Book -> ServerErrorIO Integer
    bookId (Entity (BookKey k) _) = pure $ toInteger k
    bookTitle :: Entity Book -> ServerErrorIO T.Text
    bookTitle (Entity _ Book {bookTitle}) = pure bookTitle
    bookAuthor :: Entity Book -> ServerErrorIO (Entity Author)
    bookAuthor (Entity _ Book {bookAuthor}) = do
      author <- runDb conn $ get bookAuthor
      pure $ Entity bookAuthor (fromJust author)
    bookImage :: Entity Book -> ServerErrorIO T.Text
    bookImage (Entity _ Book {bookImageUrl}) = pure bookImageUrl

    authorId :: Entity Author -> ServerErrorIO Integer
    authorId (Entity (AuthorKey k) _) = pure $ toInteger k
    authorName :: Entity Author -> ServerErrorIO T.Text
    authorName (Entity _ Author {authorName}) = pure authorName
    authorBooks :: Entity Author -> ServerErrorIO [Entity Book]
    authorBooks (Entity author _) =
      runDb conn $
        selectList [BookAuthor ==. author] [Asc BookTitle]

    allAuthors :: T.Text -> ServerErrorIO [Entity Author]
    allAuthors nameFilter =
      runDb conn $
        selectList
          [ Filter
              AuthorName
              (FilterValue nameFilter)
              (BackendSpecificFilter "LIKE")
          ]
          [Asc AuthorName]

    allBooks :: T.Text -> ServerErrorIO [Entity Book]
    allBooks titleFilter =
      runDb conn $
        selectList
          [ Filter
              BookTitle
              (FilterValue titleFilter)
              (BackendSpecificFilter "LIKE")
          ]
          [Asc BookTitle]

    allBooksConduit :: ConduitT (Entity Book) Void ServerErrorIO () -> ServerErrorIO ()
    allBooksConduit sink = do
      -- do not convert to a single selectConduit!
      -- there seems to be a problem running nested runDb's
      -- so we break it into two steps, assuming that the
      -- list of books would fit in memory
      -- see https://github.com/higherkindness/mu-haskell/issues/259
      lst <- liftIO $ runDb conn $ selectList [] [Asc BookTitle]
      runConduit $ yieldMany lst .| liftServerConduit sink

    insertNewEntity :: (PersistEntity a, PersistEntityBackend a ~ SqlBackend) => T.Text -> a -> ServerErrorIO (Entity a)
    insertNewEntity name new = do
      maybeEntity <- runDb conn $ do
        result <- insertUnique new
        pure $ Entity <$> result <*> pure new
      let errorMsg = T.unpack name <> "\" already exists"
      maybe (serverError $ ServerError Invalid errorMsg) pure maybeEntity

    newAuthor :: NewAuthor -> ServerErrorIO (Entity Author)
    newAuthor (NewAuthor name) = insertNewEntity ("Author " <> name) (Author name)

    newBook :: NewBook -> ServerErrorIO (Entity Book)
    newBook (NewBook title authorId img) = insertNewEntity ("Book " <> title) (Book title img . toSqlKey $ fromInteger authorId)
