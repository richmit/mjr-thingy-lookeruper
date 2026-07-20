;; mjr-thingy-lookeruper --- Provide verGo.sh in Emacs. -*-coding: utf-8 lexical-binding:t mode:emacs-lisp -*-

;; Copyright (C) 2026-2026 First Last me@mitchr.me

;; Author:      Mitch Richling
;; Version:     0.6
;; Keywords:    mjr-thingy-lookeruper
;; URL:         https://github.com/richmit/mjr-thingy-lookeruper

;; This file is not part of Emacs

;;; Install:

;; Manual (with `load-path'): 
;;   - Put mjr-thingy-lookeruper.el somplace
;;   - Add the directory with mjr-thingy-lookeruper.el to the `load-path'
;;   - Add this to ~/.emacs: (require 'mjr-thingy-lookeruper)
;; Manual (no `load-path' option):
;;   - Put mjr-thingy-lookeruper.el somplace
;;   - Add this to ~/.emacs: (require 'mjr-thingy-lookeruper "fully_qualified_path_name_for_mjr-thingy-lookeruper.el")
;; As a package pulled from github:
;;   - Run the following:
;;     (package-vc-install (list 'mjr-thingy-lookeruper
;;                               :url "https://github.com/richmit/mjr-thingy-lookeruper"
;;                               :rev 'newest))

;;; Commentary:

;; The mjr-thingy-lookeruper package provides an extensible way to look things up via the `mjr-thingy-lookeruper' function.
;; Several methods are provided in the constant `mjr-thingy-lookeruper-built-in-methods'.
;; The lookup methods used are defined in the `mjr-thingy-lookeruper-methods' variable -- which defaults to everything 
;; in `mjr-thingy-lookeruper-built-in-methods'.

;;; Code:

(require 'cl-lib)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defconst mjr-thingy-lookeruper-built-in-methods
  (list
   (list :name "man"
         :desc "Look for a UNIX man page via man (emacs)."
         :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([a-z0-9_-]+\\)\\b" 20) (match-string 1)))
         :actn #'man)
   (list :name "gid"
         :desc "Lookup a numeric group ID via getent (shell)."
         :atpt (lambda () (thing-at-point 'number))
         :actn "getent group %Q")
   (list :name "gname"
         :desc "Lookup a group name (gname) via getent (shell)."
         :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([.a-zA-Z0-9_-]+\\)\\b" 20) (match-string 1)))
         :actn "getent group %Q")
   (list :name "uid"
         :desc "Lookup a numeric user ID via getent (shell)."
         :atpt (lambda () (thing-at-point 'number))
         :actn "getent passwd %Q")
   (list :name "uname"
         :desc "Look up a user name (uname) with getent (shell)." 
         :atpt (lambda () (let ((tmp (and (thing-at-point-looking-at "\\b\\([a-zA-Z][a-zA-Z0-9_-]+\\)\\b" 20) (match-string 1))))
                            (and tmp (cl-find tmp (system-users) :test #'string-equal))))
         :actn "getent passwd %Q")
   (list :name "DNS"
         :desc "Lookup host name via dns-lookup-host (emacs)."
         :atpt (lambda () (and (thing-at-point-looking-at "\\([.a-zA-Z0-9_-]+\\.\\(com\\|edu\\|org\\|gov\\)\\)\\b" 20) (match-string 1)))
         :actn #'dns-lookup-host)
   (list :name "IPv4"
         :desc "Lookup IPv4 address via dns-lookup-host (emacs)."
         :atpt (lambda () (and (thing-at-point-looking-at "\\b\\(\\([0-9]+\\)\\.\\([0-9]+\\)\\.\\([0-9]+\\)\\.\\([0-9]+\\)\\)\\b" 20) 
                               (cl-every (lambda (x) (let ((y (string-to-number (match-string x)))) (and (<= 0 y) (>= 255 y)))) '(2 3 4 5))
                               (match-string 1)))
         :actn #'dns-lookup-host)
   (list :name "file"
         :desc "Look up file data via fstat.pl or stat (shell)."
         :atpt (lambda () (and-let* ((raw-fname (ffap-guess-file-name-at-point))
                                     (          (file-exists-p raw-fname))
                                     (exp-fname (expand-file-name raw-fname)))))
         :actn (if-let* ((tmp (locate-file "fstat" exec-path (list ".pl"))))
                   "fstat.pl '%Q'"
                 "stat '%Q'"))
   (list :name "URL"
         :desc "Hand URL to browser using browse-url (emacs)."
         :atpt (lambda () (thing-at-point 'url))
         :actn #'browse-url)
   (list :name "dictionary"
         :desc "Look up a word via dictionary.reference.com using browse-url (emacs)"
         :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([a-zA-Z'-]+\\)\\b" 20) (match-string 1)))
         :actn (lambda (thingy) (browse-url (concat "https://www.merriam-webster.com/dictionary/" (url-hexify-string thingy) ""))))
   (list :name "google"
         :desc "Search via google using browse-url (emacs)"
         :actn (lambda (thingy) (browse-url (concat "http://google.com/search?q=" (url-hexify-string thingy)))))
   (list :name "bing"
         :desc "Search via bing using browse-url (emacs)"
         :actn (lambda (thingy) (browse-url (concat "https://www.bing.com/search?q=" (url-hexify-string thingy)))))
   (list :name "ebay"
         :desc "Search via e-bay using browse-url (emacs)"
         :actn (lambda (thingy) (browse-url (concat "https://www.ebay.com/sch/i.html?_nkw=" (url-hexify-string thingy)))))
   (list :name "el-symbol"
         :desc "Lookup a lisp symbol in an interactive elisp session or in an elisp source file via describe-symbol (emacs)"
         :mode (list 'lisp-interaction-mode 'emacs-lisp-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (describe-symbol (if (stringp thingy)
                                                     (intern-soft thingy)
                                                     thingy))))
   (list :name "R-symbol"
         :desc "Lookup a symbol in an R session or R source code file via ess-help (emacs)"
         :mode (list 'inferior-ess-mode 'ess-mode 'ess-r-mode)
         :atpt #'ess-symbol-at-point
         :actn (lambda (thingy) (ess-help (format "%s" thingy))))
   (list :name "cl-symbol(hyperspec)"
         :desc "Lookup a symbol in an interactive SLIME REPL or common lisp buffer using the hyperspec"
         :mode (list 'slime-repl-mode 'lisp-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (hyperspec-lookup (symbol-name thingy))))
   (list :name "cl-symbol(slime)"
         :desc "Lookup a symbol in an interactive SLIME REPL or common lisp buffer using slime-describe-symbol"
         :mode (list 'slime-repl-mode 'lisp-mode)
         :atpt (lambda () (let ((sym-thingy (symbol-at-point)))
                            (when (and sym-thingy (not (zerop (length slime-net-processes))))
                              (let ((str-thingy (substring-no-properties (symbol-name sym-thingy))))
                                (if (string-match "^[:']" str-thingy)
                                    (substring str-thingy 1)
                                    str-thingy)))))
         :actn (lambda (thingy) (slime-describe-symbol thingy)))
   (list :name "symbol(devdocs.io)"
         :desc "Lookup a symbol via devdocs.io for ruby, perl, & python buffers using browse-url (emacs)"
         :mode (list 'ruby-mode 'perl-mode 'python-mode 'julia-mode 'cmake-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (browse-url (concat "http://devdocs.io/#q="
                                                    (url-hexify-string (concat
                                                                        (or (cdr (assoc major-mode (list (cons 'ruby-mode   "ruby-4.0")
                                                                                                         (cons 'perl-mode   "perl-5.26")
                                                                                                         (cons 'julia-mode  "julia")
                                                                                                         (cons 'cmake-mode  "CMake")
                                                                                                         (cons 'python-mode "python-3.6"))))
                                                                            (string-remove-suffix "-mode" (symbol-name major-mode)))
                                                                        " "
                                                                        (format "%s" thingy)))))))
   (list :name "symbol-bing"
         :desc "Search bing for captured symbol with major-mode name as search context using browse-url (emacs)."
         :mode (list 'ruby-mode 'perl-mode 'python-mode 'julia-mode 'c++-mode 'f90-mode 'c-mode 'emacs-lisp-mode
                     'lisp-mode 'fortran-mode 'javascript-mode 'java-mode 'matlab-mode 'octave-mode 'cmake-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (browse-url (concat "https://www.bing.com/search?q="
                                                    (url-hexify-string (concat
                                                                        "+\""
                                                                        (string-remove-suffix "-mode" (symbol-name major-mode))
                                                                        "\" "
                                                                        "+\""
                                                                        (format "%s" thingy)
                                                                        "\""))))))
   (list :name "CPP-header"
         :desc "Lookup a c++ header file via cppreference.com using browse-url (emacs)"
         :mode (list 'c++-mode)
         :atpt (lambda () (and (thing-at-point-looking-at "^#include *<\\([^>]+\\)>" 50) (match-string 1)))
         :actn (lambda (thingy)
                 (let* ((thingy-str (if (stringp thingy)
                                        thingy
                                        (symbol-name thingy)))
                        (thingy-fix (if (string-suffix-p ".h" thingy-str)
                                        (concat "c" (string-remove-suffix ".h" thingy-str))
                                        thingy-str)))
                   (browse-url (concat "https://en.cppreference.com/w/cpp/header/" (url-hexify-string thingy-fix))))))
   (list :name "julia-symbol"
         :desc "Search for a Julia symbol on docs.julialang.org using browse-url (emacs)"
         :mode (list 'julia-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (browse-url (concat "https://docs.julialang.org/en/v1.12/?q=" (url-hexify-string (format "%s" thingy))))))
   (list :name "cmake-symbol"
         :desc "Lookup a symbol via cmake.org using browse-url (emacs)"
         :mode (list 'cmake-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (browse-url (concat "https://cmake.org/cmake/help/latest/search.html?q=" (url-hexify-string (format "%s" thingy))))))
   (list :name "C/CPP-symbol"
         :desc "Search for a c/c++ symbol on cppreference.com using browse-url"
         :mode (list 'c++-mode 'c-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (browse-url (concat "https://cppreference.com/index.php?search=" (url-hexify-string (format "%s" thingy))))))
   (list :name "C-header"
         :desc "Lookup a c header file via cppreference.com using browse-url (emacs)"
         :mode (list 'c-mode)
         :atpt (lambda () (and (thing-at-point-looking-at "^#include *<\\([^>]+\\)\\.h>" 50) (match-string 1)))
         :actn (lambda (thingy) (browse-url (concat "https://en.cppreference.com/c/header/" (url-hexify-string (format "%s" thingy))))))
   (list :name "matlab-symbol"
         :desc "Search for a Matlab symbol on https://www.mathworks.com/search using browse-url (emacs)"
         :mode (list 'octave-mode 'matlab-mode)
         :atpt #'symbol-at-point
         :actn (lambda (thingy) (browse-url (concat "https://www.mathworks.com/search/user-center?q=" (url-hexify-string (format "%s" thingy)) "&app=documentation&page=1"))))
   (list :name "STM32"
         :desc "Search for a STM32/NUCLEO part on st.com using browse-url (emacs)"
         :atpt (lambda () (and (thing-at-point-looking-at "\\b\\(NUCLEO-[A-Z0-9]+\\|STM32[A-Z][A-Z0-9]+\\)\\b" 20) (match-string 1)))
         :actn (lambda (thingy) (browse-url (concat "https://search.st.com/?activeSource=%22Search%22&queryText=%22" (url-hexify-string thingy) "%22"))))
   (list :name "ISBN"
         :desc "Lookup an ISBN (10 or 13) number on isbnsearch.org using browse-url (emacs)"
         :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([0-9]\\{10\\}\\|[0-9]-[0-9]\\{6\\}-[0-9][0-9]-[0-9]\\|[0-9]\\{13\\}\\|[0-9]\\{3\\}-[0-9]-[0-9]\\{5\\}-[0-9]\\{3\\}-[0-9]\\)\\b" 25) (match-string 1)))
         :actn (lambda (thingy) (browse-url (concat "https://isbnsearch.org/isbn/" (url-hexify-string (replace-regexp-in-string "[^0-9]" "" thingy))))))
   ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defgroup mjr-thingy-lookeruper nil
  "mjr-thingy-lookeruper"
  :group 'external
  :group 'environment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defcustom mjr-thingy-lookeruper-methods mjr-thingy-lookeruper-built-in-methods
  "Lookup methods available to mjr-thingy-lookeruper.
A list lookup methods for mjr-thingy-lookeruper.  Each entry is a property list:
 - :name -- A string with the name of the method (Required) 
 * :desc -- A string with a description of the method (Optional)
 * :mode -- A list of major mode symbols used to a buffer's major mode. (Optional)
            If missing or nil, the method may be used with buffers of any mode
 * :atpt -- A function used to thingy (usually a string but not necessarily) from buffer.  (Optional)
            If missing or nil, the method may only be used with an active region.
 * :actn -- A function or shell command string used to perform the lookup. (Required)
            - In shell command strings %U is replaced with the URL hexified thingy, and %Q will be replaced with the thingy.
The functions `mjr-thingy-lookeruper-get-built-in', `mjr-thingy-lookeruper-add-method', and `mjr-thingy-lookeruper-delete-method'
may be helpfull to manage this list."
  :type 'list
  :group 'mjr-thingy-lookeruper)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-get-built-in (method-name) 
  (cl-find-if (lambda (x) (string-equal method-name (plist-get x :name))) mjr-thingy-lookeruper-built-in-methods))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-get-method (method-name) 
  (cl-find-if (lambda (x) (string-equal method-name (plist-get x :name))) mjr-thingy-lookeruper-methods))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-add-method (method-properties) 
  "Add a new method to mjr-thingy-lookeruper-methods.  Error if a method already exists with the same :NAME."
  (when (not (plistp method-properties))
    (error "mjr-thingy-lookeruper-add-method: method is not a valid property list."))
  (when (not (plist-get method-properties :name))
    (error "mjr-thingy-lookeruper-add-method: peoperty :name must be present and non-nil."))
  (when (not (plist-get method-properties :actn))
    (error "mjr-thingy-lookeruper-add-method: peoperty :actn must be present and non-nil."))
  (when (mjr-thingy-lookeruper-get-method method-name)
    (error "mjr-thingy-lookeruper-add-method: peoperty method with the same name is already on mjr-thingy-lookeruper-methods list!"))
  (add-to-list mjr-thingy-lookeruper-methods method-properties))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-delete-method (method-name) 
  "Delete method with given name from mjr-thingy-lookeruper-methods, and return properties of deleted method."
  (let ((method-properties (mjr-thingy-lookeruper-get-method method-name)))
    (unless method-properties
      (error "mjr-thingy-lookeruper-delete-method: No method named '%s' found in mjr-thingy-lookeruper-methods." method-name))
    (setq mjr-thingy-lookeruper-methods
          (cl-remove-if (lambda (x) (string-equal method-name (plist-get x :name))) mjr-thingy-lookeruper-methods))
    method-properties))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper (the-method the-thingy)
  "Extensible looker upper of thingys at the point or in the active region.
Interactive use (while not the true order of events in the code, this step-wise description is logically equivalent and easier to understand):
  Step 1: Construct a list of methods that are eligible to use based on context of the point.
    - If the region is not active .. Each method's tap function is used to determine if the method is eligible for execution and to extract the thingy.
    - If the region is active ...... All methods are considered eligible for execution with the contents of the active region used as the thingy.
  Step 2: Filter the list of eligible methods based on the buffer mode
    - Without a prefix argument .... Only consider methods that match the buffer mode
    - With a prefix argument ....... Ignore the buffer mode
  Step 3: Query the user
    - Only one eligible query ...... Use that method
    - Multiple eligible queries .... Query the user to choose a method.
    - No eligible queries .......... Error
Non-Interactive use: Lookup THE-THINGY via THE-METHOD.
  - THE-METHOD is the :NAME, a string, of a method stored in mjr-thingy-lookeruper-methods.  
  - THE-THINGY is an object, usually a string, to look up with the named method.
  - If THE-METHOD is not found on mjr-thingy-lookeruper-methods, then error.
Results:
 - Methods that use a shell command place the results in the buffer *thingy-lookup-results*.  
 - Methods that use a lisp function
   - If the function returns a string, the string is printed as an Emacs message.
   - Many lisp function lookup methods may provide a special environment for displaying the results.
Variables:
 - mjr-thingy-lookeruper-methods .. Describes the methods for lookup.  Examples include uname, gname, uid, gid, host name, dictionary word, and Google search."
  (interactive (let ((candidates (if (and transient-mark-mode (region-active-p) (mark))
                                     (let ((thingy (buffer-substring-no-properties (region-beginning) (region-end))))
                                       (mapcar (lambda (x) (list (plist-get x :name) thingy)) mjr-thingy-lookeruper-methods))
                                     (cl-loop for cur-method-properties in mjr-thingy-lookeruper-methods
                                              for thingy = (and (or current-prefix-arg
                                                                    (let ((cur-method-mode-list (plist-get cur-method-properties :mode)))                        
                                                                      (or (null cur-method-mode-list) 
                                                                          (member major-mode cur-method-mode-list))))
                                                                (when-let* ((cur-method-tap (plist-get cur-method-properties :atpt)))
                                                                  (funcall cur-method-tap)))
                                              when thingy
                                              collect (list (plist-get cur-method-properties :name) thingy)))))
                 (unless candidates
                   (error "mjr-thingy-lookeruper: Unable to locate suitable lookup methods."))
                 (if (null (cdr candidates))
                     (car candidates)
                     (let ((da-method (if (require 'ido nil :noerror) 
                                          (ido-completing-read "Lookup Method: " (mapcar #'car candidates) nil t)
                                          (completing-read     "Lookup Method: " (mapcar #'car candidates) nil t))))
                       (assoc da-method candidates #'string-equal)))))
  (if (stringp the-thingy)
      (setq the-thingy (substring-no-properties the-thingy)))
  (message "mjr-thingy-lookeruper: '%s' via '%s'" the-thingy the-method)
  (let ((the-method-properties (cl-find-if (lambda (x) (string-equal the-method (plist-get x :name))) mjr-thingy-lookeruper-methods)))
    (unless the-method-properties
      (error "mjr-thingy-lookeruper: Invaid value for the-method: %s!" the-method))
    (let ((the-method-command (plist-get the-method-properties :actn)))
      (unless the-method-command
        (error "mjr-thingy-lookeruper: Invaid property list for mjr-thingy-lookeruper method '%s' -- no :actn property!" the-method))
      (if (stringp the-method-command)
          (let ((the-method-command-x the-method-command)
                (the-thingy-string (if (stringp the-thingy)
                                       the-thingy
                                       (format "%s" the-thingy))))
            (dolist (da-sub (list (cons "%U" (url-hexify-string the-thingy-string))
                                  (cons "%Q" the-thingy-string)))
              (setq the-method-command-x (string-replace (car da-sub) (cdr da-sub) the-method-command-x)))
            (if (string-match "&$" the-method-command)
                (call-process-shell-command the-method-command-x)
                (let ((da-buf (get-buffer-create "*thingy-lookup-results*")))
                  (with-current-buffer da-buf
                    (erase-buffer))
                  (shell-command the-method-command-x da-buf))))
          (let ((res (funcall the-method-command the-thingy)))
            (if (stringp res)
                (message "Lookup result: %s" res)))))))

(provide 'mjr-thingy-lookeruper)

;;; filename ends here
