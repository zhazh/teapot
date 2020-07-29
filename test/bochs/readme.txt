用bochs虚拟机测试。
首先，需要安装有bochs虚拟机，如未安装，请先安装。
测试步骤：
1、在本目录使用bximage建立一块名为hdc.img硬盘，大小可以为100M。
2、src/core/boot目录下运行make && make burning生成boot.img映像文件并拷贝到此处。
3、运行虚拟机，在本目录输入命令`bochs`