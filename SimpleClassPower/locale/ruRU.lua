local ADDON = ...
local L = Wheel("LibLocale"):NewLocale(ADDON, "ruRU")

-- Chat command menu
L["/scp - Toggle the overlay for moving/scaling."] = "|cffa365ee/scp|r - Переключить оверлей для перемещения/масштабирования."
L["/scp classcolor on - Enable class colors."] = "|cffa365ee/scp classcolor on|r - Включить цвета классов."
L["/scp classcolor off - Disable class colors."] = "|cffa365ee/scp classcolor off|r - Отключить цвета классов. |cff888888(По умолчанию)|r"
L["/scp show always - Always show."] = "|cffa365ee/scp show always|r - Показывайте всегда. |cff888888(По умолчанию)|r"
L["/scp show smart - Hide when no target or unattackable."] = "|cffa365ee/scp show smart|r - Скрыть, когда нет цели или невозможно атаковать."
L["/scp help - Show this."] = "|cffa365ee/scp help|r - Показать."

-- Tooltips
L["<Left-Click> to raise"] = "<ЛКМ> поднять" 
L["<Left-Click> to lower"] = "<ЛКМ> опустить"
L["<Shift Left Click> to reset position"] = "<Shift+ЛКМ> сбросить положение"
L["<Shift Right Click> to reset scale"] = "<Shift+ПКМ> сбросить масштабирование"
