# Publishing

[BigWigsMods/packager](https://github.com/BigWigsMods/packager) builds each release. It runs from `.github/workflows/release.yml`. It uploads the package to CurseForge and Wago. It also makes a GitHub release.

`.github/workflows/ci.yml` runs the tests and checks. It runs on every push to `main` and on every pull request.

## One-time setup

1. Create the addon project on each site. Use the text and field values in [listing.md](listing.md). Note the ID of each project.
2. Add the IDs to both TOC files: `ClosestVendor/ClosestVendor_Vanilla.toc` and `ClosestVendor/ClosestVendor_Camelot.toc`.

   ```
   ## X-Curse-Project-ID: <CurseForge project ID>
   ## X-Wago-ID: <Wago project ID>
   ```

   The packager skips a site when its ID is missing. Before the projects exist, the workflow only makes the GitHub release.
3. Add these repository secrets: `CF_API_TOKEN` and `WAGO_API_TOKEN`. The path is Settings > Secrets and variables > Actions. GitHub provides `GITHUB_TOKEN`.
4. Select MIT as the license on each site. The package includes `LICENSE` and `THIRD_PARTY.md`. This keeps the pfQuest notice with the vendor data.

## Releasing

1. Archive the change.
2. Set `## Version:` to the new version in both TOC files (see `CLAUDE.md`).
3. Add a `## X.Y.Z` section to `CHANGELOG.md`.
4. Run `make test` and `make check`.
5. Commit the changes.
6. Tag the commit `vX.Y.Z`. The version without the `v` must equal the TOC version.
7. Push the tag.

After you push the tag, the workflow does these steps:

1. It runs the tests and `make check`.
2. It compares the tag with both TOC versions and with the changelog.
3. It packages the addon.
4. It uploads the package to CurseForge and Wago.
5. It creates the GitHub release with the zip attached.

## How the package is laid out

- The addon is in `ClosestVendor/` in the repository. `.pkgmeta` moves it to the top of the zip. `.pkgmeta` ignores everything else (tests, tools, docs, openspec, README).
- `.pkgmeta` does not ignore `LICENSE`, `THIRD_PARTY.md` and `CHANGELOG.md`. They are in the package.
- The packager fetches no libraries. The addon has none.
- The packager treats `ClosestVendor_Camelot.toc` as the WoW Forever TOC. "Camelot" is the packager name for the Forever client. It treats `ClosestVendor_Vanilla.toc` as the Classic Era TOC. The sibling addon `wow-dontdothat` does the same.
- Every site uses `CHANGELOG.md` as the changelog (`manual-changelog` in `.pkgmeta`).

## Regenerating the vendor data

`ClosestVendor/Data/Vendors.lua` is generated and committed. To refresh it, run these commands:

```
python3 tools/fetch_data.py      # downloads the pinned pfQuest commit and wago tables
python3 tools/build_vendors.py   # rewrites Vendors.lua
make test                        # the data check runs as part of the tests
```

To use a newer pfQuest commit or game build, follow these steps:

1. Change the pins at the top of `tools/fetch_data.py`.
2. Rebuild the data.
3. Review the diff.
