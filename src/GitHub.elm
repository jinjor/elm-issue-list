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


toIssueUrl : String -> String
toIssueUrl package =
    "https://api.github.com/repos/" ++ package ++ "/issues?labels=meta"


getIssues : (Result Http.Error IssueList -> msg) -> String -> Cmd msg
getIssues toMsg package =
    Http.get (toIssueUrl package) (issueListDecoder package)
        |> Http.send toMsg
