;;; -*- Gerbil -*-
;;; © Chream

(import :gerbil/gambit/threads
        :std/os/socket
        :std/getopt
        :std/sugar
        :std/format

        :gerbil/gambit/ports

        :std/text/utf8
        :std/misc/ports
        :std/net/socket
        :std/net/socket/base
        :std/net/bio
        (only-in :gerbil/gambit display-exception)

        :chream/utils/all

        "common")
(export #t)

(def (main . args)
  (try
   (log debug "start main" args)
   (run-stdio-server)
   ))

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

(def (run-stdio-server)
  (log debug "starting stdio server.")
  (while #t
    (try
     (log debug "Listening for input..")
     (let (header (read-line))
       (log debug "Got header!" (string->utf8 header))
       (read-line) ; skip
       (let* ((size (string->number (substring header 16 (- (string-length header) 2))))
              (buf (make-u8vector size)))
         (log debug "Got input-1" size)
         (read-subu8vector buf 0 size (current-input-port))
         (log debug "Got payload" buf)))
     (catch (e)
       (log debug "error: " e)
       (display-exception e)))))

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
