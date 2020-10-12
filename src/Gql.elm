module Gql exposing (..)

import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import LibraryApi.InputObject exposing (NewAuthor)
import LibraryApi.Mutation as Mutation exposing (NewAuthorRequiredArguments)
import LibraryApi.Object exposing (Author, Book)
import LibraryApi.Object.Author as Author
import LibraryApi.Object.Book as Book
import LibraryApi.Query as Query exposing (AuthorsRequiredArguments, BooksRequiredArguments)
import Task exposing (Task)


graphqlUrl : String
graphqlUrl =
    "http://localhost:8000"


type alias AuthorData =
    { name : String }


type alias GraphqlTask t =
    Task (Graphql.Http.Error ()) t


authorSelection : SelectionSet AuthorData Author
authorSelection =
    SelectionSet.map AuthorData Author.name


findAuthors : String -> GraphqlTask (List AuthorData)
findAuthors name =
    Query.authors (AuthorsRequiredArguments name) authorSelection
        |> Graphql.Http.queryRequest graphqlUrl
        |> Graphql.Http.toTask
        |> Task.mapError (Graphql.Http.mapError <| always ())


type alias BookData =
    { title : String
    , author : AuthorData
    }


bookSelection : SelectionSet BookData Book
bookSelection =
    SelectionSet.map2 BookData
        Book.title
        (Book.author authorSelection)


findBooks : String -> GraphqlTask (List BookData)
findBooks title =
    Query.books (BooksRequiredArguments title) bookSelection
        |> Graphql.Http.queryRequest graphqlUrl
        |> Graphql.Http.toTask
        |> Task.mapError (Graphql.Http.mapError <| always ())


findAuthorsAndBooks : String -> GraphqlTask ( List AuthorData, List BookData )
findAuthorsAndBooks queryStr =
    findAuthors queryStr
        |> Task.andThen
            (\authors ->
                findBooks queryStr
                    |> Task.map (\books -> ( authors, books ))
            )
