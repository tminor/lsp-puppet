;;; lsp-puppet.el --- Emacs Puppet lsp client -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Thomas Minor

;; Author: Thomas Minor <minort@gmail.com>
;; Created: 12 Nov 2020
;; Version: 0.0.1
;; Keywords: languages, tools, puppet
;; URL: https://github.com/minort/lsp-puppet
;; Package-Requires: ((emacs "25") (lsp-mode "6.3") (ht "2.3"))
;; License: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Adds support for Puppet LSP and editor services.

;;; Code:

(require 'lsp-mode)
(require 'ht)
(require 'dash)

(defgroup lsp-puppet nil
  "Puppet lsp server group"
  :prefix "lsp-puppet-"
  :group 'lsp-mode
  :link '(url-link "https://github.com/minort/lsp-puppet")
  :package-version '(lsp-mode . "6.4"))

(defcustom lsp-puppet-server-install-dir
  (f-join lsp-server-install-dir "puppet/")
  "Puppet Language Server install directory.
A trailing slash is expected."
  :group 'lsp-puppet
  :risky t
  :type 'directory)

(defcustom lsp-puppet-modulepath '()
  "Path to Puppet modules."
  :group 'lsp-puppet
  :type 'list)

(defcustom lsp-puppet-vardir nil
  "Path to Puppet's cache directory."
  :group 'lsp-puppet
  :type 'directory)


(defun lsp-puppet-server-start-fun ()
  "Puppet LSP start function."
  (remove nil
          `("bundle"
            "exec"
            "ruby"
            ,(concat lsp-puppet-server-install-dir "puppet-languageserver")
            "--timeout=0"
            "--slow-start"
            "--no-stop"
            "--stdio"
            "--debug=stdio"
            ,(when (or lsp-puppet-modulepath
                       lsp-puppet-vardir)
               (concat "--puppet-settings="
                       (string-join `(,@(when (bound-and-true-p lsp-puppet-modulepath)
                                          (list "--modulepath"
                                                (string-join lsp-puppet-modulepath ":")))
                                      ,@(when (bound-and-true-p lsp-puppet-vardir)
                                          (list "--vardir" lsp-puppet-vardir)))
                                    ","))))))

(add-to-list 'lsp-language-id-configuration '(puppet-mode . "puppet-ls"))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection 'lsp-puppet-server-start-fun)
  :major-modes '(puppet-mode)
  :priority -1
  :multi-root t
  :server-id 'puppet-ls
  :environment-fn (lambda ()
                    `(("BUNDLE_GEMFILE" . ,(concat lsp-puppet-server-install-dir "Gemfile"))))
  :initialized-fn (lambda (workspace)
                    (with-lsp-workspace workspace
                      (lsp--set-configuration
                       (lsp-configuration-section "puppet"))))))

(provide 'lsp-puppet)
;;; lsp-puppet.el ends here
