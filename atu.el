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

(provide 'atu)

;;; atu.el ends here
