module Tests exposing (all)

import Expect
import Test exposing (Test, describe, test)


all : Test
all =
    describe "A Test Suite"
        [ test "Addition" <|
            \_ ->
                Expect.equal 10 (3 + 7)
        , test "String.left" <|
            \_ ->
                Expect.equal "a" (String.left 1 "abcdefg")
        , test "This test should fail" <|
            \_ ->
                Expect.fail "failed as expected!"
        ]
