-- MineBagNames: authored display names for MineBags.
-- Same index order MineBags builds: satchel 1-16, shallow/mid/deep pack 1-8, fossil 1-6.
-- Founders Rig and Wormhole Bag are named in MineBags.

local MineBagNames = {
	meadow = {
		satchel = {
			"Canvas Satchel", "Twine Pouch", "Miners Pack", "Riveted Satchel",
			"Ore Crate Rig", "Leather Hauler", "Bolted Rucksack", "Slab Carrier",
			"Loam Frame", "Sod Cradle", "Hillpack", "Grassvault",
			"Dirt Hold", "Meadow Rig", "Soilcarrier", "Canvas Vault",
		},
		shallow = {
			"Fieldpack", "Hedge Rig", "Pasture Hold", "Fence Cradle",
			"Barn Hauler", "Meadow Desk", "Hillvault", "Sodwork Pack",
		},
		mid = {
			"Basalt Cradle", "Ironsoil Rig", "Nightclay Pack", "Pyre Hold",
			"Gloomar Vault", "Umber Frame", "Cinder Hauler", "Rime Carrier",
		},
		deep = {
			"Aether Sack", "Voidloam Rig", "Starash Frame", "Mythril Carrier",
			"Endsoil Rig", "Deep Hauler", "Nightvault", "Workhorse Pack",
		},
		fossil = {
			"Bone Pouch", "Amber Satchel", "Petrified Pack", "Fossil Cradle",
			"Amber Vault", "Bonework Rig",
		},
	},
	sunscar = {
		satchel = {
			"Quartz Pouch", "Flagpack", "Shale Satchel", "Mason Hold",
			"Flint Cradle", "Ashlar Pack", "Quarry Bag", "Veinpouch",
			"Coldpack", "Slate Hold", "Silverbag", "Rust Pouch",
			"Chiselhold", "Jackpack", "Capbag", "Pipepouch",
		},
		shallow = {
			"Flagcutter Pack", "Masonbit Hold", "Blastbrick Bag", "Shaleiron Pack",
			"Twoflute Rig", "Pipecharge Hold", "Coldvein Pack", "Facetcore Bag",
		},
		mid = {
			"Greyvein Frame", "Quarry Vault", "Ashlar Cradle", "Silverblack Rig",
			"Rustfreckle Hold", "Chiselspike Pack", "Doublebit Vault", "Slatecutter Pack",
		},
		deep = {
			"Veinwork Pack", "Flagstone Rig", "Masonvault", "Quarry Hauler",
			"Greyvein Workhorse", "Coldvault", "Ashlar Carrier", "Shale Endhaul",
		},
		fossil = {
			"Quartz Bone", "Flag Fossil", "Shale Amber", "Mason Relic",
			"Flint Shell", "Ashlar Bonebag",
		},
	},
	mistreef = {
		satchel = {
			"Barnacle Pouch", "Tidepack", "Abalone Satchel", "Silt Hold",
			"Algae Cradle", "Coral Pack", "Divebag", "Urchin Pouch",
			"Glassfloat Hold", "Brinepack", "Kelp Satchel", "Lagoon Bag",
			"Pearlhold", "Spume Pack", "Current Pouch", "Reef Satchel",
		},
		shallow = {
			"Tidescoop Pack", "Brinecrank Hold", "Netfloat Bag", "Reefiron Pack",
			"Pressurebit Rig", "Depthdrum Hold", "Glowkelp Pack", "Stormorb Bag",
		},
		mid = {
			"Mistreef Frame", "Tidevault", "Coral Cradle", "Brine Rig",
			"Lagoon Hold", "Pearl Vault", "Urchin Pack", "Silt Carrier",
		},
		deep = {
			"Abyss Pack", "Pressure Rig", "Kelpvault", "Dive Hauler",
			"Mistreef Workhorse", "Tide Endhaul", "Reef Carrier", "Brinevault",
		},
		fossil = {
			"Coral Bone", "Pearl Fossil", "Tide Amber", "Urchin Relic",
			"Kelp Shell", "Abalone Bonebag",
		},
	},
	arcwork = {
		satchel = {
			"Coil Pouch", "Wirepack", "Busbar Satchel", "Spark Hold",
			"Arc Cradle", "Volt Pack", "Cellbag", "Fuse Pouch",
			"Copperhold", "Amp Pack", "Gear Satchel", "Dynamo Bag",
			"Magnet Hold", "Stator Bag", "Rotor Pouch", "Grid Satchel",
		},
		shallow = {
			"Coilcleaver Pack", "Sparkworm Hold", "Fusejar Bag", "Copperkeel Pack",
			"Voltbit Rig", "Cellpack Hold", "Nightcoil Pack", "Arcorb Bag",
		},
		mid = {
			"Arcwork Frame", "Coilvault", "Spark Cradle", "Volt Rig",
			"Busbar Hold", "Dynamo Vault", "Magnet Pack", "Grid Carrier",
		},
		deep = {
			"Stator Pack", "Rotor Rig", "Ampvault", "Coil Hauler",
			"Arcwork Workhorse", "Volt Endhaul", "Amp Carrier", "Cellvault",
		},
		fossil = {
			"Coil Bone", "Spark Fossil", "Volt Amber", "Fuse Relic",
			"Copper Shell", "Arc Bonebag",
		},
	},
	bloodmoon = {
		satchel = {
			"Crimson Pouch", "Sickle Pack", "Scar Satchel", "Ember Hold",
			"Ash Cradle", "Veil Pack", "Fangbag", "Cinder Pouch",
			"Bloodhold", "Moon Pack", "Gore Satchel", "Smolder Bag",
			"Howl Hold", "Nightscar Pack", "Emberpouch", "Scarhide Satchel",
		},
		shallow = {
			"Embercleave Pack", "Cindercork Hold", "Ashpot Bag", "Scariron Pack",
			"Emberbore Rig", "Cindercharge Hold", "Nightfang Pack", "Veilorb Bag",
		},
		mid = {
			"Bloodmoon Frame", "Scarvault", "Ember Cradle", "Ash Rig",
			"Veil Hold", "Fang Vault", "Cinder Pack", "Moon Carrier",
		},
		deep = {
			"Gore Pack", "Howl Rig", "Embervault", "Scar Hauler",
			"Bloodmoon Workhorse", "Ash Endhaul", "Veil Carrier", "Fangvault",
		},
		fossil = {
			"Crimson Bone", "Ember Fossil", "Ash Amber", "Fang Relic",
			"Scar Shell", "Moon Bonebag",
		},
	},
	eclipse = {
		satchel = {
			"Umbra Pouch", "Shade Pack", "Twinumbra Satchel", "Corona Hold",
			"Penumbra Cradle", "Voidglass Pack", "Totality Bag", "Disk Pouch",
			"Nocturne Hold", "Coolshade Pack", "Silvereclipse Hold", "Endshade Satchel",
			"Occlusion Hold", "Rim Pack", "Blacksun Pouch", "Umbra Satchel",
		},
		shallow = {
			"Diskcleaver Pack", "Shadecork Hold", "Coronarim Bag", "Nocturneiron Pack",
			"Umbrajack Rig", "Shadebrick Hold", "Voidneedle Pack", "Blackcorona Bag",
		},
		mid = {
			"Eclipse Frame", "Umbravault", "Shade Cradle", "Corona Rig",
			"Penumbra Hold", "Totality Vault", "Disk Pack", "Nocturne Carrier",
		},
		deep = {
			"Void Pack", "Occlusion Rig", "Shadevault", "Umbra Hauler",
			"Eclipse Workhorse", "Corona Endhaul", "Disk Carrier", "Voidvault",
		},
		fossil = {
			"Umbra Bone", "Shade Fossil", "Corona Amber", "Disk Relic",
			"Nocturne Shell", "Void Bonebag",
		},
	},
	riftmarch = {
		satchel = {
			"Fault Pouch", "Scarhook Pack", "Gate Satchel", "Tear Hold",
			"Crack Cradle", "Warp Pack", "Bentbag", "Fracture Pouch",
			"Seam Hold", "Schism Pack", "Rift Satchel", "Fold Bag",
			"Breach Hold", "Split Pack", "Warp Pouch", "Voidgate Satchel",
		},
		shallow = {
			"Tearcleaver Pack", "Gatecork Hold", "Crackpot Bag", "Faultiron Pack",
			"Faultbore Rig", "Riftcharge Hold", "Schismedge Pack", "Tearorb Bag",
		},
		mid = {
			"Riftmarch Frame", "Faultvault", "Gate Cradle", "Tear Rig",
			"Warp Hold", "Fracture Vault", "Seam Pack", "Schism Carrier",
		},
		deep = {
			"Breach Pack", "Fold Rig", "Warpvault", "Fault Hauler",
			"Riftmarch Workhorse", "Tear Endhaul", "Gate Carrier", "Schismvault",
		},
		fossil = {
			"Fault Bone", "Tear Fossil", "Warp Amber", "Gate Relic",
			"Seam Shell", "Rift Bonebag",
		},
	},
	starfall = {
		satchel = {
			"Comet Pouch", "Meteor Pack", "Starsteel Satchel", "Dust Hold",
			"Gold Cradle", "Orbit Pack", "Thrustbag", "Nova Pouch",
			"Sky Hold", "Fall Pack", "Aster Satchel", "Cosmic Bag",
			"Trail Hold", "Bolide Bag", "Stardust Pouch", "Voidcomet Satchel",
		},
		shallow = {
			"Cometcleaver Pack", "Orbitcork Hold", "Dustpot Bag", "Skyiron Pack",
			"Cometbore Rig", "Fallcharge Hold", "Novahelix Pack", "Orbitorb Bag",
		},
		mid = {
			"Starfall Frame", "Cometvault", "Meteor Cradle", "Orbit Rig",
			"Nova Hold", "Dust Vault", "Trail Pack", "Star Carrier",
		},
		deep = {
			"Bolide Pack", "Aster Rig", "Orbitvault", "Comet Hauler",
			"Starfall Workhorse", "Nova Endhaul", "Sky Carrier", "Fallvault",
		},
		fossil = {
			"Comet Bone", "Meteor Fossil", "Star Amber", "Orbit Relic",
			"Nova Shell", "Dust Bonebag",
		},
	},
	mythral = {
		satchel = {
			"Facet Pouch", "Prism Pack", "Mythforge Satchel", "Shard Hold",
			"Amethyst Cradle", "Aether Pack", "Lattice Bag", "Gleam Pouch",
			"Crystal Hold", "Gem Bag", "Voidlattice Satchel", "Darkfacet Bag",
			"Myth Hold", "Prism Pouch", "Gleambag", "Shard Satchel",
		},
		shallow = {
			"Shardcleaver Pack", "Gemcork Hold", "Prismpot Bag", "Crystaliron Pack",
			"Prismbore Rig", "Gleamcharge Hold", "Voidlattice Pack", "Mythorb Bag",
		},
		mid = {
			"Mythral Frame", "Facetvault", "Prism Cradle", "Shard Rig",
			"Aether Hold", "Lattice Vault", "Gleam Pack", "Crystal Carrier",
		},
		deep = {
			"Gem Pack", "Myth Rig", "Prismvault", "Facet Hauler",
			"Mythral Workhorse", "Shard Endhaul", "Lattice Carrier", "Gleamvault",
		},
		fossil = {
			"Facet Bone", "Prism Fossil", "Shard Amber", "Crystal Relic",
			"Gleam Shell", "Myth Bonebag",
		},
	},
	primordium = {
		satchel = {
			"Fossilsocket Pouch", "Heartstone Pack", "Primeiron Satchel", "Seed Hold",
			"Emberash Cradle", "Shellbag", "Origin Bag", "Ancient Pouch",
			"Firstsoil Hold", "Corebag", "Prime Satchel", "Heartglow Bag",
			"Seedspiral Hold", "Ashegg Pack", "Seedshell Pouch", "Nightheart Satchel",
		},
		shallow = {
			"Heartcleaver Pack", "Seedcork Hold", "Ashurn Bag", "Primekeel Pack",
			"Heartbore Rig", "Shellcharge Hold", "Voidseed Pack", "Primeorb Bag",
		},
		mid = {
			"Primordium Frame", "Heartvault", "Seed Cradle", "Prime Rig",
			"Fossil Hold", "Origin Vault", "Shell Pack", "Ancient Carrier",
		},
		deep = {
			"Core Pack", "Firstsoil Rig", "Primevault", "Heart Hauler",
			"Primordium Workhorse", "Seed Endhaul", "Origin Carrier", "Shellvault",
		},
		fossil = {
			"Prime Bone", "Heart Fossil", "Seed Amber", "Origin Relic",
			"Shell Relic", "Ancient Bonebag",
		},
	},
}

function MineBagNames.get(zoneId, kind, index)
	local pack = MineBagNames[zoneId]
	local list = pack and pack[kind]
	local n = list and list[index]
	if type(n) == "string" and n ~= "" then
		return n
	end
	return nil
end

return MineBagNames
