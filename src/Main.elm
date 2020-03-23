module Main exposing (main)

import Browser
import GraphQL.Client.Http as GraphQL
import GraphQL.Request.Builder exposing (..)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import Html exposing (Html, div, h1, input, p, text)
import Html.Attributes exposing (class, placeholder, value)
import Html.Events exposing (onInput)
import Task exposing (Task)


{-| Responses to `authorNameRequest` are decoded into this type.
-}
type alias Author =
    { name : String
    , books : List String
    }


{-| The definition of `authorNameRequest` builds up a query request value that
will later be encoded into the following GraphQL query document:

    query authorByName($name: String!) {
      author(name: $name) {
        name
        books {
          title
        }
      }
    }

-}
authorNameRequest : String -> Request Query Author
authorNameRequest nm =
    let
        name =
            Var.required "name" .name Var.string

        book =
            extract (field "title" [] string)

        author =
            object Author
                |> with (field "name" [] string)
                |> with (field "books" [] (list book))

        queryRoot =
            extract
                (field "author"
                    [ ( "name", Arg.variable name ) ]
                    author
                )
    in
    namedQueryDocument "authorByName" queryRoot |> request { name = nm }


type alias AuthorBooksResponse =
    Result GraphQL.Error Author


type alias Model =
    { query : String
    , response : Maybe AuthorBooksResponse
    }


type Msg
    = ChangeQuery String
    | ReceiveQueryResponse AuthorBooksResponse


sendQueryRequest : Request Query a -> Task GraphQL.Error a
sendQueryRequest request =
    GraphQL.sendQuery "http://localhost:8000" request


sendAuthorNameQuery : String -> Cmd Msg
sendAuthorNameQuery name =
    authorNameRequest name
        |> sendQueryRequest
        |> Task.attempt ReceiveQueryResponse


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
    ( Model "" Nothing, Cmd.none )


view : Model -> Html Msg
view { query, response } =
    div []
        [ input [ placeholder "author name", value query, onInput ChangeQuery ] []
        , case response of
            Nothing ->
                h1 [] [ text "GraphQL server didn't respond..." ]

            Just res ->
                case res of
                    Ok { name, books } ->
                        div []
                            (h1 [] [ text name ]
                                :: List.map (\book -> p [] [ text book ]) books
                            )

                    Err msg ->
                        div [ class "error" ] [ msg |> Debug.toString |> text ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update action { query, response } =
    case action of
        ChangeQuery name ->
            ( Model name response, sendAuthorNameQuery name )

        ReceiveQueryResponse res ->
            ( Model query (Just res), Cmd.none )
