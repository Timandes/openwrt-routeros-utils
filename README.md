# OpenWrt RouterOS便捷脚本

## OpenWrt的DHCP静态地址导出

脚本将OpenWrt的DHCP静态地址导出成为在RouterOS系统中创建Lease的命令行，协助完成配置迁移。

>注意：OpenWrt静态地址中的Tag将直接以OptionSet的加入RouterOS中。

### 使用方法
1）下载脚本


2）执行脚本

```shell
uci show dhcp | grep '@host' | /bin/sh openwrt-dhcp-host-2-ros-lease.sh
```

并获取执行结果。


3）将执行结果（RouterOS命令）复制，登录RouterOS命令行粘贴执行


### Q&A
1）不支持多Tag

答：RouterOS不支持Lease绑定多个OptionSet。


2）为什么创建的OptionSet是空的

答：暂时未将接口中配置的DHCP Option对Tag的特殊配置同步迁移到RouterOS中。
因工作量不大，未来应该也不会考虑加入。
只需要根据实际需要创建Option并完成关联即可。