;;; distel.el --- Top-level of distel package, loads all subparts

;; Prerequisites
(require 'erlang)
(require 'easy-mmode)

(provide 'wrangler)

;; Compatibility with XEmacs
(unless (fboundp 'define-minor-mode)
  (defalias 'define-minor-mode 'easy-mmode-define-minor-mode))


(defgroup wrangler '()
  "Wrangler options."
  :group 'tools)

(defcustom wrangler-search-paths (cons (expand-file-name ".") nil )
	"*List f directories to search for .erl and .hrl files to refactor."
	:type '(repeat directory)
	:group 'wrangler)

(defun wrangler-customize ()
 	  "Customization of group `wrangler' for the Erlang refactorer."
	  (interactive)
 	  (customize-group "wrangler"))

(require 'erl)
(require 'erl-service)

(defvar refactor-menu-items
  '(nil
    ("Rename Variable Name" erl-refactor-rename-var)
     ("Rename Function Name" erl-refactor-rename-fun)
     ("Rename Module Name" erl-refactor-rename-mod)
     ("Generalise Function Definition" erl-refactor-generalisation)
     ("Move Function to Another Module" erl-refactor-move-fun)
     ("Function Extraction" erl-refactor-fun-extraction)
     ("Fold Expression Against Function" erl-refactor-fold-expression)
     nil
     ;;  ("From Tuple To Record (beta)" erl-refactor-tuple-to-record)
     ("Tuple Function Arguments" erl-refactor-tuple-funpar)
     nil
     ("Rename a Process (beta)" erl-refactor-rename-process)
     ("Add a Tag to Messages (beta)"  erl-refactor-add-a-tag)
     ("Register a Process (beta)"   erl-refactor-register-pid)
     ("From Function to Process" erl-refactor-fun-to-process)
     nil 
     ("Detect Duplicated Code in Current Buffer"  erl-refactor-duplicated-code-in-buffer)
     ("Detect Duplicated Code in Dirs" erl-refactor-duplicated-code-in-dirs)
     ("Expression Search" erl-refactor-expression-search)
     nil
     ("Introduce a Macro" erl-refactor-new-macro)
     ("Fold Against Macro Definition" erl-refactor-fold-against-macro)
     nil
     ("Undo" erl-refactor-undo)
     nil
     ("Customize Wrangler" wrangler-customize)
     nil
     ("Version" erl-refactor-version)))


(defvar inspector-menu-items
  '(nil
    ("Variable Search" erl-wrangler-code-inspector-var-instances) 
      ("Caller Functions" erl-wrangler-code-inspector-caller-funs)
      ("Caller/Called Modules" erl-wrangler-code-inspector-caller-called-mods)
      ("Nested If Expresssions" erl-wrangler-code-inspector-nested-ifs)
      ("Nested Case Expressions" erl-wrangler-code-inspector-nested-cases)
      ("Nested Receive Expression" erl-wrangler-code-inspector-nested-receives)
      ("Long Functions" erl-wrangler-code-inspector-long-funs)
      ("Large Modules" erl-wrangler-code-inspector-large-mods)
     ;; ("UnCalled Exported Functions" erl-wrangler-code-inspector-uncalled-exports)
      ("Non Tail-recursive Servers" erl-wrangler-code-inspector-non-tail-recursive-servers)
      ("Not Flush UnKnown Messages" erl-wrangler-code-inspector-no-flush)))
 
   
(global-set-key (kbd "C-c C-r") 'toggle-erlang-refactor)

(setq erlang-refactor-status 0)


(setq wrangler-erl-node (intern  "wrangler@localhost"))

(defun toggle-erlang-refactor ()
  (interactive)
  (cond ((= erlang-refactor-status 0)
	 (call-interactively 'erlang-refactor-on)
	 (setq erlang-refactor-status 1))
	((= erlang-refactor-status 1)
	 (call-interactively 'erlang-refactor-off)
	 (setq erlang-refactor-status 0))))


(defun start-wrangler-app()
  (interactive)
  (erl-spawn
    (erl-send-rpc wrangler-erl-node 'application 'start (list 'wrangler_app))
    (erl-receive()
	((['rex 'ok]
	  (wrangler-menu-init)
	  (message "Wrangler started.")
	  (setq erlang-refactor-status 1))
	 (['rex ['error ['already_started app]]]
	  (wrangler-menu-init)
	  (message "Wrangler started")
	  (setq erlang-refactor-status 1))
	 (['rex ['error rsn]]
	  (message "Wrangler failed to start:%s" rsn)
	  (setq erlang-refactor-status 0))))))

(defun erlang-refactor-on()
  (interactive)
  (setq inferior-erlang-machine-options (list "-name" "wrangler@localhost"
					       "-pz"  "C:/cygwin/home/hl/wrangler/share/wrangler/ebin"
					       "-setcookie" (erl-cookie)))
  (save-window-excursion
    (let  ((inferior-erlang-process-name "Wrangler-Erl-Shell")
	   (inferior-erlang-buffer-name "*Wrangler-Erl-Shell*"))
      (erlang-shell)))
  (sleep-for 2.0)
  (start-wrangler-app))


(defun erlang-refactor-off()
  (interactive)
  (erl-spawn
    (erl-send-rpc wrangler-erl-node 'application 'stop (list 'wrangler_app))
    (erl-receive()
	((['rex response]
	  (wrangler-menu-remove)
          (if (get-buffer "*Wrangler-Erl-Shell*")
             (kill-buffer "*Wrangler-Erl-Shell*"))
	  (setq erlang-refactor-status 0)))))
   (message "Wrangler stopped."))      

(defun erl-refactor-version()
  (interactive)
  (message "Wrangler version 0.6.2"))

(defun wrangler-menu-init()
  "Init Wrangler menus."
  (define-key erlang-mode-map "\C-c\C-_"  'erl-refactor-undo)
  (define-key erlang-mode-map  "\C-c\C-b" 'erl-wrangler-code-inspector-var-instances)
  (erlang-menu-install "Inspector" inspector-menu-items erlang-mode-map t)
  (erlang-menu-install "Refactor" refactor-menu-items erlang-mode-map t))

(defun wrangler-menu-remove()
  "Remove Wrangler menus."
  (define-key erlang-mode-map "\C-c\C-_"  nil)
  (define-key erlang-mode-map  "\C-c\C-b" nil)
  (erlang-menu-uninstall "Inspector" inspector-menu-items erlang-mode-map t)
  (erlang-menu-uninstall "Refactor" refactor-menu-items erlang-mode-map t))

(defun erlang-menu-uninstall (name items keymap &optional popup)
  "UnInstall a menu in Emacs or XEmacs based on an abstract description."
    (cond (erlang-xemacs-p
	 (let ((menu (erlang-menu-xemacs name items keymap)))
	   (funcall (symbol-function 'delete-menu-item) menu)))
	  ((>= erlang-emacs-major-version 19)
	 (define-key keymap (vector 'menu-bar (intern name))
	   'undefined))
	(t nil)))

(defun erl-refactor-undo()
  "Undo the latest refactoring."
  (interactive)
  (let (buffer (current-buffer))
       (let (changed)
	 (dolist (b (buffer-list) changed)
	   (let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	     (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
		 (setq changed (cons (buffer-name b) changed)))))
	 (if changed (message-box (format "there are modified buffers: %s" changed))
	   (if (yes-or-no-p "Undo a refactoring will also undo the editings done after the refactoring, undo anyway?")
	   (erl-spawn
	     (erl-send-rpc wrangler-erl-node 'wrangler_undo_server 'undo (list))
	     (erl-receive (buffer)
		 ((['rex ['badrpc rsn]]
		   (message "Undo failed: %S" rsn))
		  (['rex ['error rsn]]
		   (message "Undo failed: %s" rsn))
		  (['rex ['ok modified1]]
		   (dolist (f modified1)
		     (let ((oldfilename (car f))
		       (newfilename (car (cdr f)))
		       (buffer (get-file-buffer (car (cdr f)))))
		       (if buffer (if (not (equal oldfilename newfilename))
				      (with-current-buffer buffer
					(progn (set-visited-file-name oldfilename)
					       (revert-buffer nil t t)))
				    ;;   (delete-file newfilename)))
				    (with-current-buffer buffer (revert-buffer nil t t)))
			 nil)))
		   (message "Undo succeeded!"))))))))))


(defun erl-refactor-rename-var (name)
  "Rename an identified variable name."
  (interactive (list (read-string "New name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (let* ((n (buffer-name buffer)) (n1 (substring n 0 1)))
      (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p buffer))
	  (message-box "The current buffer has been changed")
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_var (list current-file-name line-no column-no name wrangler-search-paths tab-width))
	  (erl-receive (buffer line-no column-no)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['ok refac-rename]]
		(with-current-buffer buffer (progn (revert-buffer nil t t)
						   (goto-char (get-position line-no column-no))))
		(message "Refactoring succeeded!")))))))))

(defun erl-refactor-rename-fun (name)
  "Rename an identified function name."
  (interactive (list (read-string "New name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_fun (list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (buffer line-no column-no)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	     (dolist (f modified)
 	      (let ((buff (get-file-buffer f)))
 		(if buff
 		    (with-current-buffer buff (revert-buffer nil t t))
 		  ;;(message-box (format "modified unopened file: %s" f))))))
 		  nil)))
	     (with-current-buffer buffer
	       (goto-char (get-position line-no column-no)))
	     (message "Refactoring succeeded!")
	    ))))))))



(defun erl-refactor-rename-mod (name)
  "Rename the current module name."
  (interactive (list (read-string "New module name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_mod (list current-file-name name wrangler-search-paths tab-width))
      (erl-receive (buffer name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (with-current-buffer buffer
	      (dolist (f modified)
		(let ((buffer (get-file-buffer f)))
		  (if buffer 
		      (if (equal f buffer-file-name)				 
				 (with-current-buffer buffer ;;(delete-file buffer-file-name)
						      (set-visited-file-name (concat
							(file-name-directory (buffer-file-name)) name ".erl") t t)
						      (revert-buffer nil t t))
			         (with-current-buffer buffer (revert-buffer nil t t)))
		       nil)))))
            (message "Refactoring succeeded!"))))))))

(defun erl-refactor-rename-process(name)
  "Rename a registered process."
  (interactive (list (read-string "New name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_process (list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (buffer name current-file-name line-no column-no)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['undecidables oldname]]
	   (if (yes-or-no-p "Do you want to continue the refactoring?")
	       (erl-spawn
		 (erl-send-rpc wrangler-erl-node 'refac_rename_process 'rename_process_1
			       (list current-file-name oldname name wrangler-search-paths tab-width))
		 (erl-receive (buffer)
		     ((['rex ['badrpc rsn]]
		       (message "Refactoring failed: %S" rsn))
		      (['rex ['error rsn]]
		       (message "Refactoring failed: %s" rsn))
		      (['rex ['ok modified]]
		       (dolist (f modified)
			 (let ((buff (get-file-buffer f)))
			   (if buff
			       (with-current-buffer buff (revert-buffer nil t t))
			     ;;(message-box (format "modified unopened file: %s" f))))))
			     nil)))
		       (with-current-buffer buffer
			 (goto-char (get-position line-no column-no)))
		       (message "Refactoring succeeded!")))))
	     (message "Refactoring aborted!")))
	   (['rex ['ok modified]]
	    (dolist (f modified)
 	      (let ((buff (get-file-buffer f)))
 		(if buff
 		    (with-current-buffer buff (revert-buffer nil t t))
 		  ;;(message-box (format "modified unopened file: %s" f))))))
 		  nil)))
	    (with-current-buffer buffer
	      (goto-char (get-position line-no column-no)))
	    (message "Refactoring succeeded!")))))))))


(defun erl-refactor-register-pid(name start end)
  "Register a process with a user-provied name."
  (interactive (list (read-string "process name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'register_pid
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
	  (erl-receive (buffer current-file-name start-line-no start-col-no end-line-no end-col-no name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['unknown_pnames regpids]]
		(if (yes-or-no-p "Do you want to continue the refactoring?")
		    (erl-spawn
		      (erl-send-rpc wrangler-erl-node 'refac_register_pid 'register_pid_1
				    (list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name regpids wrangler-search-paths tab-width))
		      (erl-receive (buffer current-file-name start-line-no start-col-no end-line-no end-col-no name)
			  ((['rex ['badrpc rsn]]
			    (message "Refactoring failed: %S" rsn))
			   (['rex ['error rsn]]
			    (message "Refactoring failed: %s" rsn))
			   (['rex ['unknown_pids pars]]
			    (if (yes-or-no-p "Do you want to continue the refactoring?")
				(erl-spawn
				  (erl-send-rpc wrangler-erl-node 'refac_register_pid 'register_pid_2
						(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
				  (erl-receive (buffer)
				      ((['rex ['badrpc rsn]]
					(message "Refactoring failed: %S" rsn))
				       (['rex ['error rsn]]
					(message "Refactoring failed: %s" rsn))
				       (['rex ['ok modified]]
					(with-current-buffer buffer (revert-buffer nil t t))
					(message "Refactoring succeeded!")))))
			      (message "Refactoring aborted!")))
			   (['rex ['ok modified]]
			    (with-current-buffer buffer (revert-buffer nil t t))
			    (message "Refactoring succeeded!")))))
		  (message "Refactoring aborted!")))
	       (['rex ['unknown_pids pars]]
		(if (yes-or-no-p "Do you want to continue the refactoring?")
		    (erl-spawn
		      (erl-send-rpc wrangler-erl-node 'refac_register_pid 'register_pid_2
				    (list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
		      (erl-receive (buffer)
			  ((['rex ['badrpc rsn]]
			    (message "Refactoring failed: %S" rsn))
			   (['rex ['error rsn]]
			    (message "Refactoring failed: %s" rsn))
			   (['rex ['ok modified]]
			    (with-current-buffer buffer (revert-buffer nil t t))
			    (message "Refactoring succeeded!")))))
		  (message "Refactoring aborted!")))
	       (['rex ['ok modified]]
		(with-current-buffer buffer
		  (dolist (f modified)
		    (let ((buffer (get-file-buffer f)))
		      (if buffer (with-current-buffer buffer (revert-buffer nil t t))
			;;(message-box (format "modified unopened file: %s" f))))))
			nil))))
		(message "Refactoring succeeded!")))))))))
	  
(defun erl-refactor-move-fun (name)
  "Move a function definition from one module to another."
  (interactive (list (erl-target-node)
		     (read-string "Target Module name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer))
        (create-new-file   (create-new-file-p name wrangler-search-paths)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'move_fun
		    (list current-file-name line-no column-no name create-new-file wrangler-search-paths tab-width))
      (erl-receive (buffer line-no column-no)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (dolist (f modified)
 	      (let ((buff (get-file-buffer f)))
 		(if buff
 		    (with-current-buffer buff (revert-buffer nil t t))
 		  ;;(message-box (format "modified unopened file: %s" f))))))
 		  nil)))
	    (with-current-buffer buffer
	      (goto-char (get-position line-no column-no)))
	    (message "Refactoring succeeded!")))))))))

(defun create-new-file-p (filename wrangler-search-paths)
  (if (equal (locate-file filename (cons (file-name-directory filename) nil) '("" ".erl")) nil)
      (yes-or-no-p "The specified module does not exist, do you want to create one?")
    t))

 
;; redefined get-file-buffer to handle the difference between
;; unix and windows filepath seperator.
(defun get-file-buffer (filename)
 (let ((buffer)
	(bs (buffer-list)))
        (while (and (not buffer) (not (equal bs nil)))
	   (let ((b (car bs)))
	     (if (and (buffer-file-name b)
		      (and (equal (file-name-nondirectory filename)
				  (file-name-nondirectory (buffer-file-name b)))
			   (equal (file-name-directory filename)
			    (file-name-directory (buffer-file-name b)))))
		 (setq buffer 'true)
	       (setq bs (cdr bs)))))
	(car bs)))		  


(defun erl-refactor-generalisation(name start end)
  "Generalise a function definition over an user-selected expression."
  (interactive (list (read-string "New parameter name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (let* ((n (buffer-name buffer)) (n1 (substring n 0 1)))
      (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p buffer))
	  (message-box "The current buffer has been changed")
	(erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'generalise
		    (list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
      (erl-receive (buffer current-file-name wrangler-search-paths start-line-no start-col-no)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['unknown_side_effect pars]]	        
		 (setq  parname (elt pars 0))
		 (setq funname (elt pars 1))
		 (setq arity (elt pars 2))
		 (setq defpos (elt pars 3))
		 (setq exp (elt pars 4))
	    	(if (yes-or-no-p "Does the selected expression has side effect?")
		    (erl-spawn
		      (erl-send-rpc wrangler-erl-node 'refac_gen 'gen_fun_1 (list 'true current-file-name parname funname arity defpos exp tab-width))
		      (erl-receive (buffer)
			  ((['rex ['badrpc rsn]]
			    (message "Refactoring failed: %S" rsn))
			   (['rex ['error rsn]]
			    (message "Refactoring failed: %s" rsn))
			   (['rex ['ok refac-generalisation]]
			    (with-current-buffer buffer (progn (revert-buffer nil t t)
							       (goto-char (get-position start-line-no start-col-no))))
			    (message "Refactoring succeeded!")))))
		  (erl-spawn
		      (erl-send-rpc wrangler-erl-node 'refac_gen 'gen_fun_1 (list 'false current-file-name parname funname arity defpos exp tab-width))
		      (erl-receive (buffer start-line-no start-col-no)
			  ((['rex ['badrpc rsn]]
			    (message "Refactoring failed: %S" rsn))
			   (['rex ['error rsn]]
			    (message "Refactoring failed: %s" rsn))
			   (['rex ['ok refac-generalisation]]
			    (with-current-buffer buffer (progn (revert-buffer nil t t)
							       (goto-char (get-position start-line-no start-col-no))))
			    (message "Refactoring succeeded!")))))))
	   (['rex ['ok refac-generalisation]]
	    (with-current-buffer buffer (progn (revert-buffer nil t t)
						(goto-char (get-position start-line-no start-col-no))))
            (message "Refactoring succeeded!")))))))))


(defun erl-refactor-fun-extraction(name start end)
  "Introduce a new function to represent an user-selected expression/expression sequence."
  (interactive (list (read-string "New function name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (let* ((n (buffer-name buffer)) (n1 (substring n 0 1)))
      (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p buffer))
	  (message-box "The current buffer has been changed")
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fun_extraction
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name tab-width))
	  (erl-receive (buffer start-line-no start-col-no)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['ok refac_fun_extraction]]
		(with-current-buffer buffer (progn (revert-buffer nil t t)
							   (goto-char (get-position start-line-no start-col-no))))
		(message "Refactoring succeeded!")))))))))

(defun erl-refactor-new-macro(name start end)
  "Introduce a new marco to represent an user-selected syntax phrase."
  (interactive (list (read-string "New macro name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (let* ((n (buffer-name buffer)) (n1 (substring n 0 1)))
      (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p buffer))
	  (message-box "The current buffer has been changed")
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'new_macro
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
	  (erl-receive (buffer start-line-no start-col-no)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['ok str]]
		(with-current-buffer buffer (progn (revert-buffer nil t t)
						   (goto-char (get-position start-line-no start-col-no))))
		(message "Refactoring succeeded!")))))))))

(defun erl-refactor-fold-against-macro()
  "Fold expression(s)/patterns(s) against a macro definition."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fold_against_macro
		    (list current-file-name line-no column-no wrangler-search-paths tab-width))
      (erl-receive (buffer current-file-name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok candidates]]
	    (with-current-buffer buffer
	       (progn (while (not (equal candidates nil))
			(setq reg (car candidates))
			(setq line1 (elt reg 0))
			(setq col1  (elt  reg 1))
			(setq line2 (elt reg 2))
			(setq col2  (elt  reg 3))
			(setq macroapp (elt reg 4))
			(setq macrodef (elt reg 5))
			(highlight-region line1 col1 line2  col2 buffer)
			(if (yes-or-no-p "Would you like to replace the highlighted expression(s) with macro application? ")
			    (progn (erl-spawn (erl-send-rpc wrangler-erl-node 'refac_fold_against_macro 'fold_against_macro_1
							    (list current-file-name line1 col1 line2 col2 macroapp macrodef wrangler-search-paths tab-width))
				     (erl-receive (buffer highlight-region-overlay current-file-name)
					 ((['rex ['badrpc rsn]]
					   (delete-overlay highlight-region-overlay)
					   (message "Refactoring failed: %s" rsn))
					  (['rex ['error rsn]]
					   (delete-overlay highlight-region-overlay)
					   (message "Refactoring failed: %s" rsn))			     
					  (['rex ['ok candidates1]]
					   (with-current-buffer buffer (revert-buffer nil t t)
						(if (not (equal candidates1 nil))
						    (progn (highlight-folding-macro-candidates current-file-name candidates1 buffer highlight-region-overlay)
							   (delete-overlay highlight-region-overlay))
						  (delete-overlay highlight-region-overlay))))
					  )))
				   (setq candidates nil))
			  (setq candidates (cdr candidates))))
		      (revert-buffer nil t t)
		      (delete-overlay highlight-region-overlay)
		      (message "Refactoring succeeded.")))))))))


(defun highlight-folding-macro-candidates(current-file-name candidates buffer highlight-region-overlay)
  "highlight the found candidate expressions one by one"
  (while (not (equal candidates nil))
    (setq reg (car candidates))
    (setq line1 (elt reg 0))
    (setq col1  (elt  reg 1))
    (setq line2 (elt reg 2))
    (setq col2  (elt  reg 3))
    (setq macroapp (elt reg 4))
    (setq macrodef (elt reg 5))
    (highlight-region line1 col1 line2  col2 buffer)
    (if (yes-or-no-p "Would you like to replace the highlighted expression(s) with macro application? ")
	(progn (erl-spawn (erl-send-rpc wrangler-erl-node 'refac_fold_against_macro 'fold_against_macro_1
					(list current-file-name line1 col1 line2 col2 macroapp macrodef wrangler-search-paths tab-width))
		 (erl-receive (buffer highlight-region-overlay current-file-name)
		     ((['rex ['badrpc rsn]]
		       (delete-overlay highlight-region-overlay)
		       (message "Refactoring failed: %s" rsn))
		      (['rex ['error rsn]]
		       (delete-overlay highlight-region-overlay)
		       (message "Refactoring failed: %s" rsn))
		      (['rex ['ok candidates1]]
		       (with-current-buffer buffer (revert-buffer nil t t)
					    (if (not (equal candidates1 nil))
						(progn (highlight-folding-macro-candidates current-file-name candidates1 buffer highlight-region-overlay)
						       (delete-overlay highlight-region-overlay))
					      (delete-overlay highlight-region-overlay)))))))
	       (setq candidates nil))    
      (setq candidates (cdr candidates)) 
    (with-current-buffer buffer (revert-buffer nil t t)
			 (delete-overlay highlight-region-overlay))
   ))
    (message "Refactoring succeeded.")
    )


    
(defun erl-refactor-fold-expression()
  "Fold expression(s) against function definition."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
        (erl-spawn
	  (erl-send-rpc wrangler-erl-node 'refac_fold_expression 'cursor_at_fun_clause(list current-file-name line-no column-no wrangler-search-paths tab-width))
	  (erl-receive (buffer current-file-name line-no column-no)
	      ((['rex ['badrpc rsn]]
		(fold_expr_by_name wrangler-erl-node current-file-name (read-string "Module name: ") (read-string "Function name: ") (read-string "Arity ")
				   (read-string "Clause index (starting from 1): ")))
	       (['rex 'true]
		(if (yes-or-no-p "Would you like to fold expressions against the function clause pointed by the cursor? ")
		    (fold_expr_by_loc buffer current-file-name line-no column-no)
		  (fold_expr_by_name buffer current-file-name (read-string "Module name: ") (read-string "Function name: ") (read-string "Arity: ")
				     (read-string "Clause index (starting from 1): "))))
	       (['rex 'false]
	       (fold_expr_by_name buffer current-file-name (read-string "Module name: ") (read-string "Function name: ") (read-string "Arity: ")
				   (read-string "Clause index (starting from 1): "))))))))))




(defun fold_expr_by_name(buffer current-file-name module-name function-name arity clause-index)
    (erl-spawn
    (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fold_expr_by_name(list current-file-name module-name function-name arity clause-index wrangler-search-paths tab-width))
    (erl-receive (buffer current-file-name)
	((['rex ['badrpc rsn]]
	  (message "Refactoring failed: %S" rsn))
	 (['rex ['error rsn]]
	  (message "Refactoring failed: %s" rsn))
	 (['rex ['ok candidates]]
	  (with-current-buffer buffer
	    (progn (while (not (equal candidates nil))
		     (setq reg (car candidates))
		     (setq line1 (elt reg 0))
		     (setq col1  (elt  reg 1))
		     (setq line2 (elt reg 2))
		     (setq col2  (elt  reg 3))
		     (setq funcall (elt reg 4))
		     (setq fundef (elt reg 5))
		     (highlight-region line1 col1 line2  col2 buffer)
		     (if (yes-or-no-p "Would you like to fold this expression? ")
			 (progn (erl-spawn (erl-send-rpc wrangler-erl-node 'refac_fold_expression
							 'fold_expression_1(list current-file-name line1 col1 line2 col2 funcall fundef wrangler-search-paths tab-width))
				  (erl-receive (buffer highlight-region-overlay current-file-name)
				      ((['rex ['badrpc rsn]]
					(delete-overlay highlight-region-overlay)
					(message "Refactoring failed: %s" rsn))
				       (['rex ['error rsn]]
					(delete-overlay highlight-region-overlay)
					(message "Refactoring failed: %s" rsn))			     
				       (['rex ['ok candidates1]]
					(with-current-buffer buffer (revert-buffer nil t t)
							     (if (not (equal candidates1 nil))
								 (progn (highlight-folding-candidates current-file-name candidates1 buffer highlight-region-overlay)
									(delete-overlay highlight-region-overlay))
							       (delete-overlay highlight-region-overlay))))
				       )))
				(setq candidates nil))
		       (setq candidates (cdr candidates))))
		   (revert-buffer nil t t)
		   (delete-overlay highlight-region-overlay)
		   (message "Refactoring succeeded."))))))))


  
(defun fold_expr_by_loc(buffer current-file-name line-no column-no)
  (erl-spawn
    (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fold_expr_by_loc(list current-file-name line-no column-no wrangler-search-paths tab-width))
    (erl-receive (buffer current-file-name)
	((['rex ['badrpc rsn]]
	  (message "Refactoring failed: %S" rsn))
	 (['rex ['error rsn]]
	  (message "Refactoring failed: %s" rsn))
	 (['rex ['ok candidates]]
	  (with-current-buffer buffer
	    (progn (while (not (equal candidates nil))
		     (setq reg (car candidates))
		     (setq line1 (elt reg 0))
		     (setq col1  (elt  reg 1))
		     (setq line2 (elt reg 2))
		     (setq col2  (elt  reg 3))
		     (setq funcall (elt reg 4))
		     (setq fundef (elt reg 5))
		     (highlight-region line1 col1 line2  col2 buffer)
		     (if (yes-or-no-p "Would you like to fold this expression? ")
			 (progn (erl-spawn (erl-send-rpc wrangler-erl-node 'refac_fold_expression
							 'fold_expression_1(list current-file-name line1 col1 line2 col2 funcall fundef wrangler-search-paths tab-width))
				  (erl-receive (buffer highlight-region-overlay current-file-name)
				      ((['rex ['badrpc rsn]]
					(delete-overlay highlight-region-overlay)
					(message "Refactoring failed: %s" rsn))
				       (['rex ['error rsn]]
					(delete-overlay highlight-region-overlay)
					(message "Refactoring failed: %s" rsn))			     
				       (['rex ['ok candidates1]]
					(with-current-buffer buffer (revert-buffer nil t t)
							     (if (not (equal candidates1 nil))
								 (progn (highlight-folding-candidates current-file-name candidates1 buffer highlight-region-overlay)
									(delete-overlay highlight-region-overlay))
							       (delete-overlay highlight-region-overlay))))
				       )))
				(setq candidates nil))
		       (setq candidates (cdr candidates))))
		   (revert-buffer nil t t)
		   (delete-overlay highlight-region-overlay)
		   (message "Refactoring succeeded."))))))))



(defun highlight-folding-candidates(current-file-name candidates buffer highlight-region-overlay)
  "highlight the found candidate expressions one by one"
  (while (not (equal candidates nil))
    (setq reg (car candidates))
    (setq line1 (elt reg 0))
    (setq col1  (elt  reg 1))
    (setq line2 (elt reg 2))
    (setq col2  (elt  reg 3))
    (setq funcall (elt reg 4))
    (setq fundef (elt reg 5))
    (highlight-region line1 col1 line2  col2 buffer)
    (if (yes-or-no-p "Would you like to fold this expression? ")
	(progn (erl-spawn (erl-send-rpc wrangler-erl-node 'refac_fold_expression 'fold_expression_1(list current-file-name line1 col1
										 line2 col2 funcall fundef wrangler-search-paths tab-width))
		 (erl-receive (buffer highlight-region-overlay current-file-name)
		     ((['rex ['badrpc rsn]]
		       (delete-overlay highlight-region-overlay)
		       (message "Refactoring failed: %s" rsn))
		      (['rex ['error rsn]]
		       (delete-overlay highlight-region-overlay)
		       (message "Refactoring failed: %s" rsn))
		      (['rex ['ok candidates1]]
		       (with-current-buffer buffer (revert-buffer nil t t)
					    (if (not (equal candidates1 nil))
						(progn (highlight-folding-candidates current-file-name candidates1 buffer highlight-region-overlay)
						       (delete-overlay highlight-region-overlay))
					      (delete-overlay highlight-region-overlay)))))))
	       (setq candidates nil))    
      (setq candidates (cdr candidates)) 
    (with-current-buffer buffer (revert-buffer nil t t)
			 (delete-overlay highlight-region-overlay))
    ;;(message "Refactoring finished.")
    ))
    (message "Refactoring succeeded.")
    )
      

(defun erl-refactor-tuple-to-record(start end)
  "From tuple to record representation."
  (interactive (list (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'tuple_to_record
		    (list current-file-name start-line-no start-col-no end-line-no end-col-no tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok refac-tuple-to-record]]
	    (with-current-buffer buffer (revert-buffer nil t t))
            (message "Refactoring succeeded!")))))))))


(defun erl-refactor-duplicated-code-in-buffer(mintokens minclones)
  "Find code clones in the current buffer."
  (interactive (list (read-string "Minimum number of tokens a code clone should have (default value: 20): ")
		     (read-string "Minimum number of appearance times (minimum and default value: 2): ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (let* ((n (buffer-name buffer)) (n1 (substring n 0 1)))
      (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p buffer)) 
	  (message-box "The current buffer has been changed")
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'duplicated_code_in_buffer
		    (list current-file-name mintokens minclones tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Duplicated code detection failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Duplicated code detection failed: %s" rsn))
	   (['rex ['ok result]]
	    (message "Duplicated code detection finished!")))))))))


(defun erl-refactor-duplicated-code-in-dirs(mintokens minclones)
  "Find code clones in the directories specified by the search paths."
  (interactive (list (read-string "Minimum number of tokens a code clone should have (default value: 20): ")
		     (read-string "Minimum number of appearance times (minimum and default value: 2): ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'duplicated_code_in_dirs
		    (list wrangler-search-paths mintokens minclones tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Duplicated code detection failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Duplicated code detection failed: %s" rsn))
	   (['rex ['ok result]]
	    (message "Duplicated code detection finished!")))))))))

(defun erl-refactor-expression-search(start end)
  "Search an user-selected expression or expression sequence in the current buffer."
  (interactive (list (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (let* ((n (buffer-name buffer)) (n1 (substring n 0 1)))
      (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p buffer))
	  (message-box "The current buffer has been changed")
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'expression_search
		    (list current-file-name start-line-no start-col-no end-line-no end-col-no tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Searching failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Searching failed: %s" rsn))
	   (['rex ['ok regions]]
	    (with-current-buffer buffer 
	    (highlight-search-results regions buffer)
	   (revert-buffer nil t t)
	    (message "Searching finished."))))))))))


(defun erl-refactor-fun-to-process (name)
  "From a function to a process."
  (interactive (list (read-string "Process name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fun_to_process (list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (buffer current-file-name line-no column-no name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['undecidables msg]]
	     (if (yes-or-no-p "Do you still want to continue the refactoring?")
		 (erl-spawn
		   (erl-send-rpc wrangler-erl-node 'refac_fun_to_process 'fun_to_process_1
				 (list current-file-name line-no column-no  name wrangler-search-paths tab-width))
		   (erl-receive (buffer line-no column-no)
		       ((['rex ['badrpc rsn]]
			 (message "Refactoring failed: %S" rsn))
			(['rex ['error rsn]]
			 (message "Refactoring failed: %s" rsn))
			(['rex ['ok modified]]
			 (dolist (f modified)
			   (let ((buff (get-file-buffer f)))
			     (if buff
				 (with-current-buffer buff (revert-buffer nil t t))
			       ;;(message-box (format "modified unopened file: %s" f))))))
			       nil)))
			 (with-current-buffer buffer
			   (goto-char (get-position line-no column-no)))
			 (message "Refactoring succeeded!")))))
	       (message "Refactoring aborted!")))
	   (['rex ['ok modified]]
	    (dolist (f modified)
 	      (let ((buff (get-file-buffer f)))
 		(if buff
 		    (with-current-buffer buff (revert-buffer nil t t))
 		  ;;(message-box (format "modified unopened file: %s" f))))))
 		  nil)))
	    (with-current-buffer buffer
	      (goto-char (get-position line-no column-no)))
	    (message "Refactoring succeeded!")))))))


(defun current-line-no ()
  "grmpff. does anyone understand count-lines?"
  (+ (if (eq 0 (current-column)) 1 0)
     (count-lines (point-min) (point)))
  )

(defun current-column-no ()
  "the column number of the cursor"
  (+ 1 (current-column)))


(defun line-no-pos (pos)
  "grmpff. why no parameter to current-column?"
  (save-excursion
    (goto-char pos)
    (+ (if (eq 0 (current-column)) 1 0)
       (count-lines (point-min) (point))))
  )

(defun current-column-pos (pos)
  "grmpff. why no parameter to current-column?"
  (save-excursion
    (goto-char pos) (+ 1 (current-column)))
  )


(defun get-position(line col)
  "get the position at lie (line, col)"
  (save-excursion
    (goto-line line)
    (move-to-column col)
    (- (point) 1)))


(defvar highlight-region-overlay
  ;; Dummy initialisation
  (make-overlay 1 1)
  "Overlay for highlighting.")

(defface highlight-region-face
  '((t (:background "CornflowerBlue")))
    "Face used to highlight current line.")

(defun highlight-region(line1 col1 line2 col2 buffer)
  "hightlight the specified region"
  (overlay-put highlight-region-overlay
	       'face 'highlight-region-face)
 ;; (message "pos: %s, %s, %s, %s" line1 col1 line2 col2)
  (move-overlay highlight-region-overlay (get-position line1 col1)
		(get-position line2 (+ 1 col2)) buffer)
  (goto-char (get-position line2 col2))
  )


(defun highlight-search-results(regions buffer)
  "highlight the found results one by one"
  (while (not (equal regions nil))
    (setq reg (car regions))
    (setq line1 (elt reg 0))
    (setq col1  (elt  reg 1))
    (setq line2 (elt reg 2))
    (setq col2  (elt  reg 3))
    (highlight-region line1 col1 line2  col2 buffer)
   ;; (message "Press 'Enter' key to go to the next instance, any other key to exit.")
    (let ((input (read-event)))
      (if (equal input 'return)
	  (progn (setq regions (cdr regions))
	         (message  " ")
	   )
	(if (equal input 'escape)
	    (setq regions nil)
	  (message "Press 'Enter' key to go to the next instance, any other key to exit.")
	  )
	)
      ))
  (delete-overlay highlight-region-overlay)
  )

(defun erl-refactor-instrument-prog ()
  "Instrument an Erlang program to trace process communication."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'instrument_prog(list current-file-name wrangler-search-paths tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (with-current-buffer buffer
	       (dolist (f modified)
		 (let ((buffer (get-file-buffer f)))
		   (if buffer (with-current-buffer buffer (revert-buffer nil t t))
		     ;;(message-box (format "modified unopened file: %s" f))))))
		     nil))))
	       (message "Refactoring succeeded!")))))))

(defun erl-refactor-uninstrument-prog ()
  "Uninstrument an Erlang program to remove the code added by Wrangler to trace process communication."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'uninstrument_prog(list current-file-name wrangler-search-paths tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (with-current-buffer buffer
	       (dolist (f modified)
		 (let ((buffer (get-file-buffer f)))
		   (if buffer (with-current-buffer buffer (revert-buffer nil t t))
		     ;;(message-box (format "modified unopened file: %s" f))))))
		     nil))))
	       (message "Refactoring succeeded!")))))))


(defun erl-refactor-add-a-tag (name)
  "Add a tag to the messages received by a process."
  (interactive (list (read-string "Tag to add: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'add_a_tag(list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (buffer name current-file-name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (with-current-buffer buffer
	       (dolist (f modified)
		 (let ((buffer (get-file-buffer f)))
		   (if buffer (with-current-buffer buffer (revert-buffer nil t t))
		     ;;(message-box (format "modified unopened file: %s" f))))))
		     nil))))
	       (message "Refactoring succeeded!")))))))


(defun erl-refactor-add-a-tag-1 (name)
  "Add a tag to the messages received by a process."
  (interactive (list (read-string "Tag to add: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'add_a_tag(list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (buffer name current-file-name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok candidates]]
	    (with-current-buffer buffer (revert-buffer nil t t) 
	      (while (not (equal candidates nil))
		(setq send (car candidates))
		(setq mod (elt send 0))
		(setq fun (elt send 1))
		(setq arity (elt send 2))
		(setq index (elt send 3))
		(erl-spawn
		  (erl-send-rpc wrangler-erl-node 'refac_add_a_tag 'send_expr_to_region(list current-file-name mod fun arity index tab-width))
		  (erl-receive (buffer current-file-name name)
		      ((['rex ['badrpc rsn]]
			;;  (setq candidates nil)
			(message "Refactoring failed: %s" rsn))					  
		       (['rex ['error rsn]]
			;;  (setq candidates nil)
			(message "Refactoring failed: %s" rsn))
		       (['rex ['ok region]]
			(with-current-buffer buffer 
			(progn (setq line1 (elt region 0))
			       (setq col1 (elt region 1))
			       (setq line2 (elt region 2))
			       (setq col2 (elt region 3))
			       (highlight-region line1 col1 line2  col2 buffer)
			       (if (yes-or-no-p "Should a tag be added to this expression? ")
				   (erl-spawn (erl-send-rpc wrangler-erl-node 'refac_add_a_tag 'add_a_tag(list current-file-name name line1 col1 line2 col2 tab-width))
				     (erl-receive (buffer)
					 ((['rex ['badrpc rsn]]
					   (message "Refactoring failed: %s" rsn))
					  (['rex ['error rsn]]
					   (message "Refactoring failed: %s" rsn))
					  (['rex ['ok res]]
					   (with-current-buffer buffer (revert-buffer nil t t)
						(delete-overlay highlight-region-overlay))
					  ))))
				(delete-overlay highlight-region-overlay)
			       )))))))
		(setq candidates (cdr candidates)))
	      (with-current-buffer buffer (revert-buffer nil t t))
	      ;; (delete-overlay highlight-region-overlay)
	      (message "Refactoring succeeded!"))))))))
  
(defun erl-refactor-tuple-funpar (number)
  "Tuple function argument."
  (interactive (list (read-string "The number of arguments: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'tuple_funpar (list current-file-name line-no column-no number wrangler-search-paths tab-width))
      (erl-receive (buffer line-no column-no)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok refac-rename]]
	    (with-current-buffer buffer (progn (revert-buffer nil t t)
					       (goto-char (get-position line-no column-no))))
            (message "Refactoring succeeded!")))))))))


(defun erl-wrangler-code-inspector-var-instances()
  "Sematic search of instances of a variable"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffer-modified-p buffer) (message-box "Buffer has been changed")
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'find_var_instances(list current-file-name line-no column-no wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions defpos]]
		(with-current-buffer buffer (highlight-instances regions defpos buffer)
				     (remove-highlights buffer))
				       		
	       )))))))

(defun remove-highlights(buffer)
   (read-event)
   (dolist (ov (overlays-in  1 10000))
     (delete-overlay ov))				 
   (remove-overlays))

(defun highlight-instances(regions defpos buffer)
  "highlight regions in the buffer"
  (dolist (r regions)
     (if (member (elt r 0) defpos)
	 (highlight-def-instance r buffer)
       (highlight-use-instance r buffer))))


;; shouldn't code this really.
(defun highlight-def-instance(region buffer)
   "highlight one region in the buffer"
   (let ((line1 (elt (elt region 0) 0))
	  (col1 (elt (elt region 0) 1))
	  (line2 (elt (elt region 1) 0))
	  (col2 (elt (elt region 1) 1))
	 (overlay (make-overlay 1 1)))
     (overlay-put overlay  'face '((t (:background "orange"))))
     (move-overlay overlay (get-position line1 col1)
		   (get-position line2 (+ col2 1)) buffer)
     ))


(defun highlight-use-instance(region buffer)
   "highlight one region in the buffer"
   (let ((line1 (elt (elt region 0) 0))
	  (col1 (elt (elt region 0) 1))
	  (line2 (elt (elt region 1) 0))
	  (col2 (elt (elt region 1) 1))
	 (overlay (make-overlay 1 1)))
     (overlay-put overlay  'face '((t (:background "CornflowerBlue"))))
     (move-overlay overlay (get-position line1 col1)
		   (get-position line2 (+ col2 1)) buffer)
     ))


(defun erl-wrangler-code-inspector-nested-cases(level)
  "Sematic search of instances of a variable"
  (interactive (list (read-string "Nest level: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffer-modified-p buffer) (message-box "Buffer has been changed")
      (if (yes-or-no-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'nested_case_exprs_in_file(list current-file-name level wrangler-search-paths tab-width))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'nested_case_exprs_in_dirs(list level wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		))))
	))))


(defun erl-wrangler-code-inspector-nested-ifs(level)
  "Sematic search of instances of a variable"
  (interactive (list (read-string "Nest level: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffer-modified-p buffer) (message-box "Buffer has been changed")
      	(if (yes-or-no-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'nested_if_exprs_in_file(list current-file-name level wrangler-search-paths tab-width))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'nested_if_exprs_in_dirs(list level wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		))))
	))))

(defun erl-wrangler-code-inspector-nested-receives(level)
  "Sematic search of instances of a variable"
  (interactive (list (read-string "Nest level: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffer-modified-p buffer) (message-box "Buffer has been changed")
	(if (yes-or-no-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'nested_receive_exprs_in_file(list current-file-name level wrangler-search-paths tab-width))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'nested_receive_exprs_in_dirs(list level wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		))))
	))))



(defun erl-wrangler-code-inspector-caller-called-mods()
  "Sematic search of instances of a variable"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffer-modified-p buffer) (message-box "Buffer has been changed")
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'caller_called_modules(list current-file-name wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Analysis finished.")
	       )))))))


(defun erl-wrangler-code-inspector-long-funs(lines)
  "Search for long functions"
  (interactive (list (read-string "Number of lines: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffer-modified-p buffer) (message-box "Buffer has been changed")
      	(if (yes-or-no-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'long_functions_in_file(list current-file-name lines wrangler-search-paths tab-width))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'long_functions_in_dirs(list lines wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		))))
	))))

(defun erl-wrangler-code-inspector-large-mods(lines)
  "Search for large modules"
  (interactive (list (read-string "Number of lines: ")))
  (let 	(buffer (current-buffer))
    (if (buffer-modified-p buffer) (message-box "Buffer has been changed")
      (erl-spawn
	(erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'large_modules(list lines wrangler-search-paths tab-width))
	(erl-receive (buffer)
	    ((['rex ['badrpc rsn]]
	      (message "Error: %S" rsn))
	     (['rex ['error rsn]]
	      (message "Error: %s" rsn))
	     (['rex ['ok mods]]
	      (message "Searching finished.")
	     )))))))


(defun erl-wrangler-code-inspector-caller-funs()
  "Search for caller functions"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'caller_funs(list current-file-name line-no column-no  wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	    ((['rex ['badrpc rsn]]
	      (message "Error: %S" rsn))
	     (['rex ['error rsn]]
	      (message "Error: %s" rsn))
	     (['rex ['ok funs]]
	      (message "Searching finished.")
	    ))))))))


(defun erl-wrangler-code-inspector-non-tail-recursive-servers()
  "Search for non tail-recursive servers"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
	(if (yes-or-no-p "Only check the current buffer?")
	    (erl-spawn
	      (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'non_tail_recursive_servers_in_file(list current-file-name wrangler-search-paths tab-width))
	      (erl-receive (buffer)
		  ((['rex ['badrpc rsn]]
		    (message "Error: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Error: %s" rsn))
		   (['rex ['ok regions]]
		    (message "Searching finished.")
		    ))))
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'non_tail_recursive_servers_in_dirs(list wrangler-search-paths tab-width))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	  )))))
	  

(defun erl-wrangler-code-inspector-no-flush()
  "Search for servers without flush of unknown messages"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed (message-box (format "there are modified buffers: %s" changed))
	(if (yes-or-no-p "Only check the current buffer?")
	    (erl-spawn
	      (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'not_flush_unknown_messages_in_file(list current-file-name wrangler-search-paths tab-width))
	      (erl-receive (buffer)
		  ((['rex ['badrpc rsn]]
		    (message "Error: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Error: %s" rsn))
		   (['rex ['ok regions]]
		    (message "Searching finished.")
		    ))))
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler_code_inspector 'not_flush_unknown_messages_in_dirs(list wrangler-search-paths tab-width))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	  )))))
	  