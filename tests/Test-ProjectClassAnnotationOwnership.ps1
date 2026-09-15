$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\Common.ps1"
$project = Get-ProjectRoot
$sourceRoot = Join-Path $project 'src\redscript\CyberpunkRealism'
$script:checks = 0
function Check($condition,[string]$message) { if (-not $condition) { throw $message }; $script:checks++ }

$classRegex = [regex]'(?m)^\s*(?:(?:public|private|protected|abstract|native|final)\s+)*class\s+(CR[A-Za-z0-9_]+)\b'
$annotationRegex = [regex]'@(?:addMethod|replaceMethod|addField)\(\s*([A-Za-z_][A-Za-z0-9_:.]*)\s*\)'
$sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -File -Filter '*.reds' | Sort-Object Name)
Check ($sourceFiles.Count -gt 0) 'No production REDscript sources found.'

$projectClasses = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$textByPath = @{}
foreach ($file in $sourceFiles) {
    $text = Get-Content -Raw -LiteralPath $file.FullName
    $textByPath[$file.FullName] = $text
    foreach ($match in $classRegex.Matches($text)) {
        [void]$projectClasses.Add($match.Groups[1].Value)
    }
}
Check ($projectClasses.Count -gt 0) 'Compile guard did not discover any project-defined CR* classes.'
Check ($projectClasses.Contains('CRBodyRuntime')) 'Compile guard failed to discover the canonical body authority class.'

$nativeAnnotationCount = 0
$violations = [Collections.Generic.List[string]]::new()
foreach ($file in $sourceFiles) {
    $text = [string]$textByPath[$file.FullName]
    foreach ($match in $annotationRegex.Matches($text)) {
        $rawTarget = $match.Groups[1].Value
        $target = ($rawTarget -split '[\.:]+')[-1]
        if ($projectClasses.Contains($target)) {
            $violations.Add("$($file.Name): $($match.Value) targets project-defined $target")
        } else {
            $nativeAnnotationCount++
        }
    }
}

# Prove the detector itself rejects the exact integration mistake this test exists
# for, rather than merely passing because production source currently has no match.
$fixtureClasses = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
[void]$fixtureClasses.Add('CRCompileGuardFixture')
$fixture = "public class CRCompileGuardFixture extends IScriptable {}`n@addMethod(CRCompileGuardFixture)`npublic func BrokenOwnership() -> Void {}"
$fixtureMatch = $annotationRegex.Match($fixture)
Check ($fixtureMatch.Success) 'Compile guard fixture annotation was not parsed.'
$fixtureTarget = ($fixtureMatch.Groups[1].Value -split '[\.:]+')[-1]
Check ($fixtureClasses.Contains($fixtureTarget)) 'Compile guard fixture did not identify a project-defined annotation target.'

if ($violations.Count -gt 0) {
    throw "Production REDscript patches project-defined Biology classes with native patch annotations. Put behavior in the owning class or a project-owned helper instead:`n - $($violations -join "`n - ")"
}
Check ($nativeAnnotationCount -gt 0) 'No legitimate native annotation targets were observed; guard is not exercising production seams.'

Write-Host "PASS: $script:checks annotation-ownership checks; discovered $($projectClasses.Count) project CR* classes and accepted $nativeAnnotationCount native-boundary add/replace/field annotations."
