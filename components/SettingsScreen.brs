sub init()
    m.settingsList = m.top.findNode("settingsList")
    m.apiKeyDialog = invalid
    m.apiKey = loadTMDbApiKey()
    m.useDisneyForHuluAndESPN = loadUseDisneyForHuluAndESPN()

    updateSettingsList()
    m.top.apiKey = m.apiKey
    m.top.useDisneyForHuluAndESPN = m.useDisneyForHuluAndESPN
    m.top.setFocus(true)
    m.settingsList.setFocus(true)
    m.settingsList.observeField("itemSelected", "onSettingSelected")
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        closeSettings()
        return true
    end if

    return false
end function

sub onSettingSelected()
    selectSetting(m.settingsList.itemSelected)
end sub

sub selectSetting(idx as Integer)
    if idx = 0
        showApiKeyDialog()
    else if idx = 1
        saveUseDisneyForHuluAndESPN(not m.useDisneyForHuluAndESPN)
    end if
end sub

sub showApiKeyDialog()
    if m.apiKeyDialog <> invalid then return

    m.apiKeyDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.apiKeyDialog.title = "TMDb API Key"
    m.apiKeyDialog.buttons = ["Save", "Cancel"]
    m.apiKeyDialog.text = m.apiKey
    m.apiKeyDialog.observeField("buttonSelected", "onApiKeyDialogButtonSelected")
    m.apiKeyDialog.observeField("wasClosed", "onApiKeyDialogClosed")
    m.top.getScene().dialog = m.apiKeyDialog
end sub

sub onApiKeyDialogButtonSelected()
    dialog = m.top.getScene().dialog
    if dialog = invalid then return

    if dialog.buttonSelected = 0
        saveTMDbApiKey(dialog.text)
    end if

    m.top.getScene().dialog = invalid
    m.apiKeyDialog = invalid
    m.top.setFocus(true)
    m.settingsList.setFocus(true)
end sub

sub onApiKeyDialogClosed()
    if m.top.getScene().dialog = invalid
        m.apiKeyDialog = invalid
        m.top.setFocus(true)
        m.settingsList.setFocus(true)
    end if
end sub

sub closeSettings()
    if m.apiKeyDialog <> invalid
        m.top.getScene().dialog = invalid
        m.apiKeyDialog = invalid
    end if

    m.top.closed = true
end sub

function loadTMDbApiKey() as String
    reg = CreateObject("roRegistrySection", "RokuTracker")
    if reg.exists("TMDbApiKey")
        key = reg.read("TMDbApiKey")
        if key <> invalid then return key.trim()
    end if

    appInfo = CreateObject("roAppInfo")
    key = appInfo.GetValue("TMDb_api_key")
    if key = invalid then return ""
    return key.trim()
end function

sub saveTMDbApiKey(value as String)
    reg = CreateObject("roRegistrySection", "RokuTracker")
    m.apiKey = value.trim()

    if m.apiKey = ""
        reg.delete("TMDbApiKey")
    else
        reg.write("TMDbApiKey", m.apiKey)
    end if

    reg.flush()
    updateSettingsList()
    m.top.apiKey = m.apiKey
end sub

function loadUseDisneyForHuluAndESPN() as Boolean
    reg = CreateObject("roRegistrySection", "RokuTracker")
    if reg.exists("useDisneyForHuluAndESPN")
        return LCase(reg.read("useDisneyForHuluAndESPN")) = "true"
    end if

    return false
end function

sub saveUseDisneyForHuluAndESPN(value as Boolean)
    reg = CreateObject("roRegistrySection", "RokuTracker")
    m.useDisneyForHuluAndESPN = value

    if value
        reg.write("useDisneyForHuluAndESPN", "true")
    else
        reg.write("useDisneyForHuluAndESPN", "false")
    end if

    reg.flush()
    updateSettingsList()
    m.top.useDisneyForHuluAndESPN = m.useDisneyForHuluAndESPN
end sub

sub updateSettingsList()
    apiKeyText = m.apiKey
    if m.apiKey = ""
        apiKeyText = "[not set]"
    end if

    disneyValue = "No"
    if m.useDisneyForHuluAndESPN then disneyValue = "Yes"

    root = CreateObject("roSGNode", "ContentNode")
    apiKeyItem = root.createChild("ContentNode")
    apiKeyItem.title = "TMDb API Key: " + apiKeyText

    disneyItem = root.createChild("ContentNode")
    disneyItem.title = "Use Disney+ for HULU and ESPN?: " + disneyValue

    m.settingsList.content = root
end sub
