module Gql exposing (..)

import Graphql.Http
import RemoteData exposing (RemoteData(..))
import Task exposing (Task)


{-| elm-graphql allows also to get some "possibly recovered data",
but we don't care, that's why we have a Unit type as a parameter to Error
-}
type alias GraphqlResponse a =
    RemoteData (Graphql.Http.Error ()) a


type alias GraphqlTask t =
    Task (Graphql.Http.Error ()) t


{-| GraphQL endpoint url.
Ideally, in real apps it should be passed to the App as a flag
-}
graphqlUrl : String
graphqlUrl =
    "http://localhost:8000"


{-| Helper function for search queries.
Though not expressed in graphql schema,
the search string is actually expected to be a pattern for an SQL database
(this design choice is less obvious for API users, but more flexible).
"%" means "anything", so we search for specified string with anything before and after it.
-}
toPattern : String -> String
toPattern str =
    "%" ++ str ++ "%"
