;;; atomic-chrome-tests.el --- Tests for atomic-chrome -*- lexical-binding: t; -*-

(require 'ert)
(require 'atomic-chrome)

(ert-deftest atomic-chrome-emacsclient-command-includes-frame-arguments ()
  (let ((buffer (generate-new-buffer " *atomic-command*")))
    (unwind-protect
        (let ((command (atomic-chrome--emacsclient-command
                        buffer
                        '((left . 10) (right . 110) (top . 20)
                          (width . 100) (height . 40)))))
          (should (equal (car command) "emacsclient"))
          (should (member "-n" command))
          (should (member "-c" command))
          (should (member "-F" command))
          (should (member "-e" command))
          (should (string-match-p "atomic-chrome--display-buffer-in-client-frame"
                                  (car (last command)))))
      (kill-buffer buffer))))

(ert-deftest atomic-chrome-display-buffer-in-client-frame-registers-frame ()
  (let ((buffer (generate-new-buffer " *atomic-frame*")))
    (unwind-protect
        (progn
          (puthash buffer (list nil nil '("https://example.com" "Title" nil))
                   atomic-chrome-buffer-table)
          (atomic-chrome--display-buffer-in-client-frame (buffer-name buffer))
          (should (eq (atomic-chrome-get-frame buffer) (selected-frame)))
          (with-current-buffer buffer
            (should atomic-chrome--emacsclient-buffer)
            (should atomic-chrome-emacsclient-edit-mode)))
      (remhash buffer atomic-chrome-buffer-table)
      (kill-buffer buffer))))

(ert-deftest atomic-chrome-edit-mode-only-enables-emacsclient-keymap-when-needed ()
  (let ((client-buffer (generate-new-buffer " *atomic-client*"))
        (plain-buffer (generate-new-buffer " *atomic-plain*")))
    (unwind-protect
        (progn
          (with-current-buffer client-buffer
            (setq-local atomic-chrome--emacsclient-buffer t)
            (atomic-chrome-edit-mode 1)
            (should atomic-chrome-emacsclient-edit-mode))
          (with-current-buffer plain-buffer
            (setq-local atomic-chrome--emacsclient-buffer nil)
            (atomic-chrome-edit-mode 1)
            (should-not atomic-chrome-emacsclient-edit-mode)))
      (kill-buffer client-buffer)
      (kill-buffer plain-buffer))))

