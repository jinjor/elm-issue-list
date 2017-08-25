module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import GitHub exposing (Issue, IssueList)
import Markdown
import Navigation exposing (Location)
import List.Extra as ListExtra
import Regex
import UrlParser exposing (Parser, (</>))


---- MODEL ----


type alias Model =
    { issueLists : List IssueList
    , selectedIssue : Maybe ( String, Int )
    , errors : List String
    }


repos : List String
repos =
    [ "elm-lang/elm-compiler"
    , "elm-lang/elm-reactor"
    , "elm-lang/elm-make"
      -- , "elm-lang/elm-package"
      -- , "elm-lang/elm-repl"
      -- , "elm-lang/elm-platform"
    , "elm-lang/error-message-catalog"
      -- , "elm-lang/elm-lang.org"
      -- , "elm-lang/package.elm-lang.org"
      -- , "elm-lang/projects"
    , "elm-lang/core"
    , "elm-lang/virtual-dom"
    , "elm-lang/html"
      -- , "elm-lang/svg"
      -- , "elm-lang/http"
      -- , "elm-lang/browser"
      -- , "elm-lang/parser-primitives"
      -- , "elm-lang/url"
      -- , "elm-lang/docs"
      -- , "elm-lang/parser"
      -- , "elm-lang/geolocation"
      -- , "elm-lang/websocket"
      -- , "elm-lang/keyboard"
      -- , "elm-lang/dom"
      -- , "elm-lang/regexp"
      -- , "elm-lang/page-visibility"
      -- , "elm-lang/window"
      -- , "elm-lang/mouse"
    ]


init : Location -> ( Model, Cmd Msg )
init location =
    ( Model [] Nothing []
    , repos
        |> List.map (GitHub.getIssues Receive "meta")
        |> Cmd.batch
    )



---- UPDATE ----


type Msg
    = Receive (Result GitHub.Error IssueList)
    | Navigate (Maybe ( String, Int ))


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

        Navigate selectedIssue ->
            ( { model
                | selectedIssue = selectedIssue
              }
            , Cmd.none
            )



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


findIssue : ( String, Int ) -> List IssueList -> Maybe ( String, Issue )
findIssue ( package, issueNumber ) issueLists =
    issueLists
        |> ListExtra.find (\issueList -> issueList.package == package)
        |> Maybe.andThen
            (\issueList ->
                issueList.issues
                    |> ListExtra.find (\issue -> issue.number == issueNumber)
            )
        |> Maybe.map ((,) package)


sideMenu : List IssueList -> Html msg
sideMenu issueLists =
    div [ class "side-menu" ] (List.map viewIssueList issueLists)


viewIssueList : IssueList -> Html msg
viewIssueList issueList =
    div []
        [ h2 []
            [ a
                [ target "_blank"
                , href (GitHub.toRepoUrl issueList.package)
                ]
                [ text issueList.package ]
            ]
        , ul [] (List.map (viewIssueLink issueList.package) issueList.issues)
        ]


viewIssueLink : String -> Issue -> Html msg
viewIssueLink package issue =
    let
        url =
            "#" ++ package ++ "/" ++ toString issue.number
    in
        li [] [ a [ href url ] [ text issue.title ] ]


markdownOptions : Markdown.Options
markdownOptions =
    { githubFlavored = Just { tables = True, breaks = True }
    , defaultHighlighting = Just "elm"
    , sanitize = False
    , smartypants = False
    }


viewSelectedIssue : Maybe ( String, Issue ) -> Html msg
viewSelectedIssue selectedIssue =
    selectedIssue
        |> Maybe.map viewIssue
        |> Maybe.withDefault emptyIssue


emptyIssue : Html msg
emptyIssue =
    div [ class "issue-view" ] []


viewIssue : ( String, Issue ) -> Html msg
viewIssue ( package, issue ) =
    div [ class "issue-view show" ]
        [ div [ class "close-button" ] [ a [ href "#" ] [ text "Close" ] ]
        , h1 []
            [ a
                [ target "_blank"
                , href (GitHub.toIssueUrl package issue.number)
                ]
                [ text issue.title ]
            ]
        , Markdown.toHtmlWith markdownOptions [] (replaceLink package issue.body)
        ]


viewError : a -> Html msg
viewError _ =
    text "error"


replaceLink : String -> String -> String
replaceLink package s =
    Regex.regex "#[0-9]+"
        |> (\re ->
                Regex.replace Regex.All re (.match >> toIssueLink package) s
           )


toIssueLink : String -> String -> String
toIssueLink package num =
    String.dropLeft 1 num
        |> String.toInt
        |> Result.toMaybe
        |> Maybe.map (toIssueLinkAnchor package num)
        |> Maybe.withDefault num


toIssueLinkAnchor : String -> String -> Int -> String
toIssueLinkAnchor package num n =
    "<a href=" ++ GitHub.toIssueUrl package n ++ " target=_blank>" ++ num ++ "</a>"



---- PROGRAM ----


locationToMsg : Location -> Msg
locationToMsg location =
    UrlParser.parseHash parser location
        |> Navigate


parser : Parser (( String, Int ) -> a) a
parser =
    UrlParser.map
        (\owner repo issueNumber ->
            ( owner ++ "/" ++ repo, issueNumber )
        )
        (UrlParser.string </> UrlParser.string </> UrlParser.int)


main : Program Never Model Msg
main =
    Navigation.program
        locationToMsg
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
