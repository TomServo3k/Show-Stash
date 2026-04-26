sub init()
    m.top.functionName = "run"
end sub

sub run()
    appId = m.top.appId
    if appId = invalid or appId = ""
        m.top.result = false
        return
    end if

    appMgr = CreateObject("roAppManager")
    if appMgr.IsAppInstalled(appId, "")
        params = {}
        m.top.result = appMgr.LaunchApp(appId, "", params)
    else
        appMgr.ShowChannelStoreSpringboard(appId)
        m.top.result = true
    end if
end sub
