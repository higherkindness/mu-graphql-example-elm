module Editor exposing (Model, Msg(..), init, update, view)

import Components
import Gql exposing (GraphqlResponse, GraphqlTask)
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, a, button, div, h1, input, label, p, span, text)
import Html.Attributes exposing (class, for, href, id, placeholder, rel, target, type_, value)
import Html.Events exposing (onClick, onInput)
import LibraryApi.InputObject exposing (NewAuthor, NewBook)
import LibraryApi.Mutation as Mutation exposing (NewAuthorRequiredArguments, NewBookRequiredArguments)
import LibraryApi.Object exposing (Author, Book)
import LibraryApi.Object.Author as Author
import LibraryApi.Object.Book as Book
import LibraryApi.Query as Query exposing (AuthorsRequiredArguments, BooksRequiredArguments)
import RemoteData
import Task exposing (Task)


type alias AuthorData =
    { id : Int
    , name : String
    }


type AuthorInput
    = NewAuthorName String
    | ExistingAuthor AuthorData


type alias Model =
    { bookTitle : String
    , authorInput : AuthorInput
    }


init : ( Model, Cmd Msg )
init =
    ( { bookTitle = ""
      , authorInput = NewAuthorName ""
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
    | GotCreationResponse (GraphqlResponse String)



-- TODO: make some research on why it tries to decode on error, or why response contains no fields at all


createAuthor : NewAuthor -> Task (Graphql.Http.Error ()) AuthorData
createAuthor =
    NewAuthorRequiredArguments
        >> (\args -> Mutation.newAuthor args (SelectionSet.map2 AuthorData Author.id Author.name))
        >> Graphql.Http.mutationRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())
        >> Task.andThen (Gql.handleMutationFailure "Author")


createBook : NewBook -> Task (Graphql.Http.Error ()) String
createBook =
    NewBookRequiredArguments
        >> (\args -> Mutation.newBook args Book.title)
        >> Graphql.Http.mutationRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())
        >> Task.andThen (Gql.handleMutationFailure "Book")


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BookTitleChanged newTitle ->
            ( { model | bookTitle = newTitle }, Cmd.none )

        AuthorNameChanged newName ->
            case model.authorInput of
                NewAuthorName _ ->
                    ( { model | authorInput = NewAuthorName newName }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SelectAuthorClicked authorData ->
            ( { model | authorInput = ExistingAuthor authorData }, Cmd.none )

        DeselectAuthorClicked ->
            ( { model | authorInput = NewAuthorName "" }, Cmd.none )

        CancelClicked ->
            ( model, Cmd.none )

        SubmitClicked ->
            let
                authorTask =
                    case model.authorInput of
                        ExistingAuthor authorData ->
                            Task.succeed authorData

                        NewAuthorName authorName ->
                            createAuthor { name = authorName }

                -- TODO: update model: set RemoteData loading
            in
            ( model
            , authorTask
                |> Task.andThen (\authorData -> createBook { title = model.bookTitle, authorId = authorData.id })
                |> Task.attempt (RemoteData.fromResult >> GotCreationResponse)
            )

        GotCreationResponse res ->
            -- TODO: update model: set RemoteData success/failure
            case res of
                _ ->
                    ( model, Cmd.none )


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
        NewAuthorName str ->
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
