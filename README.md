# TI-84 Plus CE Chemistry Solver (TI-BASIC) - CHEM 101 Exam 1

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
| PTAB, ELEM, GETM | helpers: periodic table (86 elements, symbols uppercase), symbol lookup |

Constants: h = 6.63E-34, c = 3E8, N_A = 6.022E23, Rydberg energy 2.18E-18 J (from the exam's answer key).

## Layout
- `TEACHER_PROMPT.md` paste into any LLM to turn it into a tutor for this program
- `src/*.txt` programs, `tests/*.txt` test programs, `tokens/8X.xml` official token table
- `build.ps1` compiles both into `build/*.8xp`; write source as the calculator editor shows it (`Disp "HI"`, `~` for the negative sign, `|E` for scientific notation, `->` for store). The build prints any multi-letter tokens it matched so accidental ones are visible.
- `test.ps1 TNAME...` boots CEmu with the ROM, sends all programs, runs each test, saves `docs/TNAME.png`
- `New folder/thing.rom` ROM dumped from the calculator (gitignored, never commit)

## Testing
CEmu can send files, launch, and screenshot, but cannot press keys. Solvers skip their prompts when `U=1`, so each test sets `U` and the inputs, then calls the solver. Menus and `Input` prompts are not exercised by tests.
