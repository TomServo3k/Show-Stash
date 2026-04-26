sub init()
    m.nameGroup    = m.top.findNode("nameGroup")
    m.serviceGroup = m.top.findNode("serviceGroup")
    m.nameInput    = m.top.findNode("nameInput")
    m.matchGroup   = m.top.findNode("matchGroup")
    m.matchList    = m.top.findNode("matchList")
    m.matchTitle   = m.top.findNode("matchTitle")
    m.matchHint    = m.top.findNode("matchHint")
    m.serviceList  = m.top.findNode("serviceList")
    m.serviceTitle = m.top.findNode("serviceTitle")
    m.nameDialog   = invalid
    m.searchTask   = invalid
    m.matches      = []
    m.selectedMatch = invalid
    m.completed    = false

    m.services = [
        { name: "Netflix",      appId: "12"     },
        { name: "Hulu",         appId: "2285"   },
        { name: "Disney+",      appId: "291097" },
        { name: "ESPN",         appId: "34376"  },
        { name: "Amazon Prime", appId: "13"     },
        { name: "Max",          appId: "61322"  },
        { name: "Apple TV+",    appId: "551012" },
        { name: "Peacock",      appId: "593099" },
        { name: "Paramount+",   appId: "353235" }
    ]

    root = CreateObject("roSGNode", "ContentNode")
    for each svc in m.services
        child = root.createChild("ContentNode")
        child.title = svc.name
    end for
    m.serviceList.content = root

    m.phase    = "name"
    m.showName = ""

    m.serviceList.observeField("itemSelected", "onServiceSelected")
    m.matchList.observeField("itemSelected", "onMatchSelected")
end sub

sub start()
    m.phase = "name"
    m.showName = ""
    m.completed = false
    m.matches = []
    m.selectedMatch = invalid
    m.nameInput.text = ""
    m.matchGroup.visible = false
    m.serviceGroup.visible = false
    m.nameGroup.visible = false
    m.top.visible = false
    showNameDialog()
end sub

sub showNameDialog()
    m.nameDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.nameDialog.title = "Add Show"
    m.nameDialog.buttons = ["OK", "Cancel"]
    m.nameDialog.observeField("buttonSelected", "onNameDialogButtonSelected")
    m.nameDialog.observeField("wasClosed", "onNameDialogClosed")
    m.top.getScene().dialog = m.nameDialog
end sub

sub onNameDialogButtonSelected()
    dialog = m.top.getScene().dialog
    if dialog = invalid then return

    if dialog.buttonSelected = 0
        m.showName = formatShowTitle(dialog.text)
        if m.showName <> ""
            m.nameInput.text = m.showName
            m.top.getScene().dialog = invalid
            m.nameDialog = invalid
            searchForMatches()
        end if
    else
        m.top.getScene().dialog = invalid
        m.nameDialog = invalid
        cancel()
    end if
end sub

sub onNameDialogClosed()
    if m.phase = "name" and not m.completed and m.top.getScene().dialog = invalid
        m.nameDialog = invalid
        cancel()
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.phase = "name"
        if key = "back" and m.nameDialog <> invalid
            m.top.getScene().dialog = invalid
            m.nameDialog = invalid
            cancel()
            return true
        end if

        if key = "OK" or key = "back"
            m.showName = m.nameInput.text.trim()
            if m.showName <> ""
                searchForMatches()
            else if key = "back"
                cancel()
            end if
            return true
        end if
    else if m.phase = "match"
        if key = "OK"
            selectFocusedMatch()
            return true
        end if

        if key = "back"
            goToNamePhase()
            return true
        end if
    else if m.phase = "service"
        if key = "OK"
            selectFocusedService()
            return true
        end if

        if key = "back"
            goToNamePhase()
            return true
        end if
    end if

    return false
end function

sub searchForMatches()
    m.phase = "match"
    m.top.visible = true
    m.nameGroup.visible = false
    m.serviceGroup.visible = false
    m.matchGroup.visible = true
    m.matchTitle.text = "Searching for  """ + m.showName + """"
    m.matchHint.text = "Looking up possible matches..."
    m.matchList.content = CreateObject("roSGNode", "ContentNode")
    m.top.setFocus(true)
    m.matchList.setFocus(true)

    m.searchTask = CreateObject("roSGNode", "MetadataSearchTask")
    m.searchTask.provider = "TMDb"
    m.searchTask.query = m.showName
    m.searchTask.observeField("result", "onMetadataSearchResult")
    m.searchTask.control = "RUN"
end sub

sub onMetadataSearchResult()
    result = m.searchTask.result
    if result = invalid
        goToServicePhase()
        return
    end if

    if result.ok <> true
        goToServicePhase()
        return
    end if

    if result.items = invalid
        goToServicePhase()
        return
    end if

    if result.items.count() = 0
        goToServicePhase()
        return
    end if

    m.matches = [
        {
            title: m.showName,
            provider: "manual",
            TMDbId: invalid,
            mediaType: invalid,
            service: invalid,
            displayTitle: "Use """ + m.showName + """  -  choose service manually"
        }
    ]

    for each item in result.items
        m.matches.push(item)
    end for

    root = CreateObject("roSGNode", "ContentNode")
    for each item in m.matches
        child = root.createChild("ContentNode")
        child.title = item.displayTitle
    end for

    m.matchTitle.text = "Which show did you mean?"
    m.matchHint.text = "Select a match. Shows with a known service will be added automatically."
    m.matchList.content = root
    m.top.setFocus(true)
    m.matchList.setFocus(true)
end sub

sub onMatchSelected()
    selectMatch(m.matchList.itemSelected)
end sub

sub selectFocusedMatch()
    selectMatch(m.matchList.itemFocused)
end sub

sub selectMatch(idx as Integer)
    if m.completed then return
    if idx < 0 or idx >= m.matches.count() then return

    match = m.matches[idx]
    m.selectedMatch = match
    if match.title <> invalid then m.showName = formatShowTitle(match.title)
    m.nameInput.text = m.showName

    if match.service <> invalid
        if match.service.name <> invalid and match.service.appId <> invalid
            svc = preferredService(match.service)
            m.completed = true
            m.top.result = {
                title: m.showName,
                service: svc.name,
                appId: svc.appId,
                metadataProvider: match.provider,
                metadataId: match.TMDbId,
                mediaType: match.mediaType
            }
            return
        end if
    end if

    goToServicePhase()
end sub

sub goToServicePhase()
    m.phase = "service"
    m.top.visible = true
    m.nameGroup.visible = false
    m.matchGroup.visible = false
    m.serviceGroup.visible = true
    m.serviceTitle.text = "Where do you watch  "" + m.showName + ""?"
    m.top.setFocus(true)
    m.serviceList.setFocus(true)
end sub

sub goToNamePhase()
    m.phase = "name"
    m.matchGroup.visible = false
    m.serviceGroup.visible = false
    m.nameGroup.visible = false
    showNameDialog()
end sub

sub onServiceSelected()
    selectService(m.serviceList.itemSelected)
end sub

sub selectFocusedService()
    selectService(m.serviceList.itemFocused)
end sub

sub selectService(idx as Integer)
    if m.completed then return
    if idx < 0 or idx >= m.services.count() then return

    m.completed = true
    svc = preferredService(m.services[idx])
    result = {
        title:   m.showName,
        service: svc.name,
        appId:   svc.appId
    }

    if m.selectedMatch <> invalid
        result.metadataProvider = m.selectedMatch.provider
        result.metadataId = m.selectedMatch.TMDbId
        result.mediaType = m.selectedMatch.mediaType
    end if

    m.top.result = result
end sub

function preferredService(svc as Object) as Object
    if svc = invalid then return svc
    if shouldUseDisneyForHuluAndESPN() and isHuluOrESPN(svc.name)
        return {
            name: "Disney+",
            appId: "291097"
        }
    end if

    return svc
end function

function shouldUseDisneyForHuluAndESPN() as Boolean
    reg = CreateObject("roRegistrySection", "RokuTracker")
    if reg.exists("useDisneyForHuluAndESPN")
        return LCase(reg.read("useDisneyForHuluAndESPN")) = "true"
    end if

    return false
end function

function isHuluOrESPN(serviceName as Dynamic) as Boolean
    if serviceName = invalid then return false

    normalized = LCase(serviceName)
    normalized = normalized.Replace(".", "")
    normalized = normalized.Replace("+", " plus")
    normalized = normalized.trim()

    return normalized = "hulu" or normalized = "espn" or normalized = "espn plus"
end function

function formatShowTitle(rawTitle as String) as String
    title = rawTitle.trim()
    formatted = ""
    capitalizeNext = true
    separators = " -/:([&"

    for i = 1 to Len(title)
        ch = Mid(title, i, 1)
        if capitalizeNext
            formatted = formatted + UCase(ch)
        else
            formatted = formatted + ch
        end if

        capitalizeNext = Instr(1, separators, ch) > 0
    end for

    return formatted
end function

sub cancel()
    m.top.result = invalid
end sub
