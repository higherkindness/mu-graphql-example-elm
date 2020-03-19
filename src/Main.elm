module Main exposing (main)

import Browser
import GraphQL.Client.Http as GraphQL
import GraphQL.Request.Builder exposing (..)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import Html exposing (Html, div, h1, p, text)
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
authorNameRequest : Request Query Author
authorNameRequest =
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
    namedQueryDocument "authorByName" queryRoot |> request { name = "Michael Ende" }


type alias AuthorBooksResponse =
    Result GraphQL.Error Author


type alias Model =
    Maybe AuthorBooksResponse


type Msg
    = ReceiveQueryResponse AuthorBooksResponse


sendQueryRequest : Request Query a -> Task GraphQL.Error a
sendQueryRequest request =
    GraphQL.sendQuery "http://localhost:8000" request


sendAuthorNameQuery : Cmd Msg
sendAuthorNameQuery =
    sendQueryRequest authorNameRequest
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
    ( Nothing, sendAuthorNameQuery )


view : Model -> Html Msg
view model =
    case model of
        Nothing ->
            h1 [] [ text "GraphQL server didn't respond..." ]

        Just response ->
            case response of
                Ok { name, books } ->
                    div []
                        (h1 [] [ text name ]
                            :: List.map (\book -> p [] [ text book ]) books
                        )

                Err msg ->
                    div [] [ msg |> Debug.toString |> text ]


update : Msg -> Model -> ( Model, Cmd Msg )
update (ReceiveQueryResponse response) _ =
    ( Just response, Cmd.none )
