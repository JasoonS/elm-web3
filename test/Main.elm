module Main exposing (..)

import Html exposing (Html)
import Task exposing (Task)
import Element exposing (..)
import Element.Attributes exposing (..)
import Element.Events exposing (..)
import Config exposing (..)
import Pages.Home as Home exposing (Msg(..))
import Pages.Utils as Utils
import Pages.Accounts as Accounts
import Web3.Types exposing (..)
import Web3.Eth


-- import Web3
-- import Html.Events exposing (onClick)
-- import Dict exposing (Dict)
-- import BigInt exposing (BigInt)
-- import Web3.Utils
-- import Web3.Eth.Contract as Contract
-- import Web3.Eth.Accounts as Accounts
-- import Web3.Eth.Wallet as Wallet
-- import TestContract as TC
-- import Helpers exposing (Config, retryThrice)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { currentPage : Page
    , config : Config
    , homeModel : Home.Model
    , utilsModel : Utils.Model
    , accountsModel : Accounts.Model
    , error : Maybe Error
    }


init : ( Model, Cmd Msg )
init =
    { currentPage = Home
    , config = Config.mainnetConfig
    , homeModel = Home.init
    , utilsModel = Utils.init
    , accountsModel = Accounts.init
    , error = Nothing
    }
        ! [ Task.attempt EstablishNetworkId (retryThrice Web3.Eth.getId) ]


type Page
    = Home
    | Utils
    | Eth
    | Accounts
    | Wallet
    | Contract
    | Events


view : Model -> Html Msg
view model =
    Element.viewport stylesheet <|
        column None
            [ height fill ]
            [ row None
                [ height fill, width fill ]
                [ drawer
                , viewPage model
                ]
            ]


viewPage : Model -> Element Styles Variations Msg
viewPage model =
    case model.currentPage of
        Utils ->
            Utils.view model.utilsModel |> Element.map UtilsMsg

        Accounts ->
            Accounts.view model.accountsModel |> Element.map AccountsMsg

        _ ->
            text <| "No tests at " ++ toString model.currentPage ++ " yet"


drawer : Element Styles Variations Msg
drawer =
    let
        pages =
            [ Home, Utils, Eth, Accounts, Wallet, Contract, Events ]

        pageButton page =
            button None [ onClick <| SetPage page ] (text <| toString page)
    in
        column Drawer
            [ height fill, spacing 10, padding 10, width (px 180) ]
            (List.map pageButton pages)


type Msg
    = EstablishNetworkId (Result Error Int)
    | HomeMsg Home.Msg
    | UtilsMsg Utils.Msg
    | AccountsMsg Accounts.Msg
    | SetPage Page


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EstablishNetworkId result ->
            let
                ( newModel, newCmds ) =
                    update (SetPage Accounts) model
            in
                case result of
                    Ok networkId ->
                        { newModel | config = getConfig <| getNetwork networkId }
                            ! ([ newCmds, Cmd.map AccountsMsg Accounts.initCreateAccount ]
                                ++ (Utils.testCommands model.config |> List.map (Cmd.map UtilsMsg))
                              )

                    Err err ->
                        { newModel | error = Just err } ! []

        HomeMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Home.update subMsg model.homeModel
            in
                { model | homeModel = subModel } ! [ Cmd.map HomeMsg subCmd ]

        AccountsMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Accounts.update model.config subMsg model.accountsModel
            in
                { model | accountsModel = subModel } ! [ Cmd.map AccountsMsg subCmd ]

        UtilsMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Utils.update model.config subMsg model.utilsModel
            in
                { model | utilsModel = subModel } ! [ Cmd.map UtilsMsg subCmd ]

        SetPage page ->
            let
                cmds =
                    case page of
                        Home ->
                            []

                        Utils ->
                            []

                        Accounts ->
                            []

                        _ ->
                            []
            in
                { model | currentPage = page } ! cmds



-- UtilsMsg subMsg ->
--     toPage Utils UtilsMsg Utils.update subMsg model.utilsModel


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        []
