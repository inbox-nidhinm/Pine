# Pine

A menu bar colour picker for macOS. Press ⇧⌘C to pick a colour from the screen and copy its hex code.

```bash
./make-app.sh
open build/Pine.app
```

## Font

The titles and the contrast ratio are set in AA Bridge Slab, the designer's own font, built from [Montagu Slab](https://github.com/floriankarsten/montagu-slab). It comes from the AA-Bridge project, linked here as a git submodule in `Vendor/AA-Bridge`. A copy of the one file Pine uses, and its licence, is kept in `Resources/Fonts`, so Pine builds without the submodule.

To update the font: bring the submodule to the newer version (`git -C Vendor/AA-Bridge pull origin main`), run `Tools/update-fonts.sh` to copy it into `Resources/Fonts`, and commit both.

## License

[MIT](LICENSE). The bundled AA Bridge Slab font is not covered: it is under the SIL Open Font License, in `Resources/Fonts/OFL.txt`.
