module Main exposing (main)

import Browser
import Html exposing (Html, a, button, div, h1, input, p, span, text)
import Html.Attributes exposing (class, href, placeholder, rel, target, type_, value)
import Html.Events exposing (onClick, onInput)
import Search


main : Program () Model Msg
main =
    Browser.element
        { init = always init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


type Model
    = SearchPage Search.Model
    | EditorPage


init : ( Model, Cmd Msg )
init =
    let
        ( model, cmd ) =
            Search.init
    in
    ( SearchPage model, Cmd.map SearchMsg cmd )


type Msg
    = SearchMsg Search.Msg
    | EditorMsg


{-| This update function delegates its work to each page's update functions.
However, in real apps routing should be implemented in a different way.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update wrappedMsg wrappedModel =
    case ( wrappedMsg, wrappedModel ) of
        ( SearchMsg Search.OpenEditorClicked, SearchPage model ) ->
            ( EditorPage, Cmd.none )

        ( SearchMsg msg, SearchPage model ) ->
            let
                ( newModel, cmd ) =
                    Search.update msg model
            in
            ( SearchPage newModel, Cmd.map SearchMsg cmd )

        -- ( EditorMsg msg, Editor model ) ->
        --     let
        --         ( newModel, cmd ) =
        --             Editor.update msg model
        --     in
        --     ( Search newModel, Cmd.map EditorMsg cmd )
        _ ->
            ( wrappedModel, Cmd.none )


showHeading : Html msg
showHeading =
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
view model =
    div [ class "app-container" ]
        [ showHeading
        , case model of
            SearchPage m ->
                Html.map SearchMsg (Search.view m)

            EditorPage ->
                div [] [ text "editor" ]
        ]
