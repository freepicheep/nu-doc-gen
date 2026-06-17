# Bundled CSS and JavaScript assets for the generated static documentation site.

use text.nu [ html-escape ]

# Derive favicon glyphs from a module name, or pass through an explicit override.
# With no override the first letter of each '-', '_', or space separated segment is
# taken (uppercased, capped at three glyphs); "nu-doc-gen" becomes "NDG".
export def favicon-text [name: string override: string] {
    if (($override | str trim) != '') {
        $override | str trim
    } else {
        $name
        | split row --regex '[-_[:space:]]+'
        | where {|segment| ($segment | str trim) != '' }
        | each {|segment| $segment | str substring 0..0 }
        | str join
        | str upcase
        | str substring 0..2
    }
}

# Build an initials favicon as an SVG document that swaps colors with the preferred
# color scheme so it tracks the site's light/dark themes. Written to assets/favicon.svg.
export def favicon-svg [
    text: string
    light_bg: string
    light_fg: string
    dark_bg: string
    dark_fg: string
] {
    let glyphs = (html-escape $text)
    let font_size = (match ($text | str length) {
        0 | 1 => 38
        2 => 30
        3 => 24
        _ => 18
    })
    $"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'><style>rect{fill:($light_bg)}text{fill:($light_fg)}@media \(prefers-color-scheme:dark\){rect{fill:($dark_bg)}text{fill:($dark_fg)}}</style><rect width='64' height='64' rx='14'/><text x='32' y='33' font-family='Inter,ui-sans-serif,system-ui,-apple-system,sans-serif' font-size='($font_size)' font-weight='700' text-anchor='middle' dominant-baseline='central'>($glyphs)</text></svg>"
}

export def site-css [] {
'
:root {
    color-scheme: light dark;
    --radius: 8px;
    --sidebar-width: 320px;
    --content-width: 920px;
    font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

* {
    box-sizing: border-box;
}

html {
    scroll-behavior: smooth;
}

@view-transition {
    navigation: auto;
}

body {
    margin: 0;
    background: linear-gradient(180deg, var(--bg-start) 0%, var(--bg-end) 100%);
    color: var(--text);
    transition: background-color 180ms ease, color 180ms ease;
}

a {
    color: var(--accent-strong);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

.layout {
    min-height: 100vh;
    display: grid;
    grid-template-columns: minmax(280px, var(--sidebar-width)) minmax(0, 1fr);
}

.sidebar {
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
    padding: 1.5rem 1rem 5rem;
    background: var(--sidebar-bg);
    border-right: 1px solid var(--border);
    backdrop-filter: blur(14px);
    view-transition-name: sidebar;
}

.sidebar-header {
    margin-bottom: 1rem;
}

.eyebrow {
    margin: 0 0 0.35rem;
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    color: var(--muted);
}

.site-title {
    margin: 0;
    font-size: 1.35rem;
    line-height: 1.2;
}

.site-version {
    margin-left: 0.5rem;
    color: var(--muted);
    font-size: 0.78em;
    font-weight: 600;
    white-space: nowrap;
}

.site-summary {
    margin: 0.65rem 0 0;
    color: var(--muted);
    font-size: 0.94rem;
    line-height: 1.5;
    white-space: pre-line;
}

.sidebar-toggle {
    display: none;
    width: 100%;
    margin: 1rem 0;
    padding: 0.8rem 0.9rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--surface);
    color: var(--text);
    font: inherit;
    text-align: left;
}

.nav-search {
    width: 100%;
    margin: 0 0 1rem;
    padding: 0.8rem 0.9rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--surface);
    color: var(--text);
    font: inherit;
}

.nav-search-wrap {
    position: relative;
}

.nav-search-dropdown {
    position: absolute;
    z-index: 10;
    top: calc(100% - 0.7rem);
    left: 0;
    right: 0;
    max-height: min(24rem, 60vh);
    overflow-y: auto;
    padding: 0.45rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--surface);
    box-shadow: var(--shadow);
    transform-origin: top center;
    animation: search-dropdown-in 160ms ease;
}

.nav-search-dropdown[hidden] {
    display: none;
}

.search-empty {
    padding: 0.7rem 0.8rem;
    color: var(--muted);
    font-size: 0.92rem;
}

.search-result {
    display: block;
    padding: 0.6rem 0.7rem;
    border-radius: 6px;
    color: var(--text);
    transition: background-color 180ms ease, transform 180ms ease;
}

.search-result + .search-result {
    margin-top: 0.2rem;
}

.search-result:hover,
.search-result.is-selected {
    background: var(--accent-soft);
    text-decoration: none;
    transform: translateY(-1px);
}

.search-result-kind {
    display: inline-flex;
    margin-bottom: 0.3rem;
    padding: 0.14rem 0.42rem;
    border-radius: 999px;
    background: var(--surface-muted);
    color: var(--muted);
    font-size: 0.72rem;
    font-weight: 700;
    text-transform: uppercase;
}

.search-result-title {
    display: block;
    line-height: 1.35;
}

.search-result-meta {
    display: block;
    margin-top: 0.22rem;
    color: var(--muted);
    font-size: 0.88rem;
    line-height: 1.4;
}

.search-result mark {
    padding: 0;
    background: transparent;
    color: var(--accent-strong);
    font-weight: 700;
}

.nav-group-title {
    margin: 1.2rem 0 0.45rem;
    font-size: 0.76rem;
    font-weight: 700;
    color: var(--muted);
    text-transform: uppercase;
}

.nav-list,
.nav-sublist {
    list-style: none;
    margin: 0;
    padding: 0;
}

.nav-list > li + li {
    margin-top: 0.25rem;
}

.nav-link {
    display: block;
    padding: 0.55rem 0.7rem;
    border-radius: var(--radius);
    color: var(--text);
    line-height: 1.35;
    transition: background-color 180ms ease, color 180ms ease, transform 180ms ease;
}

.nav-link:hover,
.nav-link.is-active {
    background: var(--accent-soft);
    text-decoration: none;
}

.nav-link:hover {
    transform: translateX(2px);
}

.nav-sublist {
    margin: 0.2rem 0 0.45rem 0.85rem;
    border-left: 2px solid var(--surface-muted);
    padding-left: 0.7rem;
    animation: sidebar-subnav-in 220ms ease;
}

.nav-sublist .nav-link {
    padding: 0.4rem 0.55rem;
    font-size: 0.93rem;
    color: var(--muted);
}

.nav-empty {
    color: var(--muted);
    font-size: 0.9rem;
}

.content-wrap {
    min-width: 0;
}

.page-header {
    padding: 2.25rem 2rem 1.3rem;
}

.page-header-inner,
.page-content {
    width: min(calc(100% - 4rem), var(--content-width));
    margin: 0 auto;
    min-width: 0;
}

.page-header-inner {
    view-transition-name: page-header;
}

.page-title {
    margin: 0;
    font-size: clamp(2rem, 2.4rem, 2.4rem);
    line-height: 1.05;
}

.page-lead {
    margin: 0.9rem 0 0;
    max-width: 62ch;
    font-size: 1.03rem;
    line-height: 1.65;
    color: var(--muted);
    white-space: pre-line;
}

.summary-strip {
    display: flex;
    flex-wrap: wrap;
    gap: 0.8rem;
    margin: 1.2rem 0 1.5rem;
    min-width: 0;
}

.summary-pill {
    padding: 0.55rem 0.75rem;
    border-radius: var(--radius);
    background: var(--surface);
    border: 1px solid var(--border);
    box-shadow: var(--shadow);
    font-size: 0.92rem;
    max-width: 100%;
}

.page-content {
    padding: 0 0 4rem;
    view-transition-name: page-content;
}

.overview-list {
    display: grid;
    gap: 1rem;
    min-width: 0;
}

.overview-item,
.command-section,
.empty-state {
    background: var(--surface-alpha);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    box-shadow: var(--shadow);
    min-width: 0;
    max-width: 100%;
}

.overview-item {
    padding: 1.1rem 1.2rem;
}

.overview-item h2,
.command-section h2 {
    margin: 0;
    font-size: 1.28rem;
    line-height: 1.2;
}

.command-heading {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 0.65rem;
    min-width: 0;
}

.command-badge {
    display: inline-flex;
    align-items: center;
    min-height: 1.55rem;
    padding: 0.22rem 0.5rem;
    border: 1px solid var(--border);
    border-radius: 999px;
    background: var(--surface-muted);
    color: var(--muted);
    font-size: 0.76rem;
    font-weight: 700;
    text-transform: uppercase;
    line-height: 1;
}

.command-badge-internal {
    background: var(--surface-strong);
}

.overview-meta,
.command-meta {
    margin: 0.4rem 0 0;
    color: var(--muted);
    font-size: 0.9rem;
}

.overview-desc {
    margin: 0.75rem 0 0;
    line-height: 1.6;
    color: var(--muted);
}

.overview-desc p,
.overview-desc ol,
.overview-desc ul {
    margin: 0.6rem 0 0;
}

.overview-desc ol,
.overview-desc ul {
    padding-left: 1.35rem;
}

.overview-link {
    display: inline-flex;
    margin-top: 0.85rem;
    font-weight: 600;
}

.command-stack {
    display: grid;
    gap: 1.1rem;
    min-width: 0;
}

.command-section {
    padding: 1.25rem 1.25rem 1.4rem;
    scroll-margin-top: 1rem;
}

.command-description p:first-child,
.section-text p:first-child {
    margin-top: 0.25rem;
}

.command-description p,
.section-text p {
    margin: 0.75rem 0 0;
    line-height: 1.7;
    overflow-wrap: anywhere;
}

.command-description ol,
.command-description ul,
.section-text ol,
.section-text ul {
    margin: 0.75rem 0 0;
    padding-left: 1.35rem;
    line-height: 1.7;
}

.command-description li,
.section-text li {
    margin: 0.2rem 0;
}

.doc-section {
    margin-top: 1.25rem;
    padding-top: 1.1rem;
    border-top: 1px solid var(--surface-muted);
    min-width: 0;
}

.doc-section h3 {
    margin: 0;
    font-size: 1rem;
    text-transform: uppercase;
    letter-spacing: 0;
    color: var(--muted);
}

pre,
code {
    font-family: "SFMono-Regular", SFMono-Regular, ui-monospace, Menlo, Monaco, Consolas, "Liberation Mono", monospace;
}

pre {
    margin: 0.95rem 0 0;
    padding: 0.95rem 1rem;
    border-radius: var(--radius);
    background: var(--code-bg);
    color: var(--code-text);
    overflow-x: auto;
    line-height: 1.55;
    font-size: 0.94rem;
}

pre[data-shiki-lang] {
    position: relative;
}

.shiki {
    margin: 0;
    overflow-x: auto;
    border-radius: var(--radius);
    padding: 0.95rem 1rem;
    border: 1px solid var(--border);
    line-height: 1.55;
    font-size: 0.94rem;
}

.doc-section > .shiki,
.doc-section > pre[data-shiki-lang] {
    margin-top: 0.95rem;
}

.shiki code {
    display: grid;
}

.shiki,
.shiki span {
    background-color: var(--shiki-light-bg) !important;
    color: var(--shiki-light) !important;
    font-style: var(--shiki-light-font-style) !important;
    font-weight: var(--shiki-light-font-weight) !important;
    text-decoration: var(--shiki-light-text-decoration) !important;
}

[data-theme="dark"] .shiki,
[data-theme="dark"] .shiki span {
    background-color: var(--shiki-dark-bg) !important;
    color: var(--shiki-dark) !important;
    font-style: var(--shiki-dark-font-style) !important;
    font-weight: var(--shiki-dark-font-weight) !important;
    text-decoration: var(--shiki-dark-text-decoration) !important;
}

@media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) .shiki,
    :root:not([data-theme="light"]) .shiki span {
        background-color: var(--shiki-dark-bg) !important;
        color: var(--shiki-dark) !important;
        font-style: var(--shiki-dark-font-style) !important;
        font-weight: var(--shiki-dark-font-weight) !important;
        text-decoration: var(--shiki-dark-text-decoration) !important;
    }
}

.shiki .line {
    min-height: 1.5rem;
}

pre[data-shiki-lang="nushell"] {
    overflow: visible;
    height: auto;
    max-height: none;
    white-space: normal;
}

pre[data-shiki-lang="nushell"] code {
    display: block;
    width: auto;
    white-space: normal;
}

pre[data-shiki-lang="nushell"] .line {
    display: block;
    white-space: pre-wrap;
    overflow-wrap: anywhere;
    word-break: break-word;
    min-width: 0;
}

code {
    font-size: 0.94em;
}

:not(pre) > code {
    padding: 0.15rem 0.35rem;
    border-radius: 6px;
    background: var(--surface-muted);
    color: var(--text);
}

.def-list {
    display: grid;
    gap: 0.8rem;
    margin: 0.95rem 0 0;
    min-width: 0;
}

.def-item {
    padding: 0.9rem 1rem;
    border-radius: var(--radius);
    background: var(--surface);
    border: 1px solid var(--border);
    min-width: 0;
}

.def-item dt {
    font-weight: 700;
}

.def-item dd {
    margin: 0.35rem 0 0;
    color: var(--muted);
    line-height: 1.6;
}

.io-table {
    width: 100%;
    max-width: 100%;
    margin-top: 0.9rem;
    border-collapse: collapse;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
}

.command-section > *,
.doc-section > *,
.def-item > * {
    min-width: 0;
    max-width: 100%;
}

h1,
h2,
h3,
p,
dd,
th,
td,
li,
a,
code {
    overflow-wrap: anywhere;
}

.io-table th,
.io-table td {
    padding: 0.75rem 0.85rem;
    text-align: left;
    border-bottom: 1px solid var(--border);
}

.io-table thead {
    background: var(--surface-strong);
}

.io-table tbody tr:nth-child(even) {
    background: var(--table-stripe);
}

.example-block {
    margin-top: 0.95rem;
}

.example-block + .example-block {
    margin-top: 1.4rem;
}

.example-label {
    margin: 0 0 0.45rem;
    font-size: 0.95rem;
    color: var(--muted);
}

.example-result {
    margin-top: 0.55rem;
}

.example-result-tag {
    display: block;
    margin: 0 0 0.3rem;
    color: var(--muted);
    font-size: 0.72rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
}

.example-result-tag::before {
    content: "↳ ";
    margin-right: 0.15rem;
}

.example-result-body {
    margin: 0;
    padding: 0.75rem 0.95rem;
    background: var(--surface-strong);
    color: var(--muted);
    font-size: 0.88rem;
    line-height: 1.25;
}

.example-result-body code {
    background: none;
    color: inherit;
}

.empty-state {
    padding: 1.2rem;
    color: var(--muted);
}

.theme-picker {
    position: fixed;
    z-index: 20;
    left: 1rem;
    bottom: 1rem;
}

.theme-toggle {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    min-height: 2.5rem;
    padding: 0.55rem 0.75rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--surface);
    color: var(--text);
    box-shadow: var(--shadow);
    font: inherit;
    font-size: 0.9rem;
    cursor: pointer;
}

.theme-toggle:hover {
    background: var(--accent-soft);
}

.theme-toggle-icon {
    width: 0.86rem;
    height: 0.86rem;
    border-radius: 999px;
    flex: 0 0 auto;
    background: linear-gradient(90deg, var(--text) 0 50%, var(--surface-muted) 50% 100%);
    border: 1px solid var(--accent-strong);
}

.theme-toggle[data-theme-mode="light"] .theme-toggle-icon {
    background: var(--accent-strong);
    border-color: var(--accent-strong);
    box-shadow:
        0 -0.38rem 0 -0.28rem var(--accent-strong),
        0 0.38rem 0 -0.28rem var(--accent-strong),
        0.38rem 0 0 -0.28rem var(--accent-strong),
        -0.38rem 0 0 -0.28rem var(--accent-strong),
        0.27rem 0.27rem 0 -0.3rem var(--accent-strong),
        -0.27rem 0.27rem 0 -0.3rem var(--accent-strong),
        0.27rem -0.27rem 0 -0.3rem var(--accent-strong),
        -0.27rem -0.27rem 0 -0.3rem var(--accent-strong);
}

.theme-toggle[data-theme-mode="dark"] .theme-toggle-icon {
    background: var(--accent-strong);
    border-color: transparent;
    box-shadow: inset -0.25rem -0.18rem 0 var(--surface);
}

.theme-menu {
    position: absolute;
    left: 0;
    bottom: calc(100% + 0.45rem);
    min-width: 10rem;
    padding: 0.35rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: var(--surface);
    box-shadow: var(--shadow);
    transform-origin: bottom left;
    animation: theme-menu-in 140ms ease;
}

.theme-menu[hidden] {
    display: none;
}

.theme-choice {
    display: flex;
    align-items: center;
    gap: 0.55rem;
    width: 100%;
    padding: 0.55rem 0.65rem;
    border: 0;
    border-radius: 6px;
    background: transparent;
    color: var(--text);
    font: inherit;
    text-align: left;
    cursor: pointer;
}

.theme-choice:hover,
.theme-choice[aria-checked="true"] {
    background: var(--accent-soft);
}

.theme-choice-icon {
    width: 0.86rem;
    height: 0.86rem;
    border-radius: 999px;
    flex: 0 0 auto;
}

.theme-icon-system {
    background: linear-gradient(90deg, var(--text) 0 50%, var(--surface-muted) 50% 100%);
    border: 1px solid var(--accent-strong);
}

.theme-icon-light {
    background: var(--accent-strong);
    border: 1px solid var(--accent-strong);
    box-shadow:
        0 -0.38rem 0 -0.28rem var(--accent-strong),
        0 0.38rem 0 -0.28rem var(--accent-strong),
        0.38rem 0 0 -0.28rem var(--accent-strong),
        -0.38rem 0 0 -0.28rem var(--accent-strong),
        0.27rem 0.27rem 0 -0.3rem var(--accent-strong),
        -0.27rem 0.27rem 0 -0.3rem var(--accent-strong),
        0.27rem -0.27rem 0 -0.3rem var(--accent-strong),
        -0.27rem -0.27rem 0 -0.3rem var(--accent-strong);
}

.theme-icon-dark {
    background: var(--accent-strong);
    box-shadow: inset -0.25rem -0.18rem 0 var(--surface);
}

::view-transition-old(root),
::view-transition-new(root) {
    animation-duration: 180ms;
    animation-timing-function: ease;
}

::view-transition-old(sidebar),
::view-transition-new(sidebar),
::view-transition-old(page-header),
::view-transition-new(page-header),
::view-transition-old(page-content),
::view-transition-new(page-content) {
    animation-duration: 220ms;
    animation-timing-function: ease;
}

@keyframes sidebar-subnav-in {
    from {
        opacity: 0;
        transform: translateY(-4px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

@keyframes search-dropdown-in {
    from {
        opacity: 0;
        transform: translateY(-4px) scaleY(0.98);
    }

    to {
        opacity: 1;
        transform: translateY(0) scaleY(1);
    }
}

@keyframes theme-menu-in {
    from {
        opacity: 0;
        transform: translateY(4px) scale(0.98);
    }

    to {
        opacity: 1;
        transform: translateY(0) scale(1);
    }
}

@media (prefers-reduced-motion: reduce) {
    html {
        scroll-behavior: auto;
    }

    .nav-link,
    .search-result {
        transition: none;
    }

    .nav-sublist,
    .nav-search-dropdown,
    .theme-menu,
    ::view-transition-old(root),
    ::view-transition-new(root),
    ::view-transition-old(sidebar),
    ::view-transition-new(sidebar),
    ::view-transition-old(page-header),
    ::view-transition-new(page-header),
    ::view-transition-old(page-content),
    ::view-transition-new(page-content) {
        animation: none;
    }
}

@media (max-width: 980px) {
    .layout {
        grid-template-columns: 1fr;
    }

    .sidebar {
        position: static;
        height: auto;
        border-right: 0;
        border-bottom: 1px solid var(--border);
        padding-bottom: 4.5rem;
    }

    .sidebar-toggle {
        display: block;
    }

    .sidebar-nav {
        display: none;
    }

    .sidebar-nav.is-open {
        display: block;
    }

    .page-header {
        padding-top: 1.5rem;
    }
}
'
}

export def site-js [] {
'
import { codeToHtml } from "https://esm.sh/shiki@4.0.2";

const SHIKI_VERSION = "4.0.2";
const SHIKI_SELECTOR = 'pre[data-shiki-lang="nushell"]';
const themeConfigNode = document.getElementById("theme-config");
const themeConfig = (() => {
  try {
    return JSON.parse(themeConfigNode?.textContent || "{}");
  } catch {
    return {};
  }
})();
const SHIKI_THEMES = {
  light: themeConfig.shiki?.light || "rose-pine-dawn",
  dark: themeConfig.shiki?.dark || "rose-pine",
};
const toggle = document.querySelector("[data-nav-toggle]");
const themePicker = document.querySelector("[data-theme-picker]");
const themeToggle = document.querySelector("[data-theme-toggle]");
const themeToggleLabel = document.querySelector("[data-theme-toggle-label]");
const themeToggleIcon = document.querySelector("[data-theme-toggle-icon]");
const themeMenu = document.querySelector("[data-theme-menu]");
const themeChoices = Array.from(document.querySelectorAll("[data-theme-choice]"));
const sidebar = document.querySelector(".sidebar");
const nav = document.querySelector("[data-nav]");
const search = document.querySelector("[data-nav-search]");
const searchDropdown = document.querySelector("[data-search-dropdown]");
const searchIndexNode = document.getElementById("search-index");
const commandLinks = Array.from(document.querySelectorAll("[data-command-link]"));
const sidebarScrollKey = "nu-doc-gen.sidebar-scroll-top";
const themeStorageKey = "nu-doc-gen.theme";
const systemTheme = window.matchMedia("(prefers-color-scheme: dark)");
const themeModes = ["system", "light", "dark"];
const sections = commandLinks
  .map((link) => {
    const hash = link.getAttribute("href")?.split("#")[1];
    if (!hash) return null;
    const target = document.getElementById(hash);
    if (!target) return null;
    return { link, target };
  })
  .filter(Boolean);

const getStoredTheme = () => {
  try {
    const theme = localStorage.getItem(themeStorageKey);
    return themeModes.includes(theme) ? theme : "system";
  } catch {
    return "system";
  }
};

const applyTheme = () => {
  const storedTheme = getStoredTheme();

  if (storedTheme === "light" || storedTheme === "dark") {
    document.documentElement.dataset.theme = storedTheme;
  } else {
    delete document.documentElement.dataset.theme;
  }

  if (themeToggle) {
    themeToggle.dataset.themeMode = storedTheme;
    themeToggle.setAttribute("aria-label", `Choose color theme. Current theme: ${storedTheme}.`);
    themeToggle.setAttribute("title", `Theme: ${storedTheme}`);
  }

  if (themeToggleLabel) {
    themeToggleLabel.textContent = storedTheme[0].toUpperCase() + storedTheme.slice(1);
  }

  if (themeToggleIcon) {
    themeToggleIcon.dataset.themeToggleIcon = storedTheme;
  }

  themeChoices.forEach((choice) => {
    const isActive = choice.dataset.themeChoice === storedTheme;
    choice.setAttribute("aria-checked", String(isActive));
  });
};

const closeThemeMenu = () => {
  if (!themeMenu || !themeToggle) return;
  themeMenu.hidden = true;
  themeToggle.setAttribute("aria-expanded", "false");
};

const openThemeMenu = () => {
  if (!themeMenu || !themeToggle) return;
  themeMenu.hidden = false;
  themeToggle.setAttribute("aria-expanded", "true");
};

const setThemeMode = (theme) => {
  if (!themeModes.includes(theme)) return;

  try {
    localStorage.setItem(themeStorageKey, theme);
  } catch {
  }

  applyTheme();
  closeThemeMenu();
};

if (themeToggle && themeMenu) {
  themeToggle.addEventListener("click", () => {
    if (themeMenu.hidden) {
      openThemeMenu();
    } else {
      closeThemeMenu();
    }
  });

  themeChoices.forEach((choice) => {
    choice.addEventListener("click", () => {
      setThemeMode(choice.dataset.themeChoice);
    });
  });

  document.addEventListener("click", (event) => {
    const target = event.target;
    if (target instanceof Node && !themePicker?.contains(target)) {
      closeThemeMenu();
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      closeThemeMenu();
      themeToggle.focus();
    }
  });
}

const handleSystemThemeChange = () => {
  if (getStoredTheme() !== "system") return;
  applyTheme();
};

if (typeof systemTheme.addEventListener === "function") {
  systemTheme.addEventListener("change", handleSystemThemeChange);
} else if (typeof systemTheme.addListener === "function") {
  systemTheme.addListener(handleSystemThemeChange);
}

applyTheme();

if (toggle && nav) {
  toggle.addEventListener("click", () => {
    nav.classList.toggle("is-open");
  });
}

if (sidebar && typeof sessionStorage !== "undefined") {
  const savedScroll = Number.parseInt(sessionStorage.getItem(sidebarScrollKey) || "", 10);
  if (Number.isFinite(savedScroll)) {
    sidebar.scrollTop = savedScroll;
  }

  let scrollFrame = null;
  const persistSidebarScroll = () => {
    sessionStorage.setItem(sidebarScrollKey, String(sidebar.scrollTop));
    scrollFrame = null;
  };

  sidebar.addEventListener("scroll", () => {
    if (scrollFrame !== null) return;
    scrollFrame = window.requestAnimationFrame(persistSidebarScroll);
  });

  window.addEventListener("pagehide", persistSidebarScroll);
}

const escapeHtml = (value = "") =>
  value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll(String.fromCharCode(39), "&#39;");

const highlightText = (value, indices) => {
  if (!value) return "";
  if (!Array.isArray(indices) || indices.length === 0) return escapeHtml(value);

  let html = "";
  let cursor = 0;
  indices.forEach(([start, end]) => {
    if (start > cursor) {
      html += escapeHtml(value.slice(cursor, start));
    }
    html += `<mark>${escapeHtml(value.slice(start, end + 1))}</mark>`;
    cursor = end + 1;
  });

  if (cursor < value.length) {
    html += escapeHtml(value.slice(cursor));
  }

  return html;
};

const fallbackIndices = (value, query) => {
  const source = value.toLowerCase();
  const searchText = query.toLowerCase();
  const indices = [];
  let start = source.indexOf(searchText);

  while (start !== -1) {
    indices.push([start, start + searchText.length - 1]);
    start = source.indexOf(searchText, start + searchText.length);
  }

  return indices;
};

if (search && searchDropdown && searchIndexNode) {
  const searchIndex = JSON.parse(searchIndexNode.textContent || "[]");
  const fuse =
    typeof Fuse === "function"
      ? new Fuse(searchIndex, {
          includeMatches: true,
          threshold: 0.34,
          ignoreLocation: true,
          minMatchCharLength: 2,
          keys: [
            { name: "title", weight: 0.7 },
            { name: "category", weight: 0.2 },
            { name: "file", weight: 0.05 },
            { name: "summary", weight: 0.05 },
          ],
        })
      : null;

  let selectedIndex = -1;

  const getResults = (query) => {
    if (!query) return [];

    if (fuse) {
      return fuse.search(query, { limit: 8 });
    }

    return searchIndex
      .filter((item) => {
        const haystack = `${item.title} ${item.category} ${item.file} ${item.summary}`.toLowerCase();
        return haystack.includes(query.toLowerCase());
      })
      .slice(0, 8)
      .map((item) => ({
        item,
        matches: [
          { key: "title", indices: fallbackIndices(item.title, query) },
          { key: "category", indices: fallbackIndices(item.category, query) },
        ],
      }));
  };

  const getMatchIndices = (matches, key) =>
    matches?.find((entry) => entry.key === key)?.indices || [];

  const closeDropdown = () => {
    searchDropdown.hidden = true;
    searchDropdown.innerHTML = "";
    selectedIndex = -1;
  };

  const updateSelection = () => {
    const links = Array.from(searchDropdown.querySelectorAll(".search-result"));
    links.forEach((link, index) => {
      link.classList.toggle("is-selected", index === selectedIndex);
    });
  };

  const renderResults = (query) => {
    const results = getResults(query);

    if (results.length === 0) {
      searchDropdown.hidden = false;
      searchDropdown.innerHTML = `<div class="search-empty">No matches for <strong>${escapeHtml(query)}</strong>.</div>`;
      selectedIndex = -1;
      return;
    }

    searchDropdown.hidden = false;
    searchDropdown.innerHTML = results
      .map(({ item, matches }) => {
        const title = highlightText(item.title, getMatchIndices(matches, "title"));
        const category = highlightText(
          item.category,
          getMatchIndices(matches, "category").length > 0
            ? getMatchIndices(matches, "category")
            : fallbackIndices(item.category, query)
        );
        const file = highlightText(item.file, getMatchIndices(matches, "file"));

        return `
          <a class="search-result" href="${escapeHtml(item.url)}">
            <span class="search-result-kind">${escapeHtml(item.kind)}</span>
            <span class="search-result-title">${title}</span>
            <span class="search-result-meta">${category} · ${file}</span>
          </a>
        `;
      })
      .join("");

    selectedIndex = 0;
    updateSelection();
  };

  search.addEventListener("input", (event) => {
    const query = event.target.value.trim();

    if (query === "") {
      closeDropdown();
      return;
    }

    renderResults(query);
  });

  search.addEventListener("focus", () => {
    const query = search.value.trim();
    if (query !== "") {
      renderResults(query);
    }
  });

  search.addEventListener("keydown", (event) => {
    const links = Array.from(searchDropdown.querySelectorAll(".search-result"));
    if (searchDropdown.hidden || links.length === 0) return;

    if (event.key === "ArrowDown") {
      event.preventDefault();
      selectedIndex = (selectedIndex + 1) % links.length;
      updateSelection();
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      selectedIndex = (selectedIndex - 1 + links.length) % links.length;
      updateSelection();
      return;
    }

    if (event.key === "Enter" && selectedIndex >= 0) {
      event.preventDefault();
      links[selectedIndex].click();
      return;
    }

    if (event.key === "Escape") {
      closeDropdown();
      search.blur();
    }
  });

  document.addEventListener("click", (event) => {
    if (!event.target.closest(".nav-search-wrap")) {
      closeDropdown();
    }
  });
}

if (sections.length > 0) {
  const observer = new IntersectionObserver(
    (entries) => {
      const visible = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];

      if (!visible) return;

      sections.forEach(({ link, target }) => {
        link.classList.toggle("is-active", target === visible.target);
      });
    },
    {
      rootMargin: "0px 0px -70% 0px",
      threshold: [0, 1],
    }
  );

  sections.forEach(({ target }) => observer.observe(target));
}

const highlightNushellBlocks = async () => {
  const blocks = Array.from(document.querySelectorAll(SHIKI_SELECTOR));
  if (blocks.length === 0) return;

  await Promise.all(
    blocks.map(async (block) => {
      const source = block.querySelector('code[data-shiki-source="nushell"]');
      const code = block.dataset.shikiRaw ?? source?.textContent ?? "";
      if (code === "") return;
      if (
        block.dataset.shikiRendered === "true"
        && block.dataset.shikiThemeLight === SHIKI_THEMES.light
        && block.dataset.shikiThemeDark === SHIKI_THEMES.dark
      ) return;

      let html;
      try {
        html = await codeToHtml(code, {
          lang: "nushell",
          themes: SHIKI_THEMES,
          defaultColor: false,
        });
      } catch (error) {
        console.error(`Failed to highlight Nushell block with Shiki ${SHIKI_VERSION}`, error);
        return;
      }

      const template = document.createElement("template");
      template.innerHTML = html.trim();
      const pre = template.content.querySelector("pre");
      if (!pre) return;

      pre.dataset.shikiLang = "nushell";
      pre.dataset.shikiRaw = code;
      pre.dataset.shikiRendered = "true";
      pre.dataset.shikiThemeLight = SHIKI_THEMES.light;
      pre.dataset.shikiThemeDark = SHIKI_THEMES.dark;
      block.replaceWith(pre);
    })
  );
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => {
    void highlightNushellBlocks();
  }, { once: true });
} else {
  void highlightNushellBlocks();
}
'
}
