{-# LANGUAGE QuasiQuotes #-}

import Debug.Dump
import Test.Hspec

main = hspec $ do
  describe "Debug.Dump" $ do
    it "should execute even if empty" $ do
      [d||] `shouldBe` ""