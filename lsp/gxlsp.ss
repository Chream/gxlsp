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

(def env (make-app-env name: "lsp-gerbil"
                       source: "LSP_GERBIL_SOURCE"
                       home: "LSP_GERBIL_HOME"
                       log: "LSP_GERBIL_LOG"))

(def logger (make-logger ""
                            top: (log-directory env)
                            name: "LSP-SERVER-MAIN"))

(def (main . args)
  (parameterize ((current-env-context env)
                 (current-logger logger))
    (try
     (begin
       (displayln "here")
       (log 'info "Start LSP Server" args)
       (displayln "here")
       (run-stdio-server))
     (catch (e)
       (display-exception e)))))

(def (run-stdio-server (in (current-input-port))
                       (out (current-output-port)))

  (def (read-size in)
    (let (size (and (read in) (read in)))
      size))

  (log 'debug "####### starting stdio server. #######" in)
  (while #t
    (log 'debug "Listening for input.")
    (let ((size (read-size in))
          (msg (read-req in)))
      (log 'debug "Got input:" size)
      (log 'debug "" msg))))

(def (make-init-req)
  "{\"method\":\"initialize\",\"id\":1,\"params\":{\"processId\":36616,\"capabilities\":{\"textDocument\":{\"synchronization\":{\"willSave\":true,\"didSave\":true},\"symbol\":{\"symbolKind\":{\"valueSet\":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25]}}},\"workspace\":{\"executeCommand\":{\"dynamicRegistration\":true},\"applyEdit\":true}},\"rootUri\":\"file:///Users/izzy/repos/gerbil/gxlsp/lsp/\",\"initializationOptions\":null,\"rootPath\":\"/Users/izzy/repos/gerbil/gxlsp/lsp/\"},\"jsonrpc\":\"2.0\"}")

;; ;; lsp protocol.

;; (def server-capabilities
;;   (let (json (make-json))
;;     (json-add! json capabilities: definitionProvider: #t)
;;     json))

;; (def (make-response req)
;;   (with ([_ id method params] (hash->list req))
;;     (log "Making response" (list id method params))
;;     (match method
;;       ("initialize"
;;        (log 'debug "handling initialize request." (list id params))
;;        (make-response-message id server-capabilities #f)))))

;; (def (make-response-header payload)
;;   (let ((size (u8vector-length (string->utf8 payload))))
;;     (string-append (format "Content-Length: ~d\r\n" size)
;;                    "\r\n"
;;                    payload)))

;; (defproto lsp
;;   call:
;;   (handle-request msg)
;;   event:
;;   (handle-notification msg))

;; (def (lsp-handler)
;;   (let ((initialized? #f)
;;         (shutdown? #f)
;;         (drop? #f))
;;     (let lp ()
;;       (try
;;        (<- ((!lsp.handle-request req k)
;;             (log 'debug "Got request. Handling." (list initialized? shutdown? req))
;;             (cond
;;              ((and (not initialized?) (not (string=? (req-method req) "initialize")))
;;               (let* ((err-obj (make-error 'ServerNotInitialized "Server not initialized." req))
;;                      (resp (make-response-message (msg-id req)
;;                                                   #f err-obj)))
;;                 (log error "Server not initialized." resp)
;;                 (!!value resp k)
;;                 (set! drop? #t)))
;;              (else
;;               (let (r (make-response req))
;;                 (!!value r k)
;;                 (log 'debug "Sent message." r)
;;                 (unless initialized? (set! initialized? #t)))))))
;;        (catch (e)
;;          (log error "Error in request handler." e)
;;          (display-exception e)
;;          (lp))))))

;; ;; utils.






;; ;; (def (run-tcp-server (address "127.0.0.1:8093"))
;; ;;   (logg "starting socket server")
;; ;;   (def buf (make-u8vector 4096))
;; ;;   (let ((sock (ssocket-listen address)))
;; ;;     (let lp ()
;; ;;       (try
;; ;;        (logg sock)
;; ;;        (let* ((cli (ssocket-accept sock))
;; ;;               (_   (ssocket-recv cli buf))
;; ;;               (input-buffer (open-input-buffer buf))
;; ;;               (msg-size (bio-read-u32 input-buffer))
;; ;;               (msg-payload (bio-read-subu8vector msg-size 4 (u8vector-length buf))))
;; ;;          (displayln input-buffer)
;; ;;          (lp))
;; ;;        (catch (e)
;; ;;          (display-exception e))
;; ;;        (finally (ssocket-close sock))))))



;; ;; (def (echo isock)
;; ;;   (def buf (make-u8vector 4096))
;; ;;   (try
;; ;;    (let lp ()
;; ;;      (let (rd (socket-recv isock buf))
;; ;;        (cond
;; ;;         ((not rd)
;; ;;          (wait (fd-io-in isock))
;; ;;          (lp))
;; ;;         ((fxzero? rd)
;; ;;          (close-input-port isock))
;; ;;         (else
;; ;;          (logg buf)
;; ;;          (lp)))))
;; ;;    (catch (e)
;; ;;      (display-exception e)
;; ;;      (close-input-port isock))))


;; ;; ;; (def (start-epc-server address port)
;; ;; ;;   (spawn (cut epc-server-manager address port)))

;; ;; ;; (def (ecp-server-manager rpcd)
;; ;; ;;   (let ((methods '())
;; ;; ;;         (handlers '()))
;; ;; ;;     (rpc-register rpcd 'epc-manager epc-manager::proto)
;; ;; ;;     (let lp ()
;; ;; ;;       (try
;; ;; ;;        (<- ((!ecp-manager.register-function name function)
;; ;; ;;             (set! methods (cons [name . function] methods))
;; ;; ;;             (lp))
;; ;; ;;            ((!ecp-manager.print-port out)
;; ;; ;;             (displayln port)
;; ;; ;;             (lp))
;; ;; ;;            ((!ecp-manager.port k)
;; ;; ;;             (!!value port k)
;; ;; ;;             (lp)))
;; ;; ;;        (catch (e) (begin (newline)
;; ;; ;;                          (display "Actor ecp-server-manager: ")
;; ;; ;;                          (display (current-thread))
;; ;; ;;                          (newline)
;; ;; ;;                          (display-exception e)))))))

;; ;; ;; (defproto epc-server-handler
;; ;; ;;   event:
;; ;; ;;   (handle-client-connect))

;; ;; ;; (defproto epc-client
;; ;; ;;   event:
;; ;; ;;   (handle-client-connect! rpc-server client)
;; ;; ;;   (handle-client-disconnect! rpc-server client)
;; ;; ;;   call:
;; ;; ;;   (call name args)
;; ;; ;;   (methods))
