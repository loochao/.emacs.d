;; Time-stamp: <2016-12-07 18:26:47 kmodi>

;; Verilog

;; Contents:
;;
;;  Variables
;;  Functions
;;    modi/verilog-find-module-instance
;;    modi/verilog-get-header
;;    modi/verilog-jump-to-header-dwim (interactive)
;;    which-func
;;      modi/verilog-which-func
;;      modi/verilog-update-which-func-format
;;    modi/verilog-jump-to-module-at-point (interactive)
;;    modi/verilog-find-parent-module (interactive)
;;    modi/verilog-selective-indent
;;    modi/verilog-compile
;;    convert end-block comments to block names
;;  hideshow
;;  hydra-verilog-template
;;  imenu + outshine
;;  modi/verilog-mode-customization
;;  Key bindings

(use-package verilog-mode
  :load-path "elisp/verilog-mode"
  :mode (("\\.[st]*v[hp]*\\'" . verilog-mode) ; .v, .sv, .svh, .tv, .vp
         ("\\.psl\\'"         . verilog-mode)
         ("\\.vams\\'"        . verilog-mode)
         ("\\.vinc\\'"        . verilog-mode))
  :config
  (progn

;;; Variables
    (setq verilog-indent-level             3)   ; 3 (default)
    (setq verilog-indent-level-module      3)   ; 3
    (setq verilog-indent-level-declaration 3)   ; 3
    (setq verilog-indent-level-behavioral  3)   ; 3
    (setq verilog-indent-level-directive   0)   ; 1
    (setq verilog-case-indent              2)   ; 2
    (setq verilog-auto-newline             nil) ; t
    (setq verilog-auto-indent-on-newline   t)   ; t
    (setq verilog-tab-always-indent        t)   ; t
    (setq verilog-minimum-comment-distance 10)  ; 10
    (setq verilog-indent-begin-after-if    t)   ; t
    (setq verilog-auto-lineup              nil) ; 'declarations
    (setq verilog-align-ifelse             nil) ; nil
    (setq verilog-auto-endcomments         t)   ; t
    (setq verilog-tab-to-comment           nil) ; nil
    (setq verilog-date-scientific-format   t)   ; t

    (defconst modi/verilog-identifier-re "\\b[a-zA-Z][a-zA-Z0-9$_]*"
      "Regexp for a valid verilog identifier.
Reference: IEEE 1800-2012 SystemVerilog Section 5.6 Identifiers, keywords,
and system names. ")

    (defconst modi/verilog-module-instance-re
      (concat "^\\s-*"
              ;; force group number to 1; module name
              "\\(?1:" modi/verilog-identifier-re "\\)"
              "\\(?:\n\\|\\s-\\)+" ; newline/space
              ;; optional hardware parameters followed by optional comments
              ;; followed by optional space/newline before instance name
              "\\(#([^;]+?)\\(\\s-*//.*?\\)*[^;\\./]+?\\)*"
              ;; force group number to 2; instance name
              "\\(?2:" modi/verilog-identifier-re "\\)"
              "\\(?:\n\\|\\s-\\)*" ; optional newline/space
              "(" ; opening parenthesis `(' before port list
              )
      "Regexp for a valid verilog module instance declaration.")

    (defconst modi/verilog-header-re
      (concat "^\\s-*"
              "\\([a-z]+\\s-+\\)*" ; virtual, local, protected
              "\\(?1:" "case" ; force group number to 1
              "\\|" "class"
              "\\|" "clocking"
              "\\|" "`define"
              "\\|" "function"
              "\\|" "group"
              "\\|" "interface"
              "\\|" "module"
              "\\|" "program"
              "\\|" "primitive"
              "\\|" "package"
              "\\|" "property"
              "\\|" "sequence"
              "\\|" "specify"
              "\\|" "table"
              "\\|" "task" "\\)"
              "\\s-+"
              "\\([a-z]+\\s-+\\)*" ; void, static, automatic, ..
              "\\(?2:"
              "\\(?:" modi/verilog-identifier-re "::\\)*" ; allow parsing extern methods like class::task
              modi/verilog-identifier-re ; block name, force group number to 2
              "\\)"
              "\\b"
              )
      "Regexp for a valid verilog block header statement.")

    (defvar modi/verilog-keywords-re nil
      "Regexp for reserved verilog keywords which should not be incorrectly
parsed as a module or instance name.")
    ;; Generate the regexp `modi/verilog-keywords-re' based on the list of
    ;; keywords in `verilog-keywords'.
    (let ((cnt 1)
          ;; `verilog-keywords' list is defined in the `verilog-mode.el'
          (max-cnt (safe-length verilog-keywords)))
      (dolist (keyword verilog-keywords)
        (cond
         ((= cnt 1)       (setq modi/verilog-keywords-re
                                (concat "\\("
                                        "\\b" keyword "\\b")))
         ((= cnt max-cnt) (setq modi/verilog-keywords-re
                                (concat modi/verilog-keywords-re
                                        "\\|"
                                        "\\b" keyword "\\b" "\\)")))
         (t               (setq modi/verilog-keywords-re
                                (concat modi/verilog-keywords-re
                                        "\\|"
                                        "\\b" keyword "\\b"))))
        (setq cnt (1+ cnt))))

;;; Functions

    (defvar-local modi/verilog-which-func-xtra nil
      "Variable to hold extra information for `which-func' to show in the
mode-line. For instance, if point is under \"module top\", `which-func' would
show \"top\" but also show extra information that it's a \"module\".")

;;;; modi/verilog-find-module-instance
    (defun modi/verilog-find-module-instance (&optional fwd)
      "Return the module instance name within which the point is currently.

If FWD is non-nil, do the verilog module/instance search in forward direction;
otherwise in backward direction.

This function updates the local variable `modi/verilog-which-func-xtra'.

For example, if the point is as below (indicated by that rectangle), \"u_adder\"
is returned and `modi/verilog-which-func-xtra' is updated to \"adder\".

   adder u_adder
   (
    ▯
    );"
      (let (instance-name return-val) ; return-val will be nil by default
        (setq-local modi/verilog-which-func-xtra nil) ; reset
        (save-excursion
          (when (if fwd
                    (re-search-forward modi/verilog-module-instance-re nil :noerror)
                  (re-search-backward modi/verilog-module-instance-re nil :noerror))
            ;; Ensure that text in line or block comments is not incorrectly
            ;; parsed as a module instance
            (when (not (equal (face-at-point) 'font-lock-comment-face))
              ;; (message "---- 1 ---- %s" (match-string 1))
              ;; (message "---- 2 ---- %s" (match-string 2))
              ;; (message "---- 3 ---- %s" (match-string 3))
              (setq-local modi/verilog-which-func-xtra (match-string 1)) ; module name
              (setq instance-name (match-string 2)) ; instance name

              (when (and (stringp modi/verilog-which-func-xtra)
                         (string-match modi/verilog-keywords-re
                                       modi/verilog-which-func-xtra))
                (setq-local modi/verilog-which-func-xtra nil))

              (when (and (stringp instance-name)
                         (string-match modi/verilog-keywords-re
                                       instance-name))
                (setq instance-name nil))

              (when (and modi/verilog-which-func-xtra
                         instance-name)
                (setq return-val instance-name)))))
        (when (featurep 'which-func)
          (modi/verilog-update-which-func-format))
        return-val))

;;;; modi/verilog-get-header
    (defun modi/verilog-get-header (&optional fwd)
      "Function to return the name of the block (module, class, package,
function, task, `define) under which the point is currently present.

If FWD is non-nil, do the block header search in forward direction;
otherwise in backward direction.

This function updates the local variable `modi/verilog-which-func-xtra'.

For example, if the point is as below (indicated by that rectangle), \"top\"
is returned and `modi/verilog-which-func-xtra' is updated to \"mod\" (short
for \"module\").

   module top ();
   ▯
   endmodule "
      (let (block-type block-name return-val) ; return-val will be nil by default
        (setq-local modi/verilog-which-func-xtra nil) ; reset
        (save-excursion
          (when (if fwd
                    (re-search-forward modi/verilog-header-re nil :noerror)
                  (re-search-backward modi/verilog-header-re nil :noerror))
            ;; Ensure that text in line or block comments is not incorrectly
            ;; parsed as a Verilog block header
            (when (not (equal (face-at-point) 'font-lock-comment-face))
              ;; (message "---- 1 ---- %s" (match-string 1))
              ;; (message "---- 2 ---- %s" (match-string 2))
              ;; (message "---- 3 ---- %s" (match-string 3))
              ;; (message "---- 4 ---- %s" (match-string 4))
              (setq block-type (match-string 1))
              (setq block-name (match-string 2))

              (when (and (stringp block-name)
                         (not (string-match modi/verilog-keywords-re
                                            block-name)))
                (setq-local modi/verilog-which-func-xtra
                            (cond
                             ((string= "class"     block-type) "class")
                             ((string= "clocking"  block-type) "clk")
                             ((string= "`define"   block-type) "macro")
                             ((string= "group"     block-type) "group")
                             ((string= "module"    block-type) "mod")
                             ((string= "interface" block-type) "if")
                             ((string= "package"   block-type) "pkg")
                             ((string= "sequence"  block-type) "seq")
                             (t (substring block-type 0 4)))) ; first 4 chars
                (setq return-val block-name)))))
        (when (featurep 'which-func)
          (modi/verilog-update-which-func-format))
        return-val))

;;;; modi/verilog-jump-to-header-dwim (interactive)
    (defun modi/verilog-jump-to-header-dwim (fwd)
      "Jump to a module instantiation header above the current point. If
a module instantiation is not found, jump to a block header if available.

If FWD is non-nil, do that module instrantiation/header search in forward
direction; otherwise in backward direction.

Few examples of what is considered as a block: module, class, package, function,
task, `define."
      (interactive "P")
      (if (modi/verilog-find-module-instance fwd)
          (if fwd
              (re-search-forward modi/verilog-module-instance-re nil :noerror)
            (re-search-backward modi/verilog-module-instance-re nil :noerror))
        (if fwd
            (re-search-forward modi/verilog-header-re nil :noerror)
          (re-search-backward modi/verilog-header-re nil :noerror))))

    (defun modi/verilog-jump-to-header-dwim-fwd ()
      "Executes `modi/verilog-jump-to-header' with non-nil argument so that
the point jumps to a module instantiation/block header *below* the current
point."
      (interactive)
      (modi/verilog-jump-to-header-dwim :fwd))

;;;; which-func
    (with-eval-after-load 'which-func
      (add-to-list 'which-func-modes 'verilog-mode)

;;;;; modi/verilog-which-func
      (defun modi/verilog-which-func ()
        (setq-local which-func-functions '(modi/verilog-find-module-instance
                                           modi/verilog-get-header))
        (which-function-mode))
      (add-hook 'verilog-mode-hook #'modi/verilog-which-func)

;;;;; modi/verilog-update-which-func-format
      (defun modi/verilog-update-which-func-format ()
        (let ((modi/verilog-which-func-echo-help
               (concat "mouse-1/scroll up: jump to header UP" "\n"
                       "mouse-3/scroll-down: jump to header DOWN")))

          (setq-local which-func-keymap
                      (let ((map (make-sparse-keymap)))
                        ;; left click on mode line
                        (define-key map [mode-line mouse-1] #'modi/verilog-jump-to-header-dwim)
                        ;; scroll up action while mouse on mode line
                        (define-key map [mode-line mouse-4] #'modi/verilog-jump-to-header-dwim)
                        ;; middle click on mode line
                        (define-key map [mode-line mouse-2] #'modi/verilog-jump-to-header-dwim-fwd)
                        ;; scroll down action while mouse on mode line
                        (define-key map [mode-line mouse-5] #'modi/verilog-jump-to-header-dwim-fwd)
                        map))

          (if modi/verilog-which-func-xtra
              (setq-local which-func-format
                          `("["
                            (:propertize which-func-current
                             local-map ,which-func-keymap
                             face (font-lock-keyword-face :weight bold)
                             mouse-face mode-line-highlight
                             help-echo ,modi/verilog-which-func-echo-help)
                            ":"
                            (:propertize modi/verilog-which-func-xtra
                             local-map ,which-func-keymap
                             face font-lock-keyword-face
                             mouse-face mode-line-highlight
                             help-echo ,modi/verilog-which-func-echo-help)
                            "]"))
            (setq-local which-func-format
                        `("["
                          (:propertize which-func-current
                           local-map ,which-func-keymap
                           face font-lock-keyword-face
                           mouse-face mode-line-highlight
                           help-echo ,modi/verilog-which-func-echo-help)
                          "]"))))))

    (with-eval-after-load 'projectile

;;;; modi/verilog-jump-to-module-at-point (interactive)
      (defun modi/verilog-jump-to-module-at-point ()
        "When in a module instance, jump to that module's definition.

Calling this function again after that *without moving the point* will
call `pop-tag-mark' and jump will be made back to the original position.

Usage: While the point is inside a verilog instance, say, \"core u_core\",
calling this command, will make a jump to \"module core\". When you call this
command again *without moving the point*, the jump will be made back to the
earlier position where the point was inside the \"core u_core\" instance.

It is required to have `ctags' executable and `projectile' package installed,
and to have a `ctags' TAGS file pre-generated for this command to work."
        (interactive)
        ;; You need to have ctags installed.
        (if (and (executable-find "ctags")
                 (projectile-project-root))
            (let ((tags-file (expand-file-name "TAGS" (projectile-project-root))))
              ;; You need to have the ctags TAGS file pre-generated.
              (if (file-exists-p tags-file)
                  ;; `modi/verilog-which-func-xtra' contains the module name in
                  ;; whose instance declaration the point is currently.
                  (if (and (modi/verilog-find-module-instance)
                           modi/verilog-which-func-xtra)
                      (progn
                        (modi/update-etags-table)
                        (find-tag modi/verilog-which-func-xtra))
                    ;; Do `pop-tag-mark' if this command is called when the
                    ;; point in *not* inside a verilog instance.
                    (pop-tag-mark))
                (user-error "Ctags TAGS file `%s' was not found" tags-file)))
          (user-error "Executable `ctags' is required for this command to work")))

      (with-eval-after-load 'ag

;;;; modi/verilog-find-parent-module (interactive)
        (defun modi/verilog-find-parent-module ()
          "Find the places where the current verilog module is instantiated in
the project."
          (interactive)
          (let ((verilog-module-re (concat "^\\s-*" ; elisp regexp
                                           "\\(?:module\\)\\s-+" ; shy group
                                           "\\("
                                           modi/verilog-identifier-re
                                           "\\)\\b"))
                module-name
                module-instance-re)
            (save-excursion
              (re-search-backward verilog-module-re)
              (setq module-name (match-string 1))
              (setq module-instance-pcre ; pcre regex
                    (concat "^\\s*"
                            module-name
                            "\\s+"
                            "(#\\s*\\((\\n|.)*?\\))*" ; optional hardware parameters
                                        ; '(\n|.)*?' does non-greedy multi-line grep
                            "(\\n|.)*?" ; optional newline/space before instance name
                            "[^.]" ; do not match ".PARAM (PARAM_VAL),"
                            "\\K" ; don't highlight anything till this point
                            modi/verilog-identifier-re ; instance name
                            "(?=[^a-zA-Z0-9_]*\\()")) ; optional space/newline after instance name
                                        ; and before opening parenthesis `('
                                        ; don't highlight anything in (?=..)
              ;; (message module-instance-pcre)
              (ag-regexp module-instance-pcre (projectile-project-root)))))))

;;;; modi/verilog-selective-indent
    ;; http://emacs.stackexchange.com/a/8033/115
    (defvar modi/verilog-multi-line-define-line-cache nil
      "Variable set to non-nil if the current line is detected as any but the
last line of a multi-line `define such as:

  `define foo(ARG) \          <- non-nil
    begin \                   <- non-nil
      $display(\"Bar\"); \    <- non-nil
      $display(\"Baz\"); \    <- non-nil
    end                       <- nil
 ")

    (defun modi/verilog-selective-indent (&rest args)
      "Return non-nil if point is on certain types of lines.

Non-nil return will happen when either of the below is true:
- The current line starts with optional whitespace and then \"// *(space)\".
  Here that * represents one or more consecutive '*' chars.
- The current line contains \"//.\".
  Here that . represents a literal '.' char.
- The current line is part of a multi-line `define like:
    `define foo(ARG) \
      begin \
        $display(\"Bar\"); \
        $display(\"Baz\"); \
      end

If the comment is of \"// *(space)\" style, delete any preceding white space, do
not indent that comment line at all.

This function is used to tweak the `verilog-mode' indentation to skip the lines
containing \"// *(space)\" style of comments in order to not break any
`outline-mode'or `outshine' functionality.

The match with \"//.\" resolves this issue:
  http://www.veripool.org/issues/922-Verilog-mode-Consistent-comment-column
"
      (save-excursion
        (beginning-of-line)
        (let* ((outline-comment (looking-at "^[[:blank:]]*// \\*+\\s-")) ; // *(space)
               (dont-touch-indentation (looking-at "^.*//\\.")) ; Line contains "//."
               (is-in-multi-line-define (looking-at "^.*\\\\$")) ; \ at EOL
               (do-not-run-orig-fn (or (and (bound-and-true-p outshine-outline-regexp-outcommented-p)
                                            outline-comment)
                                       dont-touch-indentation
                                       is-in-multi-line-define
                                       modi/verilog-multi-line-define-line-cache)))
          ;; Cache the current value of `is-in-multi-line-define'
          (setq modi/verilog-multi-line-define-line-cache is-in-multi-line-define)
          ;; Force remove any indentation for outline comments
          (when (and (bound-and-true-p outshine-outline-regexp-outcommented-p)
                     outline-comment)
            (delete-horizontal-space))
          do-not-run-orig-fn)))
    ;; Advise the indentation behavior of `indent-region' done using `C-M-\'
    (advice-add 'verilog-indent-line-relative :before-until #'modi/verilog-selective-indent)
    ;; Advise the indentation done by hitting `TAB'
    (advice-add 'verilog-indent-line :before-until #'modi/verilog-selective-indent)

;;;; modi/verilog-compile
    (defun modi/verilog-compile (option)
      "Compile verilog/SystemVerilog.
If OPTION is \\='(4) (using `\\[universal-argument]' prefix), run simulation.
If OPTION is \\='(16) (using `\\[universal-argument] \\[universal-argument]' prefix), run linter."
      (interactive "P")
      (cl-case (car option)
        (4  (setq verilog-tool 'verilog-simulator))
        (16 (setq verilog-tool 'verilog-linter))
        (t  (setq verilog-tool 'verilog-compiler)))
      (verilog-set-compile-command)
      (call-interactively #'compile))

    (defun modi/verilog-simulate ()
      "Run verilog/SystemVerilog simulation."
      (interactive)
      (modi/verilog-compile '(4)))

;;;; convert end-block comments to block names
    (defun modi/verilog-end-block-comments-to-block-names ()
      "Convert valid end-block comments to ': BLOCK_NAME'.
Reference: IEEE 1800-2012 SystemVerilog Section 9.3.4 Block Names.

Examples: endmodule // module_name             → endmodule : module_name
          endfunction // some comment          → endfunction // some comment
          endfunction // class_name::func_name → endfunction : func_name
          end // block: block_name             → end : block_name "
      (interactive)
      (save-excursion
        (goto-char (point-min))
        (let* ((end-block-keywords '("end"
                                     "join"
                                     "join_any"
                                     "join_none"
                                     "endchecker"
                                     "endclass"
                                     "endclocking"
                                     "endconfig"
                                     "endfunction"
                                     "endgroup"
                                     "endinterface"
                                     "endmodule"
                                     "endpackage"
                                     "endprimitive"
                                     "endprogram"
                                     "endproperty"
                                     "endsequence"
                                     "endtask"))
               (end-block-keywords-re (regexp-opt end-block-keywords 'words)))
          (while (re-search-forward (concat "^"
                                            "\\(?1:\\s-*" end-block-keywords-re "\\)"
                                            "\\s-*//\\s-*"
                                            "\\(\\(block:\\|"
                                            modi/verilog-identifier-re "\\s-*::\\)\\s-*\\)*"
                                            "\\(?2:" modi/verilog-identifier-re "\\)"
                                            "\\s-*$")
                                    nil :noerror)
            ;; Make sure that the matched string after "//" is not a verilog
            ;; keyword.
            (when (not (string-match-p (regexp-opt verilog-keywords 'words)
                                       (match-string 2)))
              (replace-match "\\1 : \\2"))))))

;;; hideshow
    (with-eval-after-load 'hideshow
      (add-to-list 'hs-special-modes-alist
                   `(verilog-mode ,(concat "\\b\\(begin"
                                           "\\|task"
                                           "\\|function"
                                           "\\|class"
                                           "\\|module"
                                           "\\|program"
                                           "\\|interface"
                                           "\\|module"
                                           "\\|case"
                                           "\\|fork\\)\\b")
                                  ,(concat "\\b\\(end"
                                           "\\|endtask"
                                           "\\|endfunction"
                                           "\\|endclass"
                                           "\\|endmodule"
                                           "\\|endprogram"
                                           "\\|endinterface"
                                           "\\|endmodule"
                                           "\\|endcase"
                                           "\\|join\\|join_none\\|join_any\\)\\b")
                                  nil verilog-forward-sexp-function)))

;;; hydra-verilog-template
    (defhydra hydra-verilog-template (:color blue
                                      :hint nil)
      "
_i_nitial        _?_ if             _j_ fork           _A_ssign                _uc_ uvm-component
_b_egin          _:_ else-if        _m_odule           _I_nput                 _uo_ uvm-object
_a_lways         _f_or              _g_enerate         _O_utput
^^               _w_hile            _p_rimitive        _=_ inout
^^               _r_epeat           _s_pecify          _S_tate-machine         _h_eader
^^               _c_ase             _t_ask             _W_ire                  _/_ comment
^^               case_x_            _F_unction         _R_eg
^^               case_z_            ^^                 _D_efine-signal
"
      ("a"   verilog-sk-always)
      ("b"   verilog-sk-begin)
      ("c"   verilog-sk-case)
      ("f"   verilog-sk-for)
      ("g"   verilog-sk-generate)
      ("h"   verilog-sk-header)
      ("i"   verilog-sk-initial)
      ("j"   verilog-sk-fork)
      ("m"   verilog-sk-module)
      ("p"   verilog-sk-primitive)
      ("r"   verilog-sk-repeat)
      ("s"   verilog-sk-specify)
      ("t"   verilog-sk-task)
      ("w"   verilog-sk-while)
      ("x"   verilog-sk-casex)
      ("z"   verilog-sk-casez)
      ("?"   verilog-sk-if)
      (":"   verilog-sk-else-if)
      ("/"   verilog-sk-comment)
      ("A"   verilog-sk-assign)
      ("F"   verilog-sk-function)
      ("I"   verilog-sk-input)
      ("O"   verilog-sk-output)
      ("S"   verilog-sk-state-machine)
      ("="   verilog-sk-inout)
      ("uc"  verilog-sk-uvm-component)
      ("uo"  verilog-sk-uvm-object)
      ("W"   verilog-sk-wire)
      ("R"   verilog-sk-reg)
      ("D"   verilog-sk-define-signal)
      ("q"   nil nil :color blue)
      ("C-g" nil nil :color blue))

;;; imenu + outshine
    (with-eval-after-load 'outshine
      (defun modi/verilog-outshine-imenu-generic-expression (&rest _)
        "Update `imenu-generic-expression' when using outshine."
        (when (derived-mode-p 'verilog-mode)
          ;; Do not require the "// *" style comments used by `outshine' to start
          ;; at column 0 just for this major mode
          (setq-local outshine-outline-regexp-outcommented-p nil)

          (setq-local imenu-generic-expression
                      (append `(("*Level 1*"
                                 ,(concat "^"
                                          (if (bound-and-true-p outshine-outline-regexp-outcommented-p)
                                              ""
                                            "\\s-*")
                                          "// \\*\\{1\\} \\(?1:.*$\\)")
                                 1)
                                ("*Level 2*"
                                 ,(concat "^"
                                          (if (bound-and-true-p outshine-outline-regexp-outcommented-p)
                                              ""
                                            "\\s-*")
                                          "// \\*\\{2\\} \\(?1:.*$\\)")
                                 1)
                                ("*Level 3*"
                                 ,(concat "^"
                                          (if (bound-and-true-p outshine-outline-regexp-outcommented-p)
                                              ""
                                            "\\s-*")
                                          "// \\*\\{3\\} \\(?1:.*$\\)")
                                 1))
                              verilog-imenu-generic-expression))))
      (advice-add 'outshine-hook-function :after
                  #'modi/verilog-outshine-imenu-generic-expression))

;;; modi/verilog-mode-customization
    (defun modi/verilog-mode-customization ()
      "My customization for `verilog-mode'."
      ;; http://emacs-fu.blogspot.com/2008/12/highlighting-todo-fixme-and-friends.html
      (font-lock-add-keywords nil
                              '(("\\b\\(FIXME\\|TODO\\|BUG\\)\\b" 1
                                 font-lock-warning-face t)))
      ;; Above solution highlights those keywords anywhere in the buffer (not
      ;; just in comments). To do the highlighting intelligently, install the
      ;; `fic-mode' package - https://github.com/lewang/fic-mode

      ;; Convert end-block comments to ': BLOCK_NAME' in verilog-mode.
      (add-hook 'before-save-hook #'modi/verilog-end-block-comments-to-block-names nil :local)

      ;; Replace tabs with spaces when saving files in verilog-mode.
      (add-hook 'before-save-hook #'modi/untabify-buffer nil :local))

    ;; *Append* `modi/verilog-mode-customization' to `verilog-mode-hook' so that
    ;; that function is run very last of all other functions added to that hook.
    (add-hook 'verilog-mode-hook #'modi/verilog-mode-customization :append)

;;; Key bindings
    (bind-keys
     :map verilog-mode-map
      ;; Unbind the backtick binding done to `electric-verilog-tick'
      ;; With binding done to `electric-verilog-tick', it's not possible to type
      ;; backticks on multiple lines simultaneously in multiple-cursors mode.
      ("`"         . nil)
      ;; Bind `verilog-header' to "C-c C-H" instead of to "C-c C-h"
      ("C-c C-h"   . nil)
      ("C-c C-S-h" . verilog-header)
      ;;
      ("C-c C-t"   . hydra-verilog-template/body)
      ("C-^"       . modi/verilog-jump-to-header-dwim)
      ("C-&"       . modi/verilog-jump-to-header-dwim-fwd)
      ("<f9>"      . modi/verilog-compile)
      ("<S-f9>"    . modi/verilog-simulate))
    (bind-chord "\\\\" #'modi/verilog-jump-to-module-at-point verilog-mode-map) ; "\\"
    (when (executable-find "ag")
      (bind-chord "^^" #'modi/verilog-find-parent-module verilog-mode-map))))


(provide 'setup-verilog)

;; Convert $display statements to `uvm_info statements
;; Regex Search Expression - \$display(\(.*?\));\(.*\)
;; Replace Expression - `uvm_info("REPLACE_THIS_GENERIC_ID", $sformatf(\1), UVM_MEDIUM) \2

;; Local Variables:
;; aggressive-indent-mode: nil
;; End:
