sub init()
    m.top.functionName = "run"
end sub

sub run()
    provider = LCase(m.top.provider)
    if provider = "" then provider = "tmdb"

    if provider = "tmdb"
        m.top.result = TMDbSearchShows(m.top.query)
    else
        m.top.result = {
            ok: false,
            error: "Unsupported metadata provider: " + provider,
            items: []
        }
    end if
end sub

function metadataSupportedServices() as Object
    return [
        {
            name: "Netflix",
            appId: "12",
            providerIds: [8],
            aliases: ["netflix"]
        },
        {
            name: "Hulu",
            appId: "2285",
            providerIds: [15],
            aliases: ["hulu"]
        },
        {
            name: "Disney+",
            appId: "291097",
            providerIds: [337],
            aliases: ["disney plus", "disney+"]
        },
        {
            name: "ESPN",
            appId: "34376",
            providerIds: [317],
            aliases: ["espn", "espn plus", "espn+"]
        },
        {
            name: "Amazon Prime",
            appId: "13",
            providerIds: [9, 119],
            aliases: ["amazon prime video", "amazon video", "prime video"]
        },
        {
            name: "Max",
            appId: "61322",
            providerIds: [1899, 384],
            aliases: ["max", "hbo max"]
        },
        {
            name: "Apple TV+",
            appId: "551012",
            providerIds: [350],
            aliases: ["apple tv plus", "apple tv+"]
        },
        {
            name: "Peacock",
            appId: "593099",
            providerIds: [386],
            aliases: ["peacock", "peacock premium"]
        },
        {
            name: "Paramount+",
            appId: "353235",
            providerIds: [531],
            aliases: ["paramount plus", "paramount+"]
        }
    ]
end function

function metadataFindSupportedService(provider as Object) as Object
    if provider = invalid then return invalid

    providerId = invalid
    providerName = ""
    if provider.provider_id <> invalid then providerId = provider.provider_id
    if provider.provider_name <> invalid then providerName = normalizeProviderName(provider.provider_name)

    for each svc in metadataSupportedServices()
        for each id in svc.providerIds
            if providerId <> invalid and providerId = id then return svc
        end for

        for each alias in svc.aliases
            if providerName = alias then return svc
        end for
    end for

    return invalid
end function

function normalizeProviderName(name as String) as String
    normalized = LCase(name)
    normalized = normalized.Replace(".", "")
    normalized = normalized.Replace(":", "")
    normalized = normalized.Replace("-", " ")
    while Instr(1, normalized, "  ") > 0
        normalized = normalized.Replace("  ", " ")
    end while
    return normalized.trim()
end function
