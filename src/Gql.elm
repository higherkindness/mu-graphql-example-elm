module Gql exposing (..)

import Dict
import Graphql.Http as Http
import Graphql.Http.GraphqlError
import RemoteData exposing (RemoteData(..))
import Task exposing (Task)


{-| elm-graphql allows also to get some "possibly recovered data",
but we don't care, that's why we have a Unit type as a parameter to Error.
-}
type alias GraphqlResponse a =
    RemoteData (Http.Error ()) a


type alias GraphqlTask t =
    Task (Http.Error ()) t


{-| GraphQL endpoint url.
Ideally, in real apps, it should be passed to the App as a flag
-}
graphqlUrl : String
graphqlUrl =
    "http://localhost:8000"


{-| Helper function for search queries.
Though not expressed in graphql schema,
the search string is actually expected to be a pattern for an SQL database
(this design choice is less obvious for API users, but more flexible).
"%" means "anything", so we search for a specified string with anything before and after it.
-}
toPattern : String -> String
toPattern str =
    "%" ++ str ++ "%"


{-| The `library` example from `mu-haskell` returns HTTP 200 with no data if mutation fails.
It does not reject an HTTP request and does not provide any error info.
It was a server implementation decision, so we should deal with it at the client-side.
If server implementation will change, this function will go away.
-}
handleMutationFailure : String -> GraphqlTask (Maybe a) -> GraphqlTask a
handleMutationFailure errMessage =
    let
        err =
            Http.GraphqlError (Graphql.Http.GraphqlError.ParsedData ())
                [ { message = errMessage
                  , locations = Nothing
                  , details = Dict.fromList []
                  }
                ]
    in
    -- Check if there was an error, related to omitted "null" fields
    -- If so, rewrap error to meaningful one
    Task.mapError
        (\initialError ->
            case initialError of
                Http.HttpError (Http.BadPayload _) ->
                    err

                _ ->
                    initialError
        )
        -- Then unwrap the Maybe value. The only reason for it to be Nothing is a failed mutation,
        -- So the error message should be the same
        >> Task.andThen (Maybe.map Task.succeed >> Maybe.withDefault (Task.fail err))


{-| Show error message from GraphqlResponse
-}
showError : Http.Error () -> String
showError err =
    case err of
        Http.HttpError Http.NetworkError ->
            "Network error"

        Http.HttpError (Http.BadUrl _) ->
            "BadUrl"

        Http.HttpError Http.Timeout ->
            "Timeout"

        Http.HttpError (Http.BadStatus _ _) ->
            "BadStatus"

        Http.HttpError (Http.BadPayload _) ->
            "BadStatus"

        Http.GraphqlError _ graphqlErrors ->
            List.map (\e -> e.message) graphqlErrors |> String.join ", "
