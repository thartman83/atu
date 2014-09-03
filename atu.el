;;; atu.el --- Autotools utility functions

;; Copyright (c) 2014 Thomas Hartman (thomas.lees.hartman@gmail.com)

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; Autotools functions and utilities

;;; Code:

(require 'f)
(require 'ht)

(defvar *default-makefile.am*
  "AUTOMAKE_OPTIONS = 1.4
ACLOCAL_AMFLAGS = -I config

SUBDIRS =

EXTRA_DIST = BUGS INSTALL-unix $(m4sources)")

(defvar *default-configure.ac*
"dnl Process this file with autoconf to produce a configure script.

AC_PREREQ(2.26)

m4_define([%project-name%_major_version], [0])
m4_define([%project-name%_minor_version], [1])
m4_define([%project-name%_version], \\
          [%project-name%_major_version.%project-name%_minor_version])

AC_INIT([%project-name%],[1.0])
AC_CONFIG_MACRO_DIR([config])
AM_INIT_AUTOMAKE([1.11 dist-bzip2])
LT_PREREQ([2.2])
LT_INIT([dlopen])

AC_SUBST(%PROJECT-NAME%_MAJOR_VERSION, [%project-name%_major_version])
AC_SUBST(%PROJECT-NAME%_MINOR_VERSION, [%project-name%_minor_version])
AC_SUBST(%PROJECT-NAME%_VERSION, [%project-name%_version])

dnl Check for programs

AC_CONFIG_FILES([Makefile])

AC_OUTPUT")

(defun atu-generate-default-makefile.am (dir)
  (interactive "DProject root: ")
  (when (f-exists? (f-join dir "Makefile.am"))
    (error "%s already exists, will not clobber" (f-join dir "Makefile.am")))
  (f-write-text *default-makefile.am* 'utf-8 (f-join dir "Makefile.am")))

(defun atu-generate-default-configure.ac (dir project-name)
  (interactive "DProject root: \nsProject name: ")
  (when (f-exists? (f-join dir "configure.ac"))
    (error "%s already exists, will not clobber" (f-join dir "configure.ac")))
  (f-write-text (atu-format *default-configure.ac*
                            (ht (:project-name project-name)))
                'utf-8 "configure.ac"))

(defun atu-add-makefile.am-subdir (subdir makefile.am)
  "Add SUBDIR to the list of 'SUBDIRS' values in MAKEFILE.AM"
  (when (not (f-exists? makefile.am))
    (error "%s does not exist" makefile.am))
  (let ((text (f-read makefile.am)))
    (when (not (string-match "SUBDIRS[ \t]*=\\(.*\\)$" text))
      (error "%s does not contain a SUBDIRS variable to set" makefile.am))
    (let ((i (match-beginning 1))
          (j (match-end 1)))
      (when (not (member subdir (split-string (substring text i j) " " t)))
        (f-write (concat (substring text 0 j) " " subdir " " (substring text j))
                 'utf-8 makefile.am)))))

(defun atu-add-ac-config-files (subdir configure.ac)
  "Add AC_CONFIG([SUBDIR]/Makefile) to CONFIGURE.AC ."
  (when (not (f-exists? configure.ac))
    (error "%s does not exist" configure.ac))
  (let ((text (f-read configure.ac)))
    (when (not (string-match "AC_OUTPUT" text))
      (error "%s does not contain AC_OUTPUT, may not be autoconf file" configure.ac))
    (let ((i (match-beginning 0))
          (j (match-end 0)))
      (when (not (string-match (format "AC_CONFIG_FILES(\\[%s/Makefile\\])" subdir) text))
        (f-write (concat (substring text 0 i)
                         (format "# %s\n" subdir)
                         (format "AC_CONFIG_FILES([%s/Makefile])\n" subdir)
                         (format "AC_CONFIG_FILES([%s/src/Makefile])\n" subdir)
                         (substring text i))
                 'utf-8 configure.ac)))))

(defun atu-format (str test-suite)
  "Scan the STR for %*% and replace with the hash value associated in TEST-SUITE."
  (let ((retval str))
    (maphash #'(lambda (key val)
                 (setf str (replace-regexp-in-string
                            (concat "%" (substring (symbol-name key) 1) "%") val str)))
             test-suite)
    str))

(defun atu-autoreconf (path)
  "Run autoreconf -i from the PATH."
  (start-shell-process))

(provide 'atu)

;;; atu.el ends here
