sub init()
    m.top.functionName = "run"
end sub

sub run()
    xfer = CreateObject("roUrlTransfer")
    xfer.setCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.enableEncodings(true)
    xfer.setUrl("https://roku-tracker-default-rtdb.firebaseio.com/households/" + m.top.householdCode + "/shows.json")

    if m.top.action = "fetch"
        response = xfer.GetToString()
        parsed   = ParseJson(response)
        if type(parsed) = "roArray"
            m.top.result = parsed
        else
            m.top.result = []
        end if

    else if m.top.action = "push"
        xfer.SetRequest("PUT")
        xfer.AddHeader("Content-Type", "application/json")
        xfer.PostFromString(FormatJson(m.top.shows))
    end if
end sub
