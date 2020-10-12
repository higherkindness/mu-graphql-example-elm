module Main exposing (main)

import Browser
import Gql exposing (AuthorData, BookData)
import Graphql.Http
import Html exposing (Html, div, h1, input, p, span, text)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (onInput)
import RemoteData exposing (RemoteData(..))
import Task exposing (Task)


main : Program () Model Msg
main =
    Browser.element
        { init = always init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


init : ( Model, Cmd Msg )
init =
    ( { query = "", response = RemoteData.NotAsked }, Cmd.none )


type alias GraphqlResponse a =
    RemoteData (Graphql.Http.Error ()) a


type alias Response =
    GraphqlResponse ( List AuthorData, List BookData )


type alias Model =
    { query : String
    , response : Response
    }


type Msg
    = ChangeQuery String
    | GotResponse Response


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeQuery queryStr ->
            case String.trim queryStr of
                "" ->
                    ( { model | query = "", response = RemoteData.NotAsked }
                    , Cmd.none
                    )

                str ->
                    ( { model | query = str, response = RemoteData.Loading }
                    , Gql.findAuthorsAndBooks str
                        |> Task.attempt (RemoteData.fromResult >> GotResponse)
                    )

        GotResponse res ->
            ( { model | response = res }, Cmd.none )


{-| Show error message
elm-graphql allows also to get some "possibly recovered data",
but we don't care, that's why we have a Unit type as a parameter to Error
-}
showError : Graphql.Http.Error () -> String
showError err =
    case err of
        Graphql.Http.HttpError Graphql.Http.NetworkError ->
            "Network error"

        Graphql.Http.HttpError (Graphql.Http.BadUrl _) ->
            "BadUrl"

        Graphql.Http.HttpError Graphql.Http.Timeout ->
            "Timeout"

        Graphql.Http.HttpError (Graphql.Http.BadStatus _ _) ->
            "BadStatus"

        Graphql.Http.HttpError (Graphql.Http.BadPayload _) ->
            "BadStatus"

        Graphql.Http.GraphqlError _ graphqlErrors ->
            List.map (\e -> e.message) graphqlErrors |> String.concat


showRemoteData : (a -> Html Msg) -> GraphqlResponse a -> Html Msg
showRemoteData viewFn data =
    case data of
        RemoteData.NotAsked ->
            div [] []

        RemoteData.Loading ->
            div [] [ text "Loading..." ]

        RemoteData.Success x ->
            viewFn x

        RemoteData.Failure e ->
            div [ class "error" ] [ text (showError e) ]


viewAuthorsData : List AuthorData -> List (Html Msg)
viewAuthorsData =
    List.map
        (\{ name } ->
            div [ class "search-results-item" ]
                [ span [ class "meta" ] [ text "Author" ]
                , span [ class "author-name" ] [ text name ]
                ]
        )


viewBooksData : List BookData -> List (Html Msg)
viewBooksData =
    List.map
        (\{ title, author } ->
            div [ class "search-results-item" ]
                [ span [ class "meta" ] [ text "Book" ]
                , span [ class "book-title" ] [ text title ]
                , span [] [ text " by " ]
                , span [ class "author-name" ] [ text author.name ]
                ]
        )


viewAuthorsAndBooks : ( List AuthorData, List BookData ) -> Html Msg
viewAuthorsAndBooks ( authors, books ) =
    div [] (viewAuthorsData authors ++ viewBooksData books)


view : Model -> Html Msg
view model =
    div []
        [ input [ placeholder "author name", value model.query, onInput ChangeQuery ] []
        , div [] [ showRemoteData viewAuthorsAndBooks model.response ]
        ]
