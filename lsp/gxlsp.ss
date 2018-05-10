;;; -*- Gerbil -*-
;;; © Chream

(import :gerbil/gambit/threads
        :std/os/socket
        :std/getopt
        :std/sugar
        :std/format

        :std/srfi/1

        :std/actor

        :gerbil/gambit/ports

        :std/text/json

        :std/text/utf8
        :std/misc/ports

        :std/format

        :std/net/socket
        :std/net/socket/base
        :std/net/bio
        (only-in :gerbil/gambit display-exception)

        :chream/utils/all

        "common")
(export #t)

(def (main . args)
  (try
   (log 'info "start gxlsp main" args)
   (run-stdio-server (current-input-port))))

(def (run-stdio-server port)
  (log 'debug "####### starting stdio server. #######" port)
  (while #t
    (log 'debug "Listening for input.")
    (try
     (let ((header (read))
           (size (read))
           (msg (read-json port))
           (handle (spawn lsp-handler)))
       (if #t
         (!!lsp.handle-notification handle msg)
         (!!lsp.handle-request handle msg)))
     (catch (e)
       (log 'debug "error: " e)
       (display-exception e)))))

;; jsonrpc interface.

(def (make-message id into: (json (make-json)))
  (json-add! json id: id)
  json)

(def (msg-id msg)
  (hash-get msg 'id))
(def (msg-jsonrpc-version msg)
  "2.0")

(def (make-request-message id method
                           into: (json (make-json))
                           params: (params (make-json)))
  (make-message id into: json)
  (json-add! json params: params)
  (json-add! json method: method)
  json)

(def (req-params req)
  (json-get req 'params))
(def (req-method req)
  (json-get req 'params))

(def (make-response-message id result (error #f) into: (json (make-json)))
  (make-message id into: json)
  (when result (json-add! json result: result))
  (when error (json-add! json error: error))
  json)

(def (resp-result resp)
  (json-get resp 'result))
(def (resp-error resp)
  (json-get resp 'error))

(def (make-error datum msg (data #f) into: (json (make-json)))
  (def error-codes
    (let (table (make-hash-table))
      ;; Defined by JSON RPC
      (hash-add! table 'parse-error -32700)
      (hash-add! table 'InvalidRequest -32600)
      (hash-add! table 'MethodNotFound -32601)
      (hash-add! table 'InvalidParams -32602)
      (hash-add! table 'InternalError -32603)
      (hash-add! table 'serverErrorStart -32099)
      (hash-add! table 'serverErrorEnd -32000)
      (hash-add! table 'ServerNotInitialized -32002)
      (hash-add! table 'UnknownErrorCode -32001)
      ;; Defined by the protocol.
      (hash-add! table 'RequestCancelled -32800)
      table))

  (json-add! json code: (hash-get error-codes datum))
  (json-add! json msg: msg)
  (json-add! json data: data)
  json)

(def (resp-error-code err)
  (json-get err 'code))
(def (resp-error-msg msg)
  (json-get msg 'msg))

(def (msg-send msg (port (current-output-port)))
  (json-add! msg jsonrpc: (msg-jsonrpc-version msg))
  (display (json-object->string msg) port))

(def (msg-rescv (port current-output-port))
  (read-line port)
  (read-line port)
  (read-json port))

(def server-capabilities
  (let (json (make-json))
    (json-add! json capabilities: definitionProvider: #t)
    json))

(def (make-response req)
  (with ([_ id method params] (hash->list req))
    (log "Making response" (list id method params))
    (match method
      ("initialize"
       (log 'debug "handling initialize request." (list id params))
       (make-response-message id server-capabilities #f)))))

;; lsp protocol.

(defproto lsp
  call:
  (handle-request msg)
  event:
  (handle-notification msg))

(def (lsp-handler)
  (let ((initialized? #f)
        (shutdown? #f)
        (drop? #f))
    (let lp ()
      (try
       (<- ((!lsp.handle-request req k)
            (log 'debug "Got request. Handling." (list initialized? shutdown? req))
            (cond
             ((and (not initialized?) (not (string=? (req-method req) "initialize")))
              (let* ((err-obj (make-error 'ServerNotInitialized "Server not initialized." req))
                     (resp (make-response-message (msg-id req)
                                                  #f err-obj)))
                (log error "Server not initialized." resp)
                (!!value resp k)
                (set! drop? #t)))
             (else
              (let (r (make-response req))
                (!!value r k)
                (log 'debug "Sent message." r)
                (unless initialized? (set! initialized? #t)))))))
       (catch (e)
         (log error "Error in request handler." e)
         (display-exception e)
         (lp))))))

(def (make-response-header payload)
  (let ((size (u8vector-length (string->utf8 payload))))
    (string-append (format "Content-Length: ~d\r\n" size)
                   "\r\n"
                   payload)))

;; utils.

(def (make-init-req)
  (string->json-object "{\"method\":\"initialize\",\"id\":1,\"params\":{\"processId\":36616,\"capabilities\":{\"textDocument\":{\"synchronization\":{\"willSave\":true,\"didSave\":true},\"symbol\":{\"symbolKind\":{\"valueSet\":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]}}},\"workspace\":{\"executeCommand\":{\"dynamicRegistration\":true},\"applyEdit\":true}},\"rootUri\":\"file:///Users/izzy/repos/gerbil/gxlsp/lsp/\",\"initializationOptions\":null,\"rootPath\":\"/Users/izzy/repos/gerbil/gxlsp/lsp/\"},\"jsonrpc\":\"2.0\"}"))




;; (def (run-tcp-server (address "127.0.0.1:8093"))
;;   (logg "starting socket server")
;;   (def buf (make-u8vector 4096))
;;   (let ((sock (ssocket-listen address)))
;;     (let lp ()
;;       (try
;;        (logg sock)
;;        (let* ((cli (ssocket-accept sock))
;;               (_   (ssocket-recv cli buf))
;;               (input-buffer (open-input-buffer buf))
;;               (msg-size (bio-read-u32 input-buffer))
;;               (msg-payload (bio-read-subu8vector msg-size 4 (u8vector-length buf))))
;;          (displayln input-buffer)
;;          (lp))
;;        (catch (e)
;;          (display-exception e))
;;        (finally (ssocket-close sock))))))

;; (defstruct message (jsonrpc))
;; (defstruct (request-message message) (id method params))
;; (defstruct (response-message message) (id result error))
;; (defstruct (notification-message message) (method params))

;; (defstruct response-error (code message data))


;; (def (echo isock)
;;   (def buf (make-u8vector 4096))
;;   (try
;;    (let lp ()
;;      (let (rd (socket-recv isock buf))
;;        (cond
;;         ((not rd)
;;          (wait (fd-io-in isock))
;;          (lp))
;;         ((fxzero? rd)
;;          (close-input-port isock))
;;         (else
;;          (logg buf)
;;          (lp)))))
;;    (catch (e)
;;      (display-exception e)
;;      (close-input-port isock))))


;; ;; (def (start-epc-server address port)
;; ;;   (spawn (cut epc-server-manager address port)))

;; ;; (def (ecp-server-manager rpcd)
;; ;;   (let ((methods '())
;; ;;         (handlers '()))
;; ;;     (rpc-register rpcd 'epc-manager epc-manager::proto)
;; ;;     (let lp ()
;; ;;       (try
;; ;;        (<- ((!ecp-manager.register-function name function)
;; ;;             (set! methods (cons [name . function] methods))
;; ;;             (lp))
;; ;;            ((!ecp-manager.print-port out)
;; ;;             (displayln port)
;; ;;             (lp))
;; ;;            ((!ecp-manager.port k)
;; ;;             (!!value port k)
;; ;;             (lp)))
;; ;;        (catch (e) (begin (newline)
;; ;;                          (display "Actor ecp-server-manager: ")
;; ;;                          (display (current-thread))
;; ;;                          (newline)
;; ;;                          (display-exception e)))))))

;; ;; (defproto epc-server-handler
;; ;;   event:
;; ;;   (handle-client-connect))

;; ;; (defproto epc-client
;; ;;   event:
;; ;;   (handle-client-connect! rpc-server client)
;; ;;   (handle-client-disconnect! rpc-server client)
;; ;;   call:
;; ;;   (call name args)
;; ;;   (methods))
