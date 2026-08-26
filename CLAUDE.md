# CLAUDE.md

Community site for **Balance Kung Fu SE**, a Ch'ang-style Shaolin kung fu club in Szeged, Hungary.
Static site built with **Hugo**, deployed to **GitHub Pages** at <https://szegedkungfu.hu/> (see `CNAME`).

## Key facts

- **Theme:** [Congo](https://github.com/jpanther/congo) **v2.14.0** (module path `github.com/jpanther/congo/v2`), pulled as a **Hugo module** (`go.mod` / `config/_default/module.toml`). The theme is *not* vendored — there is no `themes/` directory. Go must be installed for the module to resolve; the sources land in Hugo's module cache (`~/.cache/hugo_cache/modules/filecache/modules/pkg/mod/github.com/jpanther/congo/v2@v2.14.0`), which is the place to look up what a theme partial actually does.
- **Language:** the site is entirely in **Hungarian** (`defaultContentLanguage = "hu"`). All page content, titles, menu labels and URL slugs are Hungarian.
- **Build:** `hugo` (or `make`) → `public/` (gitignored). Dev server: `hugo serve`. If modules misbehave: `hugo mod clean`.
- **Toolchain versions are pinned, and drift between local and CI is the historical source of breakage here.** Both are declared in the repo:
  - **Hugo** — `hugo_extended` **0.165.0**, pinned via `HUGO_VERSION` in `.github/workflows/main.yml`. Congo v2 needs a recent extended build.
  - **Go** — `go 1.26.5` in `go.mod`. CI installs it with `actions/setup-go` using `go-version-file: go.mod`, so there is one source of truth. Go compiles nothing here; it only resolves the theme module.

## Directory map

```
config/_default/     Hugo configuration (TOML, split by concern)
  config.toml        language default + sitemap settings
  languages.hu.toml  site title, description, copyright
  menus.toml         only the "home" entry; other menu items come from page front matter
  module.toml        imports the Congo theme module
  params.toml        Congo theme parameters (colour scheme, header/footer, article options)

content/             all page content (Markdown, Hungarian)
  _index.md          homepage
  edzesek.md         "Edzések" — training times/location  (weight 10)
  kapcsolat.md       "Kapcsolat" — contact + tax number   (weight 11)
  egyesulet.md       "Egyesületünk" — about the club      (weight 12)
  stilusunk/index.md "Ch'ang stílus" — the martial art    (weight 25)  page bundle
  cikkek/            "Cikkek" — blog section              (weight 40)
    _index.md          section list page
    <slug>/index.md    one page bundle per article, images co-located
  iskolak.md         "Testvériskolák" — sister clubs table (weight 50)
  impresszum.md      footer-only page (menu: footer)

layouts/             local overrides on top of the Congo theme
  partials/
    extend-head.html    injects a keywords meta tag from front-matter Keywords
    extend-footer.html  Facebook + Discord links in the footer
  shortcodes/
    logo.html           renders /img/logo.png
    hattyas-iframe.html Google Maps embed of the training venue (SZTE Sportközpont, Hattyas sor 10.)
    cloakemail.html     obfuscated e-mail link (from hugo-cloak-email)
  _default/_markup/
    render-link.html    render hook: external links get target=_blank rel=nofollow noopener

static/              copied verbatim to the site root
  img/logo.png       used by the {{< logo >}} shortcode as /img/logo.png
  docs/*.pdf         linked from content as /docs/...
  favicon.ico, favicon-16x16.png, favicon-32x32.png
  apple-touch-icon.png (180), android-chrome-192x192.png, android-chrome-512x512.png
                     Generated from assets/img/logo_complete.svg; the android pair is
                     declared "maskable", so the mark is padded into the centre ~76%.
  site.webmanifest   PWA manifest; its icon list must match the filenames above

assets/              Hugo Pipes / theme asset lookups
  img/logo_complete.svg   textless logo; SOURCE for the generated app icons above
  img/silhouette-{1,2,3}.svg, font/blowbrush.otf
                     Design sources kept deliberately but NOT wired into the site yet.
                     Do not "clean up" as unused — they are staged brand assets.

i18n/hu.yaml         translation overrides — currently empty
.github/workflows/
  main.yml           build + deploy to GitHub Pages on push to main
  develop.yml        runs pre-commit on pull requests
```

## Conventions

- **Menu order** is driven by `weight` in each page's front matter plus `menu: "main"`. `config/_default/menus.toml` only defines the home link. To add a page to the nav, set both `menu: "main"` and a `weight`.
- **Front matter is YAML** (`---` fenced) in content, while **config is TOML**. Common keys used here: `title`, `aliases`, `weight`, `menu`, `showDate: false`, `sitemap.changefreq`/`sitemap.priority`, `tags`, `draft`.
- **Renaming a page requires an alias.** Slugs were migrated from English to Hungarian, and each renamed page carries its old URL in `aliases:` so inbound links and search results keep working. Hugo emits a meta-refresh redirect page at each alias and leaves aliases out of `sitemap.xml`. Current map:

  | old URL                       | page                               |
  | ----------------------------- | ---------------------------------- |
  | `/schedule/`                  | `edzesek.md`                       |
  | `/contact/`                   | `kapcsolat.md`                     |
  | `/assocication/`              | `egyesulet.md`                     |
  | `/schools/`                   | `iskolak.md`                       |
  | `/impressum/`                 | `impresszum.md`                    |
  | `/style/`                     | `stilusunk/index.md`               |
  | `/articles/`                  | `cikkek/_index.md`                 |
  | `/articles/chang-dung-sheng/` | `cikkek/chang-dung-sheng/index.md` |

  The slug migration is complete — every published English URL now redirects. `xx-evfordulo` carries `draft: true` and was never published, so it needs no alias. When renaming, remember to grep for in-body absolute links (`grep -rn "](/" content/`) as well as adding the alias.
- **Images belonging to a page live in that page's bundle** (e.g. `content/stilusunk/chang_tung_sheng.jpg`) and are referenced by bare filename via Congo's `{{< figure src="..." >}}`. Site-wide images go in `static/`.
- Shortcodes in use: local `logo`, `hattyas-iframe`, `cloakemail`, plus Congo's built-in `figure` and `icon`.
- **Congo's `icon` partial/shortcode only resolves `assets/icons/<name>.svg`** — SVG only, no other format. The theme already bundles ~45 icons (facebook, discord, email, whatsapp, …), so custom files are only needed for icons Congo lacks.
- Layout files here are **overrides only** — anything not present in `layouts/` falls through to the Congo theme. Prefer adding an override over forking the theme.
- **Formatting** is enforced by pre-commit (`check-yaml`, `check-toml`, `end-of-file-fixer`, `trailing-whitespace`) and `.editorconfig` (LF, UTF-8, 4-space indent; 2 for TOML/YAML). `*.html` is excluded from prettier.

## Verifying a change

There is no test suite; a build plus a few greps is the check. `hugo` exits 0 on a broken
page, so assert on the output rather than the exit code:

```sh
hugo --logLevel warn --destination /tmp/check     # must print no WARN/ERROR lines
grep -c '<html' /tmp/check/edzesek/index.html     # 1 — a 0 means a template lost its baseof
grep -o 'url=[^"]*' /tmp/check/schedule/index.html   # alias still redirects
grep -o '<loc>[^<]*</loc>' /tmp/check/sitemap.xml     # canonical URLs only, no aliases
```

A page that renders content but weighs only a few KB has lost its frame. Sizes are a decent
smoke test: real pages here are 14–32KB, alias stubs well under 1KB.

## Gotchas

- **Congo v1.6.4 → v2 was forced by a Hugo upgrade.** The old theme used `.Site.Author`, which Hugo deprecated in 0.124 and *removed* in 0.146, so any modern Hugo failed with `can't evaluate field Author in type page.Site`. Congo v2's own `module.toml` claims `min = "0.87.0"` — that is wrong; v2 does not build on anything near it.
- **Bumping `HUGO_VERSION` in CI also means fixing the download URL.** Hugo renamed its release assets: the old `hugo_extended_<v>_Linux-64bit.deb` 404s on current versions, which now ship as `hugo_extended_<v>_linux-amd64.deb`.
- **Hugo 0.146 restructured template lookup, which can wake dormant overrides.** A `layouts/single.html` had sat in this repo for years doing nothing — pre-0.146 Hugo only looked for `layouts/_default/single.html`, so Congo's template rendered every page. After the upgrade `layouts/single.html` became a valid lookup path, took over, and — having no `{{ define "main" }}` — rendered every page with no base template: content but no `<html>`, no CSS, no nav or footer. It was deleted. If a page ever loses its "frame" again, suspect a project template that lacks `{{ define "main" }}`.
- The theme's own layout paths moved too (`layouts/_partials/`, `layouts/_markup/`). The old `layouts/partials/`, `layouts/shortcodes/` and `layouts/_default/_markup/` locations in this repo still resolve, and all four remaining overrides were verified working after the upgrade.

## Known gaps

- `static/site.webmanifest` still carries Congo's sample `background_color` of `#7c3aed` (purple), which Android uses for the splash screen behind the white-background app icon. It matches neither the `fire` colour scheme nor the icons. Cosmetic, deliberately left alone.
- The `deploy` job in `main.yml` is indented with 5 spaces where the rest of the file uses 6. Valid YAML, inherited from the original GitHub sample workflow.

## Branches

`main` is the deploy branch (pushing to it publishes the site). Work lands via PRs, historically through a `develop` branch; PRs run the pre-commit check.

The workflows were moved onto current action majors (`checkout@v7`, `setup-go@v7`, `configure-pages@v6`, `upload-pages-artifact@v5`, `deploy-pages@v5`, `setup-python@v7`, `pre-commit/action@v3.0.1`). The previous `upload-pages-artifact@v1` / `deploy-pages@v1` relied on the artifact backend GitHub retired in January 2025 and could no longer deploy.
