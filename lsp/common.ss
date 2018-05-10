(import (only-in :chream/utils/logger make-logger)
        :clan/utils/base
        :clan/utils/config
        :clan/utils/filesystem
        :clan/utils/path-config)

(export #t)

(set! application-source-envvar "LSP-GERBIL-SOURCE")
(set! application-home-envvar "LSP-GERBIL-HOME")
(set! application-log-envvar "LSP-GERBIL-HOME")
