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


type alias AuthorData =
    { id : Int
    , name : String
    }


type AuthorInput
    = NewAutorName String
    | ExistingAuthor AuthorData


type alias Model =
    { bookTitle : String
    , authorInput : AuthorInput
    }


init : ( Model, Cmd Msg )
init =
    ( { bookTitle = ""
      , authorInput = NewAutorName ""
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
            case model.authorInput of
                NewAutorName _ ->
                    ( { model | authorInput = NewAutorName newName }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        CancelClicked ->
            ( model, Cmd.none )

        SubmitClicked ->
            ( model, Cmd.none )



-- views


authorInput : AuthorInput -> Html Msg
authorInput author =
    case author of
        NewAutorName str ->
            input
                [ type_ "text"
                , id "author-name-input"
                , placeholder ""
                , value str
                , onInput AuthorNameChanged
                ]
                []

        ExistingAuthor _ ->
            div [] []


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
        , authorInput model.authorInput
        , div []
            [ button [ onClick CancelClicked ] [ text "Cancel" ]
            , button [ onClick SubmitClicked ] [ text "Submit a book" ]
            ]
        ]
