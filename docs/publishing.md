# Publishing

Releases are built by [BigWigsMods/packager](https://github.com/BigWigsMods/packager) from `.github/workflows/release.yml` and uploaded to CurseForge and Wago, plus a GitHub release. `.github/workflows/ci.yml` runs the tests and checks on every push to `main` and every pull request.

## One-time setup

1. Create the addon project on each site, using the text and field values in [listing.md](listing.md), and note its ID.
2. Add the IDs to the TOC files (both of them, `ClosestVendor/ClosestVendor_Vanilla.toc` and `ClosestVendor/ClosestVendor_Camelot.toc`):

   ```
   ## X-Curse-Project-ID: <CurseForge project ID>
   ## X-Wago-ID: <Wago project ID>
   ```

   The packager skips any site whose ID is missing, so the workflow works before the projects exist (it then only makes the GitHub release).
3. Add these repository secrets (Settings > Secrets and variables > Actions): `CF_API_TOKEN`, `WAGO_API_TOKEN`. `GITHUB_TOKEN` is provided by GitHub.
4. Pick MIT as the license on each site. The repository's `LICENSE` and `THIRD_PARTY.md` ship inside the package, which keeps the pfQuest notice with the vendor data.

## Releasing

1. Archive the change and bump `## Version:` in both TOC files (see `CLAUDE.md`), and add the version to `CHANGELOG.md` as a `## X.Y.Z` section.
2. Run `make test` and `make check` locally.
3. Commit, then tag the commit `vX.Y.Z` (the version without the `v` must equal the TOC version) and push the tag.
4. The workflow runs the tests and `make check`, checks the tag against both TOC versions and the changelog, packages, uploads to CurseForge and Wago, then creates the GitHub release with the zip attached.

## How the package is laid out

- The addon lives in `ClosestVendor/` inside the repository, so `.pkgmeta` moves it to the top of the zip and ignores everything else (tests, tools, docs, openspec, README).
- `LICENSE`, `THIRD_PARTY.md` and `CHANGELOG.md` are not ignored, so they ship.
- No libraries are fetched; the addon has none.
- The packager treats `ClosestVendor_Camelot.toc` as the WoW Forever TOC (its name for the Forever client) and `ClosestVendor_Vanilla.toc` as Classic Era, the same as the sibling addon `wow-dontdothat`.
- `CHANGELOG.md` is used as the changelog on every site (`manual-changelog` in `.pkgmeta`).

## Regenerating the vendor data

The vendor list `ClosestVendor/Data/Vendors.lua` is generated and committed. To refresh it:

```
python3 tools/fetch_data.py      # downloads the pinned pfQuest commit and wago tables
python3 tools/build_vendors.py   # rewrites Vendors.lua
make test                        # the data check runs as part of the tests
```

To move to a newer pfQuest commit or game build, change the pins at the top of `tools/fetch_data.py`, rebuild, and review the diff.
