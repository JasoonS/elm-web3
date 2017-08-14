module Web3
    exposing
        ( Retry
        , reset
        , toTask
        , setOrGet
        , getEvent
        , retry
        , toWei
        )

{-| Version allows one to check the various library, protocol, & network versions one is interacting with. [Web3
documentation on Version](https://github.com/ethereum/wiki/wiki/JavaScript-API#web3versionapi).


# Web3

@docs isConnected


# Core

@docs Error

-}

import BigInt exposing (BigInt(..), mul, fromInt, fromString, divmod)
import Time
import Process
import Task exposing (Task)
import Json.Encode as Encode
import Native.Web3
import Web3.Types exposing (..)
import Web3.Decoders exposing (..)
import Web3.Internal exposing (Request, EventRequest, GetDataRequest)


-- WEB3


{-| Check to see if a connection to a node exists

    Web3.isConnected  == Ok True

-}
isConnected : Task Error Bool
isConnected =
    toTask
        { func = "isConnected"
        , args = Encode.list []
        , expect = expectBool
        , callType = Async
        }



-- TODO Make this it's own native function. Perhaps have it clear out the eventRegister obect as well,
--      unless that will conflict with Contract.stopWatching task.


reset : Bool -> Task Error ()
reset keepIsSyncing =
    Native.Web3.reset (Encode.bool keepIsSyncing)


sha3 : String -> Task Error Keccak256
sha3 val =
    toTask
        { func = "sha3"
        , args = Encode.list [ Encode.string val ]
        , expect = expectJson keccakDecoder
        , callType = Sync
        }


type Sha3Encoding
    = HexEncoded


sha3Encoded : Sha3Encoding -> String -> Task Error Keccak256
sha3Encoded encodeType val =
    let
        encoding =
            case encodeType of
                HexEncoded ->
                    Encode.string "hex"
    in
        toTask
            { func = "sha3"
            , args = Encode.list [ Encode.string val, Encode.object [ ( "encoding", encoding ) ] ]
            , expect = expectJson keccakDecoder
            , callType = Sync
            }


toHex : String -> Task Error Hex
toHex val =
    toTask
        { func = "toHex"
        , args = Encode.list [ Encode.string val ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


toAscii : Hex -> Task Error String
toAscii (Hex val) =
    toTask
        { func = "toAscii"
        , args = Encode.list [ Encode.string val ]
        , expect = expectString
        , callType = Sync
        }


fromAscii : String -> Task Error Hex
fromAscii val =
    fromAsciiPadded 0 val


fromAsciiPadded : Int -> String -> Task Error Hex
fromAsciiPadded padding val =
    toTask
        { func = "fromAscii"
        , args = Encode.list [ Encode.string val, Encode.int padding ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


toDecimal : Hex -> Task Error Int
toDecimal (Hex hex) =
    toTask
        { func = "toDecimal"
        , args = Encode.list [ Encode.string hex ]
        , expect = expectInt
        , callType = Sync
        }


fromDecimal : Int -> Task Error Hex
fromDecimal decimal =
    toTask
        { func = "fromDecimal"
        , args = Encode.list [ Encode.int decimal ]
        , expect = expectJson hexDecoder
        , callType = Sync
        }


isAddress : Address -> Task Error Bool
isAddress (Address address) =
    toTask
        { func = "isAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


isChecksumAddress : ChecksumAddress -> Task Error Bool
isChecksumAddress (ChecksumAddress address) =
    toTask
        { func = "isChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectBool
        , callType = Sync
        }


toChecksumAddress : Address -> Task Error ChecksumAddress
toChecksumAddress (Address address) =
    toTask
        { func = "toChecksumAddress"
        , args = Encode.list [ Encode.string address ]
        , expect = expectJson checksumAddressDecoder
        , callType = Sync
        }



-- fromWei : EthUnit -> BigInt -> BigInt
-- toWei : EthUnit -> BigInt -> BigInt
-- CORE


toWei : EthDenomination -> BigInt -> BigInt
toWei unit amount =
    mul amount (getValueOfUnit unit)


getValueOfUnit : EthDenomination -> BigInt
getValueOfUnit unit =
    case unit of
        Wei ->
            (fromInt 1)

        Kwei ->
            (fromInt 1000)

        Ada ->
            (fromInt 1000)

        Femtoether ->
            (fromInt 1000)

        Mwei ->
            (fromInt 1000000)

        Babbage ->
            (fromInt 1000000)

        Picoether ->
            (fromInt 1000000)

        Gwei ->
            (fromInt 1000000000)

        Shannon ->
            (fromInt 1000000000)

        Nanoether ->
            (fromInt 1000000000)

        Nano ->
            (fromInt 1000000000)

        Szabo ->
            (fromInt 1000000000000)

        Microether ->
            (fromInt 1000000000000)

        Micro ->
            (fromInt 1000000000000)

        Finney ->
            (fromInt 1000000000000000)

        Milliether ->
            (fromInt 1000000000000000)

        Milli ->
            (fromInt 1000000000000000)

        Ether ->
            (fromInt 1000000000000000000)

        Kether ->
            mul (fromInt 1000000000000000000) (fromInt 1000)

        Grand ->
            mul (fromInt 1000000000000000000) (fromInt 1000)

        Einstein ->
            mul (fromInt 1000000000000000000) (fromInt 1000)

        Mether ->
            mul (fromInt 1000000000000000000) (fromInt 1000000)

        Gether ->
            mul (fromInt 1000000000000000000) (fromInt 1000000000)

        Tether ->
            mul (fromInt 1000000000000000000) (fromInt 1000000000000)


toTask : Request a -> Task Error a
toTask =
    Native.Web3.toTask


setOrGet : Request a -> Task Error a
setOrGet request =
    Native.Web3.setOrGet request


getEvent : Request a -> Task Error a
getEvent =
    Native.Web3.getEvent



-- POLLING
{-
   Mad props to Nick Miller for this retry function
              The MIRTCH Function
   "Matrix Inception Recursive Task Chaining" Function
-}


type alias Retry =
    { attempts : Int
    , sleep : Float
    }


retry : Retry -> Task Error a -> Task Error a
retry { attempts, sleep } web3Task =
    let
        remaining =
            attempts - 1
    in
        web3Task
            |> Task.onError
                (\x ->
                    if remaining > 0 then
                        Process.sleep (sleep * Time.second)
                            |> Task.andThen (\_ -> retry (Retry remaining sleep) web3Task)
                    else
                        Task.fail x
                )
