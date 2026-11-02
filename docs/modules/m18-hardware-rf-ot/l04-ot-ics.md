# 18.4 — OT/ICS: Modbus и Purdue

> **M18 · Этап 3 · 5 ч · 🔴 · артефакт:** `labs/m18-hardware-rf-ot/l04-ot/`

## Цель

Понять, чем OT отличается от IT, как устроен Modbus и модель Purdue, и почему «просканировать PLC» может остановить производство.

## Результат

- Схема Purdue для учебного стенда.
- Чтение регистров Modbus на симуляторе.
- Список рисков и мер.

## Теория

### 1. OT vs IT

| | IT | OT |
|---|---|---|
| Приоритет | конфиденциальность | доступность/безопасность |
| Обновления | часто | редко/никогда |
| Протоколы | TCP/IP | Modbus, DNP3, OPC UA |
| Последствия | утечка | авария, травма |

### 2. Purdue

```text
Level 5: Enterprise
Level 4: Site business
Level 3: Operations (MES, historian)
Level 2: Supervisory (SCADA, HMI)
Level 1: Control (PLC, RTU)
Level 0: Process (датчики, actuators)
```

Сегментация между уровнями — главная защита. Прямой доступ из интернета в Level 1 — катастрофа.

### 3. Modbus

Простой протокол: function code + адрес + данные. Нет аутентификации. Порт 502.

Функции: `01` read coils, `03` read holding registers, `05` write coil, `06` write register.

```bash
# чтение регистров (симулятор)
python3 -c "from pymodbus.client import ModbusTcpClient as C; c=C('127.0.0.1',5020); print(c.read_holding_registers(0,10))"
```

### 4. Риски

- Нет auth → любой в сети может писать.
- Legacy-ПО без патчей.
- Flat-сеть.
- Удалённый доступ через VPN без MFA.
- USB-перенос.

### 5. Защита

- Сегментация (Purdue, DMZ).
- Однонаправленные шлюзы (data diode).
- Мониторинг (Nozomi/Claroty/Dragos).
- Инвентаризация и патчи по окнам.
- Обучение.

## Лаборатория

> OpenPLC + Modbus-симулятор (например, `modbuspal` или `pymodbus` server). Только локально.

### 1. Симулятор

```bash
pip install pymodbus
python3 - <<'EOF'
from pymodbus.server import StartTcpServer
from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext
store = ModbusSlaveContext(hr=ModbusSequentialDataBlock(0, [0]*100))
StartTcpServer(context=ModbusServerContext(slaves=store, single=True), address=("127.0.0.1", 5020))
EOF
```

### 2. Чтение

```bash
python3 -c "from pymodbus.client import ModbusTcpClient as C; c=C('127.0.0.1',5020); print(c.read_holding_registers(0,10))"
```

Ожидаемо: нули.

### 3. Запись (в симуляторе)

```bash
python3 -c "from pymodbus.client import ModbusTcpClient as C; c=C('127.0.0.1',5020); c.write_register(0,42); print(c.read_holding_registers(0,1))"
```

Ожидаемо: значение 42. В реальной системе это может быть уставка.

### 4. Схема Purdue

Нарисуйте стенд: где симулятор, где HMI, где DMZ. Отметьте, где нужна сегментация.

### 5. Риски

| Риск | Влияние | Мера |
|---|---|---|

### 6. Правила

Сформулируйте 5 правил: что нельзя делать в OT без разрешения.

## Атака и защита

- **Атака:** (в симуляторе) чтение/запись.
- **Детект:** мониторинг Modbus, аномальные function codes.
- **Фикс:** сегментация, auth-шлюзы, мониторинг, патчи.

## Самопроверка

- [ ] Почему доступность важнее конфиденциальности в OT?
- [ ] Что такое Purdue Level 1?
- [ ] Почему Modbus опасен?
- [ ] Зачем data diode?
- [ ] Что нельзя делать в реальной OT-сети?

## Дальше

[Контрольная M18](exam.md)
