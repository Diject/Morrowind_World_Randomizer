local label = "[Morrowind World Randomizer] "
return function(str, ...)
    mwse.log(label.."["..tostring(os.time()).."] "..str, ...)
end