#!/bin/bash
TERMPLAN_DIR="$HOME/Desktop/termplan"
CLI_CMD="bash $TERMPLAN_DIR/termplan"

while true; do
    CHOICE=$(dialog --clear \
                    --title " 🚀 TermPlan Mac 版 " \
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