module Main exposing (main)

import Browser
import GraphQL.Client.Http as GraphQLClient
import GraphQL.Request.Builder exposing (..)
import GraphQL.Request.Builder.Arg as Arg
import GraphQL.Request.Builder.Variable as Var
import Html exposing (Html, div, text)
import Task exposing (Task)


type alias Author =
    { name : String
    , books : List Book
    }


type alias Book =
    { id : Int
    , title : String
    }


authorQuery : Document Query Author { name : String }
authorQuery =
    let
        authorName =
            Var.required "name" .name Var.string

        book =
            object Book
                |> with (field "id" [] int)
                |> with (field "title" [] string)

        author =
            object Author
                |> with (field "name" [] string)
                |> with (field "books" [] (list book))

        queryRoot =
            extract
                (field "author"
                    [ ( "name", Arg.variable authorName ) ]
                    author
                )
    in
    namedQueryDocument "authorByName" queryRoot


authorNameRequest : Request Query Author
authorNameRequest =
    authorQuery
        |> request
            { name = "nde" }


type alias AuthorResponse =
    Result GraphQLClient.Error Author


type alias Model =
    Maybe AuthorResponse


type Msg
    = ReceiveQueryResponse AuthorResponse


sendQueryRequest : Request Query a -> Task GraphQLClient.Error a
sendQueryRequest request =
    let
        options =
            { method = "POST"
            , headers = []
            , url = "http://localhost:8080" -- GraphQL URL endpoint
            , timeout = Nothing
            , withCredentials = False
            }
    in
    GraphQLClient.customSendQuery options request


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
    div []
        [ model |> Debug.toString |> text ]


update : Msg -> Model -> ( Model, Cmd Msg )
update (ReceiveQueryResponse response) _ =
    ( Just response, Cmd.none )
