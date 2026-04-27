function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "fastforward"
        m.top.shortcut = "add"
        return true
    end if

    if key = "rewind"
        m.top.shortcut = "remove"
        return true
    end if

    if key = "options"
        m.top.shortcut = "settings"
        return true
    end if

    if key = "play"
        m.top.shortcut = "launch"
        return true
    end if

    return false
end function
