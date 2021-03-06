#!/bin/bash
export USE_CCACHE=1
export ARCH=arm
export PATH=${PATH}:~/toolchain/linaro-4.8/bin
export CROSS_COMPILE=arm-linux-gnueabihf-
config=cyanogenmod_e980_defconfig

if [ ! -f out/zImage ]
then
    if [ ! -f out/kernel/noclean ]
    then
	echo "--- Cleaning up ---"
	rm -rf out
	make mrproper
    fi

	mkdir -p out/kernel
	echo "--- Making defconfig ---"
	make O=out/kernel $config
	echo "--- Building kernel ---"
	make -j4 O=out/kernel
	touch out/kernel/noclean

  if [ -f out/kernel/arch/arm/boot/zImage ]
  then
	echo "--- Installing modules ---"
	make -C out/kernel INSTALL_MOD_PATH=.. modules_install
	mdpath=`find out/lib/modules -type f -name modules.order`

	  if [ "$mdpath" != "" ]
	  then
		mpath=`dirname $mdpath`
		ko=`find $mpath/kernel -type f -name *.ko`
		for i in $ko
		do "$CROSS_COMPILE"strip --strip-unneeded $i
		mkdir -p out/system/lib/modules
		mv $i out/system/lib/modules
		done
	  else
	  echo "--- No modules found ---"
	  fi

	cp out/kernel/arch/arm/boot/zImage out
	rm -f out/kernel/noclean
	rm -rf out/lib
  else
	exit 0
  fi
fi

if [ -d ramdisk ]
then
	mkdir -p out/boot
	mv out/zImage out/boot
	cp scripts/mkbootimg out/boot
	./scripts/mkbootfs ramdisk | gzip > ramdisk.gz
	mv ramdisk.gz out/boot
	cd out/boot

	cmd_line='vmalloc=600M console=ttyHSL0,115200,n8 lpj=67677 user_debug=31 msm_rtb.filter=0x0 ehci-hcd.park=3 coresight-etm.boot_enable=0 androidboot.hardware=geefhd'
	base=0x80200000
	ramdisk=0x82200000
	
	echo "--- Creating boot.img ---"
	./mkbootimg --kernel zImage --ramdisk ramdisk.gz --cmdline "$cmd_line" -o newboot.img --base $base --ramdiskaddr $ramdisk
	cd ../..
	mv out/boot/newboot.img out/boot.img
	rm -rf out/boot
else
	echo "--- No ramdisk found ---"
	exit 0
fi
