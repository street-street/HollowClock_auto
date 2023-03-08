PROJECT = "Hollow_Clock"

VERSION = "1.0.0"

--[[
    **  Code By street
    **  MCU :ESP32_C3
    **  合宙ESP32C3开发板  简约.

    **  编程软件 :  Luatools_2.1.94  https://luatos.com/luatools/download/last
    **  可能会需要驱动程序: ESP32C3 USB直驱 https://wiki.luatos.com/pages/tools.html
    **  烧录程序视频教程: https://www.bilibili.com/video/BV1ru411v7nC/?spm_id_from=333.788&vd_source=0eec33c4e2681654042852766e6834c2
    **  从4:35 开始看.
    **  烧录教程文档: https://wiki.luatos.com/boardGuide/flash.html#


    **  程序文件 : main.lua   可以使用 记事本打开 修改

    步进电机控制引脚:
    IO02 , IO03 , IO10, IO06   分别对应 IN1 IN2 IN3 IN4      A B C D
    猜测不同电机可能会在正常运行是反转. 将 IO02 , IO03 , IO10, IO06  对应成 IN4 IN3 IN2  IN1

    **************
    1.  修改wifi 信息.
        找到 --wifi信息    修改 65 和 66 行  wifi  名称和 密码.
        示例:
        wifi 名称 : adsfadf
        wifi 密码 : 58585858
        wifiName = "adsfadf"   -- wifi SSID
        wifiPassword = "58585858" -- wifi 密码 .
    2. 将 钟表指针 调到12点 整. 尽可能对齐.
    3. 下载程序到单片机.
    4. 等待联网后 钟表自己调节到 当前时间.  (可能会反转,等待调节完成后即可正常. )

    运行后 指针位置校准
    1. 按住 "BOOT" 按键. 等待10S  等待D5 灯灭
    2. 将钟表 指针调的12点位置
    3. 重新上电或是 按RST 按键.
    4. 等待联网后 钟表自己调节到 当前时间.

    *** 其他说明
    wifi 联网校时后会自动断开.
    每次开机 自动联网校时, 开机校时不成功 钟表不走.
    每天 23:55分 自动联网校时 一次.

    ***存在问题***
    为了节省存储次数, 钟表的位置数据存储 是在 每次转动完成后进行
    *** 如果在钟表指针转动过程中,断电或是重启. 指针的当前位置信息不会被存储
    *** 重新上电后会造成时间显示不准确, 需要执行 指针位置校准.

    **** 第一次用lua写程序 不清楚是否有其他未知BUG . 请酌情使用, 本人不负任何责任.
]]

local sys = require "sys"

--添加硬狗防止程序卡死
if wdt then
    wdt.init(15000)--初始化watchdog设置为15s
    sys.timerLoopStart(wdt.feed, 3000)--10s喂一次狗
end

--需要自行填写的东西
--wifi信息
local wifiName,wifiPassword = "",""

wifiName = "street"   -- wifi SSID
wifiPassword = "53665536" -- wifi 密码 .


--------------------------------
local function connectWifi()

    log.info("wlan", "wlan_init:", wlan.init())
    wlan.setMode(wlan.STATION)
    wlan.connect(wifiName,wifiPassword)

    -- 等待连上路由，此时还没获取到ip
    result, _ = sys.waitUntil("WLAN_STA_CONNECTED")
    log.info("wlan", "WLAN_STA_CONNECTED", result)

    -- 等到成功获取ip就代表连上局域网了
    result, data = sys.waitUntil("IP_READY")
    log.info("wlan", "IP_READY", result, data)
end

local PinA,PinB,PinC,PinD = 2,3,10,6

local function stepMotor_pininit()
    gpio.setup(PinA,0,gpio.PULLDOWN)
    gpio.setup(PinB,0,gpio.PULLDOWN)
    gpio.setup(PinC,0,gpio.PULLDOWN)
    gpio.setup(PinD,0,gpio.PULLDOWN)
end

local motorstep = 0x01
function Motor_CW_oneStep()
    motorstep = motorstep *2
    if motorstep>8 then
        motorstep = 0x01
    end
    gpio.set(PinA,motorstep == 0x01 and 1 or 0)
    gpio.set(PinB,motorstep == 0x02 and 1 or 0)
    gpio.set(PinC,motorstep == 0x04 and 1 or 0)
    gpio.set(PinD,motorstep == 0x08 and 1 or 0)

end

function Motor_CCW_oneStep()
    motorstep = motorstep /2
    if motorstep <1 then
        motorstep = 0x08
    end
    gpio.set(PinA,motorstep == 0x01 and 1 or 0)
    gpio.set(PinB,motorstep == 0x02 and 1 or 0)
    gpio.set(PinC,motorstep == 0x04 and 1 or 0)
    gpio.set(PinD,motorstep == 0x08 and 1 or 0)

end

function Motor_disable()
    gpio.set(PinA, 0)
    gpio.set(PinB, 0)
    gpio.set(PinC, 0)
    gpio.set(PinD, 0)
end



-- sys.subscribe(
--     "NTP_SYNC_DONE",
--     function()
--         log.info("ntp", "done")
--         log.info("date", os.date())
--     end
-- )
--  2048 个脉冲 一圈.
--  分针 转一圈 15360 个脉冲  2048*7.5 = 15360
--  一小时脉冲数, 15360 一分钟脉冲数 256
--  12小时 脉冲数 , 15360* 12 = 184320
--  6 小时 脉冲数.  92160
local HalfDayPulse = 184320
local HalfCyclePulse = 92160
local steps , last_steps = 0 ,0
-- local twelve_Pulse_count = 0
local steps_set = 0

-- local Y,H,M,S = "0","12","00","00"
function  Calculation_timePoisition()
    Y,H ,M ,S = os.date('%Y'), os.date('%I') ,os.date('%M') ,os.date('%S')

    -- Y = "2023"

    -- H = tonumber(H)
    -- M = tonumber(M)

    -- -- M = M +1
    -- if M*1 >= 60 then
    --     M = 0
    --     H =  tonumber(H) + 1
    --     if H >12 then
    --         H = 1
    --     end
    -- end

    -- M = tostring(M)
    -- H = tostring(H)

--            ----------------------------------
    if H =="12" and tonumber(M) > 0 then   -- 0点.
        if steps >= HalfDayPulse then
            steps = 0
        end
        H=0
    end
    if Y*1 >= 2023  then
        steps_set = H*15360 + M * 256
    end
end

local Key_RstIO9 = 9
sys.taskInit( function ()    -- 步进电机移动  指针控制.

    stepMotor_pininit()
    fskv.init()   -- 数据库初始化.
    steps = fskv.get("poision")
    log.info("steps",steps,steps_set)
    sys.waitUntil("NTP_UPDATE")
    log.info("ntp", "sTART Motor Poision")
    sys.wait(3000)
        -- 上电后 快速定位.
    if (steps_set > steps and steps_set - steps <= HalfCyclePulse) then
        while steps ~= steps_set do
            Motor_CW_oneStep()
            steps =steps +1
            if steps >= HalfDayPulse then
                steps = 0
            end
            sys.wait(3)
        end
        Motor_disable()
    elseif (steps > steps_set and steps- steps_set >= HalfCyclePulse) then
        while steps ~= steps_set do
            Motor_CW_oneStep()
            steps =steps +1
            if steps >= HalfDayPulse then
                steps = 0
            end
            sys.wait(3)
        end
        Motor_disable()
    elseif (steps_set > steps and steps_set-steps > HalfCyclePulse)then-- 超过6点 反转.
        if steps == 0 then   -- set != 0  表示 还需要反转.
            steps = HalfDayPulse
        end
        while steps ~= steps_set do
            Motor_CCW_oneStep()
            steps =steps - 1
            if steps == 0 then   -- set != 0  表示 还需要反转.
                steps = HalfDayPulse
            end
            sys.wait(3)
        end
        Motor_disable()
    elseif (steps > steps_set and steps- steps_set < HalfCyclePulse)  then
        -- steps = HalfDayPulse;
        while steps ~= steps_set do
            Motor_CCW_oneStep()
            steps =steps - 1
            if steps == 0 then   -- set != 0  表示 还需要反转.
                steps = HalfDayPulse
            end
            sys.wait(3)
        end
        Motor_disable()
    end
    sys.publish("Poisition_OK")   -- 发送定位完成 消息.  进入正常计时.
    -- 上电初始化完成
    while true do

        while steps < steps_set do
            Motor_CW_oneStep()
            steps =steps +1
            sys.wait(6)
        end
        Motor_disable()
        if steps ~= last_steps then
            -- 存储当前位置.
            fskv.set("poision",steps)
            last_steps = steps
        end

        sys.wait(1000)
    end

end)

local Key_count = 0;
local keydown = gpio.LOW
sys.taskInit(function()   -- 计时 及位置计算.

    local LEDA = gpio.setup(12, 0, gpio.PULLUP) -- PE07输出模式,内部上拉
    gpio.setup(Key_RstIO9,nil,gpio.PULLUP)   -- 初始化 boot按钮. 为 校时按钮.
    --先连wifi
    connectWifi()

    --
    sys.waitUntil("NTP_UPDATE")  -- 等待 NTP更新
    wlan.disconnect() -- 断开 wifi
    log.info("wlan", "wifi info:", json.encode(wlan.getInfo()))
    log.info("SNTP", "NTP UPDATE")

    Calculation_timePoisition()

    print("runsteps ",steps_set)
    print("runsteps ",steps)
    print(os.date("%Y-%m-%d %H:%M:%S"))

    sys.waitUntil("Poisition_OK")  -- 等待 定位完成.
    log.info("start","开始 计时 -------")
    while true do
        -- wdt.feed() -- 喂狗
        Calculation_timePoisition()  -- 计算 位置.

        print("step SET: ",steps_set)
        print("Step_CUR: ",steps)
        print(os.date("%Y-%m-%d %H:%M:%S"))

        -- 启动网络校时.
        H2 ,M2 ,S2 = os.date('%H') ,os.date('%M') ,os.date('%S')
        if H2 == "23" and M2 == "55" and S2 == "00" then  --and S == '0'
            sys.publish("request_NTP")
        end

        gpio.toggle(12)  -- LED 闪烁.
        sys.wait(1000)
        -- 按键检测
        if gpio.get(Key_RstIO9) == keydown then
            if Key_count >= 10 then
                -- 复位 当前位置.  从12点起 开始计时.
                -- 保存 当前位置数据
                steps = 0
                fskv.set("poision",steps)   --存储 位置信息.
                gpio.set(13,0)  -- LED B 熄灭.
                while true do

                end
            else
                gpio.set(13,1)  -- LED B 亮.
                Key_count = Key_count + 1
            end
        else
            Key_count = 0
            gpio.set(13,0)  -- LED B 熄灭.
        end
        -- 按钮 end
    end

end)

sys.taskInit(function ()
    local LEDB = gpio.setup(13, 0, gpio.PULLUP) -- PE06输出模式,内部上拉
    while true do
        sys.waitUntil("request_NTP")
        LEDB(1)
        connectWifi()
        sys.waitUntil("NTP_UPDATE",60000)  -- 等待 NTP更新 等待 一分钟后超时.
        wlan.disconnect()
        LEDB(0)
    end
end)

-- 用户代码已结束-------------------------------------

-- 结尾总是这一句

sys.run()

-- sys.run()之后后面不要加任何语句!!!!!
