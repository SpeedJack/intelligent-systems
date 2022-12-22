#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([is-doc], [1.0.0], [https://github.com/SpeedJack/intelligent-systems])
AC_CONFIG_SRCDIR([documentation.tex])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign -Wall -Werror])

# Checks for programs.

AC_PROG_LATEXMK
AC_PROG_PDFLATEX
AC_PROG_BIBTEX
AC_LATEX_CLASS_REPORT
AC_LATEX_CLASS_BEAMER
AC_LATEX_PACKAGE_FONTENC
AC_LATEX_PACKAGE_AMSMATH
AC_LATEX_PACKAGES_REQUIRE([babel, inputenc, lmodern, csquotes, microtype,
	geometry, etoolbox, suffix, minibox, pdflscape, xcolor, graphicx,
	float, titlesec, caption, subcaption, tcolorbox, interval, array,
	makecell, enumitem, listings, nameref, varioref, hyperref, biblatex,
	gitinfo2])

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([Makefile])

AC_OUTPUT
