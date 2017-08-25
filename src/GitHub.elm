module GitHub exposing (..)

import Http
import Json.Decode as Decode exposing (Decoder)


type alias IssueList =
    { package : String
    , issues : List Issue
    }


type alias Issue =
    { number : Int
    , title : String
    , body : String
    }


type alias Error =
    Http.Error


issueDecoder : Decoder Issue
issueDecoder =
    Decode.map3 Issue
        (Decode.field "number" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "body" Decode.string)


issueListDecoder : String -> Decoder IssueList
issueListDecoder package =
    Decode.list issueDecoder
        |> Decode.map (IssueList package)


getIssues : (Result Http.Error IssueList -> msg) -> String -> String -> Cmd msg
getIssues toMsg label package =
    Http.get (toIssueQuery package label) (issueListDecoder package)
        |> Http.send toMsg


toIssueQuery : String -> String -> String
toIssueQuery package label =
    "https://api.github.com/repos/" ++ package ++ "/issues?labels=" ++ label


toIssueUrl : String -> Int -> String
toIssueUrl package issueNumber =
    "https://github.com/" ++ package ++ "/issues/" ++ toString issueNumber


toRepoUrl : String -> String
toRepoUrl package =
    "https://github.com/" ++ package
