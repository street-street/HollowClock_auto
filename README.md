# HollowClock_auto
HollowClock dirve by ESP32 C3  SNTP check time  
<br>The CAD files and the original version can be found here: https://www.instructables.com/Hollow-Clock-4/
<br>**  Code By street
    <br>**  MCU :ESP32_C3
    <br>**  合宙ESP32C3开发板  简约.
    <br>**  编程软件 :  Luatools_2.1.94  https://luatos.com/luatools/download/last
    <br>**  可能会需要驱动程序: ESP32C3 USB直驱 https://wiki.luatos.com/pages/tools.html
    <br>**  烧录程序视频教程: https://www.bilibili.com/video/BV1ru411v7nC/?spm_id_from=333.788&vd_source=0eec33c4e2681654042852766e6834c2
    <br>**  从4:35 开始看.
    <br>**  烧录教程文档: https://wiki.luatos.com/boardGuide/flash.html#
    <br>**  程序文件 : main.lua   可以使用 记事本打开 修改
    <br> 步进电机控制引脚:
    <br> IO02 , IO03 , IO10, IO06   分别对应 IN1 IN2 IN3 IN4      A B C D
    <br> 猜测不同电机可能会在正常运行是反转. 将 IO02 , IO03 , IO10, IO06  对应成 IN4 IN3 IN2  IN1
   
   <br>**************
    <br>1.  修改wifi 信息.
        <br>找到 --wifi信息    修改 65 和 66 行  wifi  名称和 密码.
       <br> 示例:
        <br>wifi 名称 : adsfadf
        <br>wifi 密码 : 58585858
        <br>wifiName = "adsfadf"   -- wifi SSID
        <br>wifiPassword = "58585858" -- wifi 密码 .
    <br>2. 将 钟表指针 调到12点 整. 尽可能对齐.
    <br>3. 下载程序到单片机.
    <br>4. 等待联网后 钟表自己调节到 当前时间.  (可能会反转,等待调节完成后即可正常. )
    
    <br>运行后 指针位置校准
    <br>1. 按住 "BOOT" 按键. 等待10S  等待D5 灯灭
    <br>2. 将钟表 指针调的12点位置
    <br>3. 重新上电或是 按RST 按键.
    <br>4. 等待联网后 钟表自己调节到 当前时间.
   <br> *** 其他说明
    <br>wifi 联网校时后会自动断开.
    <br>每次开机 自动联网校时, 开机校时不成功 钟表不走.
   <br> 每天 23:55分 自动联网校时 一次.
    <br>***存在问题***
    <br>为了节省存储次数, 钟表的位置数据存储 是在 每次转动完成后进行
    <br>*** 如果在钟表指针转动过程中,断电或是重启. 指针的当前位置信息不会被存储
    <br>*** 重新上电后会造成时间显示不准确, 需要执行 指针位置校准.
    <br>**** 第一次用lua写程序 不清楚是否有其他未知BUG . 请酌情使用, 本人不负任何责任.
