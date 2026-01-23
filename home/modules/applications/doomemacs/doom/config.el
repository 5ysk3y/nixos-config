;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-dracula)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(require 'gnus-dired)
;; make the `gnus-dired-mail-buffers' function also work on
;; ;; message-mode derived modes, such as mu4e-compose-mode
(defun gnus-dired-mail-buffers ()
  "Return a list of active message buffers."
    (let (buffers)
      (save-current-buffer
         (dolist (buffer (buffer-list t))
            (set-buffer buffer)
               (when (and (derived-mode-p 'message-mode)
                   (null message-sent-message-via))
               (push (buffer-name buffer) buffers))))
            (nreverse buffers)))

(setq gnus-dired-mail-mode 'mu4e-user-agent)
(add-hook 'dired-mode-hook 'turn-on-gnus-dired-mode)

(setq initial-major-mode 'conf-mode)
(global-visual-line-mode t)

(setq confirm-kill-emacs nil)

(set-frame-parameter nil 'alpha-background 80)
(add-to-list 'default-frame-alist '(alpha-background . 80))
;;(set-frame-parameter (selected-frame) 'alpha '(95))
;;(add-to-list 'default-frame-alist '(alpha . (95)))

(with-eval-after-load 'lsp-mode
  (lsp-register-client
    (make-lsp-client :new-connection (lsp-stdio-connection "nixd")
                     :major-modes '(nix-mode)
                     :priority 0
                     :server-id 'nixd)))

(use-package nix-mode
:after lsp-mode
:ensure t
:hook
(nix-mode . lsp-deferred) ;; So that envrc mode will work
:custom
(lsp-disabled-clients '((nix-mode . nix-nil))) ;; Disable nil so that nixd will be used as lsp-server
:config
(setq lsp-nix-nixd-server-path "nixd"
      lsp-nix-nixd-formatting-command [ "nixfmt" ]
      lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"

      ;; Use $NIXOS_CONFIG when available so Linux and macOS both work.
      lsp-nix-nixd-nixos-options-expr
      (let* ((repo (or (getenv "NIXOS_CONFIG")
                       (expand-file-name "~/nixos-config")))
             (flake (format "(builtins.getFlake \"%s\")" repo)))
        (format "%s.nixosConfigurations.gibson.options" flake))

      lsp-nix-nixd-home-manager-options-expr
      (let* ((repo (or (getenv "NIXOS_CONFIG")
                       (expand-file-name "~/nixos-config")))
             (flake (format "(builtins.getFlake \"%s\")" repo)))
        (format "%s.nixosConfigurations.gibson.config.home-manager.users.rickie.home.options" flake)))

(add-hook! 'nix-mode-hook
         ;; enable autocompletion with company
         (setq company-idle-delay 0.1))

(remove-hook 'markdown-mode-hook #'pretty-symbols-mode)
(set-fontset-font t 'unicode "Noto Color Emoji" nil 'append)
(set-fontset-font t 'emoji (font-spec :family "Noto Color Emoji") nil 'prepend)

(remove-hook 'company-mode-hook #'company-box-mode)

(setq-default line-spacing 0.2)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)
