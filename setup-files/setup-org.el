;; Time-stamp: <2016-11-29 01:38:06 kmodi>
;; Hi-lock: (("\\(^;\\{3,\\}\\)\\( *.*\\)" (1 'org-hide prepend) (2 '(:inherit org-level-1 :height 1.3 :weight bold :overline t :underline t) prepend)))
;; Hi-Lock: end

;; Org Mode

;; Contents:
;;
;;  Org Variables
;;  Agenda and Capture
;;  Org Goto
;;  Source block languages
;;  Defuns
;;  Org Entities
;;  org-link-ref - Support markdown-style link id references
;;  Diagrams
;;  Org Babel
;;  org-tree-slide
;;  Org Cliplink
;;  Htmlize Region→File
;;  Include src lines
;;  Convert included pdf to image
;;  Extract image from included .zip
;;  Org Export
;;    ox-latex - LaTeX export
;;    ox-html - HTML export
;;    ox-beamer - Beamer export
;;    ox-reveal - Presentations using reveal.js
;;    ox-twbs - Twitter Bootstrap
;;    ox-minutes - Meeting Minutes ASCII export
;;    ox-odt - ODT, doc export
;;    Org Export Customization
;;  Easy Templates
;;  Bindings
;;  Notes

(use-package org
  :preface
  (progn
    ;; If `org-load-version-dev' is non-nil, remove the older versions of org
    ;; from the `load-path'.
    (when (bound-and-true-p org-load-version-dev)
      (>=e "25.0" ; `directory-files-recursively' is not available in older emacsen
          (let ((org-stable-install-path (car (directory-files-recursively
                                               package-user-dir
                                               "org-plus-contrib-[0-9]+"
                                               :include-directories))))
            (setq load-path (delete org-stable-install-path load-path))
            ;; Also ensure that the associated path is removed from Info search list
            (setq Info-directory-list (delete org-stable-install-path
                                              Info-directory-list))

            ;; Also delete the path to the org directory that ships with emacs
            (dolist (path load-path)
              (when (string-match-p (concat "emacs/"
                                            (replace-regexp-in-string
                                             "\\.[0-9]+\\'" "" emacs-version)
                                            "/lisp/org\\'")
                                    path)
                (setq load-path (delete path load-path)))))))

    ;; Modules that should always be loaded together with org.el.
    ;; `org-modules' default: '(org-w3m org-bbdb org-bibtex org-docview org-gnus
    ;;                          org-info org-irc org-mhe org-rmail)
    (setq org-modules '(org-info))

    ;; Set my default org-export backends. This variable needs to be set before
    ;; org.el is loaded.
    (setq org-export-backends '(ascii html latex))
    ;; Do not open links of mouse left clicks.
    ;; Default behavior caused inline images in org buffers to pop up in their
    ;; own buffers when left clicked on by mistake. I can still intentionally
    ;; open links and such images in new buffers by doing C-c C-o.
    (setq org-mouse-1-follows-link nil))
  :mode ("\\.org\\'" . org-mode)
  :config
  (progn
;;; Org Variables
    (setq org-agenda-archives-mode nil) ; required in org 8.0+
    (setq org-agenda-skip-comment-trees nil)
    (setq org-agenda-skip-function nil)

    (setq org-src-fontify-natively t) ; fontify code in code blocks
    ;; Display entities like \tilde, \alpha, etc in UTF-8 characters
    (setq org-pretty-entities t)
    ;; Render subscripts and superscripts in org buffers
    (setq org-pretty-entities-include-sub-superscripts t)

    ;; Allow _ and ^ characters to sub/super-script strings but only when
    ;; string is wrapped in braces
    (setq org-use-sub-superscripts '{}) ; in-buffer rendering

    ;; Single key command execution when at beginning of a headline
    (setq org-use-speed-commands t) ; ? speed-key opens Speed Keys help
    (setq org-speed-commands-user '(("m" . org-mark-subtree)))

    (setq org-hide-leading-stars  t)
    ;; Prevent auto insertion of blank lines before headings and list items
    (setq org-blank-before-new-entry '((heading)
                                       (plain-list-item)))

    ;; fold / overview  - collapse everything, show only level 1 headlines
    ;; content          - show only headlines
    ;; nofold / showall - expand all headlines except the ones with :archive:
    ;;                    tag and property drawers
    ;; showeverything   - same as above but without exceptions
    (setq org-startup-folded 'showall)
    ;; http://orgmode.org/manual/Clean-view.html
    ;; Enable `org-indent-mode' on org startup
    (setq org-startup-indented t)

    (setq org-log-done 'timestamp) ; Insert only timestamp when closing an org TODO item
    ;; (setq org-log-done 'note) ; Insert timestamp and note when closing an org TODO item
    ;; http://orgmode.org/manual/Closing-items.html
    (setq org-todo-keywords '((sequence "TODO" "SOMEDAY" "CANCELED" "DONE")))
    (setq org-todo-keyword-faces
          '(("TODO"     . org-todo)
            ("SOMEDAY"  . (:foreground "black" :background "#FFEF9F"))
            ("CANCELED" . (:foreground "#94BFF3" :weight bold :strike-through t))
            ("DONE"     . (:foreground "black" :background "#91ba31"))
            ))
    ;; Block entries from changing state to DONE while they have children
    ;; that are not DONE - http://orgmode.org/manual/TODO-dependencies.html
    (setq org-enforce-todo-dependencies t)

    ;; http://emacs.stackexchange.com/a/17513/115
    (setq org-special-ctrl-a/e '(t ; For C-a. Possible values: nil, t, 'reverse
                                 . t)) ; For C-e. Possible values: nil, t, 'reverse

    (setq org-catch-invisible-edits 'smart) ; http://emacs.stackexchange.com/a/2091/115
    (setq org-indent-indentation-per-level 1) ; default = 2

    ;; Number of empty lines needed to keep an empty line between collapsed trees.
    ;; If you leave an empty line between the end of a subtree and the following
    ;; headline, this empty line is hidden when the subtree is folded.
    ;; Org-mode will leave (exactly) one empty line visible if the number of
    ;; empty lines is equal or larger to the number given in this variable.
    (setq org-cycle-separator-lines 2) ; default = 2

    ;; Prevent renumbering/sorting footnotes when a footnote is added/removed.
    ;; Doing so would create a big diff in an org file containing lot of
    ;; footnotes even if only one footnote was added/removed.
    (setq org-footnote-auto-adjust nil) ; `'sort' - only sort
                                        ; `'renumber' - only renumber
                                        ; `t' - sort and renumber
                                        ; `nil' - do nothing (default)

    ;; Make firefox the default web browser for applications like viewing
    ;; an html file exported from org ( C-c C-e h o )
    (when (executable-find "firefox")
      (add-to-list 'org-file-apps '("\\.x?html\\'" . "firefox %s")))

    ;; Do not add the default indentation of 2 spaces when exiting the *Org Src*
    ;; buffer (the buffer you get when you do «C-c '» while in a block like
    ;; #+BEGIN_SRC
    (setq org-edit-src-content-indentation 0)

    ;; Do NOT try to auto-evaluate entered text as formula when I begin a field's
    ;; content with "=" e.g. |=123=|. More often than not, I use the "=" to
    ;; simply format that field text as verbatim. As now the below variable is
    ;; set to nil, formula will not be automatically evaluated when hitting TAB.
    ;; But you can still using ‘C-c =’ to evaluate it manually when needed.
    (setq org-table-formula-evaluate-inline nil) ; default = t

;;; Agenda and Capture
    ;; http://orgmode.org/manual/Template-elements.html
    ;; http://orgmode.org/manual/Template-expansion.html
    (setq org-capture-templates
          '(("j" "Journal" entry ; `org-capture' binding + j
             (file+datetree "journal.org")
             "\n* %?\n  Entered on %U")
            ("n" "Note" entry ; `org-capture' binding + n
             (file "notes.org")
             "\n* %?\n  Context:\n    %i\n  Entered on %U")))

    (defvar modi/one-org-agenda-file (expand-file-name "agenda.files"
                                                       org-directory)
      "One file to contain a list of all org agenda files.")
    (setq org-agenda-files modi/one-org-agenda-file)
    (unless (file-exists-p modi/one-org-agenda-file)
      ;; http://stackoverflow.com/a/14072295/1219634
      ;; touch `modi/one-org-agenda-file'
      (write-region "" :ignore modi/one-org-agenda-file))

    ;; http://sachachua.com/blog/2013/01/emacs-org-task-related-keyboard-shortcuts-agenda/
    (defun sacha/org-agenda-done (&optional arg)
      "Mark current TODO as done.
This changes the line at point, all other lines in the agenda referring to
the same tree node, and the headline of the tree node in the Org-mode file."
      (interactive "P")
      (org-agenda-todo "DONE"))

    (defun sacha/org-agenda-mark-done-and-add-followup ()
      "Mark the current TODO as done and add another task after it.
Creates it at the same level as the previous task, so it's better to use
this with to-do items than with projects or headings."
      (interactive)
      (org-agenda-todo "DONE")
      (org-agenda-switch-to)
      (org-capture 0 "t")
      (org-metadown 1)
      (org-metaright 1))

    (defun sacha/org-agenda-new ()
      "Create a new note or task at the current agenda item.
Creates it at the same level as the previous task, so it's better to use
this with to-do items than with projects or headings."
      (interactive)
      (org-agenda-switch-to)
      (org-capture 0))

    (add-hook 'org-agenda-mode-hook
              (lambda ()
                (bind-keys
                 :map org-agenda-mode-map
                  ("x" . sacha/org-agenda-done)
                  ("X" . sacha/org-agenda-mark-done-and-add-followup)
                  ("N" . sacha/org-agenda-new))))

;;; Org Goto
    (defun modi/org-goto-override-bindings (&rest _)
      "Override the bindings set by `org-goto-map' function."
      (org-defkey org-goto-map "\C-p" #'outline-previous-visible-heading)
      (org-defkey org-goto-map "\C-n" #'outline-next-visible-heading)
      (org-defkey org-goto-map "\C-f" #'outline-forward-same-level)
      (org-defkey org-goto-map "\C-b" #'outline-backward-same-level)
      org-goto-map)
    (advice-add 'org-goto-map :after #'modi/org-goto-override-bindings)

;;; Source block languages
    ;; Change the default app for opening pdf files from org
    ;; http://stackoverflow.com/a/9116029/1219634
    (setcdr (assoc "\\.pdf\\'" org-file-apps) "acroread %s")

    (add-to-list 'org-src-lang-modes '("systemverilog" . verilog))
    (add-to-list 'org-src-lang-modes '("dot"           . graphviz-dot))

;;; Defuns
    ;; http://emacs.stackexchange.com/a/13854/115
    ;; Heading▮   --(C-c C-t)--> * TODO Heading▮
    ;; * Heading▮ --(C-c C-t)--> * TODO Heading▮
    (defun modi/org-first-convert-to-heading (orig-fun &rest args)
      (let ((is-heading))
        (save-excursion
          (forward-line 0)
          (when (looking-at "^\\*")
            (setq is-heading t)))
        (unless is-heading
          (org-toggle-heading))
        (apply orig-fun args)))
    (advice-add 'org-todo :around #'modi/org-first-convert-to-heading)

    (defun modi/org-return-no-indent (&optional n)
      "Make `org-return' repeat the number passed through the argument"
      (interactive "p")
      (dotimes (cnt n)
        (org-return nil)))

    ;; http://emacs.stackexchange.com/a/10712/115
    (defun modi/org-delete-link ()
      "Replace an org link of the format [[LINK][DESCRIPTION]] with DESCRIPTION.
If the link is of the format [[LINK]], delete the whole org link.

In both the cases, save the LINK to the kill-ring.

Execute this command while the point is on or after the hyper-linked org link."
      (interactive)
      (when (derived-mode-p 'org-mode)
        (let ((search-invisible t) start end)
          (save-excursion
            (when (re-search-backward "\\[\\[" nil :noerror)
              (when (re-search-forward "\\[\\[\\(.*?\\)\\(\\]\\[.*?\\)*\\]\\]"
                                       nil :noerror)
                (setq start (match-beginning 0))
                (setq end   (match-end 0))
                (kill-new (match-string-no-properties 1)) ; Save link to kill-ring
                (replace-regexp "\\[\\[.*?\\(\\]\\[\\(.*?\\)\\)*\\]\\]" "\\2"
                                nil start end)))))))

    ;; Bind the "org-table-*" command ONLY when the point is in an org table.
    ;; http://emacs.stackexchange.com/a/22457/115
    (bind-keys
     :map org-mode-map
     :filter (org-at-table-p)
      ("C-c ?" . org-table-field-info)
      ("C-c SPC" . org-table-blank-field)
      ("C-c +" . org-table-sum)
      ("C-c =" . org-table-eval-formula)
      ("C-c `" . org-table-edit-field)
      ("C-#" . org-table-rotate-recalc-marks)
      ("C-c }" . org-table-toggle-coordinate-overlays)
      ("C-c {" . org-table-toggle-formula-debugger))

    ;; Recalculate all org tables in the buffer when saving.
    ;; http://emacs.stackexchange.com/a/22221/115
    ;; Thu Jul 14 17:06:28 EDT 2016 - kmodi
    ;; Do not enable the buffer-wide recalculation by default because if an org
    ;; buffer has an org-table formula (like "#+TBLFM: $1=@#-1"), a *Calc*
    ;; buffer is created when `org-table-recalculate-buffer-tables' is run each
    ;; time.
    (defvar-local modi/org-table-enable-buffer-wide-recalculation nil
      "When non-nil, all the org tables in the buffer will be recalculated when
saving the file.

This variable is buffer local.")
    ;; Mark `modi/org-table-enable-buffer-wide-recalculation' as a safe local
    ;; variable as long as its value is t or nil. That way you are not prompted
    ;; to add that to `safe-local-variable-values' in custom.el.
    (put 'modi/org-table-enable-buffer-wide-recalculation 'safe-local-variable #'booleanp)

    (defun modi/org-table-recalculate-buffer-tables (&rest args)
      "Wrapper function for `org-table-recalculate-buffer-tables' that runs
that function only if `modi/org-table-enable-buffer-wide-recalculation' is
non-nil.

Also, this function has optional ARGS that is needed for any function that is
added to `org-export-before-processing-hook'. This would be useful if this
function is ever added to that hook."
      (when modi/org-table-enable-buffer-wide-recalculation
        (org-table-recalculate-buffer-tables)))

    (defun modi/org-table-recalculate-before-save ()
      "Recalculate all org tables in the buffer before saving."
      (add-hook 'before-save-hook #'modi/org-table-recalculate-buffer-tables nil :local))
    (add-hook 'org-mode-hook #'modi/org-table-recalculate-before-save)

    (defun org-table-mark-field ()
      "Mark the current table field."
      (interactive)
      ;; Do not try to jump to the beginning of field if the point is already there
      (when (not (looking-back "|\\s-?"))
        (org-table-beginning-of-field 1))
      (set-mark-command nil)
      (org-table-end-of-field 1))

    (defhydra hydra-org-table-mark-field
      (:body-pre (org-table-mark-field)
       :color red
       :hint nil)
      "
   ^^      ^🠙^     ^^
   ^^      _p_     ^^
🠘 _b_  selection  _f_ 🠚          | org table mark ▯field▮ |
   ^^      _n_     ^^
   ^^      ^🠛^     ^^
"
      ("x" exchange-point-and-mark "exchange point/mark")
      ("f" (lambda (arg)
             (interactive "p")
             (when (eq 1 arg)
               (setq arg 2))
             (org-table-end-of-field arg)))
      ("b" (lambda (arg)
             (interactive "p")
             (when (eq 1 arg)
               (setq arg 2))
             (org-table-beginning-of-field arg)))
      ("n" next-line)
      ("p" previous-line)
      ("q" nil "cancel" :color blue))

    (bind-keys
     :map org-mode-map
     :filter (org-at-table-p)
      ("S-SPC" . hydra-org-table-mark-field/body))

;;; Org Entities
    ;; http://www.mail-archive.com/emacs-orgmode@gnu.org/msg100527.html
    ;; http://emacs.stackexchange.com/a/16746/115
    (defun modi/org-entity-get-name (char)
      "Return the entity name for CHAR. For example, return \"ast\" for *."
      (let ((ll (append org-entities-user
                        org-entities))
            e name utf8)
        (catch 'break
          (while ll
            (setq e (pop ll))
            (when (not (stringp e))
              (setq utf8 (nth 6 e))
              (when (string= char utf8)
                (setq name (car e))
                (throw 'break name)))))))

    (defun modi/org-insert-org-entity-maybe (&rest args)
      "When the universal prefix C-u is used before entering any character,
insert the character's `org-entity' name if available.

If C-u prefix is not used and if `org-entity' name is not available, the
returned value `entity-name' will be nil."
      ;; It would be fine to use just (this-command-keys) instead of
      ;; (substring (this-command-keys) -1) below in emacs 25+.
      ;; But if the user pressed "C-u *", then
      ;;  - in emacs 24.5, (this-command-keys) would return "^U*", and
      ;;  - in emacs 25.x, (this-command-keys) would return "*".
      ;; But in both versions, (substring (this-command-keys) -1) will return
      ;; "*", which is what we want.
      ;; http://thread.gmane.org/gmane.emacs.orgmode/106974/focus=106996
      (let ((pressed-key (substring (this-command-keys) -1))
            entity-name)
        (when (and (listp args) (eq 4 (car args)))
          (setq entity-name (modi/org-entity-get-name pressed-key))
          (when entity-name
            (setq entity-name (concat "\\" entity-name "{}"))
            (insert entity-name)
            (message (concat "Inserted `org-entity' "
                             (propertize entity-name
                                         'face 'font-lock-function-name-face)
                             " for the symbol "
                             (propertize pressed-key
                                         'face 'font-lock-function-name-face)
                             "."))))
        entity-name))

    ;; Run `org-self-insert-command' only if `modi/org-insert-org-entity-maybe'
    ;; returns nil.
    (advice-add 'org-self-insert-command :before-until #'modi/org-insert-org-entity-maybe)

;;; org-link-ref - Support markdown-style link id references
    (use-package org-link-ref
      :load-path "elisp/org-link-ref")

;;; Diagrams
    ;; http://pages.sachachua.com/.emacs.d/Sacha.html
    (setq org-ditaa-jar-path (expand-file-name
                              "ditaa.jar"
                              (concat user-emacs-directory "software/")))
    (setq org-plantuml-jar-path (expand-file-name
                                 "plantuml.jar"
                                 (concat user-emacs-directory "software/")))

;;; Org Babel
    (defvar modi/ob-enabled-languages '("emacs-lisp"
                                        "org"
                                        "latex"
                                        "dot" ; graphviz
                                        "ditaa"
                                        "plantuml"
                                        "awk"
                                        "shell")
      "List of languages for which the ob-* packages need to be loaded.")

    (defvar modi/ob-eval-unsafe-languages '("emacs-lisp"
                                            "shell")
      "List of languages which are unsafe for babel evaluation without
confirmation. Languages present in `modi/ob-enabled-languages' will be marked
as safe for babel evaluation except for the languages in this variable.")

    (let (ob-lang-alist)
      (dolist (lang modi/ob-enabled-languages)
        (add-to-list 'ob-lang-alist `(,(intern lang) . t)))
      (org-babel-do-load-languages 'org-babel-load-languages ob-lang-alist))

    (defun modi/org-confirm-babel-evaluate-fn (lang body)
      "Returns a non-nil value if the user should be prompted for execution,
or nil if no prompt is required.

Babel evaluation will happen without confirmation for the org src blocks for
the languages in `modi/ob-enabled-languages'."
      (let ((re-all-lang (regexp-opt modi/ob-enabled-languages 'words))
            (re-unsafe-lang (regexp-opt modi/ob-eval-unsafe-languages 'words))
            (unsafe t)) ; Set the return value `unsafe' to t by default
        (when (and (not (string-match-p re-unsafe-lang lang))
                   (string-match-p re-all-lang lang))
          (setq unsafe nil))
        ;; (message "re-all:%s\nre-unsafe:%s\nlang:%s\nbody:%S\nret-val:%S"
        ;; re-all-lang re-unsafe-lang lang body unsafe)
        unsafe))
    (setq org-confirm-babel-evaluate #'modi/org-confirm-babel-evaluate-fn)

;;; org-tree-slide
    ;; https://github.com/takaxp/org-tree-slide
    (use-package org-tree-slide
      :bind (:map modi-mode-map
             ("<C-S-f8>" . org-tree-slide-mode))
      :config
      (progn
        (setq org-tree-slide--lighter " Slide")

        (defvar modi/org-tree-slide-text-scale 3
          "Text scale ratio to default when `org-tree-slide-mode' is enabled.")

        (defun modi/org-tree-slide-set-profile ()
          "Customize org-tree-slide variables."
          (interactive)
          (setq modi/org-tree-slide-text-scale 2)
          (setq org-tree-slide-header nil)
          (setq org-tree-slide-slide-in-effect t)
          (setq org-tree-slide-heading-emphasis nil)
          (setq org-tree-slide-cursor-init t) ; Move cursor to the head of buffer
          (setq org-tree-slide-modeline-display 'lighter)
          (setq org-tree-slide-skip-done nil)
          (setq org-tree-slide-skip-comments t)
          (setq org-tree-slide-activate-message
                (concat "Starting org presentation. "
                        "Use arrow keys to navigate the slides."))
          (setq org-tree-slide-deactivate-message "Ended presentation.")
          (message "my custom `org-tree-slide' profile: ON"))

        (defvar modi/writegood-mode-state nil
          "Variable to store the state of `writegood-mode'.")

        (defun modi/org-tree-slide-start ()
          "Set up the frame for the slideshow."
          (interactive)
          (when (fboundp 'writegood-mode)
            (setq modi/writegood-mode-state writegood-mode)
            (writegood-mode -1))
          (modi/toggle-one-window :force-one-window) ; force 1 window
          (modi/org-tree-slide-set-profile)
          (text-scale-set modi/org-tree-slide-text-scale))
        (add-hook 'org-tree-slide-play-hook #'modi/org-tree-slide-start)

        (defun modi/org-tree-slide-stop()
          "Undo the frame setup for the slideshow."
          (interactive)
          (modi/toggle-one-window) ; toggle 1 window
          (when (and (fboundp 'writegood-mode)
                     modi/writegood-mode-state)
            (writegood-mode 1)
            (setq modi/writegood-mode-state nil))
          (text-scale-set 0))
        (add-hook 'org-tree-slide-stop-hook #'modi/org-tree-slide-stop)

        (defun modi/org-tree-slide-text-scale-reset ()
          "Reset time scale to `modi/org-tree-slide-text-scale'."
          (interactive)
          (text-scale-set modi/org-tree-slide-text-scale))

        (defun modi/org-tree-slide-text-scale-inc1 ()
          "Increase text scale by 1."
          (interactive)
          (text-scale-increase 1))

        (defun modi/org-tree-slide-text-scale-dec1 ()
          "Decrease text scale by 1."
          (interactive)
          (text-scale-decrease 1))

        (bind-keys
         :map org-tree-slide-mode-map
          ("<left>" . org-tree-slide-move-previous-tree)
          ("<right>" . org-tree-slide-move-next-tree)
          ("C-0" . modi/org-tree-slide-text-scale-reset)
          ("C-=" . modi/org-tree-slide-text-scale-inc1)
          ("C--" . modi/org-tree-slide-text-scale-dec1)
          ("C-1" . org-tree-slide-content)
          ("C-2" . modi/org-tree-slide-set-profile)
          ("C-3" . org-tree-slide-simple-profile)
          ("C-4" . org-tree-slide-presentation-profile))))

;;; Org Cliplink
    ;; https://github.com/rexim/org-cliplink
    (use-package org-cliplink
      :bind (:map org-mode-map
             ;; "C-c C-l" is bound to `org-insert-link' by default
             ;; "C-c C-L" is bound to `org-cliplink'
             ("C-c C-S-l" . org-cliplink)))

;;; Htmlize Region→File
    (use-package htmlize-r2f
      :load-path "elisp/htmlize-r2f"
      :bind (:map region-bindings-mode-map
             ("H" . htmlize-r2f))
      :bind (:map modi-mode-map
             ("C-c H" . htmlize-r2f)))

;;; Include src lines
    ;; Auto-update line numbers for source code includes when saving org files.
    (use-package org-include-src-lines
      :load-path "elisp/org-include-src-lines"
      :config
      (progn
        ;; Execute `endless/org-include-update' before saving the file.
        (defun modi/org-include-update-before-save ()
          "Execute `endless/org-include-update' just before saving the file."
          (add-hook 'before-save-hook #'endless/org-include-update nil :local))
        (add-hook 'org-mode-hook #'modi/org-include-update-before-save)))

;;; Convert included pdf to image
    ;; Replace included pdf files with images when saving org files.
    (use-package org-include-img-from-pdf
      :load-path "elisp/org-include-img-from-pdf"
      :config
      (progn
        ;; ;; Execute `modi/org-include-img-from-pdf' before saving the file.
        ;; (defun modi/org-include-img-from-pdf-before-save ()
        ;;   "Execute `modi/org-include-img-from-pdf' just before saving the file."
        ;;   (add-hook 'before-save-hook #'modi/org-include-img-from-pdf nil :local))
        ;; (add-hook 'org-mode-hook #'modi/org-include-img-from-pdf-before-save)
        ;; Execute `modi/org-include-img-from-pdf' before exporting.
        (with-eval-after-load 'ox
          (add-hook 'org-export-before-processing-hook #'modi/org-include-img-from-pdf))))

;;; Extract image from included .zip
    ;; Auto extract images from zip files when saving org files.
    (use-package org-include-img-from-archive
      :load-path "elisp/org-include-img-from-archive"
      :config
      (progn
        ;; ;; Execute `modi/org-include-img-from-archive' before saving the file.
        ;; (defun modi/org-include-img-from-archive-before-save ()
        ;;   "Execute `modi/org-include-img-from-archive' just before saving the file."
        ;;   (add-hook 'before-save-hook #'modi/org-include-img-from-archive nil :local))
        ;; (add-hook 'org-mode-hook #'modi/org-include-img-from-archive-before-save)
        ;; Execute `modi/org-include-img-from-archive' before exporting.
        (with-eval-after-load 'ox
          (add-hook 'org-export-before-processing-hook #'modi/org-include-img-from-archive))))

;;; Org Export
    (use-package ox
      :defer t
      :config
      (progn
        ;; Require wrapping braces to interpret _ and ^ as sub/super-script
        (setq org-export-with-sub-superscripts '{}) ; also #+OPTIONS: ^:{}
        (setq org-export-with-smart-quotes t) ; also #+OPTIONS: ':t

        (setq org-export-headline-levels 4)

;;;; ox-latex - LaTeX export
        (use-package ox-latex
          :config
          (progn
            (defvar modi/ox-latex-use-minted t
              "Use `minted' package for listings.")

            (setq org-latex-compiler "xelatex") ; introduced in org 9.0

            (setq org-latex-prefer-user-labels t) ; org-mode version 8.3+

            ;; ox-latex patches
            (load (expand-file-name
                   "ox-latex-patches.el"
                   (concat user-emacs-directory "elisp/patches/"))
                  nil :nomessage)

            ;; Previewing latex fragments in org mode
            ;; http://orgmode.org/worg/org-tutorials/org-latex-preview.html
            ;; (setq org-latex-create-formula-image-program 'dvipng) ; NOT Recommended
            (setq org-latex-create-formula-image-program 'imagemagick) ; Recommended

            ;; Controlling the order of loading certain packages w.r.t. `hyperref'
            ;; http://tex.stackexchange.com/a/1868/52678
            ;; ftp://ftp.ctan.org/tex-archive/macros/latex/contrib/hyperref/README.pdf
            ;; Remove the list element in `org-latex-default-packages-alist'.
            ;; that has '("hyperref" nil) as its cdr.
            ;; http://stackoverflow.com/a/9813211/1219634
            (setq org-latex-default-packages-alist
                  (delq (rassoc '("hyperref" nil) org-latex-default-packages-alist)
                        org-latex-default-packages-alist))
            ;; `hyperref' will be added again later in `org-latex-packages-alist'
            ;; in the correct order.

            ;; The `org-latex-packages-alist' will output tex files with
            ;;   \usepackage[FIRST STRING IF NON-EMPTY]{SECOND STRING}
            ;; It is a list of cells of the format:
            ;;   ("options" "package" SNIPPET-FLAG COMPILERS)
            ;; If SNIPPET-FLAG is non-nil, the package also needs to be included
            ;; when compiling LaTeX snippets into images for inclusion into
            ;; non-LaTeX output (like when previewing latex fragments using the
            ;; "C-c C-x C-l" binding.
            ;; COMPILERS is a list of compilers that should include the package,
            ;; see `org-latex-compiler'.  If the document compiler is not in the
            ;; list, and the list is non-nil, the package will not be inserted
            ;; in the final document.

            (defconst modi/org-latex-packages-alist-pre-hyperref
              '(("letterpaper,margin=1.0in" "geometry")
                ;; Prevent an image from floating to a different location.
                ;; http://tex.stackexchange.com/a/8633/52678
                ("" "float")
                ;; % 0 paragraph indent, adds vertical space between paragraphs
                ;; http://en.wikibooks.org/wiki/LaTeX/Paragraph_Formatting
                ("" "parskip"))
              "Alist of packages that have to be loaded before `hyperref'
package is loaded.
ftp://ftp.ctan.org/tex-archive/macros/latex/contrib/hyperref/README.pdf ")

            (defconst modi/org-latex-packages-alist-post-hyperref
              '(;; Prevent tables/figures from one section to float into another section
                ;; http://tex.stackexchange.com/a/282/52678
                ("section" "placeins")
                ;; Graphics package for more complicated figures
                ("" "tikz")
                ("" "caption")
                ;;
                ;; Packages suggested to be added for previewing latex fragments
                ;; http://orgmode.org/worg/org-tutorials/org-latex-preview.html
                ("mathscr" "eucal")
                ("" "latexsym"))
              "Alist of packages that have to (or can be) loaded after `hyperref'
package is loaded.")

            ;; The "H" option (`float' package) prevents images from floating around.
            (setq org-latex-default-figure-position "H") ; figures are NOT floating
            ;; (setq org-latex-default-figure-position "htb") ; default - figures are floating

            ;; `hyperref' package setup
            (setq org-latex-hyperref-template
                  (concat "\\hypersetup{\n"
                          "pdfauthor={%a},\n"
                          "pdftitle={%t},\n"
                          "pdfkeywords={%k},\n"
                          "pdfsubject={%d},\n"
                          "pdfcreator={%c},\n"
                          "pdflang={%L},\n"
                          ;; Get rid of the red boxes drawn around the links
                          "colorlinks,\n"
                          "citecolor=black,\n"
                          "filecolor=black,\n"
                          "linkcolor=blue,\n"
                          "urlcolor=blue\n"
                          "}"))

            (if modi/ox-latex-use-minted
                ;; using minted
                ;; https://github.com/gpoore/minted
                (progn
                  (setq org-latex-listings 'minted) ; default nil
                  ;; The default value of the `minted' package option `cachedir'
                  ;; is "_minted-\jobname". That clutters the working dirs with
                  ;; _minted* dirs. So instead create them in temp folders.
                  (defvar latex-minted-cachedir (concat temporary-file-directory
                                                        (getenv "USER")
                                                        "/.minted/\\jobname"))
                  ;; `minted' package needed to be loaded AFTER `hyperref'.
                  ;; http://tex.stackexchange.com/a/19586/52678
                  (add-to-list 'modi/org-latex-packages-alist-post-hyperref
                               `(,(concat "cachedir=" ; options
                                          latex-minted-cachedir)
                                 "minted" ; package
                                 ;; If `org-latex-create-formula-image-program'
                                 ;; is set to `dvipng', minted package cannot be
                                 ;; used to show latex previews.
                                 ,(not (eq org-latex-create-formula-image-program 'dvipng)))) ; snippet-flag

                  ;; minted package options (applied to embedded source codes)
                  (setq org-latex-minted-options
                        '(("linenos")
                          ("numbersep" "5pt")
                          ("frame"     "none") ; box frame is created by `mdframed' package
                          ("framesep"  "2mm")
                          ;; minted 2.0+ required for `breaklines'
                          ("breaklines"))) ; line wrapping within code blocks
                  (when (equal org-latex-compiler "pdflatex")
                    (add-to-list 'org-latex-minted-options '(("fontfamily"  "zi4")))))
              ;; not using minted
              (progn
                ;; Commented out below because it clashes with `placeins' package
                ;; (add-to-list 'modi/org-latex-packages-alist-post-hyperref '("" "color"))
                (add-to-list 'modi/org-latex-packages-alist-post-hyperref '("" "listings"))))

            (setq org-latex-packages-alist
                  (append modi/org-latex-packages-alist-pre-hyperref
                          '(("" "hyperref" nil))
                          modi/org-latex-packages-alist-post-hyperref))

            ;; `-shell-escape' is required when using the `minted' package

            ;; http://orgmode.org/worg/org-faq.html#using-xelatex-for-pdf-export
            ;; latexmk runs pdflatex/xelatex (whatever is specified) multiple times
            ;; automatically to resolve the cross-references.
            ;; (setq org-latex-pdf-process '("latexmk -xelatex -quiet -shell-escape -f %f"))

            ;; Below value of `org-latex-pdf-process' with %latex will work in org 9.0+
            ;; (setq org-latex-pdf-process
            ;;       '("%latex -interaction nonstopmode -shell-escape -output-directory %o %f"
            ;;         "%latex -interaction nonstopmode -shell-escape -output-directory %o %f"
            ;;         "%latex -interaction nonstopmode -shell-escape -output-directory %o %f"))

            ;; Run xelatex multiple times to get the cross-references right
            (setq org-latex-pdf-process '("xelatex -shell-escape %f"
                                          "xelatex -shell-escape %f"
                                          "xelatex -shell-escape %f"))

            ;; Override `org-latex-format-headline-default-function' definition
            ;; so that the TODO keyword in TODO marked headings is exported in
            ;; bold red.
            (defun org-latex-format-headline-default-function
                (todo _todo-type priority text tags info)
              "Default format function for a headline.
See `org-latex-format-headline-function' for details."
              (concat
               ;; Tue Jan 19 16:00:58 EST 2016 - kmodi
               ;; My only change to the original function was to add \\color{red}
               (and todo (format "{\\color{red}\\bfseries\\sffamily %s} " todo))
               (and priority (format "\\framebox{\\#%c} " priority))
               text
               (and tags
                    (format "\\hfill{}\\textsc{%s}"
                            (mapconcat (lambda (tag) (org-latex-plain-text tag info))
                                       tags ":")))))))

;;;; ox-html - HTML export
        (use-package ox-html
          :config
          (progn
            ;; ox-html patches
            (load (expand-file-name
                   "ox-html-patches.el"
                   (concat user-emacs-directory "elisp/patches/"))
                  nil :nomessage)

            ;; Remove HTML tags from in-between <title>..</title> else they show
            ;; up verbatim in the browser tabs e.g. "Text <br> More Text"
            (defun modi/ox-html-remove-tags-from-title-tag (orig-return-val)
              (replace-regexp-in-string ".*<title>.*\\(<.*>\\).*</title>.*"
                                        ""
                                        orig-return-val
                                        :fixedcase :literal 1))
            (advice-add 'org-html--build-meta-info :filter-return
                        #'modi/ox-html-remove-tags-from-title-tag)

            (use-package ox-html-fancybox
              :load-path "elisp/ox-html-fancybox")

            ;; Center align the tables when exporting to HTML
            ;; Note: This aligns the whole table, not the table columns
            (setq org-html-table-default-attributes
                  '(:border "2"
                    :cellspacing "0"
                    :cellpadding "6"
                    :rules "groups"
                    :frame "hsides"
                    :align "center"
                    ;; below class requires bootstrap.css ( http://getbootstrap.com )
                    :class "table-striped"))

            ;; Customize the HTML postamble
            ;; http://thread.gmane.org/gmane.emacs.orgmode/104502/focus=104526
            (defun modi/org-html-postamble-fn (info)
              "My custom postamble for org to HTML exports.
INFO is the property list of export options."
              (let ((author (car (plist-get info :author)))
                    (creator (plist-get info :creator))
                    (date (car (org-export-get-date info)))
                    (d1 "<div style=\"display: inline\" ")
                    (d2 "</div>"))
                (concat "Exported using "
                        d1 "class=\"creator\">" creator d2 ; emacs and org versions
                        (when author
                          (concat " by " author))
                        (when date
                          (concat " on " d1 "class=\"date\">" date d2))
                        ".")))
            (setq org-html-postamble #'modi/org-html-postamble-fn) ; default: 'auto

            (setq org-html-htmlize-output-type 'css) ; default: 'inline-css
            (setq org-html-htmlize-font-prefix "org-"))) ; default: "org-"

;;;; ox-beamer - Beamer export
        (use-package ox-beamer
          :defer t
          :config
          (progn
            ;; allow for export=>beamer by placing
            ;; #+LaTeX_CLASS: beamer in org files
            (add-to-list 'org-latex-classes
                         '("beamer"
                           "\\documentclass[presentation]{beamer}"
                           ("\\section{%s}"        . "\\section*{%s}")
                           ("\\subsection{%s}"     . "\\subsection*{%s}")
                           ("\\subsubsection{%s}"  . "\\subsubsection*{%s}")))))

;;;; ox-reveal - Presentations using reveal.js
        (use-package ox-reveal
          ;; Use the local version instead of the one from Melpa, because the
          ;; Melpa version ox-reveal.el has “;; Package-Requires: ((org "20150330"))”
          ;; which installs the org package from Melpa even though I have a newer
          ;; org version in `load-path' installed from its git master branch.
          :load-path "elisp/ox-reveal"
          :config
          (progn
            (setq org-reveal-root "http://cdn.jsdelivr.net/reveal.js/3.0.0/")
            (setq org-reveal-hlevel 1)
            (setq org-reveal-theme "simple") ; beige blood moon night serif simple sky solarized
            (setq org-reveal-mathjax t) ; Use mathjax.org to render LaTeX equations

            ;; Override the `org-reveal-export-to-html' function to generate
            ;; files with “_slides” suffix. So “man.org” will export to
            ;; “man_slides.html”. That way we can have separate html files from
            ;; html and reveal exports.
            (defun org-reveal-export-to-html
                (&optional async subtreep visible-only body-only ext-plist)
              "Export current buffer to a reveal.js HTML file."
              (interactive)
              (let* ((extension (concat "_slides." org-html-extension))
                     (file (org-export-output-file-name extension subtreep))
                     (clientfile (org-export-output-file-name
                                  (concat "_client" extension) subtreep)))

                ;; export filename_client HTML file if multiplexing
                (setq client-multiplex nil)
                (setq retfile (org-export-to-file 'reveal file
                                async subtreep visible-only body-only ext-plist))

                ;; export the client HTML file if client-multiplex is set true
                ;; by previous call to org-export-to-file
                (if (eq client-multiplex t)
                    (org-export-to-file 'reveal clientfile
                      async subtreep visible-only body-only ext-plist))
                (cond (t retfile))))))
        ;; Do not print date in the reveal title slide
        ;;   #+OPTIONS: date:nil
        ;; Do not print file time stamp in the reveal title slide
        ;;   #+OPTIONS: timestamp:nil

;;;; ox-twbs - Twitter Bootstrap
        ;; https://github.com/marsmining/ox-twbs
        (use-package ox-twbs
          ;; My fork of ox-twbs has the following fixes in order to work with
          ;; org 9.0+
          ;;  - https://github.com/kaushalmodi/ox-twbs/commit/c72586abbcf857a3ecf5b665112d9672142b8504
          ;;  - https://github.com/kaushalmodi/ox-twbs/commit/0ef10224c332cf79e6724019a863180484026ef7
          :load-path "elisp/ox-twbs"
          :config
          (progn
            (setq org-twbs-link-org-files-as-html nil)

            ;; Postamble tweaks
            (setq org-twbs-postamble #'modi/org-html-postamble-fn)

            (defvar bkp/org-twbs-style-default
              org-twbs-style-default
              "Save the default `org-twbs-style-default'.")

            (setq org-twbs-style-default
                  (concat bkp/org-twbs-style-default
                          "
<style type=\"text/css\">
/* Reduce the bottom margin; default is too big. */
body {
    margin-bottom : 35px;
}
footer {
    height        : 35px;
    text-align    : center;
    /* vertical alignment trick: http://stackoverflow.com/a/16205949/1219634 */
    line-height   : 35px;
    font-style    : italic;
}
/* Remove the padding from in-between the div elements
   in the footer. */
footer > div {
    padding: 0px;
}
</style>"))))

;;;; ox-minutes - Meeting Minutes ASCII export
        (use-package ox-minutes
          :load-path "elisp/ox-minutes")

;;;; ox-odt - ODT, doc export
        ;; http://stackoverflow.com/a/22990257/1219634
        (use-package ox-odt
          :disabled
          :config
          (progn
            ;; Auto convert the exported .odt to .doc (MS Word 97) format
            ;; Requires the soffice binary packaged with openoffice
            (setq org-odt-preferred-output-format "doc")))

        (defun modi/org-export-to-html-txt-pdf ()
          "Export the org file to multiple formats."
          (interactive)
          (org-html-export-to-html)
          (org-ascii-export-to-ascii)
          (org-latex-export-to-pdf))

;;;; Org Export Customization
        ;; Delete selected columns from org tables before exporting
        ;; http://thread.gmane.org/gmane.emacs.orgmode/106497/focus=106683
        (defun mbrand/org-export-delete-commented-cols (back-end)
          "Delete columns $2 to $> marked as `<#>' on a row with `/' in $1.
If you want a non-empty column $1 to be deleted make it $2 by
inserting an empty column before and adding `/' in $1."
          (while (re-search-forward
                  "^[ \t]*| +/ +|\\(.*|\\)? +\\(<#>\\) *|" nil :noerror)
            (goto-char (match-beginning 2))
            (org-table-delete-column)
            (beginning-of-line)))
        (add-hook 'org-export-before-processing-hook
                  #'mbrand/org-export-delete-commented-cols)

        ;; http://lists.gnu.org/archive/html/emacs-orgmode/2016-09/msg00168.html
        (defun cpit/filter-begin-only (type)
          "Remove BEGIN_ONLY %s blocks whose %s doesn't equal TYPE.
For those that match, only remove the delimiters.

On the flip side, for BEGIN_EXCEPT %s blocks, remove those if %s equals TYPE. "
          (goto-char (point-min))
          (while (re-search-forward " *#\\+BEGIN_\\(ONLY\\|EXCEPT\\) +\\([a-z]+\\)\n"
                                    nil :noerror)
            (let ((only-or-export (match-string-no-properties 1))
                  (block-type (match-string-no-properties 2))
                  (begin-from (match-beginning 0))
                  (begin-to (match-end 0)))
              (re-search-forward (format " *#\\+END_%s +%s\n"
                                         only-or-export block-type))
              (let ((end-from (match-beginning 0))
                    (end-to (match-end 0)))
                (if (or (and (string= "ONLY" only-or-export)
                             (string= type block-type))
                        (and (string= "EXCEPT" only-or-export)
                             (not (string= type block-type))))
                    (progn              ; Keep the block,
                                        ; delete just the comment markers
                      (delete-region end-from end-to)
                      (delete-region begin-from begin-to))
                  ;; Delete the block
                  (message "Removing %s block" block-type)
                  (delete-region begin-from end-to))))))
        (add-hook 'org-export-before-processing-hook #'cpit/filter-begin-only)))

;;; Easy Templates
    ;; http://orgmode.org/manual/Easy-Templates.html
    ;; http://oremacs.com/2015/03/07/hydra-org-templates
    ;; https://github.com/abo-abo/hydra/wiki/Org-mode-block-templates

    (defun modi/org-template-expand (str &optional lang)
      "Expand org template."
      (let (beg old-beg end content)
        ;; Save restriction to automatically undo the upcoming `narrow-to-region'
        (save-restriction
          (when (use-region-p)
            (setq beg (region-beginning))
            (setq end (region-end))
            ;; Note that regardless of the direction of selection, we will always
            ;; have (region-beginning) < (region-end).
            (save-excursion
              ;; If `point' is at `end', exchange point and mark so that now the
              ;; `point' is now at `beg'
              (when (> (point) (mark))
                (exchange-point-and-mark))
              ;; Insert a newline if `beg' is *not* at beginning of the line.
              ;; Example: You have ^abc$ where ^ is bol and $ is eol.
              ;;          "bc" is selected and <e is pressed to result in:
              ;;            a
              ;;            #+BEGIN_EXAMPLE
              ;;            bc
              ;;            #+END_EXAMPLE
              (when (/= beg (line-beginning-position))
                (electric-indent-just-newline 1)
                (setq old-beg beg)
                (setq beg (point))
                ;; Adjust the `end' due to newline
                (setq end (+ end (- beg old-beg)))))
            (save-excursion
              ;; If `point' is at `beg', exchange point and mark so that now the
              ;; `point' is now at `end'
              (when (< (point) (mark))
                (exchange-point-and-mark))
              ;; If the `end' position is at the beginning of a line decrement
              ;; the position by 1, so that the resultant position is eol on
              ;; the previous line.
              (when (= end (line-beginning-position))
                (setq end (1- end)))
              ;; Insert a newline if `point'/`end' is *not* at end of the line.
              ;; Example: You have ^abc$ where ^ is bol and $ is eol.
              ;;          "a" is selected and <e is pressed to result in:
              ;;            #+BEGIN_EXAMPLE
              ;;            a
              ;;            #+END_EXAMPLE
              ;;            bc
              (when (not (looking-at "\\s-*$"))
                (electric-indent-just-newline 1)))
            ;; Narrow to region so that the text surround the region does
            ;; not mess up the upcoming `org-try-structure-completion' eval
            (narrow-to-region beg end)
            (setq content (delete-and-extract-region beg end)))
          (insert str)
          (org-try-structure-completion)
          (when (string= "<s" str)
            (cond
             (lang
              (insert lang)
              (forward-line))
             ((and content (not lang))
              (insert "???")
              (forward-line))
             (t
              )))
          ;; At this point the cursor will be between the #+BEGIN and #+END lines
          (when content
            (insert content)
            (deactivate-mark)))))

    (defhydra hydra-org-template (:color blue
                                  :hint nil)
      "
org-template:  _c_enter        _s_rc          _e_xample           _v_erilog        _t_ext           _I_NCLUDE:
               _l_atex         _h_tml         _V_erse             _m_atlab         _L_aTeX:         _H_TML:
               _a_scii         _q_uote        _E_macs-lisp        _S_hell          _i_ndex:         _A_SCII:
"
      ("s" (modi/org-template-expand "<s")) ; #+BEGIN_SRC ... #+END_SRC
      ("E" (modi/org-template-expand "<s" "emacs-lisp"))
      ("v" (modi/org-template-expand "<s" "systemverilog"))
      ("m" (modi/org-template-expand "<s" "matlab"))
      ("S" (modi/org-template-expand "<s" "shell"))
      ("t" (modi/org-template-expand "<s" "text"))
      ("e" (modi/org-template-expand "<e")) ; #+BEGIN_EXAMPLE ... #+END_EXAMPLE
      ("x" (modi/org-template-expand "<e")) ; #+BEGIN_EXAMPLE ... #+END_EXAMPLE
      ("q" (modi/org-template-expand "<q")) ; #+BEGIN_QUOTE ... #+END_QUOTE
      ("V" (modi/org-template-expand "<v")) ; #+BEGIN_VERSE ... #+END_VERSE
      ("c" (modi/org-template-expand "<c")) ; #+BEGIN_CENTER ... #+END_CENTER
      ("l" (modi/org-template-expand "<l")) ; #+BEGIN_EXPORT latex ... #+END_EXPORT
      ("L" (modi/org-template-expand "<L")) ; #+LaTeX:
      ("h" (modi/org-template-expand "<h")) ; #+BEGIN_EXPORT html ... #+END_EXPORT
      ("H" (modi/org-template-expand "<H")) ; #+HTML:
      ("a" (modi/org-template-expand "<a")) ; #+BEGIN_EXPORT ascii ... #+END_EXPORT
      ("A" (modi/org-template-expand "<A")) ; #+ASCII:
      ("i" (modi/org-template-expand "<i")) ; #+INDEX: line
      ("I" (modi/org-template-expand "<I")) ; #+INCLUDE: line
      ("<" self-insert-command "<")
      ("o" nil "quit"))

    (defun modi/org-template-maybe ()
      "Insert org-template if point is at the beginning of the line, or is a
region is selected. Else call `self-insert-command'."
      (interactive)
      (let ((regionp (use-region-p)))
        (if (or regionp
                (and (not regionp)
                     (looking-back "^")))
            (hydra-org-template/body)
          (self-insert-command 1))))

;;; Bindings
    (with-eval-after-load 'org-src
      (bind-key "C-c C-c" #'org-edit-src-exit org-src-mode-map))

    (defun modi/reset-local-set-keys ()
      (local-unset-key (kbd "<f10>"))
      (local-unset-key (kbd "<s-f10>"))
      (local-unset-key (kbd "<S-f10>"))
      (local-unset-key (kbd "<C-f10>")))
    (add-hook 'org-mode-hook #'modi/reset-local-set-keys)

    (bind-keys
     :map org-mode-map
      ("C-m" . modi/org-return-no-indent)
      ("<" . modi/org-template-maybe)
      ("M-p". org-previous-visible-heading)
      ("M-n". org-next-visible-heading))

    (bind-keys
     :map modi-mode-map
      ("C-c a" . org-agenda)
      ("C-c c" . org-capture)
      ("C-c i" . org-store-link))))


(provide 'setup-org)

;;; Notes
;; C-c C-e l l <-- Do org > tex
;; C-c C-e l p <-- Do org > tex > pdf using the command specified in
;;                 `org-latex-pdf-process' list
;; C-c C-e l o <-- Do org > tex > pdf and open the pdf file using the app
;;                 associated with pdf files defined in `org-file-apps'

;; When the cursor is on an existing link, `C-c C-l' allows you to edit the link
;; and description parts of the link.

;; C-c C-x f <-- Insert footnote

;; C-c C-x C-l <-- Preview latex fragment in place; C-c C-c to exit that preview.

;; Auto-completions http://orgmode.org/manual/Completion.html
;; \ M-TAB <- TeX symbols
;; ​* M-TAB <- Headlines; useful when doing [[* Partial heading M-TAB when linking to headings
;; #+ M-TAB <- org-mode special keywords like #+DATE, #+AUTHOR, etc

;; Speed-keys are awesome! http://orgmode.org/manual/Speed-keys.html

;; Easy Templates http://orgmode.org/manual/Easy-Templates.html
;; To insert a structural element, type a ‘<’, followed by a template selector
;; and <TAB>. Completion takes effect only when the above keystrokes are typed
;; on a line by itself.
;; s 	#+BEGIN_SRC ... #+END_SRC
;; e 	#+BEGIN_EXAMPLE ... #+END_EXAMPLE
;; l 	#+BEGIN_LaTeX ... #+END_LaTeX
;; L 	#+LaTeX:
;; h 	#+BEGIN_HTML ... #+END_HTML
;; H 	#+HTML:
;; I 	#+INCLUDE: line

;; Disable selected org-mode markup character on per-file basis
;; http://emacs.stackexchange.com/a/13231/115

;; How to modify `org-emphasis-regexp-components'
;; http://emacs.stackexchange.com/a/13828/115

;; Installing minted.sty
;; In order to have that tex convert to pdf, you have to ensure that you have
;; minted.sty in your TEXMF folder.
;;  - To know if minted.sty in correct path do "kpsewhich minted.sty".
;;  - If it is not found, download from http://www.ctan.org/tex-archive/macros/latex/contrib/minted
;;  - Generate minted.sty by "tex minted.ins"
;;  - To know your TEXMF folder, do "kpsewhich -var-value=TEXMFHOME"
;;  - For me TEXMF folder was ~/texmf
;;  - Move the minted.sty to your $TEXMF/tex/latex/commonstuff folder.
;;  - Do mkdir -p ~/texmf/tex/latex/commonstuff if that folder hierarchy doesn't exist
;;  - Do "mktexlsr" to refresh the sty database
;;  - Generate pdf from the org exported tex by "pdflatex -shell-escape FILE.tex"

;; Sources for org > tex > pdf conversion:
;;  - http://nakkaya.com/2010/09/07/writing-papers-using-org-mode/
;;  - http://mirrors.ctan.org/macros/latex/contrib/minted/minted.pdf

;; To have an org document auto update the #+DATE: keyword during exports, use:
;;   #+DATE: {{{time(%b %d %Y\, %a)}}}
;; The time format here can be anything as documented in `format-time-string' fn.

;; Controlling section numbering, levels in `ox-twbs' exports:
;; https://github.com/marsmining/ox-twbs/issues/10#issuecomment-140324367
;;
;;   #+OPTIONS: num:5 whn:2 toc:4 H:6
;;
;; Above would mean,
;; - Create section numbers up to level 5 (num).
;; - Display section numbers up to level 2 (whn).
;; - Display table of contents 4 deep (toc).
;; - Consider sections after 6 to be "low-level" (H).

;; How to mark the whole src block that the point is in?
;; C-c C-v C-M-h (`org-babel-mark-block')

;; How to toggle display of inline images?
;; C-c C-x C-v (`org-toggle-inline-images')

;; Setting buffer local variables to be effective during org exports
;; http://thread.gmane.org/gmane.emacs.orgmode/107058
;; If you want to set a buffer local variable foo to nil during org exports,
;; add the below to the end of the org file
;;
;;   #+BIND: foo nil
;;   # L**ocal Variables:
;;   # org-export-allow-bind-keywords: t
;;   # E**nd:
;;
;; Above ** are added in the local variables footer so that that is not
;; recognized as the local variables setup for THIS file.

;; C-u M-RET - Force create a heading (see `org-insert-heading') whether point
;; is in a list or a normal line.

;; Local Variables:
;; aggressive-indent-mode: nil
;; End:
