# TI-84 Plus CE Chemistry Solver (TI-BASIC) - CHEM 101 Exams 1 and 2

Run `CHEM` on the calculator for the menu. It calls one solver per problem type.

| Program | Solves |
|---|---|
| UNITS | SI-prefix / unit conversion (powers of 10, optional unit exponent) |
| DENS | density, water displacement, mass, volume |
| MOLES | grams/moles/atoms, identify an element, same number of atoms |
| ISOTOPE | average mass, missing isotope, % abundance, atoms of an isotope |
| RATIO | masses to formula ratio, mass ratio from a formula |
| LIGHT | wavelength, frequency, photon energy, kJ/mol |
| BOHR | energy change n(i) to n(f), released/absorbed, wavelength |
| ATOMS | protons/neutrons/electrons, element, mass number, charge |
| ENERGY | cost and kWh to kJ |
| MASSC | conservation of mass |
| CONFIG | electron configuration (full + noble gas), valence/core/unpaired electrons, orbital diagram, ion charge, find element from configuration |
| COUNT | subshells, orbitals and electrons per shell or subshell |
| ORDER | sorts subshells by energy |
| TREND | ranks atomic/ionic size, first ionization energy, Zeff |
| IEJUMP | successive ionization energies to valence electrons and element |
| FORM | molar mass from a formula; moles, molecules, atoms of a compound |
| WAIT | helper: result screen (ENTER=BACK, CLEAR=MAIN MENU) |
| PTAB, ELEM, GETM, SPEC, CFG | helpers: periodic table + first ionization energies (86 elements, symbols uppercase), symbol lookup, species parser (`CA2+`), configuration engine |

## Navigation

```
CHEM  "I NEED" (answer first), then "I HAVE" (your data)
+- AMOUNT MOL G #      GRAMS, MILLIGRAMS, MOLES, MMOL, FORMULA UNITS, ATOMS OR IONS (IONS; shows mol, mmol, g, particles)
+- MOLAR MASS / %      MOLAR MASS (IONS K=7), % OF EACH ELEM, G OF ELEMENT (PCT), MASSES TO FORMULA, ATOMS IN COMPOUND
+- MASS VOL DENSITY    DENSITY: M AND V / DISPLACE, MASS: D AND V, VOLUME: M AND D (DENS), MASS CONSERV, SAME ATOMS
+- ATOM / ELEMENT      P N E COUNTS, SYMBOL+MASS NO, ID: GRAMS+ATOMS, ISOTOPES, TRENDS, IE JUMP
+- LIGHT ENERGY UNITS  LIGHT: WAVELENGTH / FREQUENCY / KJ/MOL, BOHR N TO N, KWH FROM COST, UNIT CONVERT
+- ELECTRONS BONDS     CONFIG, SUBSHELL COUNT, ENERGY ORDER, VALENCE E-, BOND TOOLS, DISSOLVE
+- QUIT
```

Preset mode: CHEM sets `K` before every solver call (0 = the solver shows its own menu, as before). DENS, IONS, PCT, LIGHT, ATOMS and MOLES use `If U or K:Goto S` to skip their menu when K is nonzero, and their first prompt accepts 0 (or "0") as BACK. IONS K=7 is molar mass only.
Example, "mmol of Ca(NO3)2 in 4.78E22 formula units": AMOUNT, FORMULA UNITS, formula `Ca(NO3)2`, ion 0, amount 4.78E22, 0.

Back convention (TI-BASIC has no comments, so it is documented here):
- Every Menu ends with BACK (main menu: QUIT). In a solver, BACK is `"BACK",0` pointing at `Lbl 0 : ~1->U : Return` placed just before `Lbl S`.
- A solver without a menu accepts 0 at its first prompt (`"VALUE (0=BACK):"`); the prompt text says so. Text prompts use the string "0" (CONFIG gas prompt uses "Q" because 0 means none; IEJUMP uses `{0}`). Both do `~1->U : Return`.
- After every solver CHEM runs `prgmWAIT`: it shows "ENTER=BACK, CLEAR=MAIN MENU" and waits with getKey. ENTER returns to the category menu (so the next tool is one pick away), CLEAR to the main menu. If the solver set `U=~1` (BACK), WAIT resets `U` to 0 and skips the wait, returning straight to the category menu.
- Test mode is unchanged: `U=1` skips menus and prompts (and the BACK checks, which sit inside `If not(U)`).

### Adding a solver (new `src/NAME.txt` + one menu entry)
Solver boilerplate:
```
:If not(U):ClrHome
:If U:Goto S
:Menu("TITLE","OPTION A",1,"OPTION B",2,"BACK",0)
:Lbl 1
:1->K
:Goto S
:Lbl 2
:2->K
:Goto S
:Lbl 0
:~1->U
:Return
:Lbl S
:If not(U):Then
:Input "FIRST (0=BACK):",A
:If not(A):Then
:~1->U
:Return
:End
...other Input lines...
:End
(compute and Disp, never Pause; WAIT does it)
```
No-menu solvers omit the Menu/Lbl block and keep the 0 check on the first Input. Never `Stop` or `Pause` at the end, and never use `U` for anything but test mode/back.
Menu entry in `src/CHEM.txt`, 2 edits: add `,"NAME",E1` before `"BACK"` in the category Menu line (max 7 items per Menu), and add one line `:Lbl E1:prgmNAME:Goto R6` below it (use `R<category number>`; the EXAM 3 category is 6, replace its `"NONE YET",6,` entry). Labels must be unique, 1-2 characters.

Constants: h = 6.63E-34, c = 3E8, N_A = 6.022E23, Rydberg energy 2.18E-18 J (from the exam's answer key).

## Layout
- `INSTALL_PROMPT.md` paste into any LLM for step-by-step help installing the programs on your calculator and fixing install problems
- `TEACHER_PROMPT.md` paste into any LLM to turn it into a tutor for this program
- `src/*.txt` programs, `tests/*.txt` test programs, `tokens/8X.xml` official token table
- `build.ps1` compiles both into `build/send/*.8xp` (programs to put on the calculator) and `build/tests/*.8xp` (test programs, CEmu only); write source as the calculator editor shows it (`Disp "HI"`, `~` for the negative sign, `|E` for scientific notation, `->` for store). The build prints any multi-letter tokens it matched so accidental ones are visible.
- `test.ps1 TNAME...` boots CEmu with the ROM, sends all programs, runs each test, saves `docs/TNAME.png`
- `New folder/thing.rom` ROM dumped from the calculator (gitignored, never commit)

## Testing
CEmu can send files, launch, and screenshot, but cannot press keys. Solvers skip their prompts when `U=1`, so each test sets `U` and the inputs, then calls the solver. Menus and `Input` prompts are not exercised by tests.

## Input convention for formula/species Strs (BONDS, DISS, PCT, IONS, VALE, CONFIG, FORM)
Type everything in UPPERCASE (the calculator has no lowercase). Element symbols are matched against an uppercase table. DISS prints charges with a space ("CO 2+" = cobalt ion, "SO4 2-") so cobalt vs CO2 cannot be confused.
Two-letter ambiguity: `CO` and `CS` are read as carbon+oxygen/sulfur when followed by a digit or the end (DISS: `CO2` -> molecular, `CS2` -> molecular) and as cobalt/cesium otherwise (`CO(NO3)2`). Elsewhere a two-letter symbol is tried first, so write cobalt compounds with the metal first followed by `(` or an anion.
BONDS rules (checked against the Exam 3 practice key Q13/Q17/Q19/Q28/Q35/Q36 and review Q18-Q20): smaller atom = more electronegative = shorter and stronger single bond; higher bond order = shorter and stronger.
