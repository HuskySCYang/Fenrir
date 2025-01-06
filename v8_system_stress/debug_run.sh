#$(awk -F= '/^Exec/ {print $2; exit}' /root/.config/autostart/UUT_loop_main.sh.desktop )

source configuration

echo ifconfig $os_NIC $os_ip

