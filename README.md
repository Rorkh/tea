# Tea

## RU
Препроцессор Lua, написанный на говнокоде, но активно (пока) разрабатываемый.
### Цель
Упростить написание скриптов на языке программирования Lua
### Плюшки
#### Каст типов
```
print((number) "123")
->
print(tonumber("123"))
```
#### Арифметически операторы
```
i += 1
i -= 1
i /= 1
i *= 1
i .= 1
->
i = i + 1
i = i - 1
i = i / 1
i = i * 1
i = i .. 1
```
#### Операторы инкремента/декремента
```
i++
i--
->
i = i + 1
i = i - 1
```
#### Декораторы отрицания/двойного отрицания
```
![CLIENT]
function func()
end
->
function func()
if not CLIENT then return end
end
```
```
+[CLIENT]
function func()
end
->
function func()
if CLIENT then return end
end
```
```
![SERVER]
+[CLIENT]
function func()
end
->
function func()
if CLIENT then return end
if not SERVER then return end
end
```
### Баги
Багов много, в issue смотрите (если там нет, то значит я поленился писать о них, но в уме держу)
## En
Shitcoded but WIP Lua preprocessor
