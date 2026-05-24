---
name: flutter-test-analyze-debug
user-invocable: true
description: "Debug Flutter test failures and flutter analyze warnings by examining output, identifying root causes, and recommending precise fixes."
---

# Flutter Test and Analyze Debug

## Use when
- you have `flutter test` failures and need to identify why tests are broken
- you have `flutter analyze` warnings or errors and want a clear fix path
- you need a step-by-step diagnosis for Flutter/Dart build or analyzer output

## What this skill does
- reads `flutter test` output and extracts failing test names, assertions, and stack traces
- reads `flutter analyze` output and groups diagnostics by severity
- maps diagnostics to Dart/Flutter patterns such as null-safety, missing imports, unused code, type mismatches, widget assertions, and analyzer lints
- recommends exact code changes, import fixes, or `pubspec` updates
- proposes the next validation command, such as `flutter test`, `flutter analyze`, or `dart fix --apply`

## Workflow
1. Ask the user for the full terminal output for the failing `flutter test` or `flutter analyze` run.
2. Identify all errors and warnings, including file paths, line/column references, and diagnostic codes.
3. Determine the root cause for each issue:
   - failing assertions, unexpected exceptions, or widget test setup problems
   - analyzer warnings for imports, nullability, deprecated APIs, or dead code
4. Locate the relevant source block and inspect surrounding context if the file is available.
5. Recommend a concise fix for each problem and explain why it resolves the issue.
6. Suggest the follow-up command to verify the fix.

## Output expectations
- Clearly label each issue as `error`, `warning`, or `info`
- Provide a short root-cause summary for each diagnostic
- Give exact code or configuration changes when possible
- Include the next command to run for verification

## Example prompts
- "Help me debug this `flutter test` failure output."
- "Explain these `flutter analyze` warnings and show how to fix them."
- "I ran `flutter analyze`; here is the output. What should I change?"
