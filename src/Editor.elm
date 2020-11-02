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
      , authorInput = ExistingAuthor { id = 42, name = "John Galt" }
      }
    , Cmd.none
    )



-- update and Tasks


type Msg
    = BookTitleChanged String
    | AuthorNameChanged String
    | SelectAuthorClicked AuthorData
    | DeselectAuthorClicked
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

        SelectAuthorClicked authorData ->
            ( { model | authorInput = ExistingAuthor authorData }, Cmd.none )

        DeselectAuthorClicked ->
            ( { model | authorInput = NewAutorName "" }, Cmd.none )

        CancelClicked ->
            ( model, Cmd.none )

        SubmitClicked ->
            ( model, Cmd.none )



-- views


bookTitleInput : String -> Html Msg
bookTitleInput bookTitle =
    label [ for "book-title-input" ]
        [ text "Book title"
        , input
            [ type_ "text"
            , id "book-title-input"
            , placeholder ""
            , value bookTitle
            , onInput BookTitleChanged
            ]
            []
        ]


authorInput : AuthorInput -> Html Msg
authorInput author =
    case author of
        NewAutorName str ->
            label [ for "author-name-input" ]
                [ text "Author name"
                , input
                    [ type_ "text"
                    , id "author-name-input"
                    , placeholder ""
                    , value str
                    , onInput AuthorNameChanged
                    ]
                    []
                ]

        ExistingAuthor authorData ->
            div [ class "existing-author" ]
                [ text <| "Author: " ++ authorData.name
                , button [ onClick DeselectAuthorClicked ] [ text "Deselect" ]
                ]


view : Model -> Html Msg
view model =
    div []
        [ bookTitleInput model.bookTitle
        , authorInput model.authorInput
        , div []
            [ button [ onClick CancelClicked ] [ text "Cancel" ]
            , button [ onClick SubmitClicked ] [ text "Submit a book" ]
            ]
        ]
