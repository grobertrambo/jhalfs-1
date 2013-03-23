# $Id$

check_version() {
: <<inline_doc
      Tests for a minimum version level. Compares to version numbers and forces an
        exit if minimum level not met.
      NOTE: This test will fail on versions containing alpha chars. ie. jpeg 6b

    usage:	check_version "2.6.2" "`uname -r`"         "KERNEL"
		check_version "3.0"   "$BASH_VERSION"      "BASH"
		check_version "3.0"   "`gcc -dumpversion`" "GCC"

    input vars: $1=min acceptable version
    		$2=version to check
		$3=app name
    externals:  --
    modifies:   --
    returns:    nothing
    on error:	write text to console and dies
    on success: write text to console and returns
inline_doc

  declare -i major minor revision change
  declare -i ref_major ref_minor ref_revision ref_change
  declare -r spaceSTR="         "

  shopt -s extglob	#needed for ${x##*(0)} below

  ref_version=$1
  tst_version=$2
  TXT=$3

  # This saves us the save/restore hassle of the system IFS value
  local IFS

  write_error_and_die() {
     echo -e "\n\t\t$TXT version -->${tst_version}<-- is too old.
		    This script requires ${ref_version} or greater\n"
   # Ask the user instead of bomb, to make happy that packages which version
   # ouput don't follow our expectations
    echo "If you are sure that you have instaled a proper version of ${BOLD}$TXT${OFF}"
    echo "but jhalfs has failed to detect it, press 'c' and 'ENTER' keys to continue,"
    echo -n "otherwise press 'ENTER' key to stop jhalfs.  "
    read ANSWER
    if [ x$ANSWER != "xc" ] ; then
      echo "${nl_}Please, install a proper $TXT version.${nl_}"
      exit 1
    else
      minor=$ref_minor
      revision=$ref_revision
    fi
  }

  echo -ne "${TXT}${dotSTR:${#TXT}} ${L_arrow}${BOLD}${tst_version}${OFF}${R_arrow}"

#  echo -ne "$TXT:\t${L_arrow}${BOLD}${tst_version}${OFF}${R_arrow}"
  IFS=".-(pa"   # Split up w.x.y.z as well as w.x.y-rc  (catch release candidates)
  set -- $ref_version # set positional parameters to minimum ver values
  ref_major=$1; ref_minor=$2; ref_revision=$3
  #
  set -- $tst_version # Set positional parameters to test version values
  # Values beginning with zero are taken as octal, so that for example
  # 2.07.08 gives an error because 08 cannot be octal. The ## stuff supresses
  # leading zero's
  major=${1##*(0)}; minor=${2##*(0)}; revision=${3##*(0)}
  #
  # Compare against minimum acceptable version..
  (( major > ref_major )) && echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF}" && return
  (( major < ref_major )) && write_error_and_die
    # major=ref_major
  (( minor < ref_minor )) && write_error_and_die
  (( minor > ref_minor )) && echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF}" && return
    # minor=ref_minor
  (( revision >= ref_revision )) && echo " ${spaceSTR:${#tst_version}}${GREEN}OK${OFF}" && return

  # oops.. write error msg and die
  write_error_and_die
}
#  local -r PARAM_VALS='${config_param}${dotSTR:${#config_param}} ${L_arrow}${BOLD}${!config_param}${OFF}${R_arrow}'

#----------------------------#
check_prerequisites() {      #
#----------------------------#

  # Avoid translation of version strings
  local LC_ALL=C
  export LC_ALL

  # LFS/HLFS/CLFS prerequisites
  check_version "2.6.25"  "`uname -r`"          "KERNEL"
  check_version "3.2"     "$BASH_VERSION"       "BASH"
  check_version "4.1.2"   "`gcc -dumpversion`"  "GCC"  
  check_version "2.5.1"   "$(ldd --version  | head -n1 | awk '{print $NF}')"        "GLIBC"
  check_version "2.17"    "$(ld --version  | head -n1 | awk '{print $NF}')"    "BINUTILS"
  check_version "1.18"    "$(tar --version | head -n1 | cut -d" " -f4)"        "TAR"
  bzip2Ver="$(bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f8)"
  check_version "1.0.4"   "${bzip2Ver%%,*}"                                    "BZIP2"
  check_version "2.3"     "$(bison --version | head -n1 | cut -d" " -f4)"      "BISON"
  check_version "6.9"     "$(chown --version | head -n1 | cut -d")" -f2)"      "COREUTILS"
  check_version "2.8.1"   "$(diff --version  | head -n1 | cut -d" " -f4)"      "DIFF"
  check_version "4.2.31"  "$(find --version  | head -n1 | cut -d" " -f4)"      "FIND"
  check_version "3.1.5"   "$(gawk --version  | head -n1 | cut -d" " -f3)"      "GAWK"
  check_version "2.5.1a"  "$(grep --version  | head -n1 | awk '{print $NF}')"  "GREP"
  check_version "1.3.12"  "$(gzip --version 2>&1 | head -n1 | cut -d" " -f2)"  "GZIP"
  check_version "1.4.10"  "$(m4 --version 2>&1 | head -n1 | awk '{print $NF}')" "M4"
  check_version "3.81"    "$(make --version  | head -n1 | cut -d " " -f3 | cut -c1-4)"  "MAKE"
  check_version "2.5.4"   "$(patch --version | head -n1 | sed 's/.*patch //')"      "PATCH"
  check_version "5.8.8"   "$(perl -V:version | cut -f2 -d\')"                  "PERL"
  check_version "4.1.5"   "$(sed --version   | head -n1 | cut -d" " -f4)"      "SED"
  check_version "4.9"	  "$(makeinfo --version | head -n1 | awk '{ print$NF }')" "TEXINFO"
  check_version "5.0.0"   "$(xz --version | head -n1 | cut -d" " -f4)"         "XZ"
  # Check for minimum sudo version
  SUDO_LOC="$(whereis -b sudo | cut -d" " -f2)"
  if [ -x $SUDO_LOC ]; then
    sudoVer="$(sudo -V | head -n1 | cut -d" " -f3)"
    check_version "1.7.0"  "${sudoVer}"      "SUDO"
  else
    echo "${nl_}\"${RED}sudo${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi

  # Check for minimum wget version
  WGET_LOC="$(whereis -b wget | cut -d" " -f2)"
  if [ -x $WGET_LOC ]; then
    wgetVer="$(wget --version | head -n1 | cut -d" " -f3)"
    check_version "1.0.0"  "${wgetVer}"      "WGET"
  else
    echo "${nl_}\"${RED}wget${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi

  # Before checking libmxl2 and libxslt version information, ensure tools needed from those
  # packages are actually available. Avoids a small cosmetic bug of book version information
  # not being retrieved if xmllint is unavailable, especially when on recent non-LFS hosts.

  XMLLINT_LOC="$(whereis -b xmllint | cut -d" " -f2)"
  XSLTPROC_LOC="$(whereis -b xsltproc | cut -d" " -f2)"
  XML_NOTE_MSG="${nl_} ${BOLD} This can happen when running jhalfs on non-LFS hosts. ${OFF}"
  
  if [ ! -x $XMLLINT_LOC ]; then
    echo "${nl_}\"${RED}xmllint${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    echo ${XML_NOTE_MSG}
    exit 1
  fi

  if [ -x $XSLTPROC_LOC ]; then

  # Check for minimum libxml2 and libxslt versions
  xsltprocVer=$(xsltproc -V | head -n1 )
  libxmlVer=$(echo $xsltprocVer | cut -d " " -f3)
  libxsltVer=$(echo $xsltprocVer | cut -d " " -f5)

  # Version numbers are packed strings not xx.yy.zz format.
  check_version "2.06.20"  "${libxmlVer:0:1}.${libxmlVer:1:2}.${libxmlVer:3:2}"     "LIBXML2"
  check_version "1.01.14"  "${libxsltVer:0:1}.${libxsltVer:1:2}.${libxsltVer:3:2}"  "LIBXSLT"
  
  else
    echo "${nl_}\"${RED}xsltproc${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    echo ${XML_NOTE_MSG}
    exit 1
  fi
  # The next versions checks are required only when BLFS_TOOL is set and
  # this dependencies has not be selected for installation
  if [[ "$BLFS_TOOL" = "y" ]] ; then

    if [[ -z "$DEP_TIDY" ]] ; then
      tidyVer=$(tidy -V | cut -d " " -f9)
      check_version "2004" "${tidyVer}" "TIDY"
    fi

    # Check if the proper DocBook-XML-DTD and DocBook-XSL are correctly installed
XML_FILE="<?xml version='1.0' encoding='ISO-8859-1'?>
<?xml-stylesheet type='text/xsl' href='http://docbook.sourceforge.net/release/xsl/1.69.1/xhtml/docbook.xsl'?>
<!DOCTYPE article PUBLIC '-//OASIS//DTD DocBook XML V4.5//EN'
  'http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd'>
<article>
  <title>Test file</title>
  <sect1>
    <title>Some title</title>
    <para>Some text</para>
  </sect1>
</article>"

    if [[ -z "$DEP_DBXML" ]] ; then
      if `echo $XML_FILE | xmllint -noout -postvalid - 2>/dev/null` ; then
        check_version "4.5" "4.5" "DocBook XML DTD"
      else
        echo "Warning: not found a working DocBook XML DTD 4.5 installation"
        exit 2
      fi
    fi

#     if [[ -z "$DEP_DBXSL" ]] ; then
#       if `echo $XML_FILE | xsltproc --noout - 2>/dev/null` ; then
#         check_version "1.69.1" "1.69.1" "DocBook XSL"
#       else
#         echo "Warning: not found a working DocBook XSL 1.69.1 installation"
#         exit 2
#       fi
#     fi

  fi # end BLFS_TOOL=Y

}
