module Search exposing (Model, Msg(..), init, update, view)

-- import LibraryApi.Mutation as Mutation exposing (NewAuthorRequiredArguments)
-- import LibraryApi.InputObject exposing (NewAuthor)

import Gql exposing (GraphqlResponse, GraphqlTask)
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, a, button, div, h1, input, p, span, text)
import Html.Attributes exposing (class, href, placeholder, rel, target, type_, value)
import Html.Events exposing (onClick, onInput)
import LibraryApi.Object exposing (Author, Book)
import LibraryApi.Object.Author as Author
import LibraryApi.Object.Book as Book
import LibraryApi.Query as Query exposing (AuthorsRequiredArguments, BooksRequiredArguments)
import RemoteData
import Task exposing (Task)
import ViewHelpers


type alias AuthorData =
    { name : String
    }


type alias BookData =
    { title : String
    , author : AuthorData
    }


type alias SearchResults =
    ( List AuthorData, List BookData )


type alias Model =
    { query : String
    , searchResults : GraphqlResponse SearchResults
    }


init : ( Model, Cmd Msg )
init =
    ( { query = ""
      , searchResults = RemoteData.NotAsked
      }
    , Cmd.none
    )


type Msg
    = ChangeQuery String
    | GotResponse (GraphqlResponse SearchResults)
    | OpenEditorClicked


{-| TODO: get rid of it
-}
authorSelection : SelectionSet AuthorData Author
authorSelection =
    SelectionSet.map AuthorData Author.name


findAuthors : String -> SelectionSet (List AuthorData) RootQuery
findAuthors name =
    Query.authors (AuthorsRequiredArguments <| Gql.toPattern name) authorSelection


{-| TODO: get rid of it
-}
bookSelection : SelectionSet BookData Book
bookSelection =
    SelectionSet.map2 BookData
        Book.title
        (Book.author authorSelection)


findBooks : String -> SelectionSet (List BookData) RootQuery
findBooks title =
    Query.books (BooksRequiredArguments <| Gql.toPattern title) bookSelection


findAuthorsAndBooks : String -> SelectionSet SearchResults RootQuery
findAuthorsAndBooks queryStr =
    SelectionSet.map2 Tuple.pair
        (findAuthors queryStr)
        (findBooks queryStr)


findAuthorsAndBooksTask : String -> GraphqlTask SearchResults
findAuthorsAndBooksTask =
    findAuthorsAndBooks
        >> Graphql.Http.queryRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeQuery queryStr ->
            case String.trim queryStr of
                "" ->
                    ( { model | query = "", searchResults = RemoteData.NotAsked }
                    , Cmd.none
                    )

                str ->
                    ( { model | query = str, searchResults = RemoteData.Loading }
                    , findAuthorsAndBooksTask str
                        |> Task.attempt (RemoteData.fromResult >> GotResponse)
                    )

        GotResponse res ->
            ( { model | searchResults = res }, Cmd.none )

        OpenEditorClicked ->
            ( model, Cmd.none )


showAuthor : AuthorData -> Html Msg
showAuthor { name } =
    div [ class "author fade-in" ]
        [ span [ class "author-name" ] [ text name ]
        ]


showBook : BookData -> Html Msg
showBook { title, author } =
    div [ class "book fade-in" ]
        [ div [ class "book-cover" ] []
        , div []
            [ p [ class "book-title" ] [ text title ]
            , p [ class "book-author" ] [ text <| "by " ++ author.name ]
            ]
        ]


showSearchResults : SearchResults -> Html Msg
showSearchResults ( authors, books ) =
    let
        results =
            List.map showAuthor authors ++ List.map showBook books
    in
    case results of
        [] ->
            div [ class "no-results fade-in" ] [ text "Nothing found" ]

        _ ->
            div [ class "search-results fade-in" ] results


showAddButton : Html Msg
showAddButton =
    div [ class "add-button", onClick OpenEditorClicked ]
        [ span [ class "round-icon" ] [ text "+" ]
        , span [ class "add-button-label" ] [ text "Add a Book" ]
        ]


showSearchInput : String -> Html Msg
showSearchInput query =
    input
        [ type_ "text"
        , placeholder "For example, Kant"
        , value query
        , onInput ChangeQuery
        ]
        []


view : Model -> Html Msg
view model =
    div []
        [ div [ class "search-row" ]
            [ showSearchInput model.query
            , showAddButton
            ]
        , ViewHelpers.showRemoteData showSearchResults model.searchResults
        ]
