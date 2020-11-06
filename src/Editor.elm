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


{-| This data type is similar to the one used in the Search page,
but there is no need in coupling both pages together by a common type.
Moreover, it's GraphQL's strong side - we can query exactly what we need, no less and no more
-}
type alias AuthorData =
    { id : Int
    , name : String
    }


type AuthorInput
    = NewAuthorName String (GraphqlResponse (List AuthorData))
    | ExistingAuthor AuthorData


type alias Model =
    { bookTitle : String
    , authorInput : AuthorInput
    , createBookResponse : GraphqlResponse String
    }


init : ( Model, Cmd Msg )
init =
    ( { bookTitle = ""
      , authorInput = NewAuthorName "" RemoteData.NotAsked
      , createBookResponse = RemoteData.NotAsked
      }
    , Cmd.none
    )



-- update and Tasks


type Msg
    = BookTitleChanged String
    | AuthorNameChanged String
    | GotAuthorsResponse (GraphqlResponse (List AuthorData))
    | SelectAuthorClicked AuthorData
    | DeselectAuthorClicked
    | CancelClicked
    | SubmitClicked
    | GotCreationResponse (GraphqlResponse String)


findAuthors : String -> GraphqlTask (List AuthorData)
findAuthors =
    Gql.toPattern
        >> AuthorsRequiredArguments
        >> (\args -> Query.authors args (SelectionSet.map2 AuthorData Author.id Author.name))
        >> Graphql.Http.queryRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())


createAuthor : NewAuthor -> GraphqlTask AuthorData
createAuthor =
    NewAuthorRequiredArguments
        >> (\args -> Mutation.newAuthor args (SelectionSet.map2 AuthorData Author.id Author.name))
        >> Graphql.Http.mutationRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())
        >> Gql.handleMutationFailure "Author already exists"


createBook : NewBook -> GraphqlTask String
createBook =
    NewBookRequiredArguments
        >> (\args -> Mutation.newBook args Book.title)
        >> Graphql.Http.mutationRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())
        >> Gql.handleMutationFailure "Book already exists"


{-| This is how we compose 2 Tasks to submit related data using different mutations,
using id of newly created Author (result of 1st mutation) to submit the Book (the 2nd mutataion)
-}
submitBook : AuthorInput -> String -> GraphqlTask String
submitBook authorInput bookTitle =
    let
        authorTask =
            case authorInput of
                ExistingAuthor authorData ->
                    Task.succeed authorData

                NewAuthorName authorName _ ->
                    createAuthor { name = String.trim authorName }
    in
    authorTask
        |> Task.andThen (\authorData -> createBook { title = bookTitle, authorId = authorData.id })


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BookTitleChanged newTitle ->
            ( { model | bookTitle = newTitle }, Cmd.none )

        AuthorNameChanged newName ->
            case model.authorInput of
                NewAuthorName _ _ ->
                    case String.trim newName of
                        "" ->
                            ( { model | authorInput = NewAuthorName "" RemoteData.NotAsked }, Cmd.none )

                        trimmedStr ->
                            ( { model | authorInput = NewAuthorName newName RemoteData.Loading }
                            , findAuthors trimmedStr
                                |> Task.attempt (RemoteData.fromResult >> GotAuthorsResponse)
                            )

                ExistingAuthor _ ->
                    ( model, Cmd.none )

        SelectAuthorClicked authorData ->
            ( { model | authorInput = ExistingAuthor authorData }, Cmd.none )

        DeselectAuthorClicked ->
            ( { model | authorInput = NewAuthorName "" RemoteData.NotAsked }, Cmd.none )

        SubmitClicked ->
            ( { model | createBookResponse = RemoteData.Loading }
            , submitBook model.authorInput (String.trim model.bookTitle)
                |> Task.attempt (RemoteData.fromResult >> GotCreationResponse)
            )

        GotCreationResponse res ->
            ( { model | createBookResponse = res }, Cmd.none )

        CancelClicked ->
            ( model, Cmd.none )

        GotAuthorsResponse res ->
            case model.authorInput of
                NewAuthorName authorName _ ->
                    ( { model | authorInput = NewAuthorName authorName res }, Cmd.none )

                _ ->
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


showAuthorsResponse : GraphqlResponse (List AuthorData) -> Html Msg
showAuthorsResponse data =
    case data of
        RemoteData.NotAsked ->
            div [] []

        RemoteData.Loading ->
            div [] [ p [ class "fade-in-slow" ] [ text ". . ." ] ]

        RemoteData.Failure e ->
            div [] [ p [ class "error fade-in" ] [ text (Gql.showError e) ] ]

        RemoteData.Success authors ->
            List.map
                (\author ->
                    div [ class "fade-in", onClick (SelectAuthorClicked author) ] [ text author.name ]
                )
                authors
                |> div [ class "search-results fade-in" ]


authorNameInput : Bool -> Model -> Html Msg
authorNameInput isSubmitting model =
    case model.authorInput of
        NewAuthorName str authorsResponse ->
            div []
                [ label [ for "author-name-input" ]
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
                , showAuthorsResponse authorsResponse
                ]

        ExistingAuthor authorData ->
            div [ class "existing-author" ]
                [ text <| "Author: " ++ authorData.name
                , button [ onClick DeselectAuthorClicked ] [ text "Deselect" ]
                ]


showCreateBookResponse : GraphqlResponse a -> Html msg
showCreateBookResponse data =
    case data of
        RemoteData.Loading ->
            div [] [ p [ class "fade-in-slow" ] [ text "Submitting..." ] ]

        RemoteData.Failure e ->
            div [] [ p [ class "error fade-in" ] [ text (Gql.showError e) ] ]

        _ ->
            div [] []


view : Model -> Html Msg
view ({ authorInput, createBookResponse, bookTitle } as model) =
    let
        isSubmitting =
            createBookResponse == RemoteData.Loading
    in
    div []
        [ bookTitleInput isSubmitting bookTitle
        , authorNameInput isSubmitting model
        , div []
            [ button [ onClick CancelClicked ] [ text "Cancel" ]
            , button [ onClick SubmitClicked, disabled isSubmitting ] [ text "Submit a book" ]
            ]
        , showCreateBookResponse createBookResponse
        ]
