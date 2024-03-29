let upstream = https://github.com/aviate-labs/package-set/releases/download/v0.1.7/package-set.dhall sha256:433429e918c292301ae0a7fa2341d463fea2d586c3f9d03209d68ca52e987aa8

let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions =
    [{ name = "testing"
    ,  version = "main"
    ,  repo = "https://github.com/internet-computer/testing"
    , dependencies = [] : List Text
    }] : List Package



in  upstream # additions
