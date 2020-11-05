module Search exposing (Model, Msg(..), init, update, view)

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



-- update and Tasks


type Msg
    = QueryChanged String
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
        QueryChanged queryStr ->
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



-- views


showAuthor : AuthorData -> Html Msg
showAuthor { name } =
    div [ class "fade-in" ] [ text name ]


showBook : BookData -> Html Msg
showBook { title, author } =
    div [ class "book fade-in" ]
        [ div [ class "book__cover" ] []
        , div []
            [ p [ class "book__title" ] [ text title ]
            , p [ class "book__author" ] [ text <| "by " ++ author.name ]
            ]
        ]


showSearchResults : GraphqlResponse SearchResults -> Html Msg
showSearchResults data =
    case data of
        RemoteData.NotAsked ->
            div [] []

        RemoteData.Loading ->
            div [] [ p [ class "fade-in-slow" ] [ text ". . ." ] ]

        RemoteData.Failure e ->
            div [] [ p [ class "error fade-in" ] [ text (Gql.showError e) ] ]

        RemoteData.Success ( [], [] ) ->
            div [ class "no-results fade-in" ] [ text "Nothing found" ]

        RemoteData.Success ( authors, books ) ->
            (List.map showAuthor authors ++ List.map showBook books)
                |> div [ class "search-results fade-in" ]


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick OpenEditorClicked ] [ text "Add a book" ]
        , input
            [ type_ "text"
            , placeholder "For example, Kant"
            , value model.query
            , onInput QueryChanged
            ]
            []
        , showSearchResults model.searchResults
        ]
