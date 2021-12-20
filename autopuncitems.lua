local ap = {} -- module table

function ap.rtrim(s)
   return (s:gsub("^(.-)%s*$", "%1"))
end

ap.punc = {}
ap.punc = {'.',  '; and'}  -- punctuation table, 1 is last val, 2 is 2nd last val
ap.punc[0] = ';'  -- [0] is default punctuation
ap.total = 0 -- total num of items (int)
ap.curr = 0  -- current item we're on (int)
ap.itemp = '\9' -- temporary item, item which WILL be affected by autopunc
ap.item = '\\item' -- item
ap.omit = '\\APomit' -- flag for hiding an item from punc and count, acts as if item is not there
ap.pass = '\\APpass' -- flag for passing item from punc, but still considered in count
ap.code = 0 -- code for skipping punc if > 0, keep in count if == 1, omit from count if == 2

ap.autopassnested = true

function ap.start(s)
     ap.curr = 0
    _, ap.total = s:gsub(ap.itemp, '')
    local _, omit = s:gsub(ap.omit, '')
    ap.total = ap.total - omit
end

function ap.setcode(s)
    local _, code1 = s:gsub(ap.pass, '', 1)
    local _, code2 = s:gsub(ap.omit, '', 1)
    ap.code = code1 + 2*code2
end

function ap.addcount(s)
    ap.setcode(s)
    if ap.code < 2 then -- if not omitting, we still keep counter going
        ap.curr = ap.curr + 1 -- increment counter
    end
end

function ap.getdelim()
        local d = ''
        if ap.code == 0 then         -- d limiter -- if not passing look at punctuation table for delimiter
            d = ap.punc[ap.total-ap.curr+1] or ap.punc[0]
        end
        return d
end

function ap.protectnest(s)
    local x = ''
    if ap.autopassnested then x = ap.pass..'{}' end
    s = s:gsub("\0", "\0", 0) -- dummy replacement to make code easier
     :gsub("\\begin%s*{itemize}", x.."\1%0") -- pad \1 and \2 in inner envirnments
     :gsub("\\end%s*{itemize}", "%0\2")
     :gsub("\\begin%s*{enumerate}", x.."\1%0")
     :gsub("\\end%s*{enumerate}", "%0\2")
     :gsub("\\begin%s*{description}", x.."\1%0")
     :gsub("\\end%s*{description}", "%0\2")
     :gsub("%b\1\2", "\0%0\0") -- use bracket to place \0 (on OUTER) nested lists only
     :gsub("(%Z*)%z?(%Z*)%z?", -- only affect matches outside list
         function(a, b) return a:gsub(ap.item, ap.itemp)..b:gsub("[\1\2]", "") end)
    return s
end


function ap.go(s)
    s = ap.protectnest(s)
    ap.start(s) -- start counters
    --texio.write_nl('yooo...'..s)
    s = s:gsub(ap.itemp, '\0\0'):gsub('\0', '', 1)  -- make all items \0\0 then change first item to one \0
    s = s:gsub('(%z)(%Z*)(%z?)',  -- find betwen \0 .. \0
            function(it, s, _it)  -- discarding duplicate item '_it' that was made in first gsub
                ap.addcount(s) -- add count, helps determine delimiter
                return ap.rtrim(it..s)..ap.getdelim()..' '
            end
        )
    s = s:gsub('\0', ap.itemp) -- replace items
    s = s:gsub(ap.itemp, ap.item) -- replace items
    return s
end

return ap