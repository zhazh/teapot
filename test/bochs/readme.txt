用bochs虚拟机测试。
首先，需要安装有bochs虚拟机，如未安装，请先安装。
测试步骤：
1、在本目录使用bochs bximage建立一个1.44软盘，名称为boot.img。
2、在本目录使用bximage建立一块名为hdc.img硬盘，大小可以为100M。
3、运行install.sh将boot.bin写入boot.img。
4、运行虚拟机，在本目录输入命令`bochs`