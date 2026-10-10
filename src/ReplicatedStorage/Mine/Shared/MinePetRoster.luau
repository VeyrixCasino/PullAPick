-- MinePetRoster: the named pet roster, generated from the design list.
--
-- GENERATED -- do not hand-edit. Regenerate from roster/pets.txt + roster/tiers.txt.
--
-- Two ambiguities in the source list, resolved here and worth knowing:
--   1. Divine and Exotic were written as ANIMAL types while the other six
--      tiers were written as PET names, so 43 pets landed in two tiers at
--      once. Rule applied: HIGHEST tier wins, since those two are the
--      premium tiers -- a Unicorn is Divine even though "Starlight" is
--      also listed under Epic. Those pets carry tierVia = "animal".
--   2. 42 pets appear in the name list but in no tier list. They
--      default to Common and carry tierVia = "default", so they are easy
--      to find and correct.
local MinePetRoster = {}

MinePetRoster.TIER_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Exotic" }

MinePetRoster.TIER_COLOR = {
	Common = Color3.fromRGB(170, 170, 170),
	Uncommon = Color3.fromRGB(85, 255, 127),
	Rare = Color3.fromRGB(85, 170, 255),
	Epic = Color3.fromRGB(170, 85, 255),
	Legendary = Color3.fromRGB(255, 170, 0),
	Mythic = Color3.fromRGB(85, 220, 255),
	Divine = Color3.fromRGB(255, 245, 160),
	Exotic = Color3.fromRGB(255, 55, 55),
}

MinePetRoster.TIER_RANK = {}
for i, t in ipairs(MinePetRoster.TIER_ORDER) do
	MinePetRoster.TIER_RANK[t] = i
end

-- name -> { animal, tier, tierVia }
MinePetRoster.PETS = {
	{ name = "Acorn", hex3 = "001", animal = "Squirrel", tier = "Uncommon", tierVia = "animal" },
	{ name = "Aquamarine", hex3 = "002", animal = "Sea Dragon", tier = "Divine", tierVia = "animal" },
	{ name = "Aurora", hex3 = "003", animal = "Northern Lights Wolf", tier = "Divine", tierVia = "animal" },
	{ name = "Bambi", hex3 = "004", animal = "Fawn", tier = "Uncommon", tierVia = "name" },
	{ name = "Bamboo", hex3 = "005", animal = "Panda", tier = "Uncommon", tierVia = "name" },
	{ name = "Bandit", hex3 = "006", animal = "Raccoon", tier = "Uncommon", tierVia = "name" },
	{ name = "Basil", hex3 = "007", animal = "Green Parrot", tier = "Uncommon", tierVia = "name" },
	{ name = "Binky", hex3 = "008", animal = "Bunny", tier = "Common", tierVia = "name" },
	{ name = "Biscuit", hex3 = "009", animal = "Corgi", tier = "Common", tierVia = "name" },
	{ name = "Blizzard", hex3 = "00a", animal = "Ice Wolf", tier = "Legendary", tierVia = "name" },
	{ name = "Bloop", hex3 = "00b", animal = "Blobfish", tier = "Common", tierVia = "default" },
	{ name = "Blossom", hex3 = "00c", animal = "Flower Deer", tier = "Epic", tierVia = "name" },
	{ name = "Bolt", hex3 = "00d", animal = "Lightning Leopard", tier = "Divine", tierVia = "animal" },
	{ name = "Bongo", hex3 = "00e", animal = "Gorilla", tier = "Rare", tierVia = "name" },
	{ name = "Boogie", hex3 = "00f", animal = "Disco Duck", tier = "Exotic", tierVia = "animal" },
	{ name = "Boomer", hex3 = "010", animal = "Bulldog", tier = "Common", tierVia = "name" },
	{ name = "Boop", hex3 = "011", animal = "Seal", tier = "Common", tierVia = "default" },
	{ name = "Bramble", hex3 = "012", animal = "Thorn Bear", tier = "Legendary", tierVia = "name" },
	{ name = "Breezy", hex3 = "013", animal = "Cloud Cat", tier = "Common", tierVia = "name" },
	{ name = "Brisket", hex3 = "014", animal = "Boxer", tier = "Common", tierVia = "default" },
	{ name = "Brix", hex3 = "015", animal = "Brick Golem", tier = "Mythic", tierVia = "name" },
	{ name = "Bubba", hex3 = "016", animal = "Baby Hippo", tier = "Epic", tierVia = "name" },
	{ name = "Bubbles", hex3 = "017", animal = "Axolotl", tier = "Uncommon", tierVia = "name" },
	{ name = "Buttercup", hex3 = "018", animal = "Cow", tier = "Common", tierVia = "default" },
	{ name = "Button", hex3 = "019", animal = "Harvest Mouse", tier = "Common", tierVia = "name" },
	{ name = "Cactus", hex3 = "01a", animal = "Desert Lizard", tier = "Epic", tierVia = "name" },
	{ name = "Caper", hex3 = "01b", animal = "Capybara", tier = "Uncommon", tierVia = "name" },
	{ name = "Chai", hex3 = "01c", animal = "Siamese Cat", tier = "Uncommon", tierVia = "name" },
	{ name = "Cheddar", hex3 = "01d", animal = "Gerbil", tier = "Common", tierVia = "name" },
	{ name = "Cherry", hex3 = "01e", animal = "Red Panda", tier = "Rare", tierVia = "name" },
	{ name = "Chiffon", hex3 = "01f", animal = "Persian Cat", tier = "Epic", tierVia = "name" },
	{ name = "Chippy", hex3 = "020", animal = "Chipmunk", tier = "Common", tierVia = "name" },
	{ name = "Chirpy", hex3 = "021", animal = "Canary", tier = "Uncommon", tierVia = "name" },
	{ name = "Chomp", hex3 = "022", animal = "Baby Alligator", tier = "Mythic", tierVia = "name" },
	{ name = "Churro", hex3 = "023", animal = "Chinchilla", tier = "Common", tierVia = "default" },
	{ name = "Churro Pop", hex3 = "024", animal = "Alpaca", tier = "Common", tierVia = "default" },
	{ name = "Cinder", hex3 = "025", animal = "Lava Dragon", tier = "Mythic", tierVia = "name" },
	{ name = "Cloudy", hex3 = "026", animal = "Sheep", tier = "Uncommon", tierVia = "name" },
	{ name = "Clover", hex3 = "027", animal = "Deer", tier = "Uncommon", tierVia = "name" },
	{ name = "Cobalt", hex3 = "028", animal = "Blue Dragon", tier = "Legendary", tierVia = "name" },
	{ name = "Cocoa", hex3 = "029", animal = "Brown Bear", tier = "Common", tierVia = "name" },
	{ name = "Comet", hex3 = "02a", animal = "Dog", tier = "Common", tierVia = "name" },
	{ name = "Coral", hex3 = "02b", animal = "Seahorse", tier = "Rare", tierVia = "name" },
	{ name = "Cosmo", hex3 = "02c", animal = "Astronaut Dog", tier = "Exotic", tierVia = "name" },
	{ name = "Cotton", hex3 = "02d", animal = "Lamb", tier = "Common", tierVia = "default" },
	{ name = "Cracker", hex3 = "02e", animal = "Parakeet", tier = "Common", tierVia = "name" },
	{ name = "Cranberry", hex3 = "02f", animal = "Red Bird", tier = "Epic", tierVia = "name" },
	{ name = "Crayon", hex3 = "030", animal = "Colorful Dog", tier = "Common", tierVia = "default" },
	{ name = "Crickets", hex3 = "031", animal = "Cricket", tier = "Common", tierVia = "default" },
	{ name = "Crouton", hex3 = "032", animal = "Bread Dog", tier = "Common", tierVia = "default" },
	{ name = "Crumble", hex3 = "033", animal = "Cookie Dog", tier = "Exotic", tierVia = "animal" },
	{ name = "Dandelion", hex3 = "034", animal = "Yellow Chick", tier = "Epic", tierVia = "name" },
	{ name = "Dandy", hex3 = "035", animal = "Dandelion Sprite", tier = "Rare", tierVia = "name" },
	{ name = "Dapper", hex3 = "036", animal = "Tuxedo Cat", tier = "Epic", tierVia = "name" },
	{ name = "Dazzle", hex3 = "037", animal = "Peacock", tier = "Rare", tierVia = "name" },
	{ name = "Dingo", hex3 = "038", animal = "Wild Dog", tier = "Common", tierVia = "default" },
	{ name = "Doodle", hex3 = "039", animal = "Poodle", tier = "Common", tierVia = "name" },
	{ name = "Dot", hex3 = "03a", animal = "Tiny Dalmatian", tier = "Common", tierVia = "name" },
	{ name = "Dottie", hex3 = "03b", animal = "Ladybug", tier = "Common", tierVia = "default" },
	{ name = "Drift", hex3 = "03c", animal = "Shark", tier = "Legendary", tierVia = "name" },
	{ name = "Drizzle", hex3 = "03d", animal = "Rain Cloud Pet", tier = "Mythic", tierVia = "name" },
	{ name = "Dusk", hex3 = "03e", animal = "Raven", tier = "Common", tierVia = "default" },
	{ name = "Dusty", hex3 = "03f", animal = "Armadillo", tier = "Uncommon", tierVia = "name" },
	{ name = "Echo", hex3 = "040", animal = "Owl", tier = "Rare", tierVia = "name" },
	{ name = "Ember", hex3 = "041", animal = "Dragon", tier = "Rare", tierVia = "name" },
	{ name = "Fable", hex3 = "042", animal = "Griffin", tier = "Epic", tierVia = "name" },
	{ name = "Fawncy", hex3 = "043", animal = "Doe", tier = "Common", tierVia = "default" },
	{ name = "Fennel", hex3 = "044", animal = "Angora Rabbit", tier = "Uncommon", tierVia = "name" },
	{ name = "Fern", hex3 = "045", animal = "Forest Fox", tier = "Epic", tierVia = "name" },
	{ name = "Fizz", hex3 = "046", animal = "Soda Cub", tier = "Exotic", tierVia = "animal" },
	{ name = "Fizzgig", hex3 = "047", animal = "Gremlin", tier = "Mythic", tierVia = "name" },
	{ name = "Fizzle", hex3 = "048", animal = "Sparkle Fox", tier = "Common", tierVia = "default" },
	{ name = "Fizzlet", hex3 = "049", animal = "Mini Dragon", tier = "Mythic", tierVia = "name" },
	{ name = "Fizzpaw", hex3 = "04a", animal = "Soda Cat", tier = "Exotic", tierVia = "animal" },
	{ name = "Flapjack", hex3 = "04b", animal = "Pancake Penguin", tier = "Common", tierVia = "default" },
	{ name = "Flash", hex3 = "04c", animal = "Cheetah", tier = "Legendary", tierVia = "name" },
	{ name = "Flint", hex3 = "04d", animal = "Rock Golem", tier = "Mythic", tierVia = "name" },
	{ name = "Flintlock", hex3 = "04e", animal = "Pirate Parrot", tier = "Exotic", tierVia = "animal" },
	{ name = "Flopsy", hex3 = "04f", animal = "Rabbit", tier = "Common", tierVia = "name" },
	{ name = "Flurry", hex3 = "050", animal = "Snow Bunny", tier = "Mythic", tierVia = "name" },
	{ name = "Freckles", hex3 = "051", animal = "Dalmatian", tier = "Uncommon", tierVia = "name" },
	{ name = "Frizzle", hex3 = "052", animal = "Llama", tier = "Rare", tierVia = "name" },
	{ name = "Frosty", hex3 = "053", animal = "Polar Bear", tier = "Rare", tierVia = "name" },
	{ name = "Fudge", hex3 = "054", animal = "Brownie Bear", tier = "Common", tierVia = "default" },
	{ name = "Galaxy", hex3 = "055", animal = "Space Dragon", tier = "Divine", tierVia = "animal" },
	{ name = "Gemma", hex3 = "056", animal = "Crystal Bunny", tier = "Divine", tierVia = "animal" },
	{ name = "Gingersnap", hex3 = "057", animal = "Ginger Cat", tier = "Common", tierVia = "default" },
	{ name = "Glaze", hex3 = "058", animal = "Donut Dog", tier = "Mythic", tierVia = "name" },
	{ name = "Glimmer", hex3 = "059", animal = "Crystal Pony", tier = "Divine", tierVia = "animal" },
	{ name = "Glitch", hex3 = "05a", animal = "Digital Bunny", tier = "Divine", tierVia = "animal" },
	{ name = "Gumdrop", hex3 = "05b", animal = "Candy Bunny", tier = "Epic", tierVia = "name" },
	{ name = "Gummy", hex3 = "05c", animal = "Gummy Bear", tier = "Common", tierVia = "default" },
	{ name = "Halo", hex3 = "05d", animal = "Angel Cat", tier = "Divine", tierVia = "animal" },
	{ name = "Haze", hex3 = "05e", animal = "Misty Panther", tier = "Mythic", tierVia = "name" },
	{ name = "Honey", hex3 = "05f", animal = "Bee", tier = "Uncommon", tierVia = "name" },
	{ name = "Huckle", hex3 = "060", animal = "Blue Bear", tier = "Legendary", tierVia = "name" },
	{ name = "Jamboree", hex3 = "061", animal = "Circus Elephant", tier = "Exotic", tierVia = "animal" },
	{ name = "Jellybean", hex3 = "062", animal = "Slime", tier = "Rare", tierVia = "name" },
	{ name = "Jett", hex3 = "063", animal = "Falcon", tier = "Epic", tierVia = "name" },
	{ name = "Jinx", hex3 = "064", animal = "Shadow Cat", tier = "Exotic", tierVia = "animal" },
	{ name = "Jolly", hex3 = "065", animal = "Elf Dog", tier = "Common", tierVia = "default" },
	{ name = "Jumble", hex3 = "066", animal = "Patchwork Dog", tier = "Exotic", tierVia = "animal" },
	{ name = "Juno", hex3 = "067", animal = "Space Bunny", tier = "Exotic", tierVia = "animal" },
	{ name = "Kettle", hex3 = "068", animal = "Teacup Poodle", tier = "Common", tierVia = "default" },
	{ name = "Kiwi", hex3 = "069", animal = "Green Bird", tier = "Rare", tierVia = "name" },
	{ name = "Koda", hex3 = "06a", animal = "Husky", tier = "Uncommon", tierVia = "name" },
	{ name = "Lava Lamp", hex3 = "06b", animal = "Magma Slime", tier = "Divine", tierVia = "animal" },
	{ name = "Lollipop", hex3 = "06c", animal = "Candy Horse", tier = "Exotic", tierVia = "animal" },
	{ name = "Lotus", hex3 = "06d", animal = "Pink Dolphin", tier = "Rare", tierVia = "name" },
	{ name = "Luna", hex3 = "06e", animal = "Moon Fox", tier = "Divine", tierVia = "animal" },
	{ name = "Mallow", hex3 = "06f", animal = "Marshmallow Bunny", tier = "Exotic", tierVia = "animal" },
	{ name = "Maple", hex3 = "070", animal = "Beaver", tier = "Common", tierVia = "name" },
	{ name = "Marble", hex3 = "071", animal = "Tabby Cat", tier = "Common", tierVia = "name" },
	{ name = "Meringue", hex3 = "072", animal = "Cloud Bunny", tier = "Common", tierVia = "default" },
	{ name = "Midnight", hex3 = "073", animal = "Black Cat", tier = "Common", tierVia = "name" },
	{ name = "Minty", hex3 = "074", animal = "Koala", tier = "Uncommon", tierVia = "name" },
	{ name = "Miso", hex3 = "075", animal = "Shiba Inu", tier = "Uncommon", tierVia = "name" },
	{ name = "Mochi", hex3 = "076", animal = "Marshmallow Bear", tier = "Uncommon", tierVia = "name" },
	{ name = "Moondust", hex3 = "077", animal = "Lunar Dragon", tier = "Divine", tierVia = "animal" },
	{ name = "Moxie", hex3 = "078", animal = "Terrier", tier = "Rare", tierVia = "name" },
	{ name = "Muffin", hex3 = "079", animal = "Lop Bunny", tier = "Common", tierVia = "default" },
	{ name = "Munchkin", hex3 = "07a", animal = "Kitten", tier = "Common", tierVia = "default" },
	{ name = "Murmur", hex3 = "07b", animal = "Quiet Owl", tier = "Common", tierVia = "name" },
	{ name = "Nibbles", hex3 = "07c", animal = "Hamster", tier = "Common", tierVia = "name" },
	{ name = "Noodle", hex3 = "07d", animal = "Snake", tier = "Uncommon", tierVia = "name" },
	{ name = "Nori", hex3 = "07e", animal = "Black Rabbit", tier = "Epic", tierVia = "name" },
	{ name = "Nova", hex3 = "07f", animal = "Space Cat", tier = "Divine", tierVia = "animal" },
	{ name = "Nugget", hex3 = "080", animal = "Chick", tier = "Common", tierVia = "default" },
	{ name = "Oatmeal", hex3 = "081", animal = "Merino Sheep", tier = "Epic", tierVia = "name" },
	{ name = "Opal", hex3 = "082", animal = "Gem Cat", tier = "Legendary", tierVia = "name" },
	{ name = "Opie", hex3 = "083", animal = "Opossum", tier = "Uncommon", tierVia = "name" },
	{ name = "Orbit", hex3 = "084", animal = "Alien", tier = "Exotic", tierVia = "animal" },
	{ name = "Orbitz", hex3 = "085", animal = "Planet Pup", tier = "Divine", tierVia = "animal" },
	{ name = "Panko", hex3 = "086", animal = "Japanese Spitz", tier = "Uncommon", tierVia = "name" },
	{ name = "Patches", hex3 = "087", animal = "Calico Cat", tier = "Uncommon", tierVia = "name" },
	{ name = "Paws", hex3 = "088", animal = "Tiger", tier = "Epic", tierVia = "name" },
	{ name = "Pawsitron", hex3 = "089", animal = "Robot Cat", tier = "Legendary", tierVia = "name" },
	{ name = "Pebble", hex3 = "08a", animal = "Cottontail", tier = "Common", tierVia = "name" },
	{ name = "Pecan", hex3 = "08b", animal = "Dormouse", tier = "Common", tierVia = "name" },
	{ name = "Pecan Pie", hex3 = "08c", animal = "Pie Cat", tier = "Rare", tierVia = "name" },
	{ name = "Pecan Puff", hex3 = "08d", animal = "Flying Squirrel", tier = "Mythic", tierVia = "name" },
	{ name = "Pickles", hex3 = "08e", animal = "Frog", tier = "Common", tierVia = "name" },
	{ name = "Pika", hex3 = "08f", animal = "Electric Mouse", tier = "Common", tierVia = "default" },
	{ name = "Pippa", hex3 = "090", animal = "Penguin", tier = "Rare", tierVia = "name" },
	{ name = "Pips", hex3 = "091", animal = "Sparrow", tier = "Common", tierVia = "name" },
	{ name = "Pipsqueak", hex3 = "092", animal = "Mouse", tier = "Rare", tierVia = "name" },
	{ name = "Pixel", hex3 = "093", animal = "Cyber Fox", tier = "Mythic", tierVia = "name" },
	{ name = "Pizzazz", hex3 = "094", animal = "Party Pony", tier = "Legendary", tierVia = "name" },
	{ name = "Plume", hex3 = "095", animal = "Swan", tier = "Rare", tierVia = "name" },
	{ name = "Pogo", hex3 = "096", animal = "Kangaroo", tier = "Rare", tierVia = "name" },
	{ name = "Pollen", hex3 = "097", animal = "Bumblebee", tier = "Mythic", tierVia = "name" },
	{ name = "Pompom", hex3 = "098", animal = "Pomeranian", tier = "Uncommon", tierVia = "name" },
	{ name = "Poppy", hex3 = "099", animal = "Parrot", tier = "Rare", tierVia = "name" },
	{ name = "Prism", hex3 = "09a", animal = "Rainbow Unicorn", tier = "Divine", tierVia = "animal" },
	{ name = "Pudding", hex3 = "09b", animal = "Bear", tier = "Common", tierVia = "name" },
	{ name = "Puddle", hex3 = "09c", animal = "Otter", tier = "Uncommon", tierVia = "name" },
	{ name = "Puffer", hex3 = "09d", animal = "Pufferfish", tier = "Uncommon", tierVia = "name" },
	{ name = "Puffle", hex3 = "09e", animal = "Puffin", tier = "Uncommon", tierVia = "name" },
	{ name = "Quasar", hex3 = "09f", animal = "Cosmic Wolf", tier = "Divine", tierVia = "animal" },
	{ name = "Quibble", hex3 = "0a0", animal = "Quokka", tier = "Rare", tierVia = "name" },
	{ name = "Quill", hex3 = "0a1", animal = "Porcupine", tier = "Rare", tierVia = "name" },
	{ name = "Ramen", hex3 = "0a2", animal = "Tanuki", tier = "Rare", tierVia = "name" },
	{ name = "Razzle", hex3 = "0a3", animal = "Razzberry Dragon", tier = "Exotic", tierVia = "animal" },
	{ name = "Reef", hex3 = "0a4", animal = "Sea Turtle", tier = "Uncommon", tierVia = "name" },
	{ name = "Riff", hex3 = "0a5", animal = "Rock Star Dog", tier = "Exotic", tierVia = "animal" },
	{ name = "Ringo", hex3 = "0a6", animal = "Monkey", tier = "Common", tierVia = "default" },
	{ name = "Ripple", hex3 = "0a7", animal = "Dolphin", tier = "Epic", tierVia = "name" },
	{ name = "Riptide", hex3 = "0a8", animal = "Orca", tier = "Legendary", tierVia = "name" },
	{ name = "Rocket", hex3 = "0a9", animal = "Robot Dog", tier = "Exotic", tierVia = "animal" },
	{ name = "Rollo", hex3 = "0aa", animal = "Roly-Poly Bug", tier = "Common", tierVia = "default" },
	{ name = "Rook", hex3 = "0ab", animal = "Crow", tier = "Common", tierVia = "default" },
	{ name = "Roxy", hex3 = "0ac", animal = "Fennec Fox", tier = "Uncommon", tierVia = "name" },
	{ name = "Ruffles", hex3 = "0ad", animal = "Sheepdog", tier = "Rare", tierVia = "name" },
	{ name = "Rumble", hex3 = "0ae", animal = "Dinosaur", tier = "Legendary", tierVia = "name" },
	{ name = "Rumblebee", hex3 = "0af", animal = "Carpenter Bee", tier = "Common", tierVia = "default" },
	{ name = "S'more", hex3 = "0b0", animal = "Campfire Bear", tier = "Exotic", tierVia = "animal" },
	{ name = "Sable", hex3 = "0b1", animal = "Black Fox", tier = "Epic", tierVia = "name" },
	{ name = "Saffron", hex3 = "0b2", animal = "Golden Tiger", tier = "Exotic", tierVia = "animal" },
	{ name = "Scout", hex3 = "0b3", animal = "Beagle", tier = "Common", tierVia = "name" },
	{ name = "Shimmer", hex3 = "0b4", animal = "Mermaid Cat", tier = "Divine", tierVia = "animal" },
	{ name = "Shiver", hex3 = "0b5", animal = "Ice Dragon", tier = "Divine", tierVia = "animal" },
	{ name = "Sizzle", hex3 = "0b6", animal = "Fire Lizard", tier = "Exotic", tierVia = "animal" },
	{ name = "Sizzlepop", hex3 = "0b7", animal = "Firework Dragon", tier = "Divine", tierVia = "animal" },
	{ name = "Skipper", hex3 = "0b8", animal = "Porpoise", tier = "Common", tierVia = "default" },
	{ name = "Skittles", hex3 = "0b9", animal = "Chameleon", tier = "Uncommon", tierVia = "name" },
	{ name = "Skye", hex3 = "0ba", animal = "Blue Jay", tier = "Rare", tierVia = "name" },
	{ name = "Smudge", hex3 = "0bb", animal = "Gray Kitten", tier = "Uncommon", tierVia = "name" },
	{ name = "Snickers", hex3 = "0bc", animal = "Ferret", tier = "Common", tierVia = "name" },
	{ name = "Snoot", hex3 = "0bd", animal = "Piglet", tier = "Uncommon", tierVia = "name" },
	{ name = "Snoozy", hex3 = "0be", animal = "Sleepy Sloth", tier = "Common", tierVia = "default" },
	{ name = "Snowcap", hex3 = "0bf", animal = "Arctic Fox", tier = "Legendary", tierVia = "name" },
	{ name = "Snug", hex3 = "0c0", animal = "Sloth", tier = "Rare", tierVia = "name" },
	{ name = "Sol", hex3 = "0c1", animal = "Sun Lion", tier = "Legendary", tierVia = "name" },
	{ name = "Soot", hex3 = "0c2", animal = "Coal Cat", tier = "Common", tierVia = "default" },
	{ name = "Spark", hex3 = "0c3", animal = "Phoenix", tier = "Mythic", tierVia = "animal" },
	{ name = "Spindle", hex3 = "0c4", animal = "Spider", tier = "Common", tierVia = "default" },
	{ name = "Spooky", hex3 = "0c5", animal = "Ghost Dog", tier = "Rare", tierVia = "name" },
	{ name = "Sprinkles", hex3 = "0c6", animal = "Cupcake Cat", tier = "Exotic", tierVia = "animal" },
	{ name = "Sprocket", hex3 = "0c7", animal = "Robot Hamster", tier = "Exotic", tierVia = "animal" },
	{ name = "Sproing", hex3 = "0c8", animal = "Tree Frog", tier = "Epic", tierVia = "name" },
	{ name = "Sprout", hex3 = "0c9", animal = "Turtle", tier = "Common", tierVia = "name" },
	{ name = "Squeaky", hex3 = "0ca", animal = "Guinea Pig", tier = "Common", tierVia = "default" },
	{ name = "Squiggle", hex3 = "0cb", animal = "Octopus", tier = "Rare", tierVia = "name" },
	{ name = "Squish", hex3 = "0cc", animal = "Jellyfish", tier = "Common", tierVia = "default" },
	{ name = "Starlight", hex3 = "0cd", animal = "Unicorn", tier = "Divine", tierVia = "animal" },
	{ name = "Sterling", hex3 = "0ce", animal = "Silver Wolf", tier = "Legendary", tierVia = "name" },
	{ name = "Stomper", hex3 = "0cf", animal = "Baby Elephant", tier = "Legendary", tierVia = "name" },
	{ name = "Stumpy", hex3 = "0d0", animal = "Hedgehog", tier = "Uncommon", tierVia = "name" },
	{ name = "Sunny", hex3 = "0d1", animal = "Duckling", tier = "Common", tierVia = "name" },
	{ name = "Sushi", hex3 = "0d2", animal = "Koi Fish", tier = "Rare", tierVia = "name" },
	{ name = "Swirl", hex3 = "0d3", animal = "Ice Cream Unicorn", tier = "Divine", tierVia = "animal" },
	{ name = "Swoop", hex3 = "0d4", animal = "Eagle", tier = "Legendary", tierVia = "name" },
	{ name = "Taffeta", hex3 = "0d5", animal = "Fancy Poodle", tier = "Mythic", tierVia = "name" },
	{ name = "Taffy", hex3 = "0d6", animal = "Candy Cat", tier = "Exotic", tierVia = "animal" },
	{ name = "Tango", hex3 = "0d7", animal = "Orange Cat", tier = "Exotic", tierVia = "animal" },
	{ name = "Tango Pop", hex3 = "0d8", animal = "Flamingo", tier = "Common", tierVia = "default" },
	{ name = "Tater", hex3 = "0d9", animal = "Potato Penguin", tier = "Rare", tierVia = "name" },
	{ name = "Teddy", hex3 = "0da", animal = "Teddy Bear", tier = "Common", tierVia = "name" },
	{ name = "Tide", hex3 = "0db", animal = "Blue Shark", tier = "Epic", tierVia = "name" },
	{ name = "Tiki", hex3 = "0dc", animal = "Toucan", tier = "Common", tierVia = "name" },
	{ name = "Tiki Torch", hex3 = "0dd", animal = "Fire Fox", tier = "Mythic", tierVia = "name" },
	{ name = "Timber", hex3 = "0de", animal = "Moose", tier = "Legendary", tierVia = "name" },
	{ name = "Tinker", hex3 = "0df", animal = "Clockwork Mouse", tier = "Common", tierVia = "default" },
	{ name = "Tinsel", hex3 = "0e0", animal = "Reindeer", tier = "Epic", tierVia = "name" },
	{ name = "Tinseltoe", hex3 = "0e1", animal = "Holiday Reindeer", tier = "Exotic", tierVia = "animal" },
	{ name = "Toffee", hex3 = "0e2", animal = "Fox", tier = "Common", tierVia = "name" },
	{ name = "Tofu", hex3 = "0e3", animal = "White Cat", tier = "Uncommon", tierVia = "name" },
	{ name = "Topaz", hex3 = "0e4", animal = "Golden Retriever", tier = "Legendary", tierVia = "name" },
	{ name = "Truffle", hex3 = "0e5", animal = "Pig", tier = "Common", tierVia = "default" },
	{ name = "Tumble", hex3 = "0e6", animal = "Tumbleweed Pup", tier = "Exotic", tierVia = "animal" },
	{ name = "Tundra", hex3 = "0e7", animal = "Wolf", tier = "Legendary", tierVia = "name" },
	{ name = "Turbo", hex3 = "0e8", animal = "Racing Turtle", tier = "Rare", tierVia = "name" },
	{ name = "Twinkle", hex3 = "0e9", animal = "Fairy", tier = "Exotic", tierVia = "animal" },
	{ name = "Twirl", hex3 = "0ea", animal = "Ribbon Unicorn", tier = "Mythic", tierVia = "name" },
	{ name = "Twix", hex3 = "0eb", animal = "Stoat", tier = "Common", tierVia = "default" },
	{ name = "Vanta", hex3 = "0ec", animal = "Shadow Panther", tier = "Divine", tierVia = "animal" },
	{ name = "Velvet", hex3 = "0ed", animal = "Fruit Bat", tier = "Epic", tierVia = "name" },
	{ name = "Vesper", hex3 = "0ee", animal = "Bat", tier = "Epic", tierVia = "name" },
	{ name = "Vine", hex3 = "0ef", animal = "Jungle Snake", tier = "Common", tierVia = "default" },
	{ name = "Vivid", hex3 = "0f0", animal = "Rainbow Gecko", tier = "Divine", tierVia = "animal" },
	{ name = "Vortex", hex3 = "0f1", animal = "Storm Serpent", tier = "Divine", tierVia = "animal" },
	{ name = "Waffles", hex3 = "0f2", animal = "Duck", tier = "Common", tierVia = "name" },
	{ name = "Whiskers", hex3 = "0f3", animal = "Cat", tier = "Common", tierVia = "name" },
	{ name = "Wicket", hex3 = "0f4", animal = "Ewok-like Bear", tier = "Common", tierVia = "default" },
	{ name = "Wisp", hex3 = "0f5", animal = "Spirit Wolf", tier = "Epic", tierVia = "name" },
	{ name = "Wobble", hex3 = "0f6", animal = "Emperor Penguin", tier = "Epic", tierVia = "name" },
	{ name = "Yeti", hex3 = "0f7", animal = "Snow Monster", tier = "Mythic", tierVia = "name" },
	{ name = "Zephyr", hex3 = "0f8", animal = "Wind Hawk", tier = "Divine", tierVia = "animal" },
	{ name = "Zest", hex3 = "0f9", animal = "Lemon Bird", tier = "Rare", tierVia = "name" },
	{ name = "Ziggy", hex3 = "0fa", animal = "Zebra", tier = "Common", tierVia = "name" },
	-- Event Horizon limited pets (canonical display names).
	{ name = "Matter+", hex3 = "0fb", animal = "White Box", tier = "Exotic", tierVia = "name" },
	{ name = "Matter-", hex3 = "0fc", animal = "Black Box", tier = "Exotic", tierVia = "name" },
	{ name = "Albert Minestein", hex3 = "0fd", animal = "Albert Einstein", tier = "Exotic", tierVia = "name" },
}

-- Legacy Horizon / paren spellings → canonical Matter± / Albert Minestein.
MinePetRoster.NAME_ALIASES = {
	["Horizon+"] = "Matter+",
	["Horizon-"] = "Matter-",
	["Albert Horizontein"] = "Albert Minestein",
	["Albert Minestine"] = "Albert Minestein",
	["Matter(+)"] = "Matter+",
	["Matter(-)"] = "Matter-",
}

do
	local shared = game:GetService("ReplicatedStorage"):WaitForChild("Mine"):WaitForChild("Shared")
	local mod = shared:FindFirstChild("MineEHPets") or shared:FindFirstChild("MineEventHorizonPets")
	local ok, eh = pcall(require, mod)
	if ok and eh and eh.mergeIntoRoster then
		eh.mergeIntoRoster(MinePetRoster)
	end
end

--[[
	ZONE POTS (MineZonePets, owner 2026-10-10: 70 pets per zone). Every regular
	pet gets the zone whose pot it belongs to, and the new zone pets join the
	roster here -- BEFORE the indexes below are built, so BY_NAME, BY_TIER and
	HEX3_BY_NAME all see them. A name already in the roster is never replaced.
]]
do
	local ok, zp = pcall(require, script.Parent:FindFirstChild("MineZonePets"))
	if ok and type(zp) == "table" and zp.PETS then
		local have = {}
		for _, pet in ipairs(MinePetRoster.PETS) do
			have[pet.name] = true
		end
		for _, row in ipairs(zp.PETS) do
			if not have[row.name] then
				table.insert(MinePetRoster.PETS, {
					name = row.name, hex3 = row.hex3, animal = row.animal, tier = row.tier, tierVia = "zone", zone = row.zone,
				})
			end
		end
		for _, pet in ipairs(MinePetRoster.PETS) do
			pet.zone = pet.zone or (zp.ZONE_OF and zp.ZONE_OF[pet.name])
		end
	end
end

MinePetRoster.BY_NAME = {}
MinePetRoster.BY_TIER = {}
-- zone id -> its pets. Event Horizon pets carry no zone here; they are bigbang's.
MinePetRoster.BY_ZONE = {}
for _, pet in ipairs(MinePetRoster.PETS) do
	MinePetRoster.BY_NAME[pet.name] = pet
	MinePetRoster.BY_TIER[pet.tier] = MinePetRoster.BY_TIER[pet.tier] or {}
	table.insert(MinePetRoster.BY_TIER[pet.tier], pet)
	if pet.zone then
		MinePetRoster.BY_ZONE[pet.zone] = MinePetRoster.BY_ZONE[pet.zone] or {}
		table.insert(MinePetRoster.BY_ZONE[pet.zone], pet)
	end
end
for oldName, newName in pairs(MinePetRoster.NAME_ALIASES) do
	local pet = MinePetRoster.BY_NAME[newName]
	if pet then
		MinePetRoster.BY_NAME[oldName] = pet
	end
end

function MinePetRoster.color(tier)
	return MinePetRoster.TIER_COLOR[tier] or MinePetRoster.TIER_COLOR.Common
end
MinePetRoster.HEX3_BY_NAME = {}
for _, pet in ipairs(MinePetRoster.PETS) do
	if pet.hex3 and pet.name then
		MinePetRoster.HEX3_BY_NAME[pet.name] = pet.hex3
	end
end
for oldName, newName in pairs(MinePetRoster.NAME_ALIASES) do
	local hex = MinePetRoster.HEX3_BY_NAME[newName]
	if hex then
		MinePetRoster.HEX3_BY_NAME[oldName] = hex
	end
end

function MinePetRoster.hex3For(name)
	if type(name) ~= "string" then
		return "000"
	end
	return MinePetRoster.HEX3_BY_NAME[name] or "000"
end

do
	local shared = script.Parent
	local mod = shared:FindFirstChild("MineEHPets") or shared:FindFirstChild("MineEventHorizonPets")
	local ok, eh = pcall(require, mod)
	if ok and eh and eh.applyToPetRoster then
		eh.applyToPetRoster(MinePetRoster)
	end
end

return MinePetRoster
