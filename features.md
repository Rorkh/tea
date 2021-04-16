<p align="right"><a href="https://github.com/Rorkh/tea/blob/docs/features-ru.md">RU</a></p>
<p align="center">
	<img src="assets/logo_tea.png" height="130">
</p>

---

<p align="center"><i>Features (sorry but idh time to translate)</i></p>

---

#### Развертка цикла for
```lua
#for i = 1, 3 do
surface.CreateFont("font_$(i)", {size=$(i)})
#end
->
surface.CreateFont("font_1", {size=1})
surface.CreateFont("font_2", {size=2})
surface.CreateFont("font_3", {size=3})
```
#### Условная компиляция
```lua
#if true then
true
#end
->
true
```
#### Сокращенный for
```lua
local tbl = {}
for elem in tbl do
	print(elem)
end
->
local tbl = {}
for k, elem in ipairs(tbl) do
	print(elem)
end
```
#### Форматирование текста
```lua
print("My name is ${var} Smith")
->
print("My name is "..var.." Smith")
```
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
