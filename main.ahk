#Requires AutoHotkey v2.0
#SingleInstance Force

; ==================================================================================================
; === CONFIGURATION (Все статические значения и настройки) ===
; ==================================================================================================

; --- Координаты ---
; Таблица ВСЕХ возможных координат в сетке
static readonly COORDS := [
    [[300, 380],  [600, 380],  [825, 380],  [1111, 380], [1350, 380]],
    [[300, 600],  [600, 600],  [825, 600],  [1111, 600], [1350, 600]],
    [[300, 850],  [600, 850],  [825, 850],  [1111, 850], [1350, 850]],
    [[300, 1111], [600, 1111], [825, 1111], [1111, 1111], [1350, 1111]]
]
; Координаты для кликов выбора улучшений (1, 2, 3)
static readonly MAIN_CLICK_COORDS := [
    {x: 2235, y: 570},  ; Режим 1
    {x: 2235, y: 820},  ; Режим 2
    {x: 2235, y: 1080}  ; Режим 3
]
; Координаты по умолчанию для 4 ячеек Numpad
static readonly DEFAULT_NUMPAD_COORDS := [
    {x: 1380, y: 380},
    {x: 1110, y: 373},
    {x: 1088, y: 1114},
    {x: 865,  y: 899}
]

; --- Задержки (в миллисекундах) ---
static readonly DELAY_KEY_PRESS := 50          ; Задержка между нажатием и отпусканием клавиши
static readonly DELAY_MOUSE_MOVE := 50         ; Задержка после перемещения мыши перед кликом
static readonly DELAY_INVENTORY_OPEN := 200    ; Пауза после открытия инвентаря
static readonly DELAY_BEFORE_INVENTORY_CLOSE := 100 ; Пауза перед закрытием инвентаря

; --- Клавиши и Настройки ---
static readonly KEY_INVENTORY := "i"           ; Клавиша для открытия/закрытия инвентаря
static readonly NUM_OF_TARGETS := 4            ; Количество отслеживаемых ячеек (Numpad 1-4)

; --- Настройки GUI ---
static readonly GUI_TITLE := "Выберите 4 клетки"
static readonly GUI_BTN_WIDTH := 120
static readonly GUI_BTN_HEIGHT := 40
static readonly GUI_MARGIN := 10
static readonly BUTTON_NAMES := [
    "АнтиКонтроль", "5сЩит", "ЛучшиеЩиты", "Анти АтакиПоОбласти", "Анти прямые",
    "+Скорость", "ДЕньги", "+КОнница", "ПерезарядкаСупера", "-кд",
    "+регенВнеБоя", "Вампирка", "+ХилОтХилок", "+МаксХп", "+ХилОтКилов",
    "+дмгПоТурелям", "-кдПерезарядки", "Спид+Прыжок", "+дмгПослеКила", "+уронПОЩитам"
]


; ==================================================================================================
; === STATE VARIABLES (Глобальные переменные, изменяемые в процессе работы) ===
; ==================================================================================================

; Массив ТЕКУЩИХ координат для Numpad 1-4. Клонируем из констант, чтобы не изменять оригинал.
global NumpadCoords := DEFAULT_NUMPAD_COORDS.Clone()

; Массив счетчиков для последовательных кликов (замена k_1, k_2, k_3, k_4)
global ClickCounters := []

; Вспомогательные переменные для GUI
global SelectedCells := []
global MyGui


; ==================================================================================================
; === SCRIPT START (Инициализация и запуск) ===
; ==================================================================================================

Init()

Init() {
    ; Инициализируем массив счетчиков
    loop NUM_OF_TARGETS
        ClickCounters.Push(1)
    
    SetupHotkeys()
    ShowGrid()
}


; ==================================================================================================
; === HOTKEY SETUP & CALLBACKS (Настройка горячих клавиш и их обработчики) ===
; ==================================================================================================

SetupHotkeys() {
    ; --- Динамическое создание горячих клавиш для Numpad 1-4 ---
    loop NUM_OF_TARGETS {
        n := A_Index ; Захватываем текущее значение A_Index для использования в лямбда-функции

        ; Обычное нажатие (циклический клик 1-2-3)
        Hotkey('Numpad' n, (hk, ctx) => {
            PerformFullSequence(n, [ClickCounters[n]])
            ClickCounters[n] := Mod(ClickCounters[n], 3) + 1
        })

        ; Ctrl + Numpad (тройной клик 1-2-3)
        Hotkey('^Numpad' n, (*) => PerformFullSequence(n, [1, 2, 3]))

        ; Alt + Numpad (двойной клик 1-2)
        Hotkey('!Numpad' n, (*) => PerformFullSequence(n, [1, 2]))
    }

    ; --- Статичные горячие клавиши ---
    Numpad7::SetAllModes(1)
    Numpad8::SetAllModes(2)
    Numpad9::SetAllModes(3)
    ^!r::ShowGrid()
}

; Сбрасывает все счетчики в одно состояние
SetAllModes(mode) {
    global ClickCounters
    loop NUM_OF_TARGETS {
        ClickCounters[A_Index] := mode
    }
    ToolTip("Все режимы установлены на: " mode, 1000)
}


; ==================================================================================================
; === CORE LOGIC & HELPER FUNCTIONS (Основная логика и вспомогательные функции) ===
; ==================================================================================================

; Выполняет полную последовательность действий: открыть инвентарь, кликнуть, закрыть.
PerformFullSequence(numpadIndex, modes) {
    SetKeyDelay(DELAY_KEY_PRESS)
    
    Send(KEY_INVENTORY)
    Sleep(DELAY_INVENTORY_OPEN)
    
    ClickAtCoords(NumpadCoords[numpadIndex].x, NumpadCoords[numpadIndex].y)
    
    for mode in modes {
        MainClick(mode)
    }
    
    Sleep(DELAY_BEFORE_INVENTORY_CLOSE)
    Send(KEY_INVENTORY)
}

; Выполняет основной клик по выбору улучшения
MainClick(mode) {
    coord := MAIN_CLICK_COORDS[mode]
    ClickAtCoords(coord.x, coord.y)
}

; Перемещает мышь и кликает в указанных координатах
ClickAtCoords(x, y) {
    MouseMove(x, y, 0)
    Sleep(DELAY_MOUSE_MOVE)
    SendEvent("{LButton}")
}


; ==================================================================================================
; === GUI FUNCTIONS (Функции для работы с графическим интерфейсом) ===
; ==================================================================================================

ShowGrid() {
    global MyGui, SelectedCells
    SelectedCells := []

    if WinExist(GUI_TITLE)
        MyGui.Destroy()

    MyGui := Gui("+AlwaysOnTop -SysMenu", GUI_TITLE)
    MyGui.OnEvent("Close", (*) => ExitApp())

    name_index := 1
    loop 4 { ; rows
        j := A_Index
        loop 5 { ; columns
            i := A_Index
            
            x_pos := GUI_MARGIN + (i - 1) * (GUI_BTN_WIDTH + GUI_MARGIN)
            y_pos := GUI_MARGIN + (j - 1) * (GUI_BTN_HEIGHT + GUI_MARGIN)
            
            options := "x" x_pos " y" y_pos " w" GUI_BTN_WIDTH " h" GUI_BTN_HEIGHT
            
            btn := MyGui.Add("Button", options, BUTTON_NAMES[name_index])
            btn.j := j
            btn.i := i
            btn.OnEvent("Click", SelectCell)
            
            name_index++
        }
    }

    confirm_y := GUI_MARGIN + 4 * (GUI_BTN_HEIGHT + GUI_MARGIN)
    confirmBtn := MyGui.Add("Button", "x" GUI_MARGIN " y" confirm_y " w" GUI_BTN_WIDTH " h" GUI_BTN_HEIGHT, "Подтвердить")
    confirmBtn.OnEvent("Click", ConfirmSelection)
    
    exit_x := GUI_MARGIN + GUI_BTN_WIDTH + GUI_MARGIN
    exitBtn := MyGui.Add("Button", "x" exit_x " y" confirm_y " w" GUI_BTN_WIDTH " h" GUI_BTN_HEIGHT, "Выход")
    exitBtn.OnEvent("Click", (*) => ExitApp())

    MyGui.Show()
}

SelectCell(btnCtrl, info) {
    global SelectedCells
    j := btnCtrl.j
    i := btnCtrl.i

    for index, cell in SelectedCells {
        if (cell.j = j && cell.i = i) {
            SelectedCells.RemoveAt(index)
            name_index := (j - 1) * 5 + i
            btnCtrl.Text := BUTTON_NAMES[name_index]
            UpdateSelectedButtonLabels()
            return
        }
    }

    if (SelectedCells.Length >= NUM_OF_TARGETS) {
        ToolTip("Уже выбрано максимальное количество ячеек (" NUM_OF_TARGETS ")", 1500)
        return
    }

    SelectedCells.Push({
        j: j, i: i,
        x: COORDS[j][i][1], y: COORDS[j][i][2],
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

ConfirmSelection(*) {
    global SelectedCells, MyGui, NumpadCoords

    if (SelectedCells.Length != NUM_OF_TARGETS) {
        MsgBox "Ошибка: Нужно выбрать ровно " NUM_OF_TARGETS " клетки.", "Неверный выбор", "Icon! 48"
        return
    }

    loop NUM_OF_TARGETS {
        n := A_Index
        selected_cell := SelectedCells[n]
        NumpadCoords[n].x := selected_cell.x
        NumpadCoords[n].y := selected_cell.y
    }

    MyGui.Destroy()
    ToolTip("Координаты успешно обновлены!", 1500)
}
