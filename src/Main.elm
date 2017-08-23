module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import GitHub exposing (Issue, IssueList)
import Markdown
import Navigation exposing (Location)
import List.Extra as ListExtra


---- MODEL ----


type alias Model =
    { issueLists : List IssueList
    , selectedIssue : Maybe ( String, String )
    , errors : List String
    }


repos : List String
repos =
    [ "elm-lang/core"
    , "elm-lang/html"
    , "elm-lang/virtual-dom"
    , "elm-lang/svg"
    , "elm-lang/http"
    , "elm-lang/elm-make"
    , "elm-lang/elm-compiler"
    , "elm-lang/elm-repl"
    , "elm-lang/elm-package"
    , "elm-lang/elm-platform"
    ]


init : Location -> ( Model, Cmd Msg )
init location =
    ( Model [] Nothing []
    , repos
        |> List.map (GitHub.getIssues Receive)
        |> Cmd.batch
    )



---- UPDATE ----


type Msg
    = Receive (Result GitHub.Error IssueList)
    | Navigate (Maybe ( String, String ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Receive (Ok issueList) ->
            ( { model | issueLists = issueList :: model.issueLists }
            , Cmd.none
            )

        Receive (Err e) ->
            ( { model
                | errors = toString e :: model.errors
              }
            , Cmd.none
            )

        Navigate (Just ( package, issueTitle )) ->
            ( { model
                | selectedIssue = Just ( package, issueTitle )
              }
            , Cmd.none
            )

        Navigate Nothing ->
            ( model, Cmd.none )



---- VIEW ----


elmLogo : Html msg
elmLogo =
    img [ src "/logo.svg" ] []


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ sideMenu model.issueLists
        , viewSelectedIssue
            (model.selectedIssue
                |> Maybe.andThen
                    (\key ->
                        findIssue key model.issueLists
                    )
            )
        ]


findIssue : ( String, String ) -> List IssueList -> Maybe Issue
findIssue ( package, issueTitle ) issueLists =
    issueLists
        |> ListExtra.find (\issueList -> issueList.package == package)
        |> Maybe.andThen
            (\issueList ->
                issueList.issues
                    |> ListExtra.find (\issue -> issue.title == issueTitle)
            )


sideMenu : List IssueList -> Html msg
sideMenu issueLists =
    div [ class "side-menu" ] (List.map viewIssueList issueLists)


viewIssueList : IssueList -> Html msg
viewIssueList issueList =
    div []
        [ h2 [] [ text issueList.package ]
        , ul [] (List.map (viewIssueLink issueList.package) issueList.issues)
        ]


viewIssueLink : String -> Issue -> Html msg
viewIssueLink package issue =
    let
        url =
            "#" ++ package ++ "/" ++ issue.title
    in
        li [] [ a [ href url ] [ text issue.title ] ]


markdownOptions : Markdown.Options
markdownOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Just "elm"
    , sanitize = False
    , smartypants = False
    }


viewSelectedIssue : Maybe Issue -> Html msg
viewSelectedIssue selectedIssue =
    selectedIssue
        |> Maybe.map viewIssue
        |> Maybe.withDefault emptyIssue


emptyIssue : Html msg
emptyIssue =
    div [ class "issue-view" ] []


viewIssue : Issue -> Html msg
viewIssue issue =
    div [ class "issue-view" ]
        [ h1 [] [ text issue.title ]
        , Markdown.toHtmlWith markdownOptions [] issue.body
        ]


viewError : a -> Html msg
viewError _ =
    text "error"



---- PROGRAM ----


locationToMsg : Location -> Msg
locationToMsg location =
    let
        list =
            String.dropLeft 1 location.hash
                |> String.split "/"
    in
        case list of
            owner :: repo :: issueTitle :: _ ->
                Navigate (Just ( owner ++ "/" ++ repo, issueTitle ))

            _ ->
                Navigate Nothing


main : Program Never Model Msg
main =
    Navigation.program
        locationToMsg
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
