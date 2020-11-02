module Components exposing (..)

import Gql exposing (GraphqlResponse, GraphqlTask)
import Graphql.Http
import Html exposing (Html, a, button, div, h1, input, p, span, text)
import Html.Attributes exposing (class, href, placeholder, rel, target, type_, value)
import RemoteData


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


showRemoteData : (a -> Html msg) -> GraphqlResponse a -> Html msg
showRemoteData viewFn data =
    case data of
        RemoteData.NotAsked ->
            div [] []

        RemoteData.Loading ->
            div [] [ p [ class "fade-in-slow" ] [ text ". . ." ] ]

        RemoteData.Success x ->
            viewFn x

        RemoteData.Failure e ->
            div [] [ p [ class "error fade-in" ] [ text (showError e) ] ]
