function string.starts(s, a)
  return string.sub(s, 1, string.len(a)) == a
end