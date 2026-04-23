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

(after! lsp-mode
  (setq lsp-diagnostics-provider :flycheck)

  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection "nixd")
    :major-modes '(nix-mode)
    :priority 1
    :server-id 'nixd)))

(after! flycheck
  (flycheck-add-mode 'statix 'nix-mode))

(after! nix-mode
  (add-hook 'nix-mode-hook #'lsp-deferred)

  (add-hook 'nix-mode-hook
            (lambda ()
              (add-to-list 'flycheck-disabled-checkers 'nix)
              (setq-local company-idle-delay 0.1))))

(after! lsp-nix
  (let* ((repo (or (getenv "NIXOS_CONFIG")
                   (expand-file-name "~/nixos-config")))
         (flake (format "(builtins.getFlake \"%s\")" repo))
         (is-darwin (eq system-type 'darwin)))
    (setq lsp-nix-nixd-server-path "nixd"
          lsp-nix-nixd-formatting-command [ "nixfmt" ]
          lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"
          lsp-disabled-clients '((nix-mode . nix-nil))

          lsp-nix-nixd-nixos-options-expr
          (if is-darwin
              (format "%s.darwinConfigurations.macbook.options" flake)
            (format "%s.nixosConfigurations.gibson.options" flake))

          lsp-nix-nixd-home-manager-options-expr
          (if is-darwin
              (format "%s.darwinConfigurations.macbook.config.home-manager.users.rickie.home.options" flake)
            (format "%s.nixosConfigurations.gibson.config.home-manager.users.rickie.home.options" flake)))))

(remove-hook 'markdown-mode-hook #'pretty-symbols-mode)
(set-fontset-font t 'unicode "Noto Color Emoji" nil 'append)
(set-fontset-font t 'emoji (font-spec :family "Noto Color Emoji") nil 'prepend)

(remove-hook 'company-mode-hook #'company-box-mode)

(setq-default line-spacing 0.2)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)

(setq mac-option-modifier 'meta
      mac-command-modifier 'super
      mac-right-option-modifier 'none)

;; improve colours for magit; makes them more like github darkmode
(defun change-magit-diff-faces ()
(set-face-attribute 'magit-section-highlight nil :background "#1b2330")
(set-face-attribute 'magit-diff-hunk-heading nil :foreground "#9fb1c1" :background "#1f2a38")
(set-face-attribute 'magit-diff-hunk-heading-highlight nil :foreground "#dce6f0" :background "#263445")
(set-face-attribute 'magit-diff-context-highlight nil :background "#1b2330")
(add-hook 'magit-mode-hook #'change-magit-diff-faces)
(add-hook 'doom-load-theme-hook #'change-magit-diff-faces)
