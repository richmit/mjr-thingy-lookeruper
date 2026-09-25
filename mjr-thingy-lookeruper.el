;;; mjr-thingy-lookeruper.el --- Look up things -*- lexical-binding:t; coding: utf-8; mode:emacs-lisp; fill-column:158 -*-

;; Copyright (c) 2026-2026 Mitch Richling <https://www.mitchr.me>.  All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
;;
;; 1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without
;;    specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
;; TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;; Author:      Mitch Richling
;; Version:     1.45
;; Keywords:    mjr-thingy-lookeruper
;; URL:         https://github.com/richmit/mjr-thingy-lookeruper

;; This file is not part of Emacs

;;; Commentary:
;;
;; * Looking up stuff in Emacs
;;
;; See the README: https://github.com/richmit/mjr-thingy-lookeruper/
;;
;; ** Introduction
;;
;; The mjr-thingy-lookeruper Emacs package provides an extensible way to identify and lookup things in a buffer.  For example, if the cursor is near an ISBN
;; number then mjr-thingy-lookeruper can recognize the ISBN number and look the book up.
;;
;; The primary entry point is the function `mjr-thingy-lookeruper' which I bind the function `mjr-thingy-lookeruper' to "C-c l" -- i.e. "l" for "Lookup":
;;
;;      (keymap-global-set "C-c l" 'mjr-thingy-lookeruper)
;;
;; Several example lookup methods are provided in variable `mjr-thingy-lookeruper-built-in-methods':
;;
;;   - UNIX man pages
;;   - UNIX-ish users & groups via names or numerical ID
;;   - Windows users & groups via names or SID
;;   - Git commits/diffs
;;   - DNS queries
;;   - Dictionary words
;;   - Data about files
;;   - URLs
;;   - Internet search queries (google, bing, & ebay)
;;   - Symbols in several languages (Emacs lisp, Common Lisp, R, Perl, Python, Ruby, Julia, C, C++, Matlab, CMake)
;;   - C & C++ header files
;;   - ST Micro STM32 parts
;;   - Documents & Books by DOI, ISBN, & bibcode
;;   - Zotero items via DOI, ISBN, or Zotero item-key
;;   - The On-Line Encyclopedia of Integer Sequences (OEIS)
;;
;; The methods for looking things up are defined in the variable `mjr-thingy-lookeruper-methods'.  By default this variable is set to the contents of
;; `mjr-thingy-lookeruper-built-in-methods'.  The variable may be customizing `mjr-thingy-lookeruper-methods'.
;;
;; Some utilities related to the variables mentioned above:
;;  - `mjr-thingy-lookeruper-get-built-in'
;;  - `mjr-thingy-lookeruper-get-method'
;;  - `mjr-thingy-lookeruper-delete-method'
;;  - `mjr-thingy-lookeruper-add-method'
;;   
;; ** Installing
;;
;; The easiest way to install mjr-thingy-lookeruper is to pull it directly from github:
;;
;;      (package-vc-install (list 'mjr-thingy-lookeruper
;;                           :url "https://github.com/richmit/mjr-thingy-lookeruper"
;;                           :rev 'newest))
;;                        
;; Be sure to install and load any packages required by any of the methods included on `mjr-thingy-lookeruper-methods'.  For example several of the built in
;; methods require things like: `thingatpt' & `browse-url'.

;;; Code:

(require 'cl-lib)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defconst mjr-thingy-lookeruper-built-in-methods
  (cl-remove 
   nil
   (list
    ;; These only work with a region so I list them first.
    (list :name "bing"
          :desc "Search via bing using browse-url (emacs)"
          :actn (lambda (thingy) (browse-url (concat "https://www.bing.com/search?q=" (url-hexify-string thingy)))))
    (list :name "google"
          :desc "Search via google using browse-url (emacs)"
          :actn (lambda (thingy) (browse-url (concat "http://google.com/search?q=" (url-hexify-string thingy)))))
    (list :name "ebay"
          :desc "Search via e-bay using browse-url (emacs)"
          :actn (lambda (thingy) (browse-url (concat "https://www.ebay.com/sch/i.html?_nkw=" (url-hexify-string thingy)))))
    ;; Mode specific symbol matches
    (list :name "el-symbol"
          :desc "Lookup a lisp symbol in an interactive elisp session or in an elisp source file via describe-symbol (emacs)"
          :optp (list 'lisp-interaction-mode 'emacs-lisp-mode)
          :atpt #'symbol-at-point
          :actn (lambda (thingy) (describe-symbol (if (stringp thingy)
                                                      (intern-soft thingy)
                                                      thingy))))
    (list :name "R-symbol"
          :desc "Lookup a symbol in an R session or R source code file via ess-help (emacs)"
          :optp (list 'inferior-ess-mode 'ess-mode 'ess-r-mode)
          :reqp (lambda () (cl-every #'fboundp '(ess-help ess-symbol-at-point)))
          :atpt #'ess-symbol-at-point
          :actn (lambda (thingy) (ess-help (format "%s" thingy))))
    (list :name "cl-symbol(hyperspec)"
          :desc "Lookup a symbol in an interactive SLIME REPL or common lisp buffer using the hyperspec"
          :optp (list 'slime-repl-mode 'lisp-mode)
          :reqp (lambda () (cl-every #'fboundp '(hyperspec-lookup)))
          :atpt #'symbol-at-point
          :actn (lambda (thingy) (hyperspec-lookup (format "%s" thingy))))
    (list :name "cl-symbol(slime)"
          :desc "Lookup a symbol in an interactive SLIME REPL or common lisp buffer using slime-describe-symbol"
          :reqp (lambda () (and (boundp 'slime-net-processes)                ;; List of lisp connections
                                (boundp 'slime-describe-symbol)              ;; Needed to lookup symbol
                                (not (zerop (length slime-net-processes))))) ;; Need a connected lisp
          :optp (list 'slime-repl-mode 'lisp-mode)
          :atpt (lambda () (when-let* ((sym-thingy (symbol-at-point))
                                       (str-thingy (substring-no-properties (symbol-name sym-thingy))))
                             (if (string-match "^[:']" str-thingy)
                                 (substring str-thingy 1)
                                 str-thingy)))
          :actn (lambda (thingy) (slime-describe-symbol thingy)))
    (list :name "symbol(devdocs.io)"
          :desc "Lookup a symbol via devdocs.io for ruby, perl, & python buffers using browse-url (emacs)"
          :optp (list 'ruby-mode 'perl-mode 'python-mode 'julia-mode 'cmake-mode)
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
    (list :name "julia-symbol"
          :desc "Search for a Julia symbol on docs.julialang.org using browse-url (emacs)"
          :optp (list 'julia-mode)
          :atpt #'symbol-at-point
          :actn (lambda (thingy) (browse-url (concat "https://docs.julialang.org/en/v1.12/?q=" (url-hexify-string (format "%s" thingy))))))
    (list :name "cmake-symbol"
          :desc "Lookup a symbol via cmake.org using browse-url (emacs)"
          :optp (list 'cmake-mode)
          :atpt #'symbol-at-point
          :actn (lambda (thingy) (browse-url (concat "https://cmake.org/cmake/help/latest/search.html?q=" (url-hexify-string (format "%s" thingy))))))
    (list :name "C/CPP-symbol"
          :desc "Search for a c/c++ symbol on cppreference.com using browse-url"
          :optp (list 'c++-mode 'c-mode)
          :atpt #'symbol-at-point
          :actn (lambda (thingy) (browse-url (concat "https://cppreference.com/index.php?search=" (url-hexify-string (format "%s" thingy))))))
    (list :name "matlab-symbol"
          :desc "Search for a Matlab symbol on https://www.mathworks.com/search using browse-url (emacs)"
          :optp (list 'octave-mode 'matlab-mode)
          :atpt #'symbol-at-point
          :actn (lambda (thingy) (browse-url (concat "https://www.mathworks.com/search/user-center?q=" (url-hexify-string (format "%s" thingy)) "&app=documentation&page=1"))))
    ;; List after other "symbol" methods because we probably want to use one of them if they matched
    (list :name "symbol-bing"
          :desc "Search bing for captured symbol with major-mode name as search context using browse-url (emacs)."
          :optp (list 'ruby-mode 'perl-mode 'python-mode 'julia-mode 'c++-mode 'f90-mode 'c-mode 'emacs-lisp-mode
                      'lisp-interaction-mode 'lisp-mode 'fortran-mode 'javascript-mode 'java-mode 'matlab-mode
                      'octave-mode 'cmake-mode)
          :atpt #'symbol-at-point
          :actn (lambda (thingy) (browse-url (concat "https://www.bing.com/search?q="
                                                     (url-hexify-string (concat
                                                                         "+\""
                                                                         (let ((tmp (string-remove-suffix "-mode" (symbol-name major-mode))))
                                                                           (setq tmp (string-replace "f90"              "fortran"    tmp))
                                                                           (setq tmp (string-replace "lisp-interaction" "emacs lisp" tmp)))
                                                                         "\" "
                                                                         "+\""
                                                                         (format "%s" thingy)
                                                                         "\""))))))
    ;; Stuff with super specific match rules, so if they match we probably want to use them.
    (list :name "C-header"
          :desc "Lookup a c header file via cppreference.com using browse-url (emacs)"
          :optp (list 'c-mode)
          :atpt (lambda () (and (thing-at-point-looking-at "^#include *<\\([^>]+\\)\\.h>" 50) (match-string 1)))
          :actn (lambda (thingy) (browse-url (concat "https://en.cppreference.com/c/header/" (url-hexify-string (format "%s" thingy))))))
    (list :name "CPP-header"
          :desc "Lookup a c++ header file via cppreference.com using browse-url (emacs)"
          :optp (list 'c++-mode)
          :atpt (lambda () (and (thing-at-point-looking-at "^#include *<\\([^>]+\\)>" 50) (match-string 1)))
          :actn (lambda (thingy)
                  (let* ((thingy-str (if (stringp thingy)
                                         thingy
                                         (symbol-name thingy)))
                         (thingy-fix (if (string-suffix-p ".h" thingy-str)
                                         (concat "c" (string-remove-suffix ".h" thingy-str))
                                         thingy-str)))
                    (browse-url (concat "https://en.cppreference.com/w/cpp/header/" (url-hexify-string thingy-fix))))))
    (list :name "STM32"
          :desc "Search for a STM32/NUCLEO part on st.com using browse-url (emacs)"
          :atpt (lambda () (and (thing-at-point-looking-at "\\b\\(NUCLEO-[A-Z0-9]+\\|STM32[A-Z][A-Z0-9]+\\)\\b" 20) (match-string 1)))
          :actn (lambda (thingy) (browse-url (concat "https://search.st.com/?activeSource=%22Search%22&queryText=%22" (url-hexify-string thingy) "%22"))))
    (list :name "ISBN"
          :desc "Lookup an ISBN (10 or 13) number on isbnsearch.org using browse-url (emacs)"
          :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([0-9]\\{10\\}\\|[0-9]-[0-9]\\{6\\}-[0-9][0-9]-[0-9]\\|[0-9]\\{13\\}\\|[0-9]\\{3\\}-[0-9]-[0-9]\\{5\\}-[0-9]\\{3\\}-[0-9]\\)\\b" 25) (match-string 1)))
          :actn (lambda (thingy) (browse-url (concat "https://isbnsearch.org/isbn/" (url-hexify-string (replace-regexp-in-string "[^0-9]" "" thingy))))))
    (when (executable-find "git")
      (list :name "git-commit"
            :desc "Lookup a git commit via a full 40 character hexadecimal commit ID."
            :reqp (lambda () (file-directory-p ".git"))
            :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([0-9a-f]\\{40\\}\\)\\b" 41) (match-string 1)))
            :tokp (lambda (q) (and (stringp q) (string-match-p "\\`[0-9a-f]\\{40\\}\\'" q)))
            :actn "git show %Q"))
    (when (executable-find "git")
      (list :name "git-commit-ediff"
            :desc "Ediff a file that changed between a git commit (identified by a full 40 character hexadecimal commit ID) and working."
            :reqp (lambda () (file-directory-p ".git"))
            :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([0-9a-f]\\{40\\}\\)\\b" 41) (match-string 1)))
            :tokp (lambda (q) (and (stringp q) (string-match-p "\\`[0-9a-f]\\{40\\}\\'" q)))
            :actn (lambda (thingy)
                    (let ((changed-files (process-lines "git" "diff" "--name-only" thingy)))
                      (unless changed-files (error "Could not construct changed file list!"))
                      (let ((file-to-diff (ido-completing-read "File to diff: " changed-files nil t)))
                        (unless file-to-diff (error "Something went wrong reading file!"))
                        (vc-version-ediff (list file-to-diff) thingy nil))))))
   ;; Common stuff
    (list :name "man"
          :desc "Look for a UNIX man page via man (emacs)."
          :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([a-z0-9_-]+\\)\\b" 20) (match-string 1)))
          :actn #'man)
    (list :name "file"
          :desc "Look up file data via fstat.pl or stat (shell)."
          :atpt (lambda () (and-let* ((raw-fname (ffap-guess-file-name-at-point))
                                      (          (file-exists-p raw-fname))
                                      (exp-fname (expand-file-name raw-fname)))))
          :actn (if-let* ((tmp (locate-file "fstat" exec-path (list ".pl"))))
                    "fstat.pl '%Q'"
                  "stat '%Q'"))
   ;; Less common things
    (list :name "URL"
          :desc "Hand URL to browser using browse-url (emacs)."
          :atpt (lambda () (thing-at-point 'url))
          :actn #'browse-url)
    (list :name "dictionary"
          :desc "Look up a word via dictionary.reference.com using browse-url (emacs)"
          :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([a-zA-Z'-]+\\)\\b" 20) (match-string 1)))
          :actn (lambda (thingy) (browse-url (concat "https://www.merriam-webster.com/dictionary/" (url-hexify-string thingy) ""))))
    (when (executable-find "getent")
      (list :name "gid"
            :desc "Lookup a numeric group ID via getent (shell)."
            :atpt (lambda () (thing-at-point 'number))
            :tokp "\\`[1-9][0-9]*\\'"
            :actn "getent group %Q"))
    (when (executable-find "getent")
      (list :name "gname"
            :desc "Lookup a group name (gname) via getent (shell)."
            :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([.a-zA-Z0-9_-]+\\)\\b" 20) (match-string 1)))
            :actn "getent group %Q"))
    (when (executable-find "getent")
      (list :name "uid"
            :desc "Lookup a numeric user ID via getent (shell)."
            :atpt (lambda () (thing-at-point 'number))
            :tokp "\\`[1-9][0-9]*\\'"
            :actn "getent passwd %Q"))
    (when (executable-find "getent")
      (list :name "uname"
            :desc "Look up a user name (uname) with getent (shell)."
            :atpt (lambda () (let ((tmp (and (thing-at-point-looking-at "\\b\\([a-zA-Z][a-zA-Z0-9_-]+\\)\\b" 20) (match-string 1))))
                               (and tmp (cl-find tmp (system-users) :test #'string-equal))))
            :actn "getent passwd %Q"))
    (when (and (eq system-type 'windows-nt) (executable-find "PowerShell"))
      (list :name "win-user-sid"
            :desc "Lookup a windows SID for user (PowerShell)."
            :atpt (lambda () (and (thing-at-point-looking-at "\\b[sS]-1\\(-[0-9]+\\)+\\b" 100) (match-string 0)))
            :tokp "\\`[sS]-1\\(-[0-9]+\\)+\\'"
            :qokp (lambda (q) (string-match-p "\\`S-1\\(-[0-9]+\\)\\'" q))
            :actn "PowerShell -Command 'Get-LocalUser -SID %Q | Format-List'"))
    (when (and (eq system-type 'windows-nt) (executable-find "PowerShell"))
      (list :name "win-user-name"
            :desc "Lookup a windows user name (PowerShell)."
            ;; The TaP only detects names with no spaces
            :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([^]\\\\/:;|=,+*?<>@[:space:]\n\r[]+\\)\\b" 40) (match-string 1)))
            :actn "PowerShell -Command 'Get-LocalUser -Name \"%Q\" | Format-List'"))
    (when (and (eq system-type 'windows-nt) (executable-find "PowerShell"))
      (list :name "win-group-name"
            :desc "Lookup a windows group name (PowerShell)."
            ;; The TaP only detects names with no spaces
            :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([^]\\\\/:;|=,+*?<>@[:space:]\n\r[]+\\)\\b" 40) (match-string 1)))
            :actn "PowerShell -Command 'Get-LocalGroup -Name \"%Q\" | Format-List'"))
    (when (and (eq system-type 'windows-nt) (executable-find "PowerShell"))
      (list :name "win-group-sid"
            :desc "Lookup a windows SID for group (PowerShell)."
            :atpt (lambda () (and (thing-at-point-looking-at "\\b[sS]-1\\(-[0-9]+\\)+\\b" 100) (match-string 0)))
            :tokp "\\`[sS]-1\\(-[0-9]+\\)+\\'"
            :qokp (lambda (q) (string-match-p "\\`S-1\\(-[0-9]+\\)\\'" q))
            :actn "PowerShell -Command 'Get-LocalGroup -SID %Q | Format-List'"))
    (list :name "DNS"
          :desc "Lookup host name via dns-lookup-host (emacs)."
          ;; The TaP only detects a limited number of TLDs
          :atpt (lambda () (and (thing-at-point-looking-at "\\([.a-zA-Z0-9_-]+\\.\\(com\\|edu\\|org\\|gov\\|me\\)\\)\\b" 20) (match-string 1)))
          :tokp "\\`[.a-zA-Z0-9_-]+\\'"
          :actn #'dns-lookup-host)
    (list :name "IPv4"
          :desc "Lookup IPv4 address via dns-lookup-host (emacs)."
          :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\\)\\b" 20) (match-string 1)))
          :tokp (lambda (q) (and (stringp q)
                                 (string-match "\\`\\(\\([0-9]+\\)\\.\\([0-9]+\\)\\.\\([0-9]+\\)\\.\\([0-9]+\\)\\)\\'" q)
                                 (cl-every (lambda (x) (let ((y (string-to-number (match-string x q)))) (and (<= 0 y) (>= 255 y)))) '(2 3 4 5))))
          :actn #'dns-lookup-host)
    (list :name "DOI"
          :desc "Lookup a DOI on doi.org using browse-url (emacs)"
          :atpt (lambda () (and (thing-at-point-looking-at "\\b\\(doi:\\)\\{0,1\\}\\(10\\.[^/[:space:]\n\r]+/[^[:space:]\n\r]+\\)\\b" 100) (match-string 2)))
          :actn (lambda (thingy) (browse-url (concat "https://doi.org/" (url-hexify-string thingy)))))
    (list :name "ADS_Bibcode"
          :desc "Lookup a bibcode on ui.adsabs.harvard.edu using browse-url (emacs)"
          :atpt (lambda () (and (thing-at-point-looking-at "\\bbibcode:[[:space:]]*\\([^[:space:]\n\r]+\\)\\b" 100) (match-string 1)))
          :actn (lambda (thingy) (browse-url (concat "https://ui.adsabs.harvard.edu/search/fq=%7B!type%3Daqp%20v%3D%24fq_database%7D&fq_database=(database%3Aastronomy%20OR%20database%3Aphysics)&q=bibcode%3A" 
                                                     (url-hexify-string thingy) 
                                                     "&sort=date%20desc%2C%20bibcode%20desc&p_=0"))))
    (list :name "Zotero"
          :desc "Lookup a Zotero match-specifier (emacs/zotreo/browser)"
          :reqp (lambda () (require 'mjr-zotero nil t))
          :atpt (lambda () (mjr-zotero-match-specifier-at-point t))
          :actn (lambda (thingy) (or (mjr-zotero-db-cache-open-item thingy t)
                                     (when (stringp thingy)
                                       (mjr-zotero-connector-open-item thingy)))))
    (list :name "OIES"
          :desc "Lookup a sequence of integers on oeis.org using browse-url (emacs)"
          :atpt (lambda () (and (thing-at-point-looking-at "\\b\\([[:digit:]]+\\([,; \t]+?[[:digit:]]+\\)\\{4,\\}\\)\\b" 100) (match-string 1)))
          :tokp (lambda (q) (message "HI") (and (stringp q) (string-match "\\`[[:space:]]*[[:digit:]]+\\([,; \t]+?[[:digit:]]+\\)\\{4,\\}[[:space:]]*\\'" q)))
          :actn (lambda (thingy) (browse-url (concat "https://oeis.org/search?q="
                                                     (url-hexify-string (replace-regexp-in-string "[^[:digit:]]+" "," (string-trim thingy)))
                                                     "&language=english&go=Search"))))
    )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defgroup mjr-thingy-lookeruper nil
  "mjr-thingy-lookeruper"
  :group 'external
  :group 'environment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defcustom mjr-thingy-lookeruper-methods mjr-thingy-lookeruper-built-in-methods
  "Lookup methods available to `mjr-thingy-lookeruper'.
A list lookup methods for `mjr-thingy-lookeruper'.  Each entry is a property list:
 - :name -- A string with the name of the method (Required)
 * :desc -- A string with a description of the method (Optional)
 * :reqp -- Predicate function checking runtime requirements for method.   
 * :optp -- Predicate function checking runtime suggestions for method.  Suppressed with prefix argument.
            This may be a list of mode symbols in which case the buffer `major-mode' must be on this list
 * :tokp -- Predicate function checking the thing for validity
            This can be a STRING in which case the thingy is checked by `string-match-p' with :totp as the regex.
 * :atpt -- A function used to thingy (usually a string but not necessarily) from buffer.  (Optional)
            If missing or nil, the method may only be used with an active region.
 * :actn -- A function or shell command string used to perform the lookup.  (Required)
            - In shell command strings %U is replaced with the URL hexified thingy, and %Q will be replaced with the thingy.
The functions `mjr-thingy-lookeruper-get-built-in', `mjr-thingy-lookeruper-add-method', and `mjr-thingy-lookeruper-delete-method'
may be helpfull to manage this list."
  :type '(repeat (plist :key-type (choice (const :name)
                                          (const :desc)
                                          (const :reqp)
                                          (const :optp)
                                          (const :tokp)
                                          (const :atpt)
                                          (const :actn))))
  :group 'mjr-thingy-lookeruper)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-get-built-in (method-name)
  "Return the built-in method by name.
Built-In methods are stored in `mjr-thingy-lookeruper-built-in-methods'."
  (cl-find-if (lambda (x) (string-equal method-name (plist-get x :name))) mjr-thingy-lookeruper-built-in-methods))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-get-method (method-name)
  "Return the method by name.
Built-In methods are stored in `mjr-thingy-lookeruper-methods'."
  (cl-find-if (lambda (x) (string-equal method-name (plist-get x :name))) mjr-thingy-lookeruper-methods))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-add-method (method-properties)
  "Add a new method to `mjr-thingy-lookeruper-methods'.  
Silently return doing nothing if METHOD-PROPERTIES is NIL.
If METHOD-PROPERTIES is non-NIL, then an error occurs if METHOD-PROPERTIES:
  - Is not a plist
  - Is missing a :name property
  - Is missing an :actn property
  - Has the same name as an existing method already on `mjr-thingy-lookeruper-methods'."
  (when (not (plistp method-properties))
    (error "mjr-thingy-lookeruper-add-method: Method is not a valid property list"))
  (when (not (plist-get method-properties :name))
    (error "mjr-thingy-lookeruper-add-method: Peoperty :name must be present and non-nil"))
  (when (not (plist-get method-properties :actn))
    (error "mjr-thingy-lookeruper-add-method: Peoperty :actn must be present and non-nil"))
  (when (mjr-thingy-lookeruper-get-method (plist-get method-properties :name))
    (error "mjr-thingy-lookeruper-add-method: Peoperty method with the same name is already on mjr-thingy-lookeruper-methods list!"))
  (add-to-list 'mjr-thingy-lookeruper-methods method-properties))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper-delete-method (method-name)
  "Delete method with given name from mjr-thingy-lookeruper-methods, and return properties of deleted method.  Return nil if nothing was deleted."
  (let ((method-properties (mjr-thingy-lookeruper-get-method method-name)))
    (setq mjr-thingy-lookeruper-methods
          (cl-remove-if (lambda (x) (string-equal method-name (plist-get x :name))) mjr-thingy-lookeruper-methods))
    method-properties))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-thingy-lookeruper (the-method the-thingy)
  "Extensible looker upper of thingys at the point or in the active region.

Interactive use (while not the true order of events in the code, this step-wise description is logically equivalent and easier to understand):
  Step 1: Filter the list of of eligible methods based on the :reqp predicate
  Step 2: If no prefix argument is provided, then filter the list of of eligible methods based on the :optp predicate 
  Step 3: Filter the list of methods that are eligible to use based on context of the point.
    - If the region is not active .. Each method's tap function is used to determine if the method is eligible for execution and to extract the thingy.
    - If the region is active ...... All methods are considered eligible for execution with the contents of the active region used as the thingy.
  Step 4: Filter the list of of eligible methods based on the :qokp predicate
  Step 5: Query the user
    - Only one eligible query ...... Use that method
    - Multiple eligible queries .... Query the user to choose a method.
    - No eligible queries .......... Error
Non-Interactive use: Lookup THE-THINGY via THE-METHOD.
  - THE-METHOD is the :NAME, a string, of a method stored in `mjr-thingy-lookeruper-methods'.
  - THE-THINGY is an object, usually a string, to look up with the named method.
  - If THE-METHOD is not found on `mjr-thingy-lookeruper-methods', then error.
  - None of the method predicates are evaluated -- i.e. the lookup is always attempted
Results:
 - Methods that use a shell command place the results in the buffer *thingy-lookup-results*.
 - Methods that use a Lisp function
   - If the function returns a string, the string is printed as an Emacs message.
   - Many Lisp function lookup methods may provide a special environment for displaying the results.
Variables:
 - `mjr-thingy-lookeruper-methods' .. Defines lookup methods.  Examples include uname, gname, uid, gid, host name, dictionary word, and Google search."
  (interactive (let* ((region-string (and transient-mark-mode (region-active-p) (mark) (buffer-substring-no-properties (region-beginning) (region-end))))
                      (candidates    (cl-loop for cur-method-properties in mjr-thingy-lookeruper-methods
                                              for thingy = (when (let ((cur-method-reqp (plist-get cur-method-properties :reqp))
                                                                       (cur-method-optp (plist-get cur-method-properties :optp)))
                                                                   (and (or (null cur-method-reqp)       ;; Check :reqp
                                                                            (funcall cur-method-reqp))
                                                                        (or current-prefix-arg           ;; Check :optp
                                                                            (null cur-method-optp)
                                                                            (if (listp cur-method-optp)
                                                                                (member major-mode cur-method-optp)
                                                                                (funcall cur-method-optp)))))
                                                             (let ((pot-thingy (or region-string ;; Get potential thingy from buffer
                                                                                   (when-let* ((cur-method-tap (plist-get cur-method-properties :atpt)))
                                                                                     (funcall cur-method-tap)))))
                                                               (when pot-thingy ;; We got something from the buffer
                                                                 (when (let ((cur-method-tokp (plist-get cur-method-properties :tokp)))
                                                                         (or (null cur-method-tokp)  ;; Check our potential thingy with :tokp
                                                                             (if (stringp cur-method-tokp)
                                                                                 (string-match-p cur-method-tokp (format "%s" pot-thingy))
                                                                                 (funcall cur-method-tokp pot-thingy))))
                                                                   pot-thingy))))
                                              when thingy
                                              collect (list (plist-get cur-method-properties :name) thingy))))
                 (unless candidates
                   (error "mjr-thingy-lookeruper: Unable to locate suitable lookup methods"))
                 (if (null (cdr candidates))
                     (car candidates)
                     (let ((da-method (if (and (boundp 'ido-everywhere) ido-everywhere)
                                          (ido-completing-read "Lookup Method: " (mapcar #'car candidates) nil t)
                                          (completing-read     "Lookup Method: " (mapcar #'car candidates) nil t))))
                       (assoc da-method candidates #'string-equal)))))
  (if (stringp the-thingy)
      (setq the-thingy (substring-no-properties the-thingy)))
  (message "mjr-thingy-lookeruper: '%s' via '%s'" the-thingy the-method)
  (let ((the-method-properties (mjr-thingy-lookeruper-get-method the-method)))
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

;;(mjr-install-mjr-packages :reinstall :git 'mjr-thingy-lookeruper)

;;; mjr-thingy-lookeruper.el ends here

