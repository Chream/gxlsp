#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import
  :std/build-script :std/srfi/1)

(defbuild-script
  (cons [exe: "lsp/gxlsp"]
        ["gxlsp" "lsp/common"]))
