$out = Join-Path $PSScriptRoot 'in'
New-Item -ItemType Directory $out -Force | Out-Null
$l = [System.Net.HttpListener]::new()
$l.Prefixes.Add('http://localhost:34999/')
$l.Start()
"listening"
while ($l.IsListening) {
  $ctx = $l.GetContext()
  $name = $ctx.Request.QueryString['name']
  if ($name -eq 'STOP') { $ctx.Response.Close(); break }
  $ms = [System.IO.MemoryStream]::new()
  $ctx.Request.InputStream.CopyTo($ms)
  [System.IO.File]::WriteAllBytes((Join-Path $out $name), $ms.ToArray())
  "got $name $($ms.Length)"
  $b = [Text.Encoding]::UTF8.GetBytes('ok')
  $ctx.Response.OutputStream.Write($b, 0, $b.Length)
  $ctx.Response.Close()
}
$l.Stop()
