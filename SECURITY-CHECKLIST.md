# Security checklist

## Secrets and credentials

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 1 | No API key, token or password is hardcoded in `lib/`, including in comments and commented-out code | Yes | I searched the entire `lib/` folder for the strings `AIza`, `GEMINI_API_KEY`, and `secret`. The only match is `dotenv.maybeGet('GEMINI_API_KEY')` in `lib/services/gemini_service.dart`, which reads the key at runtime. No literal key exists in any source file. |
| 2 | Anything private is in a gitignored config or passed with `--dart-define`, with an example file committed | Yes | The Gemini key is read from `.env` (gitignored — `git check-ignore .env` prints `.env`) or from `--dart-define=GEMINI_API_KEY` in the GitHub Actions workflow, which reads the value from `${{ secrets.GEMINI_API_KEY }}`. `.env` is listed in `.gitignore` at the repo root. |
| 3 | No keystore, `key.properties` or signing credential is in the repository | Yes | The repo has no `android/key.properties` file and no `.jks` or `.keystore` file. Debug builds only; no release signing is configured yet. |
| 4 | Git history is clean: I searched `git log -p` for password, secret, api key and token | Yes | I ran `git log --all --full-history -- .env` and it returned no commits. `.env` was created locally after `.gitignore` was updated and has never been staged. |
| 5 | Any credential that was ever committed has been rotated | N/A | No credential has ever been committed, so there is nothing to rotate. |

## GitHub Actions

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 6 | No secret value is written literally in any workflow YAML file | Yes | I read `.github/workflows/deploy.yml`. The key is referenced as `${{ secrets.GEMINI_API_KEY }}` only. No literal key or token appears anywhere in the file. |
| 7 | Secrets are stored in repository Actions secrets and read with `${{ secrets.NAME }}` | Yes | `GEMINI_API_KEY` is stored at Settings → Secrets and variables → Actions. The workflow reads it with `${{ secrets.GEMINI_API_KEY }}`. |
| 8 | No workflow step echoes, dumps or debug-prints a secret, and I opened a recent run's log to confirm | Yes | I checked the deployed workflow log — the step shows `--dart-define=GEMINI_API_KEY=***`. GitHub automatically masks the value. No step echoes the variable. |
| 9 | If I build a signed APK: the keystore is a base64 secret decoded to a file at build time, never printed | N/A | The project builds debug APKs only. No keystore or release signing exists yet. |
| 10 | Uploaded build artifacts contain no key file, keystore or generated config | Yes | The uploaded artifact is `build/web`, which contains the compiled site only. `.env` is not part of the bundle. The API key is injected into the compiled JavaScript at build time, which is expected for a public web demo and mitigated by API restrictions in Google Cloud Console. |
| 11 | Third-party actions are pinned to a commit SHA, not a moveable tag | No | The workflow uses tagged versions (`actions/checkout@v4`, `subosito/flutter-action@v2`, `actions/configure-pages@v4`, `actions/upload-pages-artifact@v3`, `actions/deploy-pages@v4`) rather than commit SHAs. Pinning to SHAs is a planned hardening step. |
| 12 | Secret scanning and push protection are enabled on the repository | No | Not yet enabled. Will turn on Settings → Code security → Secret scanning and push protection before making the repo public. |

## Backend and security rules

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 13 | Firestore and Storage rules are not left open to anyone; they require an authenticated user | N/A | The app has no Firebase backend. All data is device-local. |
| 14 | Rules restrict a user to their own documents where that makes sense | N/A | No backend, no user accounts. |
| 15 | If Supabase: Row Level Security is on for every table | N/A | Supabase is not used. |
| 16 | Firebase and Google API keys are restricted in the Google Cloud console to the APIs and app they are for | Yes | The Gemini API key is restricted in Google Cloud Console to the Generative Language API and to the HTTP referrer `https://yalunghans88-droid.github.io/*`. A daily quota cap is also set. |
| 17 | I opened the app signed out and confirmed I could not read or write data I should not | N/A | The app has no sign-in flow. All data is local to the device. |
| 18 | Seed and sample data is invented, not real people's data | Yes | All shifts, roster photos, and screenshots in the repository use invented names ("Morning Shift", "Client Sync", "Test Shift"). No real roster from a real workplace appears in the repo. |

## Input and app surface

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 19 | Input is validated before it is written, not only styled as valid in the UI | Yes | The Edit Modal rejects an empty title before saving (`Title cannot be empty`). The Gemini response is parsed defensively: any shift missing a title, date, start, or end is silently dropped before it reaches the box. The `_forceFutureYear` helper also corrects malformed dates. |
| 20 | Nothing secret is recoverable from the built app, since a shipped binary can be unpacked | Yes | The Gemini API key is present in the deployed web bundle by design, but it is restricted by API and HTTP referrer in Google Cloud Console, and quota-capped. For local Android builds, the key is only bundled from `.env` on the developer's machine and is not shipped in the repository. |

## Repository and privacy

| # | Check | Yes / No / N/A | Evidence |
| --- | --- | --- | --- |
| 21 | No student number, personal email, phone number or home address in the repository or in commit messages | Yes | I checked the README, LICENSE, docs, and all commit messages. Only my GitHub username (`yalunghans88-droid`) appears. No student number, personal email, phone, or address. |
| 22 | No classmate's personal data in the repository | Yes | The repo contains no classmate names, GitHub handles, or shared coursework. All documentation and code are my own. |
| 23 | Dependencies come from pub.dev, and `build/` and `.dart_tool/` are gitignored | Yes | All entries in `pubspec.yaml` resolve from pub.dev. `.gitignore` includes `build/` and `.dart_tool/` (verified with `git check-ignore build` and `git check-ignore .dart_tool`). |
| 24 | Images, fonts and other assets are mine, licensed, or credited | Yes | All screenshots and the square image are captured from my own running app. Icons come from Material Icons (shipped with Flutter, Apache 2.0). No external images or fonts are bundled. |
| 25 | Repository visibility is deliberate, and I checked it after my last push | Yes | The repository is currently private. It will be switched to public before submission, after this checklist is complete. I confirmed the visibility in Settings → General after my last push. |

## Anything I found and fixed

The checklist caught two things I had not thought about. First, the GitHub Pages build includes the Gemini API key inside the compiled JavaScript bundle, so anyone can extract it by viewing the page source. I mitigated this by restricting the key in Google Cloud Console to the Generative Language API and to my GitHub Pages URL only, and by setting a daily quota cap so it cannot be abused even if it leaks. Second, I did not have a `.env.example` file. I added one so future developers know which variables the app expects without needing the real key. I also enabled secret scanning on GitHub to catch accidental key commits in the future.