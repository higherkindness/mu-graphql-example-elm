-- Do not manually edit this file, it was auto-generated by dillonkearns/elm-graphql
-- https://github.com/dillonkearns/elm-graphql


module LibraryApi.Object.Author exposing (..)

import Graphql.Internal.Builder.Argument as Argument exposing (Argument)
import Graphql.Internal.Builder.Object as Object
import Graphql.Internal.Encode as Encode exposing (Value)
import Graphql.Operation exposing (RootMutation, RootQuery, RootSubscription)
import Graphql.OptionalArgument exposing (OptionalArgument(..))
import Graphql.SelectionSet exposing (SelectionSet)
import Json.Decode as Decode
import LibraryApi.InputObject
import LibraryApi.Interface
import LibraryApi.Object
import LibraryApi.Scalar
import LibraryApi.ScalarCodecs
import LibraryApi.Union


id : SelectionSet Int LibraryApi.Object.Author
id =
    Object.selectionForField "Int" "id" [] Decode.int


name : SelectionSet String LibraryApi.Object.Author
name =
    Object.selectionForField "String" "name" [] Decode.string


books :
    SelectionSet decodesTo LibraryApi.Object.Book
    -> SelectionSet (List decodesTo) LibraryApi.Object.Author
books object____ =
    Object.selectionForCompositeField "books" [] object____ (Basics.identity >> Decode.list)