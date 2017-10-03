module TestContract exposing (..)

import BigInt exposing (BigInt)
import Json.Decode as Decode exposing (Decoder, int, string)
import Json.Decode.Pipeline exposing (decode, required, optional)
import Json.Encode as Encode exposing (Value)
import Web3.Types exposing (..)
import Web3.Eth.Contract as Contract
import Web3.Decoders exposing (..)
import Task exposing (Task)


{-
   Core Contract info : ABI and Bytecode
-}


type alias Constructor =
    { constructorInt_ : BigInt, constructorString_ : String }


encodeContractABI : BigInt -> String -> Task Error Hex
encodeContractABI constructorInt_ constructorString_ =
    Contract.encodeContractABI
        { abi = abi_
        , gasPrice = Nothing
        , gas = Nothing
        , methodName = Nothing
        , data = Just bytecode_
        , params = [ Encode.string <| BigInt.toString constructorInt_, Encode.string constructorString_ ]
        , decoder = hexDecoder
        }


estimateContractGas : BigInt -> String -> Task Error Int
estimateContractGas constructorInt_ constructorString_ =
    Contract.estimateContractGas
        { abi = abi_
        , gasPrice = Nothing
        , gas = Nothing
        , methodName = Nothing
        , data = Just bytecode_
        , params = [ Encode.string <| BigInt.toString constructorInt_, Encode.string constructorString_ ]
        , decoder = int
        }


abi_ : Abi
abi_ =
    Abi """[{"constant":true,"inputs":[],"name":"otherNum","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsTwoUnnamed","outputs":[{"name":"","type":"uint256"},{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"kill","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsOneNamed","outputs":[{"name":"someNumber","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"uintArray","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"mutableInt","outputs":[{"name":"","type":"int256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"constructorString","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsTwoNamed","outputs":[{"name":"someUint","type":"uint256"},{"name":"someString","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"a","type":"uint256"},{"name":"b","type":"uint256"}],"name":"returnsOneUnnamed","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"inputs":[{"name":"constructorInt_","type":"int256"},{"name":"constructorString_","type":"string"}],"payable":true,"stateMutability":"payable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"mathematician","type":"address"},{"indexed":false,"name":"intLog","type":"int256"}],"name":"Add","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"professor","type":"address"},{"indexed":false,"name":"numberz","type":"uint256"},{"indexed":false,"name":"aPrime","type":"int256"}],"name":"Subtract","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"uintArrayLog","type":"uint256[23]"}],"name":"UintArray","type":"event"}]"""


bytecode_ : Hex
bytecode_ =
    Hex """0x60606040526102e060405190810160405280691a128493b237654ff3b36affffffffffffffffffffff168152602001607c6affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016a0a2f3bc9b0f19288d073b36affffffffffffffffffffff168152602001602b6affffffffffffffffffffff168152602001691a128493b237654ff3b36affffffffffffffffffffff16815260200162158d476affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016102916affffffffffffffffffffff168152602001602a6affffffffffffffffffffff16815260200160046affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016a65d82a82b536f8a7cff3b36affffffffffffffffffffff1681526020016102f46affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681526020016102916affffffffffffffffffffff168152602001691a128493b237654ff3b36affffffffffffffffffffff16815260200161071f6affffffffffffffffffffff16815260200161316d6affffffffffffffffffffff168152602001607b6affffffffffffffffffffff16815260200161050d6affffffffffffffffffffff1681526020016130446affffffffffffffffffffff168152602001607b6affffffffffffffffffffff1681525060049060176102239291906102b1565b506040516109d93803806109d9833981016040528080519060200190919080518201919050505b816000819055508060019080519060200190610267929190610300565b5033600360006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505b50506103a5565b82601781019282156102ef579160200282015b828111156102ee57825182906affffffffffffffffffffff169055916020019190600101906102c4565b5b5090506102fc9190610380565b5090565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f1061034157805160ff191683800117855561036f565b8280016001018555821561036f579182015b8281111561036e578251825591602001919060010190610353565b5b50905061037c9190610380565b5090565b6103a291905b8082111561039e576000816000905550600101610386565b5090565b90565b610625806103b46000396000f300606060405236156100a2576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff1680631c761abb146100a757806328985c17146100d057806341c0e1b51461017d57806386231246146101925780638da5cb5b146101d25780639ae918c714610227578063b4e70e6e1461025e578063bcdf89a414610287578063c43a6a7914610316578063ed1a9ca1146103c3575b600080fd5b34156100b257600080fd5b6100ba610403565b6040518082815260200191505060405180910390f35b34156100db57600080fd5b6100fa6004808035906020019091908035906020019091905050610409565b6040518083815260200180602001828103825283818151815260200191508051906020019080838360005b838110156101415780820151818401525b602081019050610125565b50505050905090810190601f16801561016e5780820380516001836020036101000a031916815260200191505b50935050505060405180910390f35b341561018857600080fd5b610190610458565b005b341561019d57600080fd5b6101bc6004808035906020019091908035906020019091905050610495565b6040518082815260200191505060405180910390f35b34156101dd57600080fd5b6101e56104a3565b604051808273ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200191505060405180910390f35b341561023257600080fd5b61024860048080359060200190919050506104c9565b6040518082815260200191505060405180910390f35b341561026957600080fd5b6102716104e4565b6040518082815260200191505060405180910390f35b341561029257600080fd5b61029a6104ea565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156102db5780820151818401525b6020810190506102bf565b50505050905090810190601f1680156103085780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b341561032157600080fd5b6103406004808035906020019091908035906020019091905050610588565b6040518083815260200180602001828103825283818151815260200191508051906020019080838360005b838110156103875780820151818401525b60208101905061036b565b50505050905090810190601f1680156103b45780820380516001836020036101000a031916815260200191505b50935050505060405180910390f35b34156103ce57600080fd5b6103ed60048080359060200190919080359060200190919050506105d7565b6040518082815260200191505060405180910390f35b60025481565b60006104136105e5565b8284016040805190810160405280600e81526020017f5468697320697320612074657374000000000000000000000000000000000000815250915091505b9250929050565b600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16ff5b565b600081830190505b92915050565b600360009054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b6004816017811015156104d857fe5b0160005b915090505481565b60005481565b60018054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156105805780601f1061055557610100808354040283529160200191610580565b820191906000526020600020905b81548152906001019060200180831161056357829003601f168201915b505050505081565b60006105926105e5565b8284016040805190810160405280600e81526020017f5468697320697320612074657374000000000000000000000000000000000000815250915091505b9250929050565b600081830190505b92915050565b6020604051908101604052806000815250905600a165627a7a723058200ede350c5699a44201280f5845af4f1176c7f9fdb6a760dc2015fbb0c23808820029"""


returnsTwoNamed : Int -> Int -> Contract.Params { someUint : BigInt, someString : String }
returnsTwoNamed a b =
    let
        decoder =
            decode (\someUint someString -> { someUint = someUint, someString = someString })
                |> required "someUint" bigIntDecoder
                |> required "someString" string
    in
        { abi = abi_
        , gasPrice = Nothing
        , gas = Nothing
        , methodName = Just "returnsTwoNamed(uint256,uint256)"
        , data = Nothing
        , params = [ Encode.int a, Encode.int b ]
        , decoder = decoder
        }
