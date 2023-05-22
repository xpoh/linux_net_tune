#!/bin/bash
## linux_net_tune
#
# Script for https://ya-zero.github.io/linux/nic/nic_tune/
#
# Тюнинг сетевого стека Linux (nic performance)
# Рекомендации :
# - отключить HT
# - привязывать сетевую карту к одному процессору (numa)
# Повышение производительности сетевого стека linux.
# Что будем тюнить
# - CPU
# - NIC
# - Soft interrupt issued by a device driver
# - Kernel buffer
# - The network layer (IP, TCP or UDP)

# CPU
 apt install cpufrequtils
 cpufreq-set -g performance

# NIC
# IntMode 2 - режим MSI-X , нужен для поддержки multiqueue
# RSS - сколько использовать очередей
# VMDQ - отключаем, так как ненужен.
# InterruptThrottleRate - устанавливаем 1 , подбирает динамически кол. прерываний в сек.
# DCA - defaylt 1 (enable)
# MQ - default 1 (enable) нужно включить для поддержки RSS
# max_vfs - default 0
# через запятую указываем значение для каждого порта,если четыре то =1,1,1,1
# параметр allow_unsupported_sfp выставляем только одно значение = 1 , а не 1,1 если даже два порта
echo options ixgbe IntMode=2,2  RSS=6,6  VMDQ=0,0 InterruptThrottleRate=1,1 allow_unsupported_sfp=1 > /etc/modprobe.d/ixgbe.conf
modprobe ixgbe

# Отключение контроля перегрузок
ethtool -K eno1 lro off

# Отключение системное управление прерываний и передаем контроль NAPI.
ethtool -C eno1 adaptive-rx off

# Узнать максимальные размеры буфера
echo "max buffers:"
ethtool -g eno1

# Установить максимальные размеры буферов на прием, передачу
ethtool -G eno1 rx 4096
ethtool -G eno1 tx 4096

# Размер очереди пакетов
ip link set eno1 txqueuelen 10000

# Привязка прерываний к одному cpu
lscpu | grep numa0
set_irq_affinity 0-23,48-71 eno1

# остановить демон балансировки
service irqbalance stop

# Soft irq budget — это весь доступный бюджет, который будет разделён на все доступные NAPI-структуры, зарегистрированные на этот CPU.
#   по умолчанию в некоторых системах он равен 300 , рекомендуется установить 600 для сетей 10Gb/s и выше
sysctl -w net.core.netdev_budget=600

##  Kernel buffer.
# CORE settings (mostly for socket and UDP effect)

# set maximum receive socket buffer size, default 131071 *
sysctl -w net.core.rmem_max=524287 \
          net.core.wmem_max=524287 \
          net.core.rmem_default=524287 \
          net.core.wmem_default=524287 \
          net.core.optmem_max=524287 \
          net.ipv4.tcp_timestamps=0 \
          net.ipv4.tcp_sack=0 \
          net.ipv4.tcp_rmem="10000000 10000000 10000000" \
          net.ipv4.tcp_wmem="10000000 10000000 10000000" \
          net.ipv4.tcp_mem="10000000 10000000 10000000" \
          net.ipv4.tcp_sack=0 \
          net.ipv4.tcp_fin_timeout=20 \
          net.ipv4.tcp_timestamps=0 \
          net.netfilter.nf_conntrack_tcp_timeout_established=900 \
          net.core.somaxconn=4096 \
          