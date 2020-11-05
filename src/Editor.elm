module Editor exposing (Model, Msg(..), init, update, view)

import Gql exposing (GraphqlResponse, GraphqlTask)
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, a, button, div, h1, input, label, p, span, text)
import Html.Attributes exposing (class, disabled, for, href, id, placeholder, rel, target, type_, value)
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
    , createBookResponse : GraphqlResponse String
    }


init : ( Model, Cmd Msg )
init =
    ( { bookTitle = ""
      , authorInput = NewAuthorName ""
      , createBookResponse = RemoteData.NotAsked
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
    | SuccessfullyCreated String


createAuthor : NewAuthor -> GraphqlTask AuthorData
createAuthor =
    NewAuthorRequiredArguments
        >> (\args -> Mutation.newAuthor args (SelectionSet.map2 AuthorData Author.id Author.name))
        >> Graphql.Http.mutationRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())
        >> Gql.handleMutationFailure "Author"


createBook : NewBook -> GraphqlTask String
createBook =
    NewBookRequiredArguments
        >> (\args -> Mutation.newBook args Book.title)
        >> Graphql.Http.mutationRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())
        >> Gql.handleMutationFailure "Book"


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
            in
            ( { model | createBookResponse = RemoteData.Loading }
            , authorTask
                |> Task.andThen (\authorData -> createBook { title = model.bookTitle, authorId = authorData.id })
                |> Task.attempt (RemoteData.fromResult >> GotCreationResponse)
            )

        GotCreationResponse res ->
            let
                cmd =
                    case res of
                        RemoteData.Success str ->
                            Task.succeed (SuccessfullyCreated str)
                                |> Task.perform identity

                        _ ->
                            Cmd.none
            in
            ( { model | createBookResponse = res }, cmd )

        SuccessfullyCreated _ ->
            ( model, Cmd.none )


bookTitleInput : Bool -> String -> Html Msg
bookTitleInput isSubmitting bookTitle =
    label [ for "book-title-input" ]
        [ text "Book title"
        , input
            [ type_ "text"
            , id "book-title-input"
            , placeholder ""
            , value bookTitle
            , onInput BookTitleChanged
            , disabled isSubmitting
            ]
            []
        ]


authorNameInput : Bool -> AuthorInput -> Html Msg
authorNameInput isSubmitting authorInput =
    case authorInput of
        NewAuthorName str ->
            label [ for "author-name-input" ]
                [ text "Author name"
                , input
                    [ type_ "text"
                    , id "author-name-input"
                    , placeholder ""
                    , value str
                    , onInput AuthorNameChanged
                    , disabled isSubmitting
                    ]
                    []
                ]

        ExistingAuthor authorData ->
            div [ class "existing-author" ]
                [ text <| "Author: " ++ authorData.name
                , button [ onClick DeselectAuthorClicked ] [ text "Deselect" ]
                ]


response : GraphqlResponse a -> Html msg
response data =
    case data of
        RemoteData.Success _ ->
            div [] [ p [ class "fade-in" ] [ text "Created successfully" ] ]

        RemoteData.Loading ->
            div [] [ p [ class "fade-in-slow" ] [ text "Submitting..." ] ]

        RemoteData.Failure e ->
            div [] [ p [ class "error fade-in" ] [ text (Gql.showError e) ] ]

        _ ->
            div [] []


view : Model -> Html Msg
view { authorInput, createBookResponse, bookTitle } =
    let
        isSubmitting =
            createBookResponse == RemoteData.Loading
    in
    div []
        [ bookTitleInput isSubmitting bookTitle
        , authorNameInput isSubmitting authorInput
        , div []
            [ button [ onClick CancelClicked ] [ text "Cancel" ]
            , button [ onClick SubmitClicked, disabled isSubmitting ] [ text "Submit a book" ]
            ]
        , response createBookResponse
        ]
