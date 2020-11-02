module Editor exposing (Model, Msg(..), init, update, view)

import Components
import Gql exposing (GraphqlResponse, GraphqlTask)
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, a, button, div, h1, input, label, p, span, text)
import Html.Attributes exposing (class, for, href, id, placeholder, rel, target, type_, value)
import Html.Events exposing (onClick, onInput)
import LibraryApi.InputObject exposing (NewAuthor)
import LibraryApi.Mutation as Mutation exposing (NewAuthorRequiredArguments)
import LibraryApi.Object exposing (Author, Book)
import LibraryApi.Object.Author as Author
import LibraryApi.Query as Query exposing (AuthorsRequiredArguments, BooksRequiredArguments)
import RemoteData
import Task exposing (Task)


type alias Model =
    { bookTitle : String
    , authorName : String
    }


init : ( Model, Cmd Msg )
init =
    ( { bookTitle = ""
      , authorName = ""
      }
    , Cmd.none
    )



-- update and Tasks


type Msg
    = BookTitleChanged String
    | AuthorNameChanged String
    | CancelClicked
    | SubmitClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BookTitleChanged newTitle ->
            ( { model | bookTitle = newTitle }, Cmd.none )

        AuthorNameChanged newName ->
            ( { model | authorName = newName }, Cmd.none )

        CancelClicked ->
            ( model, Cmd.none )

        SubmitClicked ->
            ( model, Cmd.none )



-- views


view : Model -> Html Msg
view model =
    div []
        [ label [ for "book-title-input" ] [ text "Book title" ]
        , input
            [ type_ "text"
            , id "book-title-input"
            , placeholder ""
            , value model.bookTitle
            , onInput BookTitleChanged
            ]
            []
        , label [ for "author-name-input" ] [ text "Author name" ]
        , input
            [ type_ "text"
            , id "author-name-input"
            , placeholder ""
            , value model.authorName
            , onInput AuthorNameChanged
            ]
            []
        , div []
            [ button [ onClick CancelClicked ] [ text "Cancel" ]
            , button [ onClick SubmitClicked ] [ text "Submit a book" ]
            ]
        ]
