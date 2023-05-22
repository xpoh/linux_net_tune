# linux_net_tune

Script for https://ya-zero.github.io/linux/nic/nic_tune/

## Тюнинг сетевого стека Linux (nic performance)
### Рекомендации :
- отключить HT
- привязывать сетевую карту к одному процессору (numa)
### Повышение производительности сетевого стека linux.
Что будем тюнить
- CPU
- NIC
- Soft interrupt issued by a device driver
- Kernel buffer
- The network layer (IP, TCP or UDP)