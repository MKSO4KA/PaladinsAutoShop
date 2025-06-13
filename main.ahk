#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Глобальные переменные ---

; 1. Таблица ВСЕХ возможных координат в сетке
global Coords := [
    [[300, 380],  [600, 380],  [825, 380],  [1111, 380], [1350, 380]],
    [[300, 600],  [600, 600],  [825, 600],  [1111, 600], [1350, 600]],
    [[300, 850],  [600, 850],  [825, 850],  [1111, 850], [1350, 850]],
    [[300, 1111], [600, 1111], [825, 1111], [1111, 1111], [1350, 1111]]
]

; === НОВЫЙ МАССИВ С НАЗВАНИЯМИ КНОПОК ===
global ButtonNames := [
    "АнтиКонтроль", "5сЩит", "ЛучшиеЩиты", "Анти АтакиПоОбласти", "Анти прямые",
    "+Скорость", "ДЕньги", "+КОнница", "ПерезарядкаСупера", "-кд",
    "+регенВнеБоя", "Вампирка", "+ХилОтХилок", "+МаксХп", "+ХилОтКилов",
    "+дмгПоТурелям", "-кдПерезарядки", "Спид+Прыжок", "+дмгПослеКила", "+уронПОЩитам"
]

; 2. Массив ТЕКУЩИХ координат для Numpad 1-4.
global NumpadCoords := [
    {x: 1380, y: 380},   ; Координаты для Numpad1 по умолчанию
    {x: 1110, y: 373},   ; Координаты для Numpad2 по умолчанию
    {x: 1088, y: 1114},  ; Координаты для Numpad3 по умолчанию
    {x: 865,  y: 899}    ; Координаты для Numpad4 по умолчанию
]

; 3. Переменные состояния для кликов
global k_1 := 1, k_2 := 1, k_3 := 1, k_4 := 1

; 4. Вспомогательные переменные для GUI
global SelectedCells := []
global MyGui

;5 Задержки для кликов
global KeyDelay := 10

; --- Запуск скрипта ---
ShowGrid()

; ======================================================================
; === СТАТИЧНЫЕ ГОРЯЧИЕ КЛАВИШИ ===
; ======================================================================

Numpad1:: {
    global k_1
    PerformFullSequence(1, [k_1])
    k_1 := Mod(k_1, 3) + 1
}
Numpad2:: {
    global k_2
    PerformFullSequence(2, [k_2])
    k_2 := Mod(k_2, 3) + 1
}
Numpad3:: {
    global k_3
    PerformFullSequence(3, [k_3])
    k_3 := Mod(k_3, 3) + 1
}
Numpad4:: {
    global k_4
    PerformFullSequence(4, [k_4])
    k_4 := Mod(k_4, 3) + 1
}

Numpad7:: {
    global k_1 := 1, k_2 := 1, k_3 := 1, k_4 := 1
}
Numpad8:: {
    global k_1 := 2, k_2 := 2, k_3 := 2, k_4 := 2
}
Numpad9:: {
    global k_1 := 3, k_2 := 3, k_3 := 3, k_4 := 3
}

^!r::ShowGrid()

; ======================================================================
; === НОВЫЕ ГОРЯЧИЕ КЛАВИШИ (ТРОЙНОЙ КЛИК ПО Ctrl+Numpad) ===
; ======================================================================

^Numpad1:: PerformFullSequence(1, [1, 2, 3])
^Numpad2:: PerformFullSequence(2, [1, 2, 3])
^Numpad3:: PerformFullSequence(3, [1, 2, 3])
^Numpad4:: PerformFullSequence(4, [1, 2, 3])

; ======================================================================
; === НОВЫЕ ГОРЯЧИЕ КЛАВИШИ (Двойной КЛИК ПО ALT+Numpad) ===
; ======================================================================

!Numpad1:: PerformFullSequence(1, [1, 2])
!Numpad2:: PerformFullSequence(2, [1, 2])
!Numpad3:: PerformFullSequence(3, [1, 2])
!Numpad4:: PerformFullSequence(4, [1, 2])

; ======================================================================
; === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (GUI и клики) ===
; ======================================================================

; === ИЗМЕНЕННАЯ УНИВЕРСАЛЬНАЯ ФУНКЦИЯ ===
PerformFullSequence(numpadIndex, modes) {
    global NumpadCoords
    global KeyDelay
    ; Устанавливаем небольшую задержку между нажатием и отпусканием клавиши.
    ; Это критически важно для SendEvent в играх.
    SetKeyDelay(KeyDelay)
    
    ; 1. Открываем инвентарь через SendEvent
    SendEvent("i")
    Sleep(200) ; Пауза, чтобы инвентарь успел открыться
    
    ; 2. Кликаем по основной ячейке
    ClickAtCoords(NumpadCoords[numpadIndex].x, NumpadCoords[numpadIndex].y,KeyDelay)
    
    ; 3. Выполняем все клики из переданного списка режимов
    for mode in modes {
        MainClick(mode,KeyDelay)
    }
    
    ; 4. Закрываем инвентарь через SendEvent
    Sleep(100) ; Небольшая пауза перед закрытием
    SendEvent("i")
}

ShowGrid() {
    global MyGui, SelectedCells, ButtonNames
    SelectedCells := []

    if WinExist("Выберите 4 клетки")
        MyGui.Destroy()

    MyGui := Gui("+AlwaysOnTop -SysMenu", "Выберите 4 клетки")
    MyGui.OnEvent("Close", (*) => ExitApp())

    margin := 10
    btn_w := 120
    btn_h := 40
    
    name_index := 1
    loop 4 {
        j := A_Index
        loop 5 {
            i := A_Index
            
            x_pos := margin + (i - 1) * (btn_w + margin)
            y_pos := margin + (j - 1) * (btn_h + margin)
            
            options := "x" x_pos " y" y_pos " w" btn_w " h" btn_h
            
            current_name := ButtonNames[name_index]
            
            btn := MyGui.Add("Button", options, current_name)
            btn.j := j
            btn.i := i
            btn.OnEvent("Click", (btnCtrl, info) => SelectCell(btnCtrl))
            
            name_index++
        }
    }

    confirm_y := margin + 4 * (btn_h + margin)
    confirmBtn := MyGui.Add("Button", "x" margin " y" confirm_y " w120 h40", "Подтвердить")
    confirmBtn.OnEvent("Click", (*) => ConfirmSelection())
    
    exit_x := margin + 120 + margin
    exitBtn := MyGui.Add("Button", "x" exit_x " y" confirm_y " w120 h40", "Выход")
    exitBtn.OnEvent("Click", (*) => ExitApp())

    MyGui.Show()
}

SelectCell(btnCtrl) {
    global SelectedCells, Coords, ButtonNames
    j := btnCtrl.j
    i := btnCtrl.i

    for index, cell in SelectedCells {
        if (cell.j = j && cell.i = i) {
            SelectedCells.RemoveAt(index)
            
            name_index := (j - 1) * 5 + i
            btnCtrl.Text := ButtonNames[name_index]
            
            UpdateSelectedButtonLabels()
            return
        }
    }

    if (SelectedCells.Length >= 4) {
        return
    }

    SelectedCells.Push({
        j: j, i: i,
        x: Coords[j][i][1], y: Coords[j][i][2],
        ctrl: btnCtrl
    })
    
    btnCtrl.Text := "Выбрано: " SelectedCells.Length
}

UpdateSelectedButtonLabels() {
    global SelectedCells
    for index, cell in SelectedCells {
        cell.ctrl.Text := "Выбрано: " index
    }
}

ConfirmSelection() {
    global SelectedCells, MyGui, NumpadCoords

    if (SelectedCells.Length != 4) {
        MsgBox "Ошибка: Нужно выбрать ровно 4 клетки.", "Неверный выбор", "Icon! 48"
        return
    }

    loop 4 {
        n := A_Index
        selected_cell := SelectedCells[n]
        NumpadCoords[n].x := selected_cell.x
        NumpadCoords[n].y := selected_cell.y
    }

    MyGui.Destroy()
}

MainClick(mode, delay := 50) {
    switch mode {
        case 1: ClickAtCoords(2235, 570, delay)
        case 2: ClickAtCoords(2235, 820, delay)
        case 3: ClickAtCoords(2235, 1080, delay)
    }
}

ClickAtCoords(x, y, delay := 50) {
    MouseMove(x, y, 0)
    Sleep(delay)
    SendEvent("{LButton}")
}
