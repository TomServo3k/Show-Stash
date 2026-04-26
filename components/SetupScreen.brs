sub init()
    m.chooseGroup  = m.top.findNode("chooseGroup")
    m.createdGroup = m.top.findNode("createdGroup")
    m.joinGroup    = m.top.findNode("joinGroup")
    m.codeDisplay  = m.top.findNode("codeDisplay")
    m.codeInput    = m.top.findNode("codeInput")
    m.optionList   = m.top.findNode("optionList")
    m.joinDialog   = invalid

    root = CreateObject("roSGNode", "ContentNode")
    c1 = root.createChild("ContentNode")
    c1.title = "Create New Household  (first Roku in the home)"
    c2 = root.createChild("ContentNode")
    c2.title = "Join Existing Household  (already set up on another Roku)"
    m.optionList.content = root

    m.phase         = "choose"
    m.generatedCode = ""

    m.optionList.setFocus(true)
    m.optionList.observeField("itemSelected", "onOptionSelected")
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.phase = "created" and key = "OK"
        m.top.householdCode = m.generatedCode
        return true
    end if

    if m.phase = "join" and (key = "OK" or key = "back")
        code = UCase(m.codeInput.text.trim())
        if Len(code) >= 4
            m.top.householdCode = code
        else if key = "back"
            goToChoose()
        end if
        return true
    end if

    return false
end function

sub onOptionSelected()
    if m.optionList.itemSelected = 0
        createHousehold()
    else
        goToJoin()
    end if
end sub

sub createHousehold()
    m.generatedCode    = generateCode()
    m.codeDisplay.text = m.generatedCode
    m.phase            = "created"
    m.chooseGroup.visible  = false
    m.createdGroup.visible = true
    m.top.setFocus(true)
end sub

sub goToJoin()
    m.phase = "join"
    m.chooseGroup.visible = false
    m.joinGroup.visible   = true
    showJoinDialog()
end sub

sub showJoinDialog()
    m.joinDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.joinDialog.title = "Join Existing Household"
    m.joinDialog.buttons = ["OK", "Cancel"]
    m.joinDialog.observeField("buttonSelected", "onJoinDialogButtonSelected")
    m.joinDialog.observeField("wasClosed", "onJoinDialogClosed")
    m.top.getScene().dialog = m.joinDialog
end sub

sub onJoinDialogButtonSelected()
    dialog = m.top.getScene().dialog
    if dialog = invalid then return

    if dialog.buttonSelected = 0
        code = UCase(dialog.text.trim())
        if Len(code) >= 4
            m.codeInput.text = code
            m.top.getScene().dialog = invalid
            m.joinDialog = invalid
            m.top.householdCode = code
        end if
    else
        m.top.getScene().dialog = invalid
        m.joinDialog = invalid
        goToChoose()
    end if
end sub

sub onJoinDialogClosed()
    if m.phase = "join" and m.top.getScene().dialog = invalid
        m.joinDialog = invalid
        goToChoose()
    end if
end sub

sub goToChoose()
    m.phase = "choose"
    m.joinGroup.visible   = false
    m.chooseGroup.visible = true
    m.optionList.setFocus(true)
end sub

function generateCode() as String
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    code  = ""
    for i = 0 to 5
        code = code + Mid(chars, Rnd(Len(chars)), 1)
    end for
    return code
end function
