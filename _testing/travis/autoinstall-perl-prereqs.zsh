#!/bin/zsh

. ./_testing/_get_files_arr.zsh

local -a modlist
modlist=($(scan-perl-prereqs $filelist))

sudo apt-file update >/dev/null 2>&1

local -a ubu_pkgs
local -a cpan_mods
for mod ($modlist) {
    mod=${mod%\~*}
    if [[ $mod != Irssi* && $mod != feature ]] {
        if { ! perl -M$mod -E1 2>/dev/null } {
            local -a ubu_pkg
            ubu_pkg=($(apt-file -l search "/perl5/${mod//:://}.pm"))
            if [[ $#ubu_pkg -gt 0 ]] { ubu_pkgs+=($ubu_pkg) } \
            else { cpan_mods+=($mod) }
        }
    }
}

if [[ $#ubu_pkgs -gt 0 ]] { sudo apt-get install -qq $ubu_pkgs }

typeset -A broken_tests
typeset -A broken_mods

broken_tests=($(perl -MYAML::Tiny=LoadFile -e'print "$_ 1 " for @{LoadFile(+shift)->{cpan}{broken_tests}}' _testing/config.yml))
broken_mods=($(perl -MYAML::Tiny=LoadFile -e'print "$_ 1 " for @{LoadFile(+shift)->{cpan}{broken_modules}}' _testing/config.yml))

for mod ($cpan_mods) {
    if { ! perl -M$mod -E1 2>/dev/null } {
        local skip_test=
        if [[ -n $broken_tests[$mod] ]] {
            skip_test=--notest
            echo Skipping broken test on $mod
        }
        if [[ -n $broken_mods[$mod] ]] {
            echo SKIPPING AUTOINSTALL OF BROKEN MODULE $mod
        } \
        else {
            echo Auto-installing $mod
            sudo cpanm -q --skip-satisfied $skip_test $mod
        }
    }
}
exit 0
