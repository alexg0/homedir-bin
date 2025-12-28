#!/bin/zsh

# keeping these definitions here, since zsh_aliases may not be read

hb_prefix_arm="/opt/homebrew"
hb_prefix_intel="/usr/local"

hb_shellenv_arm=$(${hb_prefix_arm}/bin/brew shellenv 2> /dev/null)
hb_shellenv_intel=$(${hb_prefix_intel}/bin/brew shellenv 2> /dev/null)

abrew() { (eval $hb_shellenv_arm; eval "${hb_prefix_arm}/bin/brew $*" ) }
ibrew() { (eval $hb_shellenv_intel; eval "${arch_cmd_intel} ${hb_prefix_intel}/bin/brew $*" ) }


# Function to migrate packages
migrate_packages() {
  local uninstall_cmd=$1
  local pkg_list=$2
  local install_cmd=$3
  local cmd pkg

  for pkg in $pkg_list; do
    echo "Uninstalling $pkg..."
    cmd="$uninstall_cmd $pkg"
    echo "running: $cmd"
    $cmd
    if [ $? -ne 0 ]; then
      echo "Error uninstalling $pkg"
      exit 1
    fi

    echo "Installing $pkg..."
    cmd="$install_cmd $pkg"
    echo "running: $cmd"
    $cmd
    if [ $? -ne 0 ]; then
      echo "Error installing $pkg"
      exit 1
    fi
  done
}

taps=$(comm -23 <(ibrew tap | sort) <(abrew tap | sort))
echo "Taps to migrate: $taps"
for n in $taps; do
  abrew tap $n
done

# Migrate normal packages
echo "Migrating normal packages..."
pkg_list=$(ibrew list --formula)
migrate_packages "ibrew uninstall --formula --ignore-dependencies" "$pkg_list" "abrew install --formula --force-bottle"

# Migrate casks
echo "Migrating casks..."
cask_list=$(ibrew list --cask)
migrate_packages "ibrew uninstall --cask --ignore-dependencies" "$cask_list" "abrew install --cask"

echo "Migration completed successfully"
