#!/bin/bash
TERMPLAN_DIR="/d/termplan"
CLI_CMD="bash $TERMPLAN_DIR/termplan"

# ==================== 纯文本用户登录注册逻辑 ====================
handle_auth() {
    while true; do
        echo "====================================="
        echo "      🚀 TermPlan 账户中心 🚀        "
        echo "====================================="
        echo " 1. 用户登录"
        echo " 2. 新用户注册"
        echo " 3. 退出系统"
        echo "====================================="
        read -p "请选择操作序号 (1-3): " AUTH_CHOICE

        if [ "$AUTH_CHOICE" == "3" ] || [ -z "$AUTH_CHOICE" ]; then
            echo "退出系统..."
            exit 0
        fi

        if [ "$AUTH_CHOICE" != "1" ] && [ "$AUTH_CHOICE" != "2" ]; then
            echo -e "\n❌ 输入错误，请输入 1, 2 或 3！\n"
            continue
        fi

        local ACTION="login"
        if [ "$AUTH_CHOICE" == "2" ]; then ACTION="register"; fi

        echo "-------------------------------------"
        read -p "请输入用户名: " USERNAME
        # -s 参数可以隐藏密码输入，保护隐私
        read -s -p "请输入密码: " PASSWORD
        echo -e "\n-------------------------------------"

        if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
            echo -e "\n❌ 用户名或密码不能为空！\n"
            continue
        fi

        echo "正在验证数据，请稍候..."
        # 调用你写好的 Python 后端大脑
        RESULT=$(python auth.py $ACTION "$USERNAME" "$PASSWORD")

        if [[ "$RESULT" == *"SUCCESS"* ]]; then
            echo -e "\n✨ 恭喜，操作成功！"
            if [ "$ACTION" == "login" ]; then
                USER_ID=$(echo $RESULT | cut -d':' -f2)
                export TERMPLAN_USER_ID=$USER_ID
                echo -e "欢迎回来！当前用户 ID: $TERMPLAN_USER_ID\n"
                break 
            fi
        elif [[ "$RESULT" == "USER_EXISTS" ]]; then
            echo -e "\n❌ 该用户名已被注册，请换一个！\n"
        else
            echo -e "\n❌ 用户名或密码错误，请重试！\n"
        fi
    done
}

# 启动时先进行登录验证
handle_auth
# ==================================================================

# 验证成功后，进入组长原本的功能系统（保留他原本的 dialog 逻辑，方便他检查）
while true; do
    CHOICE=$(dialog --clear \
                    --title " 🚀 TermPlan 系统 (已登录用户ID: $TERMPLAN_USER_ID) " \
                    --menu "请使用上下键选择操作：" 15 50 4 \
                    1 "📊 查看复习看板" \
                    2 "⏱️  无扰打卡" \
                    3 "📝 添加考试科目" \
                    4 "❌ 退出系统" \
                    2>&1 >/dev/tty)
    
    if [ $? -ne 0 ]; then clear; exit 0; fi

    case $CHOICE in
        1)
            $CLI_CMD view > /tmp/termplan_view.txt
            dialog --title " 任务复习看板 " --textbox /tmp/termplan_view.txt 25 80
            ;;
        2)
            SUBJECT=$(dialog --title " 无扰打卡 " --inputbox "请输入复习科目：" 8 40 2>&1 >/dev/tty)
            if [ -n "$SUBJECT" ]; then
                DURATION=$(dialog --title " 时长 " --inputbox "时长(分钟)：" 8 40 "30" 2>&1 >/dev/tty)
                RESULT=$($CLI_CMD punch "$SUBJECT" "$DURATION")
                dialog --title " 结果 " --msgbox "$RESULT" 8 50
            fi
            ;;
        3)
            FORM_DATA=$(dialog --title " 录入考试 " \
                               --form "请输入详细信息：" 12 50 3 \
                               "科目名称:" 1 1 "" 1 15 20 0 \
                               "权重(1-5):" 2 1 "" 2 15 20 0 \
                               "日期(YYYY-MM-DD):" 3 1 "" 3 20 20 0 \
                               2>&1 >/dev/tty)
            if [ $? -eq 0 ]; then
                SUB=$(echo "$FORM_DATA" | sed -n '1p')
                WGT=$(echo "$FORM_DATA" | sed -n '2p')
                DDL=$(echo "$FORM_DATA" | sed -n '3p')
                RESULT=$($CLI_CMD add "$SUB" "$WGT" "$DDL")
                dialog --title " 结果 " --msgbox "$RESULT" 8 50
            fi
            ;;
        4)
            clear; exit 0
            ;;
    esac
done