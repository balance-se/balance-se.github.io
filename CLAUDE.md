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
  config.toml        baseURL, language default, sitemap, robots.txt + llms.txt output
  languages.hu.toml  site title, description, copyright
  menus.toml         intentionally empty; every menu item comes from page front matter
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
  home.html           the homepage (params.toml sets homepage.layout = "custom");
                      all its copy and photo references come from _index.md front matter,
                      including hero.keepTogether — phrases whose spaces become U+00A0
                      so the h1 never splits them ("Shaolin Kung Fu")
  robots.txt          overrides Congo's; names the AI crawlers explicitly
  home.llms.txt       generates /llms.txt from real page data (see Output formats)
  partials/
    logo.html           overrides Congo's: sets the site title in the header in two lines
                        ("Balance Kung Fu SE" / "Szeged"). NOT the {{< logo >}} shortcode
                        below — same filename, different lookup directory.
    photo.html          responsive <picture> for the homepage photos — see Photos below
    extend-head.html    SportsClub + Person JSON-LD, FAQPage JSON-LD, analytics preconnect
    extend-footer.html  the footer's last row: Facebook + Discord (rel="me") on the
                        left, the Hugo/Congo colophon pushed right. Congo's own
                        attribution is off (footer.showThemeAttribution)
    meta/date.html          overrides Congo to emit a valid ISO-8601 datetime attribute
    meta/date-updated.html  ditto
  shortcodes/
    logo.html           renders /img/logo.png (homepage LCP: sized, high priority, never lazy)
    hattyas-iframe.html Google Maps embed of the training venue (SZTE Sportközpont, Hattyas sor 10.)
    faq.html            renders the page's `faq:` front matter as visible Q&A
    cloakemail.html     obfuscated e-mail link (from hugo-cloak-email)
  _default/_markup/
    render-link.html    render hook: external links get target=_blank rel=noopener

static/              copied verbatim to the site root
  img/logo.png       used by the {{< logo >}} shortcode as /img/logo.png
  img/og-image.png   1200x630 Open Graph / Twitter card, site-wide fallback via
                     `images` in params.toml. Generated from static/img/logo.png
                     over a dark card; regenerate if the logo changes.
  docs/*.pdf         linked from content as /docs/...
  favicon.ico, favicon-16x16.png, favicon-32x32.png
  apple-touch-icon.png (180), android-chrome-192x192.png, android-chrome-512x512.png
                     Generated from assets/img/logo_complete.svg; the android pair is
                     declared "maskable", so the mark is padded into the centre ~76%.
  site.webmanifest   PWA manifest; its icon list must match the filenames above

assets/              Hugo Pipes / theme asset lookups
  css/custom.css          homepage, header and footer styling; Congo loads it on
                          every page. The header rules carry measured pixel widths
                          in their comments -- re-measure if a menu label or the
                          club name changes length
  img/kozosseg/*.jpg      prepared masters for the homepage photos — generated,
                          do not retouch by hand (see Photos below)
  img/logo_complete.svg   textless logo; SOURCE for the generated app icons above
  img/silhouette-{1,2,3}.svg, font/blowbrush.otf
                     Design sources kept deliberately but NOT wired into the site yet.
                     Do not "clean up" as unused — they are staged brand assets.

photos/original/     untouched camera files behind assets/img/kozosseg/. Outside
                     assets/ and static/, so Hugo never publishes them; they exist
                     only so the crops stay re-derivable.

scripts/
  prepare-photos.sh  crops and grades photos/original/ into assets/img/kozosseg/

i18n/hu.yaml         translation overrides — currently empty
.github/workflows/
  main.yml           build + deploy to GitHub Pages on push to main
  develop.yml        runs pre-commit on pull requests
```

## Conventions

- **Menu order** is driven by `weight` in each page's front matter plus `menu: "main"`. To add a page to the nav, set both `menu: "main"` and a `weight`. `config/_default/menus.toml` is deliberately empty — see the nav gotcha below. The site title in the header is already a link to `/`, so the nav carries no home entry.
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

## SEO / GEO

The site is tuned for local search and for AI answer engines. The load-bearing pieces:

- **`baseURL` is pinned** to `https://szegedkungfu.hu/` in `config.toml` and CI no longer passes
  `--baseURL`. Before, the value came from `actions/configure-pages` at build time, so a local
  `hugo` build silently baked `//localhost:1313/` into every canonical, `og:url` and `sitemap.xml`
  entry. Keep config and `CNAME` in agreement; changing one means changing the other.
- **Descriptions are mandatory.** Every page carries a hand-written `description` in front matter.
  Without one Congo falls back to `.Summary`, i.e. the first ~70 words of body text cut mid-sentence.
  Keep them unique and roughly 120-160 characters.
- **`keywords`, not `tags`.** Taxonomies are switched off (`disableKinds` in `config.toml`) because
  the tag lists were keyword stuffing that generated a dozen near-empty `/tags/*` pages on an
  eight-page site. The same terms live in `keywords` front matter, which Congo unions with
  `params.keywords` into the meta tag and the JSON-LD. Re-enabling taxonomies means deleting that
  `disableKinds` line *and* giving the tag pages real content.
- **Structured data is split in two.** Congo's `schema.html` emits `WebSite` (home), `Article` and
  `BreadcrumbList`; `layouts/partials/extend-head.html` adds what the theme has no concept of — the
  club as a real-world `SportsClub` with address, phone, training hours and `sameAs` profiles, plus
  a `Person` for the club leader. **The facts in that partial are duplicated from
  `content/kapcsolat.md` and `content/edzesek.md` — change one, change the other.** It is built with
  `jsonify` rather than hand-written JSON so Hungarian text escapes correctly.
- **FAQ content and FAQ schema share one source.** A page's `faq:` front matter (a list of `q`/`a`)
  is rendered visibly by `{{< faq >}}` and emitted as `FAQPage` JSON-LD by `extend-head.html`.
  Never hand-write one without the other — markup describing an answer the page does not show is a
  structured-data violation. Currently used on `edzesek.md`.
- **`/llms.txt`** is a custom Hugo output format (`llms` in `config.toml`, template
  `layouts/home.llms.txt`). It lists key club facts and every page with its description, generated
  from real page data so it cannot go stale. `notAlternative = true` keeps it out of `<head>`.
- **`/robots.txt`** needs `enableRobotsTXT = true` — without it Hugo ignores the template entirely
  and the file 404s, which is how it stood for years. The override names GPTBot, ClaudeBot,
  PerplexityBot and friends explicitly.
- **External links are not `nofollow`.** They point at sister clubs, the national federation and a
  university staff page; the previous blanket `nofollow` in `render-link.html` threw away the topical
  association those citations earn. The club's own Facebook/Discord links carry `rel="me"`, matching
  the `sameAs` list in the JSON-LD.
- **Analytics** is self-hosted Umami, configured through Congo's native `[umamiAnalytics]` param
  (`site` + a `script` override for the custom host) rather than a hand-rolled `<script>` tag. Congo
  gates it behind `hugo.IsProduction`, so `hugo serve` never sends events; a plain `hugo` build does,
  since Hugo defaults that to the production environment.
- **Site `description` must be set twice** in `languages.hu.toml`: the top-level key feeds Hugo core
  (RSS), the `[params]` one feeds Congo's head and schema partials. With only the top-level key —
  the state this repo was in — Congo rendered no site description at all.

## Photos

The homepage photos are club phone snapshots, and they go through two stages
before they reach a visitor.

- **`scripts/prepare-photos.sh` does the darkroom work**, reading
  `photos/original/` and writing `assets/img/kozosseg/`. Per photo it applies a
  hand-picked crop and a grade (white-balance nudge, S-curve contrast, a little
  saturation and unsharp). Both are tabulated at the top of the script; edit
  there and re-run, never retouch the output. The originals are wide-angle
  frames with a lot of ceiling and empty mat — the crops are most of the win.
- **Each master is cropped to the exact aspect ratio of its slot** — 3:2 hero,
  4:3 gallery thumbs, 16:7 full-width band — matching the `aspect-ratio` rules
  in `custom.css`. That is what keeps `object-fit: cover` from silently
  re-cropping a photo at some breakpoint and taking somebody's head off. Change
  one of those ratios and you must change the other.
- **`layouts/partials/photo.html` handles delivery**, resizing each master into
  a WebP + JPEG `srcset` at build time. Its `sizes` strings are the template's
  only claim about layout, so they have to track `custom.css`; get them wrong
  and the browser picks the wrong file. Serving the originals unresized, as this
  page did at first, cost 1.6 MB against roughly 220 KB now.
- **The photos live in `assets/`, not `static/`.** Hugo's image processing only
  works on `assets/`, and only files it actually processes get published — which
  is also why `photos/original/` can sit in the repo without shipping.

## Gotchas

- **Congo's Tailwind is precompiled, so you cannot invent utility classes in an override.** `head.html` bundles `css/compiled/main.css` straight out of the module — there is no Tailwind pass over this repo's `layouts/`. Only the utilities the theme itself uses exist; `gap-4`, `ms-auto` and friends are simply not in the file and silently do nothing. This had already bitten once: `extend-footer.html` carried `class=".m-0"` (note the leading dot) for years with no effect and no warning. Style overrides with real rules in `assets/css/custom.css` instead — it is concatenated into the same bundle — and check before reaching for a utility:

  ```sh
  grep -c '\.gap-4' ~/.cache/hugo_cache/modules/filecache/modules/pkg/mod/github.com/jpanther/congo/v2@v2.14.0/assets/css/compiled/main.css
  ```
- **`layout: simple` on a section `_index.md` silently deletes the article list.** Congo's `simple.html` renders only `.Title` and `.Content`; unlike `list.html` it never ranges `.Data.Pages`, so it emits no `article-link.html` at all — and no warning. `content/cikkek/_index.md` carried it from the day the section was created, so `/cikkek/` showed its intro paragraph and nothing else while the articles themselves built fine and were reachable by direct URL. Use `simple` for standalone pages only. Assert on the output: `grep -c '<article' public/cikkek/index.html` must be at least the number of published articles.
- **Congo v1.6.4 → v2 was forced by a Hugo upgrade.** The old theme used `.Site.Author`, which Hugo deprecated in 0.124 and *removed* in 0.146, so any modern Hugo failed with `can't evaluate field Author in type page.Site`. Congo v2's own `module.toml` claims `min = "0.87.0"` — that is wrong; v2 does not build on anything near it.
- **Bumping `HUGO_VERSION` in CI also means fixing the download URL.** Hugo renamed its release assets: the old `hugo_extended_<v>_Linux-64bit.deb` 404s on current versions, which now ship as `hugo_extended_<v>_linux-amd64.deb`.
- **Hugo 0.146 restructured template lookup, which can wake dormant overrides.** A `layouts/single.html` had sat in this repo for years doing nothing — pre-0.146 Hugo only looked for `layouts/_default/single.html`, so Congo's template rendered every page. After the upgrade `layouts/single.html` became a valid lookup path, took over, and — having no `{{ define "main" }}` — rendered every page with no base template: content but no `<html>`, no CSS, no nav or footer. It was deleted. If a page ever loses its "frame" again, suspect a project template that lacks `{{ define "main" }}`.
- **A menu entry with no label is invisible, not absent.** The nav used to contain *two* links to `/` — one from a `[[main]]` entry in `menus.toml`, one from `menu: "main"` in `content/_index.md`. Because the homepage had no `title`, Congo rendered both with an empty label, so they showed up as two blank clickable gaps rather than as an obvious duplicate. Giving the homepage a `title` for SEO made them appear at full width and wrecked the header. Both were removed. If the nav ever looks subtly off, count the `<li>` elements rather than trusting the visible labels.
- The theme's own layout paths moved too (`layouts/_partials/`, `layouts/_markup/`). The old `layouts/partials/`, `layouts/shortcodes/` and `layouts/_default/_markup/` locations in this repo still resolve, and all four remaining overrides were verified working after the upgrade.

## Known gaps

- The homepage `<title>` is just the site title. Congo hardcodes `.Site.Title` for `.IsHome`, ignoring the page's own `title` front matter (which still feeds `og:title`). Fixing it properly means overriding the whole 150-line `head.html`, which is not worth the maintenance; the alternative is lengthening `title` in `languages.hu.toml`, but that is also the visible brand in the nav.
- Congo's `head.html` wraps the `description` meta content in template whitespace, so it renders with leading and trailing newlines inside the attribute. Harmless — every consumer collapses whitespace — but it is why the tag looks oddly formatted in the built HTML.
- The `deploy` job in `main.yml` is indented with 5 spaces where the rest of the file uses 6. Valid YAML, inherited from the original GitHub sample workflow.

## Branches

`main` is the deploy branch (pushing to it publishes the site). Work lands via PRs, historically through a `develop` branch; PRs run the pre-commit check.

The workflows were moved onto current action majors (`checkout@v7`, `setup-go@v7`, `configure-pages@v6`, `upload-pages-artifact@v5`, `deploy-pages@v5`, `setup-python@v7`, `pre-commit/action@v3.0.1`). The previous `upload-pages-artifact@v1` / `deploy-pages@v1` relied on the artifact backend GitHub retired in January 2025 and could no longer deploy.
