# Job: look over the 900 unique top pet bodies and fix the broken ones

## Why

Each of the 900 Epic-and-up set pets now wears its own body. The bodies are in
`src/ReplicatedStorage/Mine/Shared/PetBodies/*Top.luau`, with recolour bodies in
`*Extra.luau`. They were written by agents and checked by script. **Nobody has
looked at them in Studio.** The owner wants them all to be good cards (*"MAKE
MORE ... GOOD CARDS"*).

## Scope

Fix **broken** bodies only:
- parts floating off the body;
- a face missing, or hidden inside the body;
- the pet far too big or too small next to its set mates;
- a shape that does not read as its label at all;
- an obvious clip or z-fight.

Taste calls are the owner's. If a body works but you think it is ugly, list it
in the report and do not rewrite it.

Edit only the `PetBodies/*Top.luau` and `*Extra.luau` files. Never rename a
species id, and never change `tools/gen/sets/*.json` or the generated `SetPets/`.

## How to look (Studio, Edit mode only; do not start Play)

1. `PetModelFactory` builds a pet from its species id. `ServerStorage.PetShowcaseBuilder`
   lays out plinths; read it first. Build one set at a time into a folder named
   `_PetQA` in Workspace: every Top body of that set, in rows, each with its
   label.
2. Screen-capture each set from the front and from a 3/4 angle. Zoom in where
   something looks off.
3. Fix what is broken, rebuild that set and re-capture it.
4. Delete `_PetQA` when you are done. Never save the place.

## Verify and finish

- After each set's fixes, run `node tools/verify/set-pets.js`. When you are
  done, also run `node tools/verify/compile.js` and the full suite.
- Add a `wiki/log.md` entry. Fix `wiki/systems/pets.md` if anything it says
  changed.
- Commit only the PetBodies files you changed and those wiki files.
- The report needs:
  - a table of each set with the number of bodies looked at and fixed, and
    what was wrong;
  - a short list of "works but maybe ugly" bodies for the owner.
