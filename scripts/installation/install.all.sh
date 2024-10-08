#!/bin/bash
set -e

SCRIPT_FILE="$(readlink --canonicalize-existing "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_FILE")"
export target_install_path=$SCRIPT_DIR/installed
export target_install_path_jddlab=$target_install_path/usr/local/jddlab
export venv=/usr/local/python-venv
export PATH="/root/.cargo/bin:$PATH"
mkdir -p $target_install_path/usr/local $target_install_path_jddlab

pushd $SCRIPT_DIR
for filename in ??.*.sh; do
  source $filename
done
popd

build_info=$target_install_path_jddlab/version.txt
echo "jddlab build $DOCKER_IMAGE_BUILD_VERSION created at `date "+%+4Y-%m-%d %H:%M"`" >$build_info

software_list_file=$target_install_path_jddlab/software-list.txt
echo -n "" >$software_list_file

pushd $target_install_path/usr/local
for dir in *; do
  if [ ! -d "$dir" ]; then continue; fi
  pushd $dir
  if compgen -G "*.software_version.txt" > /dev/null; then
    echo "Group: $dir"   >>$software_list_file
    for filename in *.software_version.txt; do
      name="${filename%.software_version.txt}"
      echo "  Tool: $name" >>$software_list_file
      info_ver=`sed -n '1p' $filename`
      info_page=`sed -n '2p' $filename`
      info_fname=`sed -n '3p' $filename`
      info_furl=`sed -n '4p' $filename`
      echo "    Version: $info_ver"       >>$software_list_file
      echo "    Url: $info_page"          >>$software_list_file
      if [ -n "$info_fname" ]; then echo "    File: $info_fname"        >>$software_list_file; fi
      if [ -n "$info_furl" ]; then  echo "    Download-Url: $info_furl" >>$software_list_file; fi
    done
  fi
  popd
done
popd

# Preparing welcome screen and prompt
echo '[ ! -z "$TERM" -a -r /etc/motd -a ! -f ~/.motd.shown ] && cat /etc/motd && echo 1 >~/.motd.shown' >> $target_install_path/$HOME/.bashrc
echo "PS1='\[\u@jddlab:\w\$ '" >>$target_install_path/$HOME/.bashrc
chmod +x $target_install_path/$HOME/.bashrc
echo -e "Welcome to `cat $build_info`\n"  >$target_install_path/etc/motd
echo -e "List of available commands: `ls $target_install_path/usr/local/bin/ | tr '\n' ' '`\n" >>$target_install_path/etc/motd
