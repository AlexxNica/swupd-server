# NOTE: source this file from a *.bats file

# The location of the swupd_* binaries
export SRCDIR="$BATS_TEST_DIRNAME/../../../"

export CREATE_UPDATE="$SRCDIR/swupd_create_update"
export MAKE_FULLFILES="$SRCDIR/swupd_make_fullfiles"
export MAKE_PACK="$SRCDIR/swupd_make_pack"

export DIR="$BATS_TEST_DIRNAME/web-dir"

init_test_dir() {
  local testdir="$BATS_TEST_DIRNAME"
  mkdir -p "$testdir"/logs
  mkdir -p $DIR/{image,www}
  # run swupd_* inside the directory to dump the logs
  cd "$testdir"/logs
}

clean_test_dir() {
  sudo rm -rf $DIR "$BATS_TEST_DIRNAME"/logs
}

init_server_ini() {
  cp $SRCDIR/server.ini $DIR
  sed -i "s|/var/lib/update|$DIR|" $DIR/server.ini
}

set_latest_ver() {
  echo "$1" > $DIR/image/LAST_VER
}

init_groups_ini() {
  for bundle in "$@"; do
    cat >> $DIR/groups.ini << EOF
[$bundle]
group=$bundle
status=ACTIVE
EOF
  done
}

# If the variable RUN_JUST_ONE is set then only run that test
maybeskip() {
    [ -z "$RUN_JUST_ONE" ] || [ "$RUN_JUST_ONE" -eq "$BATS_TEST_NUMBER" ] || skip
}

set_os_release() {
  local ver=$1
  local bundle=$2
  mkdir -p $DIR/image/$ver/$bundle/usr/lib/
  echo "VERSION_ID=$ver" > $DIR/image/$ver/$bundle/usr/lib/os-release
}

track_bundle() {
  local ver=$1
  local bundle=$2
  mkdir -p $DIR/image/$ver/$bundle/usr/share/clear/bundles
  touch $DIR/image/$ver/$bundle/usr/share/clear/bundles/$bundle
}

gen_includes_file() {
  local bundle=$1
  local ver=$2
  local includes="${@:3}"
  mkdir -p $DIR/image/$ver/noship
  for b in $includes; do
    cat >> $DIR/image/$ver/noship/"$bundle"-includes << EOF
$b
EOF
  done
}

gen_file_to_delta() {
  local origver=$1
  local origsize=$2
  local newver=$3
  local newbytes=$4
  local bundle=$5
  local name=$6

  # create some random data for the original version
  mkdir -p $DIR/image/$origver/$bundle
  dd if=/dev/urandom of=$DIR/image/$origver/$bundle/$name bs=1 count=$origsize

  # append more random data to the end of the file in the new version
  TMP=$(mktemp foo.XXXXXX)
  mkdir -p $DIR/image/$newver/$bundle
  dd if=/dev/urandom of=$TMP bs=1 count=$newbytes
  cat $DIR/image/$origver/$bundle/$name $TMP > $DIR/image/$newver/$bundle/$name
  rm $TMP
}

gen_file_plain() {
  local ver=$1
  local bundle=$2
  local name="$3"

  # Add plain text file into a bundle
  case "$name" in
      (*"/"*)	mkdir -p "$DIR/image/$ver/$bundle/${name%/*}" ;;
      (*)	mkdir -p $DIR/image/$ver/$bundle ;;
  esac
  echo "$name" > $DIR/image/$ver/$bundle/"$name"
}

gen_file_plain_change() {
  local ver=$1
  local bundle=$2
  local name="$3"

  # Add plain text file into a bundle
  case "$name" in
      (*"/"*)	mkdir -p "$DIR/image/$ver/$bundle/${name%/*}" ;;
      (*)	mkdir -p $DIR/image/$ver/$bundle ;;
  esac
  echo "$ver $name" > $DIR/image/$ver/$bundle/"$name"
}

gen_symlink_to_file() {
  local ver=$1
  local bundle=$2
  local symname="$3"
  local filename="$4"

  mkdir -p $DIR/image/$ver/$bundle/$(dirname "$symname")
  ln -s "$filename" $DIR/image/$ver/$bundle/"$symname"
}

copy_file() {
  local origver=$1
  local origbundle=$2
  local origname="$3"
  local newver=$4
  local newbundle=$5
  local newname="$6"

  mkdir -p $DIR/image/$newver/$newbundle/$(dirname "$newname")
  cp -a $DIR/image/$origver/$origbundle/"$origname" $DIR/image/$newver/$newbundle/"$newname"
}

# Gets the hash for file NAME in BUNDLE manifest for VER
hash_for() {
  local ver=$1
  local bundle=$2
  local name="$3"

  awk -F'\t' -v NAME="$name" 'NF == 4 && $4 == NAME { print $2 }' $DIR/www/$ver/Manifest.$bundle
}

gen_file_plain_with_content() {
  local ver=$1
  local bundle=$2
  local name="$3"
  local content="$4"
  case "$name" in
      (*"/"*)	mkdir -p "$DIR/image/$ver/$bundle/${name%/*}" ;;
      (*)	mkdir -p $DIR/image/$ver/$bundle ;;
  esac
  echo "$content" > $DIR/image/$ver/$bundle/"$name"
}

# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
