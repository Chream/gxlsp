(import (only-in :chream/utils/logger make-logger))

(export #t)

(def log-file "~/tmp/log/lsp.log")
(def test (make-logger name: 'default-test-logger level: 6 file: log-file))
(def trace (make-logger name: 'default-trace-logger level: 5 file: log-file))
(def debug (make-logger name: 'default-debug-logger level: 4 file: log-file))
(def info (make-logger name: 'default-info-logger level: 3 file: log-file))
(def warn (make-logger name: 'default-warn-logger level: 2 file: log-file))
(def error (make-logger name: 'default-error-logger level: 1 file: log-file))
