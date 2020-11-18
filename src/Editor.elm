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
    = NewAuthorByName String (GraphqlResponse (List AuthorData))
    | ExistingAuthor AuthorData


type alias Model =
    { bookTitle : String
    , bookImage : String
    , authorInput : AuthorInput
    , createBookResponse : GraphqlResponse String
    }


init : ( Model, Cmd Msg )
init =
    ( { bookTitle = ""
      , bookImage = ""
      , authorInput = NewAuthorByName "" RemoteData.NotAsked
      , createBookResponse = RemoteData.NotAsked
      }
    , Cmd.none
    )



-- update and Tasks


type Msg
    = BookTitleChanged String
    | BookImageChanged String
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


createBook : NewBook -> GraphqlTask String
createBook =
    NewBookRequiredArguments
        >> (\args -> Mutation.newBook args Book.title)
        >> Graphql.Http.mutationRequest Gql.graphqlUrl
        >> Graphql.Http.toTask
        >> Task.mapError (Graphql.Http.mapError <| always ())


{-| This is how we compose 2 Tasks to submit related data using different mutations,
using id of newly created Author (result of 1st mutation) to submit the Book (the 2nd mutation).
-}
submitBook : AuthorInput -> String -> String -> GraphqlTask String
submitBook authorInput bookTitle bookCover =
    let
        authorTask =
            case authorInput of
                ExistingAuthor authorData ->
                    Task.succeed authorData

                NewAuthorByName authorName _ ->
                    createAuthor { name = String.trim authorName }
    in
    authorTask
        |> Task.andThen (\{ id } -> createBook { title = bookTitle, authorId = id, imageUrl = bookCover })


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BookTitleChanged newTitle ->
            ( { model
                | bookTitle = newTitle
                , createBookResponse = RemoteData.NotAsked
              }
            , Cmd.none
            )

        BookImageChanged newCover ->
            ( { model | bookImage = newCover }, Cmd.none )

        AuthorNameChanged newName ->
            case model.authorInput of
                NewAuthorByName _ _ ->
                    case String.trim newName of
                        "" ->
                            ( { model
                                | authorInput = NewAuthorByName "" RemoteData.NotAsked
                                , createBookResponse = RemoteData.NotAsked
                              }
                            , Cmd.none
                            )

                        trimmedStr ->
                            ( { model
                                | authorInput = NewAuthorByName newName RemoteData.Loading
                                , createBookResponse = RemoteData.NotAsked
                              }
                            , findAuthors trimmedStr
                                |> Task.attempt (RemoteData.fromResult >> GotAuthorsResponse)
                            )

                ExistingAuthor _ ->
                    ( model, Cmd.none )

        SelectAuthorClicked authorData ->
            ( { model | authorInput = ExistingAuthor authorData }, Cmd.none )

        DeselectAuthorClicked ->
            ( { model
                | authorInput = NewAuthorByName "" RemoteData.NotAsked
                , createBookResponse = RemoteData.NotAsked
              }
            , Cmd.none
            )

        SubmitClicked ->
            ( { model | createBookResponse = RemoteData.Loading }
            , submitBook model.authorInput (String.trim model.bookTitle) (String.trim model.bookImage)
                |> Task.attempt (RemoteData.fromResult >> GotCreationResponse)
            )

        GotCreationResponse res ->
            ( { model | createBookResponse = res }, Cmd.none )

        CancelClicked ->
            ( model, Cmd.none )

        GotAuthorsResponse res ->
            case model.authorInput of
                NewAuthorByName authorName _ ->
                    ( { model | authorInput = NewAuthorByName authorName res }, Cmd.none )

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


bookImageInput : Bool -> String -> Html Msg
bookImageInput isSubmitting bookImage =
    label [ for "book-image-input" ]
        [ text "Book cover"
        , input
            [ type_ "text"
            , id "book-image-input"
            , placeholder ""
            , value bookImage
            , onInput BookImageChanged
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
        NewAuthorByName str authorsResponse ->
            div [ class "author-input__container" ]
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
            div [ class "author-input__container" ]
                [ text "Author"
                , div [ class "existing-author" ]
                    [ text authorData.name
                    , button [ onClick DeselectAuthorClicked ] [ text "Deselect" ]
                    ]
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
view ({ authorInput, createBookResponse, bookTitle, bookImage } as model) =
    let
        isSubmitting =
            createBookResponse == RemoteData.Loading

        isValidBookInput =
            case authorInput of
                NewAuthorByName authorName _ ->
                    String.trim authorName /= "" && String.trim bookTitle /= ""

                ExistingAuthor _ ->
                    String.trim bookTitle /= ""

        buttonText =
            case model.authorInput of
                NewAuthorByName _ _ ->
                    "Submit book and author"

                ExistingAuthor _ ->
                    "Submit a book"
    in
    div []
        [ bookTitleInput isSubmitting bookTitle
        , bookImageInput isSubmitting bookImage
        , authorNameInput isSubmitting model
        , div [ class "editor__buttons" ]
            [ button [ onClick CancelClicked ] [ text "Cancel" ]
            , button [ onClick SubmitClicked, disabled (isSubmitting || not isValidBookInput) ] [ text buttonText ]
            ]
        , showCreateBookResponse createBookResponse
        ]
