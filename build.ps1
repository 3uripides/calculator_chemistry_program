# Converts src/*.txt (TI-BASIC text) into build/*.8xp for the TI-84 Plus CE.
# Tokens come from tokens/8X.xml (TI-Toolkit). Write source as the calculator's editor shows it
# (e.g. `Disp "HI"`, `inString(`); longest match wins. Unknown text throws.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

[xml]$doc = Get-Content "$root\tokens\8X.xml" -Encoding UTF8
$Tbl = New-Object 'System.Collections.Generic.Dictionary[string,byte[]]' ([StringComparer]::Ordinal)
$forced = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
# Several tokens share a name (e.g. "T" is also the transpose token). Letters/digits get their plain ASCII-code
# token, lowercase gets the BBxx token, otherwise the shortest token wins, then the first one in the file.
function Put([string]$n, [byte[]]$b) {
  if ($n.Length -eq 1 -and $n -cmatch '^[A-Z0-9]$' -and $b.Length -eq 1 -and $b[0] -eq [byte][char]$n) { $Tbl[$n] = $b; [void]$forced.Add($n); return }
  if (-not $Tbl.ContainsKey($n)) { $Tbl[$n] = $b; return }
  if ($forced.Contains($n)) { return }
  $old = $Tbl[$n]
  if ($b.Length -lt $old.Length -or ($n -cmatch '^[a-z]$' -and $b[0] -eq 0xBB -and $old[0] -ne 0xBB)) { $Tbl[$n] = $b }
}
function Add-Tok($el, $prefix) {
  $hex = $prefix + ($el.value -replace '\$', '')
  $bytes = [byte[]]@(for ($i = 0; $i -lt $hex.Length; $i += 2) { [Convert]::ToByte($hex.Substring($i, 2), 16) })
  foreach ($ver in @($el.version)) { foreach ($lg in @($ver.lang)) { if ($lg.code -eq 'en') {
    foreach ($n in (@($lg.accessible) + @($lg.display))) { if ($n) { Put $n $bytes } }
  } } }
  foreach ($c in @($el.token)) { if ($c) { Add-Tok $c $hex } }
}
foreach ($el0 in @($doc.tokens.token)) { Add-Tok $el0 '' }
foreach ($tb in @($doc.tokens.'two-byte')) { foreach ($c in @($tb.token)) { if ($c) { Add-Tok $c ($tb.value -replace '\$', '') } } }
$maxLen = ($Tbl.Keys | Measure-Object -Property Length -Maximum).Maximum

function Convert-Line([string]$s) {
  $out = New-Object System.Collections.Generic.List[byte]; $i = 0; $inQ = $false; $afterPrgm = $false
  while ($i -lt $s.Length) {
    $k = $null
    if ($afterPrgm -and $s[$i] -cnotmatch '[A-Z0-9]') { $afterPrgm = $false }
    $top = if ($inQ -or $afterPrgm) { 1 } else { [Math]::Min($maxLen, $s.Length - $i) }  # in quotes or a program name: literal characters only
    for ($len = $top; $len -ge 1; $len--) {
      $c = $s.Substring($i, $len); if ($Tbl.ContainsKey($c)) { $k = $c; break }
    }
    if (-not $k) { throw "Cannot tokenize '$($s.Substring($i))' (char '$($s[$i])')" }
    $i += $k.Length
    if ($k -eq '"') { $inQ = -not $inQ }
    if ($k -ceq 'prgm') { $afterPrgm = $true }
    if (-not $inQ -and $k.Length -gt 1 -and $k -cmatch '^[A-Za-z0-9]+$') { [void]$script:multi.Add($k) }  # shown so accidental multi-letter tokens (e.g. PV) are visible
    if ($k -eq ' ' -and -not $inQ) { continue }  # a stray space outside quotes is a syntax error on the calculator
    $out.AddRange([byte[]]$Tbl[$k])
  }
  ,$out.ToArray()
}

New-Item -ItemType Directory -Force "$root\build" | Out-Null
foreach ($f in (Get-ChildItem "$root\src\*.txt", "$root\tests\*.txt" -ErrorAction SilentlyContinue)) {
  $script:multi = New-Object 'System.Collections.Generic.HashSet[string]'
  $name = $f.BaseName.ToUpper()
  $tok = New-Object System.Collections.Generic.List[byte]
  $lines = Get-Content $f.FullName -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
  for ($n = 0; $n -lt $lines.Count; $n++) {
    try { $tok.AddRange([byte[]](Convert-Line ($lines[$n] -replace '^:', ''))) }
    catch { throw "$($f.Name) line $($n+1): $_" }
    if ($n -lt $lines.Count - 1) { $tok.Add(0x3F) }
  }
  $dl = $tok.Count + 2
  $entry = New-Object System.Collections.Generic.List[byte]
  $entry.AddRange([byte[]](0x0D,0x00,($dl -band 0xFF),($dl -shr 8),0x05))
  $nm = [Text.Encoding]::ASCII.GetBytes($name.PadRight(8,[char]0)); $entry.AddRange([byte[]]($nm[0..7]))
  $entry.AddRange([byte[]](0x00,0x00,($dl -band 0xFF),($dl -shr 8),($tok.Count -band 0xFF),($tok.Count -shr 8)))
  $entry.AddRange($tok)
  $sum = ($entry | Measure-Object -Sum).Sum -band 0xFFFF
  $hdr = [Text.Encoding]::ASCII.GetBytes('**TI83F*') + [byte[]](0x1A,0x0A,0x00) +
         [Text.Encoding]::ASCII.GetBytes('Built by build.ps1'.PadRight(42,[char]0))[0..41]
  $all = $hdr + [byte[]](($entry.Count -band 0xFF), ($entry.Count -shr 8)) + $entry.ToArray() + [byte[]](($sum -band 0xFF), ($sum -shr 8))
  [IO.File]::WriteAllBytes("$root\build\$name.8xp", [byte[]]$all)
  "Built build\$name.8xp ($($tok.Count) token bytes)" + $(if ($script:multi.Count) { "  [words: $($script:multi -join ' ')]" })
}
