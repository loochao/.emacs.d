;; Time-stamp: <2016-12-07 10:14:36 kmodi>

;; Info

(use-package info
  :defer t
  :config
  (progn
    (>=e "25.0" ; `Info-quoted' was a new face introduced then
        (with-eval-after-load 'setup-font-check
          (when font-dejavu-sans-mono-p
            (set-face-attribute 'Info-quoted nil :family "DejaVu Sans Mono"))))

    (use-package info+
      :config
      (progn
        ;; The faces implementation to highlight strings in "..." is incomplete;
        ;; it does not work well in text having a mix of regular and escaped
        ;; double quotes (" and \"). So the workaround is to disable highlighting
        ;; the double quotes.
        (setq info-quoted+<>-regexp
              (concat
               ;; "\"\\(?:[^\"]\\|\\\\\\(?:.\\|[\n]\\)\\)*\"\\|"           ; "..."
               "`\\(?:[^']\\|\\\\\\(.\\|[\n]\\)\\)*'\\|"                ; `...'
               "‘\\(?:[^’]\\|\\\\\\(.\\|[\n]\\)\\)*’\\|"                ; ‘...’
               "\“\\(?:[^”]\\|\\\\\\(.\\|[\n]\\)\\)*”\\|"               ; “...”
               "<\\(?:[[:alpha:]][^>]*\\|\\(\\\\\\(.\\|[\n]\\)\\)*\\)>" ; <...>
               ))

        (defun modi/Info-mode-customization ()
          "My customization for `Info-mode'."
          ;; Show the Info node breadcrumbs only in the header
          ;; Tue Dec 06 23:10:05 EST 2016 - kmodi
          ;; Using both anzu and info+ results in error if info+ breadcrumbs are
          ;; shown in the mode line because anzu modifies the mode line by adding
          ;; its info as a cons, whereas info+ updates the mode line directly.
          (when (not Info-breadcrumbs-in-header-flag)
            (Info-toggle-breadcrumbs-in-header))
          (Info-breadcrumbs-in-mode-line-mode -1))
        (add-hook 'Info-mode-hook #'modi/Info-mode-customization)

        (bind-keys
         :map Info-mode-map
          ;; Allow mouse scrolling to do its normal thing
          ("<mouse-4>" . nil)
          ("<mouse-5>" . nil)
          ;; Override the Info-mode-map binding to "?" set by info+
          ("?" . hydra-info/body))))

    (defhydra hydra-info (:color blue
                          :hint nil)
      "
Info-mode:

  ^^_]_ forward  (next logical node)       ^^_l_ast (←)                     _u_p (↑)                             _f_ollow reference       _d_irectory of all manuals
  ^^_[_ backward (prev logical node)       ^^_r_eturn (→)                   _m_enu (↓) (C-u for new window)      _i_ndex                  _T_OC of current manual
  ^^_n_ext (same level only)               ^^_H_istory                      _g_oto (C-u for new window)          _,_ next index item      _w_ copy node name
  ^^_p_rev (same level only)               _<_/_t_op of current manual      _b_eginning of buffer                virtual _I_ndex          _c_lone buffer
  regex _s_earch (_S_ case sensitive)      ^^_>_ final                      _e_nd of buffer                      ^^                       _a_propos

  _<backspace>_/_<SPC>_ Scroll up/down     _1_ .. _9_ Pick first .. ninth item in the node's menu.

"
      ("]"   Info-forward-node)
      ("["   Info-backward-node)
      ("n"   Info-next)
      ("p"   Info-prev)
      ("s"   Info-search)
      ("S"   Info-search-case-sensitively)

      ("l"   Info-history-back)
      ("r"   Info-history-forward)
      ("H"   Info-history)
      ("t"   Info-top-node)
      ("<"   Info-top-node)
      (">"   Info-final-node)

      ("u"   Info-up)
      ("^"   Info-up)
      ("m"   Info-menu)
      ("g"   Info-goto-node)
      ("b"   beginning-of-buffer)
      ("e"   end-of-buffer)

      ("f"   Info-follow-reference)
      ("i"   Info-index)
      (","   Info-index-next)
      ("I"   Info-virtual-index)

      ("d"   Info-directory)
      ("T"   Info-toc)
      ("w"   Info-copy-current-node-name) ; M-0 w will copy elisp form of current node name
      ("c"   clone-buffer)
      ("a"   info-apropos)

      ("1"   Info-nth-menu-item)
      ("2"   Info-nth-menu-item)
      ("3"   Info-nth-menu-item)
      ("4"   Info-nth-menu-item)
      ("5"   Info-nth-menu-item)
      ("6"   Info-nth-menu-item)
      ("7"   Info-nth-menu-item)
      ("8"   Info-nth-menu-item)
      ("9"   Info-nth-menu-item)

      ("<backspace>" Info-scroll-down)
      ("<SPC>" Info-scroll-up)

      ("?"   Info-summary "Info summary")
      ("h"   Info-help "Info help")
      ("q"   Info-exit "Info exit")
      ("C-g" nil "cancel" :color blue))
    (bind-key "?" #'hydra-info/body Info-mode-map)))

(defun counsel-ag-emacs-info (&optional initial-input)
  "Search in all Info manuals in the emacs 'info/' directory using ag.
This directory contains the emacs, elisp, eintr, org, calc Info manuals and other
manuals too for the packages that ship with emacs.
INITIAL-INPUT can be given as the initial minibuffer input."
  (interactive)
  (counsel-ag initial-input (car Info-default-directory-list)
              " -z" "Search emacs/elisp info"))

;; http://oremacs.com/2015/03/17/more-info/
(defun ora-open-info (topic bufname)
  "Open info on TOPIC in BUFNAME."
  (if (get-buffer bufname)
      (progn
        (switch-to-buffer bufname)
        (unless (string-match topic Info-current-file)
          (Info-goto-node (format "(%s)" topic))))
    (info topic bufname)))

(defhydra hydra-info-to (:hint nil
                         :color teal)
  "
_i_nfo      _o_rg      e_l_isp      e_L_isp intro      _e_macs      _c_alc      _g_rep emacs info"
  ("i" info)
  ("o" (ora-open-info "org" "*org info*"))
  ("l" (ora-open-info "elisp" "*elisp info*"))
  ("L" (ora-open-info "eintr" "*elisp intro info*"))
  ("e" (ora-open-info "emacs" "*emacs info*"))
  ("c" (ora-open-info "calc" "*calc info*"))
  ("g" counsel-ag-emacs-info))
(bind-key "C-h i" #'hydra-info-to/body modi-mode-map)


(provide 'setup-info)
