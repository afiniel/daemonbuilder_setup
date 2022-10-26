#!/usr/bin/env bash
#####################################################
# Created by afiniel for crypto use...
#####################################################

source /etc/functions.sh
source /etc/yiimpool.conf
source $HOME/yiimp_install_script/daemon_builder/.my.cnf
cd $HOME/yiimp_install_script/daemon_builder

# Set what we need
now=$(date +"%m_%d_%Y")
set -e
NPROC=$(nproc)
if [[ ! -e '$STORAGE_ROOT/coin_builder/temp_coin_builds' ]]; then
sudo mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds
else
echo -e "$YELLOW temp_coin_builds already exists.... Skipping $COL_RESET"
fi
fi

# Just double checking folder permissions
sudo setfacl -m u:$USER:rwx $STORAGE_ROOT/daemon_builder/temp_coin_builds

cd $STORAGE_ROOT/daemon_builder/temp_coin_builds

# Kill the old coin and get the github info
read -r -e -p "Enter the name of the coin : " coin
read -r -e -p "Paste the github link for the coin : " git_hub
read -r -e -p "Do you need to use a specific github branch of the coin (y/n) : " branch_git_hub
if [[ ("$branch_git_hub" == "y" || "$branch_git_hub" == "Y" || "$branch_git_hub" == "yes" || "$branch_git_hub" == "Yes" || "$branch_git_hub" == "YES") ]]; then
read -r -e -p "Please enter the branch name exactly as in github, i.e. v2.5.1  : " branch_git_hub_ver
fi
read -r -e -p "Enter the coind name as it is in yiimp, example bitcoind : " pkillcoin

coindir=$coin$now

# save last coin information in case coin build fails
echo '
lastcoin='"${coindir}"'
' | sudo -E tee $STORAGE_ROOT/daemon_builder/temp_coin_builds/.lastcoin.conf >/dev/null 2>&1

# Clone the coin
if [[ ! -e $coindir ]]; then
git clone $git_hub $coindir
cd "${coindir}"
if [[ ("$branch_git_hub" == "y" || "$branch_git_hub" == "Y" || "$branch_git_hub" == "yes" || "$branch_git_hub" == "Yes" || "$branch_git_hub" == "YES") ]]; then
  git fetch
  git checkout "$branch_git_hub_ver"
fi
else
echo -e "$YELLOW $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir} already exists.... Skipping"
echo -e "$YELLOW If there was an error in the build use the build error options on the installer menu $COL_RESET"
exit 0
fi

# Build the coin under the proper configuration
if [[ ("$autogen" == "true") ]]; then
if [[ ("$berkeley" == "4.8") ]]; then
echo -e "$YELLOW Building using$GREEN Berkeley 4.8 $COL_RESET"
basedir=$(pwd)
sh autogen.sh
if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh' ]]; then
  echo "$RED => genbuild.sh not found skipping $COL_RESET"
else
sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
fi
if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform' ]]; then
  echo -e "$YELLOW build_detect_platform not found skipping $COL_RESET"
else
sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
fi
./configure CPPFLAGS="-I${STORAGE_ROOT}/berkeley/db4/include -O2" LDFLAGS="-L${STORAGE_ROOT}/berkeley/db4/lib" --without-gui --disable-tests
else
echo -e "$YELLOW Building using$GREEN Berkeley 5.1 $COL_RESET"
basedir=$(pwd)
sh autogen.sh
if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh' ]]; then
  echo "$RED => genbuild.sh not found skipping $COL_RESET"
else
sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/share/genbuild.sh
fi
if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform' ]]; then
  echo -e "$YELLOW build_detect_platform not found skipping $COL_RESET"
else
sudo chmod 777 $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb/build_detect_platform
fi
./configure CPPFLAGS="-I${STORAGE_ROOT}/berkeley/db5/include -O2" LDFLAGS="-L${STORAGE_ROOT}/berkeley/db5/lib" --without-gui --disable-tests
fi
make -j$(nproc)
else
echo -e "$YELLOW Building using makefile.unix method... $COL_RESET"
cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src
if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj' ]]; then
 mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj
        else
    echo -e "$GREEN Hey the developer did his job and the$YELLOW src/obj$GREEN dir is there! $COL_RESET"
fi
if [[ ! -e '$STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin' ]]; then
mkdir -p $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/obj/zerocoin
else
echo -e "$GREEN Wow even the$YELLOW /src/obj/zerocoin$GREEN is there! Good job developer! $COL_RESET"
fi
cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/leveldb
sudo chmod +x build_detect_platform
sudo make clean
sudo make libleveldb.a libmemenv.a
cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src
sed -i '/USE_UPNP:=0/i BDB_LIB_PATH = /home/crypto-data/berkeley/db4/lib\nBDB_INCLUDE_PATH = /home/crypto-data/berkeley/db4/include\nOPENSSL_LIB_PATH = /home/crypto-data/openssl/lib\nOPENSSL_INCLUDE_PATH = /home/crypto-data/openssl/include' makefile.unix
sed -i '/USE_UPNP:=1/i BDB_LIB_PATH = /home/crypto-data/berkeley/db4/lib\nBDB_INCLUDE_PATH = /home/crypto-data/berkeley/db4/include\nOPENSSL_LIB_PATH = /home/crypto-data/openssl/lib\nOPENSSL_INCLUDE_PATH = /home/crypto-data/openssl/include' makefile.unix
make -j$NPROC -f makefile.unix USE_UPNP=-
fi

clear

# LS the SRC dir to have user input bitcoind and bitcoin-cli names
cd $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/
find . -maxdepth 1 -type f \( -perm -1 -o \( -perm -10 -o -perm -100 \) \) -printf "%f\n"
read -r -e -p "Please enter the coind name from the directory above, example bitcoind :" coind
read -r -e -p "Is there a coin-cli, example bitcoin-cli [y/N] :" ifcoincli

if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
read -r -e -p "Please enter the coin-cli name :" coincli
fi

clear

# Strip and copy to /usr/bin
sudo pkill -9 ${pkillcoin}
sudo strip $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coind}
sudo cp $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coind} /usr/bin
if [[ ("$ifcoincli" == "y" || "$ifcoincli" == "Y") ]]; then
sudo strip $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coincli}
sudo cp $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}/src/${coincli} /usr/bin
fi

# Have user verify con.conf file and start coin
echo -e "$YELLOW I am now going to open nano,$RED please verify if there any changes that are needed such as adding or removing addnodes. $COL_RESET"
read -n 1 -s -r -p "Press any key to continue"
sudo nano $STORAGE_ROOT/wallets/."${coind::-1}"/${coind::-1}.conf
clear
cd $HOME/yiimp_install_script/daemon_builder
echo -e "$GREEN Starting ${coind::-1} $COL_RESET"
"${coind}" -datadir=$STORAGE_ROOT/wallets/."${coind::-1}" -conf="${coind::-1}.conf" -daemon -shrinkdebugfile -reindex

# If we made it this far everything built fine removing last coin.conf and build directory
sudo rm -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/.lastcoin.conf
sudo rm -r $STORAGE_ROOT/daemon_builder/temp_coin_builds/${coindir}
sudo rm -r $HOME/yiimp_install_script/daemon_builder/.my.cnf


clear
echo -e "$YELLOW Upgrade of ${coind::-1} is$GREEN completed$YELLOW and running. The blockchain is being reindexed, it could be several minutes before you can connect to your coin. $COL_RESET"
echo Type daemonbuilder at anytime to install a new coin!
