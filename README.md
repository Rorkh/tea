# Tea

## RU
Препроцессор Lua, написанный на говнокоде, но активно (пока) разрабатываемый.
### Цель
Упростить написание скриптов на языке программирования Lua
### Плюшки
#### Прагма минификации
```lua
#pragma minimize

print("Something!")

function something(some)
	print(some.."thing!")
end

something("Some")
->
print("Something!")
function something(QDnlt)print(QDnlt.."thing!")end;something("Some")
```
#### Каст типов
```lua
print((number) "123")
->
print(tonumber("123"))
```
#### Арифметически операторы
```lua
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
```lua
i++
i--
->
i = i + 1
i = i - 1
```
#### Декораторы отрицания/двойного отрицания
```lua
![CLIENT]
function func()
end
->
function func()
if not CLIENT then return end
end
```
```lua
+[CLIENT]
function func()
end
->
function func()
if CLIENT then return end
end
```
```lua
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
#### Декораторы совпадения
```lua
[CLIENT][false]
function something()
end
->
function something()
  if CLIENT then return false end
end
```
#### Дефайны и алиасы
```lua
#define да true
#alias да точно

print(да)
print(точно)
->
print(true)
print(true)
```
#### Стандартные значения
```lua
function print_something(text="Something")
print(text)
end
->
function print_something(text)
text = text or "Something"
print(text)
end
```
### Баги
Багов много, в issue смотрите (если там нет, то значит я поленился писать о них, но в уме держу)
## En
Shitcoded but WIP Lua preprocessor
