sub init()
    m.showList      = m.top.findNode("showList")
    m.emptyLabel    = m.top.findNode("emptyLabel")
    m.codeLabel     = m.top.findNode("codeLabel")
    m.addOverlay    = invalid
    m.setupScreen   = invalid
    m.settingsScreen = invalid
    m.firebaseTask  = invalid
    m.launchTask    = invalid
    m.launching     = false
    m.deleteDialog  = invalid
    m.pendingDelete = -1
    m.shows         = []
    m.householdCode = ""

    loadLocal()
    sortShows()

    reg = CreateObject("roRegistrySection", "RokuTracker")
    if reg.exists("householdCode")
        m.householdCode = reg.read("householdCode")
        m.codeLabel.text = "Household: " + m.householdCode
        refreshList()
        fetchFromFirebase()
    else
        showSetup()
    end if

    m.top.setFocus(true)
    m.showList.observeField("itemSelected", "onItemSelected")
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "options"
        showAddOverlay()
        return true
    end if

    if key = "play"
        showSettings()
        return true
    end if

    if key = "back" and m.addOverlay <> invalid and m.addOverlay.visible
        if m.top.dialog <> invalid
            m.top.dialog = invalid
        end if
        m.addOverlay.visible = false
        m.top.setFocus(true)
        if m.shows.count() > 0
            m.showList.setFocus(true)
        end if
        return true
    end if

    if m.deleteDialog <> invalid
        if key = "back"
            cancelDelete()
            return true
        end if
    end if

    if key = "back"
        m.top.close = true
        return true
    end if

    if key = "rewind" and m.shows.count() > 0
        showDeleteDialog(m.showList.itemFocused)
        return true
    end if

    return false
end function

sub onItemSelected()
    launchShow(m.showList.itemSelected)
end sub

sub launchShow(idx as Integer)
    if m.launching then return
    if idx < 0 or idx >= m.shows.count() then return

    appId = m.shows[idx].appId
    if appId = invalid or appId = "" then return

    m.launching = true
    m.launchTask = CreateObject("roSGNode", "LaunchTask")
    m.launchTask.appId = appId
    m.launchTask.observeField("result", "onLaunchResult")
    m.launchTask.control = "RUN"
end sub

sub onLaunchResult()
    m.launching = false
end sub

sub removeShow(idx as Integer)
    if idx < 0 or idx >= m.shows.count() then return
    m.shows.delete(idx)
    sortShows()
    saveLocal()
    pushToFirebase()
    refreshList()
end sub

sub showDeleteDialog(idx as Integer)
    if idx < 0 or idx >= m.shows.count() then return

    m.pendingDelete = idx
    m.deleteDialog = CreateObject("roSGNode", "Dialog")
    m.deleteDialog.title = "Remove Show?"
    m.deleteDialog.message = m.shows[idx].title + " will be removed from your favorites."
    m.deleteDialog.buttons = ["Cancel", "Delete"]
    m.deleteDialog.observeField("buttonSelected", "onDeleteDialogButtonSelected")
    m.top.dialog = m.deleteDialog
end sub

sub onDeleteDialogButtonSelected()
    if m.deleteDialog = invalid then return

    selected = m.deleteDialog.buttonSelected
    m.top.dialog = invalid
    m.deleteDialog = invalid

    if selected = 1
        idx = m.pendingDelete
        m.pendingDelete = -1
        removeShow(idx)
    else
        m.pendingDelete = -1
        if m.shows.count() > 0
            m.showList.setFocus(true)
        else
            m.top.setFocus(true)
        end if
    end if
end sub

sub cancelDelete()
    m.top.dialog = invalid
    m.deleteDialog = invalid
    m.pendingDelete = -1
    if m.shows.count() > 0
        m.showList.setFocus(true)
    else
        m.top.setFocus(true)
    end if
end sub

' ── Setup ─────────────────────────────────────────────────

sub showSetup()
    m.setupScreen = m.top.createChild("SetupScreen")
    m.setupScreen.observeField("householdCode", "onHouseholdCodeSet")
    m.setupScreen.setFocus(true)
end sub

sub onHouseholdCodeSet()
    code = m.setupScreen.householdCode
    if code = "" then return

    m.householdCode  = code
    m.codeLabel.text = "Household: " + code

    reg = CreateObject("roRegistrySection", "RokuTracker")
    reg.write("householdCode", code)
    reg.flush()

    m.top.removeChild(m.setupScreen)
    m.setupScreen = invalid

    refreshList()
    fetchFromFirebase()
    m.top.setFocus(true)
end sub

' ── Add show overlay ──────────────────────────────────────

sub showAddOverlay()
    if m.addOverlay = invalid
        m.addOverlay = m.top.createChild("AddShow")
        m.addOverlay.observeField("result", "onAddResult")
    end if
    m.addOverlay.callFunc("start")
end sub

sub onAddResult()
    result = m.addOverlay.result
    m.addOverlay.visible = false
    m.top.setFocus(true)
    if m.shows.count() > 0 then m.showList.setFocus(true)

    if result = invalid or result.title = "" then return
    existingIdx = findShowIndex(result)
    if existingIdx >= 0
        focusShow(existingIdx)
        return
    end if

    m.shows.push(result)
    sortShows()
    saveLocal()
    pushToFirebase()
    refreshList()
    focusShow(findShowIndex(result))
end sub

sub showSettings()
    if m.settingsScreen = invalid
        m.settingsScreen = m.top.createChild("SettingsScreen")
        m.settingsScreen.observeField("closed", "onSettingsClosed")
    else
        m.settingsScreen.visible = true
    end if

    m.settingsScreen.setFocus(true)
end sub

sub onSettingsClosed()
    if m.settingsScreen = invalid then return

    m.top.removeChild(m.settingsScreen)
    m.settingsScreen = invalid
    restoreMainFocus()
end sub

sub restoreMainFocus()
    m.top.setFocus(true)
    if m.shows.count() > 0
        m.showList.setFocus(true)
    end if
end sub

' ── Display ───────────────────────────────────────────────

sub refreshList()
    if m.shows.count() = 0
        m.emptyLabel.visible = true
        m.showList.visible   = false
        m.top.setFocus(true)
    else
        m.emptyLabel.visible = false
        m.showList.visible   = true
        root = CreateObject("roSGNode", "ContentNode")
        for each show in m.shows
            child = root.createChild("ContentNode")
            child.title = show.title + "  —  " + show.service
            ' child.title = show.title + "  on  " + show.service
        end for
        m.showList.content = root
        m.showList.setFocus(true)
    end if
end sub

sub focusShow(idx as Integer)
    if idx < 0 or idx >= m.shows.count() then return
    if not m.showList.visible then return

    m.showList.jumpToItem = idx
    m.showList.setFocus(true)
end sub

' ── Firebase ──────────────────────────────────────────────

sub fetchFromFirebase()
    if m.householdCode = "" then return
    m.firebaseTask = CreateObject("roSGNode", "FirebaseTask")
    m.firebaseTask.householdCode = m.householdCode
    m.firebaseTask.action        = "fetch"
    m.firebaseTask.observeField("result", "onFirebaseFetch")
    m.firebaseTask.control = "RUN"
end sub

sub onFirebaseFetch()
    shows = m.firebaseTask.result
    if shows = invalid or shows.count() = 0 then return
    m.shows = shows
    sortShows()
    saveLocal()
    refreshList()
end sub

sub pushToFirebase()
    if m.householdCode = "" then return
    task = CreateObject("roSGNode", "FirebaseTask")
    task.householdCode = m.householdCode
    task.shows         = m.shows
    task.action        = "push"
    task.control       = "RUN"
end sub

' ── Local storage ─────────────────────────────────────────

sub loadLocal()
    reg = CreateObject("roRegistrySection", "RokuTracker")
    if reg.exists("shows")
        parsed = ParseJson(reg.read("shows"))
        if parsed <> invalid then m.shows = parsed
    end if
end sub

sub sortShows()
    count = m.shows.count()
    if count < 2 then return

    for i = 0 to count - 2
        for j = 0 to count - i - 2
            if compareShowTitles(m.shows[j], m.shows[j + 1]) > 0
                temp = m.shows[j]
                m.shows[j] = m.shows[j + 1]
                m.shows[j + 1] = temp
            end if
        end for
    end for
end sub

function compareShowTitles(a as Object, b as Object) as Integer
    aTitle = ""
    bTitle = ""

    if a <> invalid and a.title <> invalid then aTitle = a.title
    if b <> invalid and b.title <> invalid then bTitle = b.title

    aKey = LCase(aTitle)
    bKey = LCase(bTitle)

    if aKey < bKey then return -1
    if aKey > bKey then return 1
    if aTitle < bTitle then return -1
    if aTitle > bTitle then return 1

    return 0
end function

function showExists(candidate as Object) as Boolean
    return findShowIndex(candidate) >= 0
end function

function findShowIndex(candidate as Object) as Integer
    if candidate = invalid then return -1

    candidateTitle = ""
    candidateService = ""
    if candidate.title <> invalid then candidateTitle = normalizeShowKey(candidate.title)
    if candidate.service <> invalid then candidateService = normalizeShowKey(candidate.service)

    for i = 0 to m.shows.count() - 1
        show = m.shows[i]
        showTitle = ""
        showService = ""
        if show.title <> invalid then showTitle = normalizeShowKey(show.title)
        if show.service <> invalid then showService = normalizeShowKey(show.service)

        if showTitle = candidateTitle and showService = candidateService
            return i
        end if
    end for

    return -1
end function

function normalizeShowKey(value as String) as String
    normalized = LCase(value.trim())
    while Instr(1, normalized, "  ") > 0
        normalized = normalized.Replace("  ", " ")
    end while
    return normalized
end function

sub saveLocal()
    reg = CreateObject("roRegistrySection", "RokuTracker")
    reg.write("shows", FormatJson(m.shows))
    reg.flush()
end sub
