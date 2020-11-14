module Main exposing (main)

import Browser
import Editor
import Html exposing (Html, a, button, div, h1, input, p, span, text)
import Html.Attributes exposing (class, href, placeholder, rel, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import RemoteData
import Search


main : Program () Model Msg
main =
    Browser.element
        { init = always init
        , view = view
        , update = update
        , subscriptions = Sub.map SearchMsg << Search.subscriptions
        }


type Model
    = SearchPage Search.Model
    | EditorPage Editor.Model


init : ( Model, Cmd Msg )
init =
    let
        ( model, cmd ) =
            Search.init
    in
    ( SearchPage model, Cmd.map SearchMsg cmd )



-- update


type Msg
    = SearchMsg Search.Msg
    | EditorMsg Editor.Msg


{-| This update function delegates its work to each page's update functions.
However, in real apps routing should be implemented differently.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update wrappedMsg wrappedModel =
    case ( wrappedMsg, wrappedModel ) of
        -- Redirect to Editor page without additional actions
        ( SearchMsg Search.OpenEditorClicked, SearchPage model ) ->
            Editor.init
                |> Tuple.mapBoth EditorPage (Cmd.map EditorMsg)

        ( SearchMsg msg, SearchPage model ) ->
            Search.update msg model
                |> Tuple.mapBoth SearchPage (Cmd.map SearchMsg)

        -- Redirect to Search page without additional actions
        ( EditorMsg Editor.CancelClicked, EditorPage model ) ->
            Search.init
                |> Tuple.mapBoth SearchPage (Cmd.map SearchMsg)

        -- Redirect to Search page and use the book title
        ( EditorMsg (Editor.GotCreationResponse (RemoteData.Success newBookTitle)), EditorPage model ) ->
            update
                (SearchMsg <| Search.QueryChanged newBookTitle)
                (SearchPage <| Tuple.first Search.init)

        ( EditorMsg msg, EditorPage model ) ->
            Editor.update msg model
                |> Tuple.mapBoth EditorPage (Cmd.map EditorMsg)

        _ ->
            ( wrappedModel, Cmd.none )



-- views


heading : Html msg
heading =
    div []
        [ h1 [] [ text "Library example" ]
        , p []
            [ text "Featuring "
            , a
                [ href "https://higherkindness.io/mu-haskell/"
                , target "_blank"
                ]
                [ text "Mu-Haskell" ]
            , text " and "
            , a
                [ href "https://package.elm-lang.org/packages/dillonkearns/elm-graphql/latest/"
                , target "_blank"
                ]
                [ text "elm-graphql" ]
            ]
        ]


view : Model -> Html Msg
view wrappedModel =
    div [ class "app-container" ]
        [ heading
        , case wrappedModel of
            SearchPage model ->
                Html.map SearchMsg (Search.view model)

            EditorPage model ->
                Html.map EditorMsg (Editor.view model)
        ]
