port module Search exposing (Model, Msg(..), init, subscriptions, update, view)

import Gql exposing (GraphqlResponse, GraphqlTask)
import Graphql.Document
import Graphql.Http
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.SelectionSet as SelectionSet exposing (SelectionSet)
import Html exposing (Html, a, button, div, h1, img, input, p, span, text)
import Html.Attributes exposing (class, disabled, href, placeholder, rel, src, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import LibraryApi.Object exposing (Author, Book)
import LibraryApi.Object.Author as Author
import LibraryApi.Object.Book as Book
import LibraryApi.Query as Query exposing (AuthorsRequiredArguments, BooksRequiredArguments)
import LibraryApi.Subscription as Subscription
import RemoteData
import Task exposing (Task)


type alias AuthorData =
    { name : String
    }


type alias BookData =
    { title : String
    , imageUrl : String
    , authorName : String
    }


type alias SearchResults =
    { authors : List AuthorData
    , books : List BookData
    }


type alias Model =
    { query : String
    , searchResponse : GraphqlResponse SearchResults
    , isSubscribed : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { query = ""
      , searchResponse = RemoteData.NotAsked
      , isSubscribed = False
      }
    , Cmd.none
    )


type Msg
    = QueryChanged String
    | GotSearchResponse (GraphqlResponse SearchResults)
    | OpenEditorClicked
    | SubscribeToBooks
    | GotSubscriptionData String


{-| Allows to map different subscriptions to different Msg
-}
subscriptions : model -> Sub Msg
subscriptions _ =
    gotSubscriptionData GotSubscriptionData


port subscribeToAllBooks : String -> Cmd msg


{-| should be (Json.Decode.Value -> msg) -> Sub msg
to compose with gql
-}
port gotSubscriptionData : (String -> msg) -> Sub msg


{-| hope it works at least for outgoing
-}
subscriptionDocument : SelectionSet BookData RootSubscription
subscriptionDocument =
    Subscription.allBooks bookSelection


{-| That's the simplest example of how we convert the response to domain types.
-}
authorSelection : SelectionSet AuthorData Author
authorSelection =
    SelectionSet.map AuthorData Author.name


{-| This is a bit more complex example - we unnest response data to convert to our domain types
Also, we can define one SelectionSet in terms of other SelectionSets.
-}
bookSelection : SelectionSet BookData Book
bookSelection =
    SelectionSet.map3 BookData
        Book.title
        Book.imageUrl
        (Book.author Author.name)


{-| TODO: remove me
I am a dumb decoder substitution for bookSelection.
-}
tempBookDecoder : Decode.Decoder BookData
tempBookDecoder =
    Decode.map3 BookData
        (Decode.field "title" Decode.string)
        (Decode.field "imageUrl" Decode.string)
        (Decode.succeed "Temp Author Name")


findAuthors : String -> SelectionSet (List AuthorData) RootQuery
findAuthors =
    Gql.toPattern
        >> AuthorsRequiredArguments
        >> (\args -> Query.authors args authorSelection)


findBooks : String -> SelectionSet (List BookData) RootQuery
findBooks =
    Gql.toPattern
        >> BooksRequiredArguments
        >> (\args -> Query.books args bookSelection)


{-| That's how we can run 2 Queries in 1 HTTP request, combining their results to a SearchResults record.
This SelectionSet can still become a part of something greater.
-}
findAuthorsAndBooks : String -> SelectionSet SearchResults RootQuery
findAuthorsAndBooks queryStr =
    SelectionSet.map2 SearchResults
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
                    ( { model | query = "", searchResponse = RemoteData.NotAsked }, Cmd.none )

                trimmedStr ->
                    ( { model | query = queryStr, searchResponse = RemoteData.Loading }
                    , findAuthorsAndBooksTask trimmedStr
                        |> Task.attempt (RemoteData.fromResult >> GotSearchResponse)
                    )

        GotSearchResponse res ->
            ( { model | searchResponse = res }, Cmd.none )

        OpenEditorClicked ->
            ( model, Cmd.none )

        SubscribeToBooks ->
            ( { model | isSubscribed = True, searchResponse = RemoteData.Loading }
            , subscribeToAllBooks (Graphql.Document.serializeSubscription subscriptionDocument)
            )

        GotSubscriptionData websocketString ->
            let
                stringDecoder =
                    Decode.field "payload" <| Decode.field "data" <| tempBookDecoder

                -- TODO: Decode.field "payload" <| Decode.field "data" <| Graphql.Document.decoder bookSelection
            in
            case Decode.decodeString stringDecoder websocketString of
                Ok bookData ->
                    let
                        searchResponse =
                            case model.searchResponse of
                                RemoteData.Success success ->
                                    RemoteData.Success { success | books = bookData :: success.books }

                                _ ->
                                    RemoteData.Success { authors = [], books = [ bookData ] }
                    in
                    ( { model | query = bookData.title, searchResponse = searchResponse }
                    , Cmd.none
                    )

                Err error ->
                    ( model, Cmd.none )



-- views


showAuthor : AuthorData -> Html Msg
showAuthor { name } =
    div [ class "fade-in" ] [ text name ]


showBook : BookData -> Html Msg
showBook { title, authorName, imageUrl } =
    div [ class "book fade-in" ]
        [ div [ class "book__cover" ] [ img [ src imageUrl ] [] ]
        , div []
            [ p [ class "book__title" ] [ text title ]
            , p [ class "book__author" ] [ text <| "by " ++ authorName ]
            ]
        ]


showSearchResults : SearchResults -> Html Msg
showSearchResults { authors, books } =
    let
        items =
            List.map showAuthor authors ++ List.map showBook books
    in
    case items of
        [] ->
            div [ class "no-results fade-in" ] [ text "Nothing found" ]

        _ ->
            div [ class "search-results fade-in" ] items


showSearchResponse : GraphqlResponse SearchResults -> Html Msg
showSearchResponse data =
    case data of
        RemoteData.NotAsked ->
            div [] []

        RemoteData.Loading ->
            div [] [ p [ class "fade-in-slow" ] [ text ". . ." ] ]

        RemoteData.Failure e ->
            div [] [ p [ class "error fade-in" ] [ text (Gql.showError e) ] ]

        RemoteData.Success results ->
            showSearchResults results


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick OpenEditorClicked ] [ text "Add a book" ]
        , button [ onClick SubscribeToBooks, disabled model.isSubscribed ]
            [ text "Try subscriptions" ]
        , input
            [ type_ "text"
            , placeholder "For example, Kant"
            , value model.query
            , onInput QueryChanged
            ]
            []
        , showSearchResponse model.searchResponse
        ]
