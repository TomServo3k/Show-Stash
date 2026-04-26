function TMDbSearchShows(query as String) as Object
    apiKey = TMDbApiKey()
    if apiKey = ""
        return {
            ok: false,
            error: "TMDb API key is missing.",
            items: []
        }
    end if

    cleanedQuery = TMDbNormalizeTitleQuery(query)
    if cleanedQuery = ""
        return {
            ok: true,
            error: "",
            items: []
        }
    end if

    items = []
    seenIds = {}

    queries = TMDbSearchQueries(cleanedQuery)
    for each searchQuery in queries
        TMDbAppendSearchResults(items, seenIds, searchQuery, cleanedQuery, apiKey)
    end for

    TMDbSortItemsByScore(items)

    return {
        ok: true,
        error: "",
        provider: "TMDb",
        items: items
    }
end function

sub TMDbAppendSearchResults(items as Object, seenIds as Object, query as String, originalQuery as String, apiKey as String)
    url = "https://api.themoviedb.org/3/search/tv?query=" + TMDbUrlEncode(query) + "&include_adult=false&language=en-US&page=1&api_key=" + apiKey
    parsed = TMDbGetJson(url)
    if parsed = invalid or parsed.results = invalid then return

    for each show in parsed.results
        if items.count() >= 16 then return
        if show.id <> invalid
            idKey = StrI(show.id).trim()
            if seenIds[idKey] = invalid
                seenIds[idKey] = true

                title = ""
                if show.name <> invalid then title = show.name
                if title = "" and show.original_name <> invalid then title = show.original_name

                if title <> ""
                    year = TMDbYearFromDate(show.first_air_date)
                    providerResult = TMDbBestSupportedProvider(show.id, apiKey)
                    displayTitle = TMDbDisplayTitle(title, year, providerResult.service)
                    if TMDbComparableTitle(originalQuery) <> TMDbComparableTitle(title)
                        displayTitle = "Did you mean: " + displayTitle
                    end if

                    item = {
                        title: title,
                        year: year,
                        TMDbId: show.id,
                        provider: "TMDb",
                        mediaType: "tv",
                        service: invalid,
                        services: providerResult.services,
                        matchScore: TMDbTitleScore(originalQuery, title),
                        displayTitle: displayTitle
                    }

                    if providerResult.service <> invalid
                        item.service = {
                            name: providerResult.service.name,
                            appId: providerResult.service.appId
                        }
                    end if

                    items.push(item)
                end if
            end if
        end if
    end for
end sub

function TMDbSearchQueries(query as String) as Object
    queries = []
    TMDbPushUniqueQuery(queries, query)
    TMDbPushUniqueQuery(queries, TMDbStripLeadingArticle(query))

    simplified = TMDbSimplifyQuery(query)
    TMDbPushUniqueQuery(queries, simplified)
    TMDbPushUniqueQuery(queries, TMDbStripLeadingArticle(simplified))

    words = simplified.split(" ")
    if words.count() > 1
        for each word in words
            if Len(word) >= 4 then TMDbPushUniqueQuery(queries, word)
        end for
    end if

    for each variant in TMDbQueryVariants(simplified)
        TMDbPushUniqueQuery(queries, variant)
    end for

    return queries
end function

function TMDbQueryVariants(query as String) as Object
    variants = []
    words = query.split(" ")
    if words.count() = 0 then return variants

    lastIdx = words.count() - 1
    lastWord = words[lastIdx]
    if Len(lastWord) < 4 then return variants

    suffixes = ["s", "es"]
    for each suffix in suffixes
        copy = TMDbCopyWords(words)
        copy[lastIdx] = lastWord + suffix
        variants.push(TMDbJoinWords(copy))
    end for

    if Right(lastWord, 1) = "y"
        copy = TMDbCopyWords(words)
        copy[lastIdx] = Left(lastWord, Len(lastWord) - 1) + "ies"
        variants.push(TMDbJoinWords(copy))
    end if

    replacements = [
        { from: "ice", to: "ise" },
        { from: "ise", to: "ice" },
        { from: "ase", to: "ise" },
        { from: "ese", to: "ise" },
        { from: "dice", to: "dise" },
        { from: "dase", to: "dise" }
    ]

    for each replacement in replacements
        if Right(lastWord, Len(replacement.from)) = replacement.from
            copy = TMDbCopyWords(words)
            copy[lastIdx] = Left(lastWord, Len(lastWord) - Len(replacement.from)) + replacement.to
            variants.push(TMDbJoinWords(copy))
        end if
    end for

    if Len(lastWord) >= 5
        for i = 2 to Len(lastWord) - 1
            removed = Left(lastWord, i - 1) + Mid(lastWord, i + 1)
            copy = TMDbCopyWords(words)
            copy[lastIdx] = removed
            variants.push(TMDbJoinWords(copy))
        end for
    end if

    if Len(lastWord) >= 4
        for i = 2 to Len(lastWord) - 1
            swapped = Left(lastWord, i - 1) + Mid(lastWord, i + 1, 1) + Mid(lastWord, i, 1) + Mid(lastWord, i + 2)
            copy = TMDbCopyWords(words)
            copy[lastIdx] = swapped
            variants.push(TMDbJoinWords(copy))
        end for
    end if

    return variants
end function

function TMDbCopyWords(words as Object) as Object
    copy = []
    for each word in words
        copy.push(word)
    end for
    return copy
end function

function TMDbJoinWords(words as Object) as String
    text = ""
    for each word in words
        if text <> "" then text = text + " "
        text = text + word
    end for
    return text
end function

sub TMDbPushUniqueQuery(queries as Object, query as String)
    cleaned = TMDbNormalizeTitleQuery(query)
    if cleaned = "" then return

    lower = LCase(cleaned)
    for each existing in queries
        if LCase(existing) = lower then return
    end for

    queries.push(cleaned)
end sub

sub TMDbSortItemsByScore(items as Object)
    count = items.count()
    if count < 2 then return

    for i = 0 to count - 2
        for j = 0 to count - i - 2
            if TMDbCompareItems(items[j], items[j + 1]) > 0
                temp = items[j]
                items[j] = items[j + 1]
                items[j + 1] = temp
            end if
        end for
    end for

    while items.count() > 8
        items.pop()
    end while
end sub

function TMDbCompareItems(a as Object, b as Object) as Integer
    aScore = 999999
    bScore = 999999
    if a.matchScore <> invalid then aScore = a.matchScore
    if b.matchScore <> invalid then bScore = b.matchScore

    if aScore < bScore then return -1
    if aScore > bScore then return 1

    aTitle = ""
    bTitle = ""
    if a.title <> invalid then aTitle = LCase(a.title)
    if b.title <> invalid then bTitle = LCase(b.title)

    if aTitle < bTitle then return -1
    if aTitle > bTitle then return 1
    return 0
end function

function TMDbTitleScore(query as String, title as String) as Integer
    q = TMDbComparableTitle(query)
    t = TMDbComparableTitle(title)
    score = TMDbLevenshteinDistance(q, t)

    strippedTitle = TMDbComparableTitle(TMDbStripLeadingArticle(title))
    strippedScore = TMDbLevenshteinDistance(q, strippedTitle)
    if strippedScore < score then score = strippedScore

    prefixScore = TMDbPartialWordScore(q, t)
    if prefixScore < score then score = prefixScore

    if Instr(1, t, q) > 0 then score = score - 4
    if Instr(1, q, t) > 0 then score = score - 2
    if score < 0 then score = 0
    return score
end function

function TMDbPartialWordScore(query as String, title as String) as Integer
    queryWords = query.split(" ")
    titleWords = title.split(" ")
    if queryWords.count() = 0 or titleWords.count() = 0 then return 999999

    total = 0
    matched = 0

    for each queryWord in queryWords
        if Len(queryWord) >= 3
            best = 999999
            for each titleWord in titleWords
                wordScore = TMDbPrefixWordDistance(queryWord, titleWord)
                if wordScore < best then best = wordScore
            end for

            total = total + best
            matched = matched + 1
        end if
    end for

    if matched = 0 then return 999999
    return total
end function

function TMDbPrefixWordDistance(queryWord as String, titleWord as String) as Integer
    if queryWord = titleWord then return 0

    if Len(titleWord) >= Len(queryWord)
        if Left(titleWord, Len(queryWord)) = queryWord
            return Len(titleWord) - Len(queryWord)
        end if
    end if

    if Len(queryWord) >= Len(titleWord)
        if Left(queryWord, Len(titleWord)) = titleWord
            return Len(queryWord) - Len(titleWord) + 2
        end if
    end if

    compareLen = Len(queryWord)
    if Len(titleWord) < compareLen then compareLen = Len(titleWord)
    if compareLen < 1 then return 999999

    return TMDbLevenshteinDistance(queryWord, Left(titleWord, compareLen)) + Abs(Len(titleWord) - Len(queryWord))
end function

function TMDbComparableTitle(value as String) as String
    return TMDbSimplifyQuery(TMDbStripLeadingArticle(value))
end function

function TMDbSimplifyQuery(value as String) as String
    text = LCase(value)
    allowed = "abcdefghijklmnopqrstuvwxyz0123456789 "
    simplified = ""

    for i = 1 to Len(text)
        ch = Mid(text, i, 1)
        if Instr(1, allowed, ch) > 0
            simplified = simplified + ch
        else
            simplified = simplified + " "
        end if
    end for

    return TMDbNormalizeTitleQuery(simplified)
end function

function TMDbLevenshteinDistance(a as String, b as String) as Integer
    aLen = Len(a)
    bLen = Len(b)
    if aLen = 0 then return bLen
    if bLen = 0 then return aLen

    previous = []
    current = []

    for j = 0 to bLen
        previous.push(j)
        current.push(0)
    end for

    for i = 1 to aLen
        current[0] = i
        aChar = Mid(a, i, 1)

        for j = 1 to bLen
            bChar = Mid(b, j, 1)
            cost = 1
            if aChar = bChar then cost = 0

            deletion = previous[j] + 1
            insertion = current[j - 1] + 1
            substitution = previous[j - 1] + cost
            current[j] = TMDbMin3(deletion, insertion, substitution)
        end for

        for j = 0 to bLen
            previous[j] = current[j]
        end for
    end for

    return previous[bLen]
end function

function TMDbMin3(a as Integer, b as Integer, c as Integer) as Integer
    minValue = a
    if b < minValue then minValue = b
    if c < minValue then minValue = c
    return minValue
end function

function TMDbBestSupportedProvider(TMDbId as Integer, apiKey as String) as Object
    providers = TMDbWatchProviders(TMDbId, apiKey)
    services = []
    best = invalid

    for each provider in providers
        svc = metadataFindSupportedService(provider)
        if svc <> invalid
            alreadyAdded = false
            for each existing in services
                if existing.name = svc.name then alreadyAdded = true
            end for

            if not alreadyAdded
                services.push({
                    name: svc.name,
                    appId: svc.appId
                })
            end if

            if best = invalid then best = svc
        end if
    end for

    return {
        service: best,
        services: services
    }
end function

function TMDbWatchProviders(TMDbId as Integer, apiKey as String) as Object
    url = "https://api.themoviedb.org/3/tv/" + StrI(TMDbId).trim() + "/watch/providers?api_key=" + apiKey
    parsed = TMDbGetJson(url)
    providers = []
    if parsed = invalid or parsed.results = invalid then return providers
    if parsed.results.US = invalid then return providers

    us = parsed.results.US
    TMDbAppendProviders(providers, us.flatrate)
    TMDbAppendProviders(providers, us.free)
    TMDbAppendProviders(providers, us.ads)
    TMDbAppendProviders(providers, us.rent)
    TMDbAppendProviders(providers, us.buy)
    return providers
end function

sub TMDbAppendProviders(providers as Object, group as Object)
    if group = invalid then return
    for each provider in group
        providers.push(provider)
    end for
end sub

function TMDbGetJson(url as String) as Object
    xfer = CreateObject("roUrlTransfer")
    xfer.setCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.enableEncodings(true)
    xfer.setUrl(url)
    response = xfer.GetToString()
    if response = invalid or response = "" then return invalid
    return ParseJson(response)
end function

function TMDbApiKey() as String
    reg = CreateObject("roRegistrySection", "RokuTracker")
    if reg.exists("TMDbApiKey")
        key = reg.read("TMDbApiKey")
        if key <> invalid and key.trim() <> "" then return key.trim()
    end if

    appInfo = CreateObject("roAppInfo")
    key = appInfo.GetValue("TMDb_api_key")
    if key = invalid then return ""
    return key.trim()
end function

function TMDbNormalizeTitleQuery(query as String) as String
    normalized = query.trim()
    while Instr(1, normalized, "  ") > 0
        normalized = normalized.Replace("  ", " ")
    end while
    return normalized
end function

function TMDbStripLeadingArticle(query as String) as String
    lower = LCase(query)
    if Left(lower, 4) = "the " then return Mid(query, 5).trim()
    if Left(lower, 3) = "an " then return Mid(query, 4).trim()
    if Left(lower, 2) = "a " then return Mid(query, 3).trim()
    return query
end function

function TMDbDisplayTitle(title as String, year as String, service as Object) as String
    display = title
    if year <> "" then display = display + " (" + year + ")"

    if service <> invalid
        display = display + "  -  " + service.name
    else
        display = display + "  -  choose service"
    end if

    return display
end function

function TMDbYearFromDate(dateValue) as String
    if dateValue = invalid then return ""
    dateText = dateValue
    if Len(dateText) < 4 then return ""
    return Left(dateText, 4)
end function

function TMDbUrlEncode(value as String) as String
    xfer = CreateObject("roUrlTransfer")
    return xfer.Escape(value)
end function
