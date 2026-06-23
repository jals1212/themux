# Changelog

## [0.2.0](https://github.com/jals1212/themux/compare/v0.1.0...v0.2.0) (2026-06-23)


### Added

* **modules:** interpolate plugin-data modules in the status-line grammar ([ff838a6](https://github.com/jals1212/themux/commit/ff838a652c54398cb98525bd137271d2d43d8d4f))
* **padding:** configurable badge padding grammar ([ece0656](https://github.com/jals1212/themux/commit/ece0656d2c486de2e8b84d9c8463820582171b8b))
* status-line grammar — configurable padding + grammar-native modules + docs ([7205862](https://github.com/jals1212/themux/commit/720586247cfe71d0c55b9438054face05b9d0304))


### Documentation

* document the clean reload and tmux 3.6 requirement ([bff498c](https://github.com/jals1212/themux/commit/bff498c1c47ce1834b198d2e6265b3f5e2a05537))
* migrate status-line examples to the [@themux](https://github.com/themux)_status_line grammar ([29663e1](https://github.com/jals1212/themux/commit/29663e12d1f0264ef219fe31f4e859020dedd013))

## 0.1.0 (2026-06-22)


### ⚠ BREAKING CHANGES

* themux now requires tmux >= 3.6 (was 3.3); module styles render without colour on older builds.
* **module:** a custom @themux_<name>_icon override must now include its own leading space (e.g. " <glyph> "); without it the icon sits flush against the left cap.
* **config:** @themux_window_{name,text,current_text,text_mode} are renamed as above, and per-item shape/indicator/text/notch/position/highlight defaults now come from @themux_all_*; set the per-item option to override.
* **window:** the connect trigger moves from an empty @themux_window_divider to @themux_window_seam. Emptying the divider no longer connects the list; set @themux_window_seam to <>, >, < or = instead. The shipped default look is unchanged (the default squared shape has no caps, so it never connects).
* **layout:** space between modules no longer connects them into a powerline run; use =, > or < to merge. Capped-shape configs that relied on space adjacency now render separate pills.

### chore

* release as 0.1.0 ([9004d36](https://github.com/jals1212/themux/commit/9004d3664a7545e70bbaeca3f32e2e773d0ff278))


### build

* require tmux &gt;= 3.6 ([8b2b70d](https://github.com/jals1212/themux/commit/8b2b70d9dc93b18e764ed9c09399de278ffa4e88))


### Added

* active-variant styling, inline = flush grammar, and cpu/ram colour escalation ([c3cd151](https://github.com/jals1212/themux/commit/c3cd151e56079fcf0e8fbdec1dd41db02530773b))
* **config:** shared item props via [@themux](https://github.com/themux)_all_&lt;prop&gt; ([10d847f](https://github.com/jals1212/themux/commit/10d847fc13b5f3aba82f1f82ed3b225a135af658))
* **layout:** flush the connected window ribbon to the terminal edge ([88af428](https://github.com/jals1212/themux/commit/88af428a925745861cea293b4e9d0458ddeb1245))
* **layout:** fold edge flush into the status-line grammar ([38bc38f](https://github.com/jals1212/themux/commit/38bc38fdb0340ad5da16b6a46ac450d173c03132))
* **layout:** module connector grammar and nvim-style flush edges ([804ab8c](https://github.com/jals1212/themux/commit/804ab8c23ee610e78c0af7a297308fdfc842f02b))
* **layout:** per-line prepend/append content ([c0dd08f](https://github.com/jals1212/themux/commit/c0dd08fa5eea953b5d1d8e7bf969aa370a6e5a34))
* **layout:** split flush into independent status and window controls ([c1f3c6e](https://github.com/jals1212/themux/commit/c1f3c6edd49a364b55b50181720d4c0671184b04))
* **module:** cpu/ram colour escalation via tmux-cpu's live colour pair ([bf5a073](https://github.com/jals1212/themux/commit/bf5a073fc7e1e415864972dc4c1e33d53a63c013))
* **module:** let the icon value carry its own padding for per-glyph control ([602df38](https://github.com/jals1212/themux/commit/602df381f8c661c4bb0e73bcd4654091f8847b6d))
* **modules:** add time module (clock-only %H:%M) ([ca6d181](https://github.com/jals1212/themux/commit/ca6d181e728824a0bfbe64aa7b65d6c754ca0530))
* **modules:** notch=off draws a flat block divider ([ec0251c](https://github.com/jals1212/themux/commit/ec0251cc091bc66dc53bcca465733459f803ce83))
* **reload:** add [@themux](https://github.com/themux)_reload_key for a clean reload ([5bc71f3](https://github.com/jals1212/themux/commit/5bc71f37a0a9e47508e3ef88e0ca6a4d9e5531a1))
* **shapes:** add powerline arrow shape ([1b630ee](https://github.com/jals1212/themux/commit/1b630eee28e85155c83f39b02c2bfd6f6597671d))
* **variant:** replace highlight channels with an active-variant model ([ecd35c1](https://github.com/jals1212/themux/commit/ecd35c18ee0eca5c314d28dfd65a41ae4faed611))
* **window:** add [@themux](https://github.com/themux)_window_seam connector grammar ([64f6d90](https://github.com/jals1212/themux/commit/64f6d9001eeda813b610a8475cfab83df50406ff))


### Fixed

* **load:** execute the uptime command instead of printing it literally ([00c9809](https://github.com/jals1212/themux/commit/00c980913debd09bccaf5d64783aec3266888c37))
* **module:** keep the icon footprint when a notch tapers the seam ([bbf733f](https://github.com/jals1212/themux/commit/bbf733fb600d5b6a8d58ac9d5d1ede605a8bc4f3))
* **window:** centre internal numbers under seam "=" ([2d9cddd](https://github.com/jals1212/themux/commit/2d9cddd8f3e6dfe83fb8732e87cd47d2c329ced9))


### Documentation

* **readme:** fix pane section — show [@themux](https://github.com/themux)_pane_shape, correct the border-reset claim ([09a0e76](https://github.com/jals1212/themux/commit/09a0e764c2236e445b764264a203f6acae9c72f7))
* **reference:** correct [@themux](https://github.com/themux)_module_divider default (" " not " │ ") ([7d37b1a](https://github.com/jals1212/themux/commit/7d37b1a2f4d65fc0764d97bab0a1cb037b11d6c5))
* scrub stale "variant" wording and fix kube plugin reference ([fe8c67a](https://github.com/jals1212/themux/commit/fe8c67ae8b1d8267f867a65f2a141d570d7f7f7f))

## Changelog

All notable changes to themux are documented here.

This file is managed by [release-please]; entries are generated from
conventional commit messages on each release. themux versioning starts fresh
from its own `0.x` line (the project is a fork of catppuccin/tmux — see the
README credits for the lineage).

[release-please]: https://github.com/googleapis/release-please
