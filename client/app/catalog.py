"""The shop's product catalogue.

This is static shop content (names, jokes, prices), not purchase data, so it
lives here in plain Python. Each product's photograph is
static/img/products/<slug>.webp (see the `art` macro in templates/partials/macros.html).
`effect` only picks the product's animation in main.css / effects.js.
"""
from .money import split_pips, to_pips

CATEGORIES = [
    {"slug": "truancy-treats", "name": "Truancy Treats",
     "blurb": "Confectionery for the strategically unwell."},
    {"slug": "sneaking", "name": "Sneaking & Spying",
     "blurb": "For those who need to know, and shouldn't."},
    {"slug": "mayhem", "name": "Mayhem & Pyrotechnics",
     "blurb": "Loud, bright and very hard to get out of corridors."},
    {"slug": "creatures", "name": "Creatures & Charms",
     "blurb": "Small, soft, dreamy and almost certainly legal."},
]

PRODUCTS = [
    {
        "slug": "long-reach-listeners",
        "name": "Long-Reach Listeners",
        "category": "sneaking",
        "tagline": "Hear everything. Admit nothing.",
        "description": (
            "A pair of very lifelike ears on a long, discreet cord. Lower them down a stairwell, "
            "slide them under a door or dangle them over a banister and you'll hear the whole "
            "conversation, crisp as a fresh-baked biscuit. Thoroughly tested on our own "
            "family kitchen. Repeatedly."
        ),
        "properties": [
            "Stretches up to five storeys without losing a syllable",
            "Hears through doors, though not through a properly sealed one",
            "Self-winding cord that coils itself up when you're done",
        ],
        "warning": "Do not leave unattended near cats. They will take it personally.",
        "price": to_pips(0, 11, 6),
        "badge": "Family favourite",
        "accent": "#d98a6c",
        "effect": "ears",
        "demo": "Raise the ears",
    },
    {
        "slug": "queasy-drops",
        "name": "Queasy Drops",
        "category": "truancy-treats",
        "tagline": "Feel queasy, leave early, get better on the stairs.",
        "description": (
            "Suck the orange side and you'll turn a convincing shade of green just as the lesson "
            "gets dull. Once you're safely out, the purple side settles your stomach on the spot, "
            "and you have the rest of the afternoon to yourself. Comes in a tin. You'll want the tin."
        ),
        "properties": [
            "Takes effect in under a minute (we timed it, extensively)",
            "Two-sided: orange to bring it on, purple to make it stop",
            "Mint finish, for the sake of everyone near you",
        ],
        "warning": "Do not suck both sides at once. Ask our friend Barnaby why.",
        "price": to_pips(0, 6, 0),
        "badge": "Banned at the Academy",
        "accent": "#7fa64a",
        "effect": "pastilles",
        "demo": "Open the tin",
    },
    {
        "slug": "crimson-nose-nougat",
        "name": "Crimson Nose Nougat",
        "category": "truancy-treats",
        "tagline": "A dramatic exit, with nuts.",
        "description": (
            "Chewy honey nougat with toasted hazelnuts that sets off a small, theatrical "
            "nosebleed at the moment you choose. The teacher sends you to the infirmary, "
            "you take the scenic route, and the antidote end stops it the moment you're out the door."
        ),
        "properties": [
            "Nosebleed arrives on demand, never before",
            "Antidote end tested to stop it in two seconds flat",
            "Real Cornish hazelnuts, sourced by our cousin's attic gremlin",
        ],
        "warning": "Not to be eaten while a Queasy Drop is still working. We've been there.",
        "price": to_pips(0, 7, 14),
        "badge": None,
        "accent": "#9e2a3a",
        "effect": "nougat",
        "demo": "Take a bite",
    },
    {
        "slug": "hot-brow-fudge",
        "name": "Hot-Brow Fudge",
        "category": "truancy-treats",
        "tagline": "Run hot. Get out of class.",
        "description": (
            "Rich butter fudge that gives you a fine-looking fever, flushed cheeks and a "
            "hot forehead, enough to convince even the most suspicious housemaster. "
            "Early test batches also gave our tasters large, painful spots. We've mostly fixed that."
        ),
        "properties": [
            "Raises your temperature about two degrees, very convincingly",
            "Spots reduced by 94% since the last batch",
            "Clotted-cream recipe, Mum's (she must never know)",
        ],
        "warning": "Any spots that do appear will go away by Tuesday. Probably.",
        "price": to_pips(0, 5, 18),
        "badge": "Improved formula",
        "accent": "#e07a34",
        "effect": "fudge",
        "demo": "Turn up the heat",
    },
    {
        "slug": "pocket-fluffs",
        "name": "Pocket Fluffs",
        "category": "creatures",
        "tagline": "Miniature, fluffy, tirelessly devoted.",
        "description": (
            "Bred from wild hedgerow fluff into a palm-sized ball of pink and purple fur. "
            "Pocket Fluffs hum when they're happy, follow your every move with enormous eyes "
            "and eat almost anything, including the spiders under your bed. Go on, move your mouse. It's watching."
        ),
        "properties": [
            "Bonded for life after the first tickle",
            "Comes in Pink, Purple and an unauthorised Violet",
            "Gets along with owls, cats and most younger brothers",
        ],
        "warning": "Might try to nibble a sleeping relative's toes. Very affectionate.",
        "price": to_pips(1, 3, 0),
        "badge": "Sold out twice",
        "accent": "#d65aa5",
        "effect": "puffs",
        "demo": "Tickle it",
    },
    {
        "slug": "bottled-bog",
        "name": "Bottled Bog",
        "category": "mayhem",
        "tagline": "A corridor of bog. In a bottle.",
        "description": (
            "Uncork, tip out and watch an entire corridor fill with a stinking, knee-deep "
            "marsh, complete with reeds, midges and an indignant toad. Nobody has yet worked "
            "out how to get rid of one. Our longest-standing bog is now a protected wetland."
        ),
        "properties": [
            "Covers up to forty feet of corridor",
            "Smells like genuine bog, sourced from the West Country",
            "Toad included (results vary; the toad is grumpy)",
        ],
        "warning": "Wellies sold separately. Keep the cork somewhere you'll remember.",
        "price": to_pips(2, 0, 0),
        "badge": "Signature mischief",
        "accent": "#5f7d3a",
        "effect": "swamp",
        "demo": "Uncork the bottle",
    },
    {
        "slug": "diversion-crackers",
        "name": "Diversion Crackers",
        "category": "sneaking",
        "tagline": "Drop one. Run in the opposite direction.",
        "description": (
            "A little round cracker that scuttles off on tiny legs and goes off with "
            "a satisfying BANG somewhere well away from you. Everyone rushes to look while "
            "you get on with whatever you shouldn't be doing."
        ),
        "properties": [
            "Scuttles up to ninety feet before it goes off",
            "Bang heard across three floors; smoke clears in seconds",
            "Legs are completely harmless, if a little disturbing",
        ],
        "warning": "Has been known to sprint towards school inspectors. We don't apologise.",
        "price": to_pips(1, 9, 0),
        "badge": None,
        "accent": "#3a3138",
        "effect": "decoy",
        "demo": "Wind it up",
    },
    {
        "slug": "instant-midnight",
        "name": "Instant Midnight Powder",
        "category": "sneaking",
        "tagline": "Throw a pinch. Disappear.",
        "description": (
            "Ground from the far side of a moonless night, at considerable risk to our import "
            "licence. One pinch throws a room into perfect, ink-thick darkness that no lantern "
            "or light spell can get through. Ideal for a quick getaway, a dramatic entrance or "
            "avoiding your botany homework."
        ),
        "properties": [
            "Total darkness that no lamp, candle or charm can touch",
            "Twelve to twenty-four seconds per pinch",
            "Comes in a waxed jar that doesn't leak (mostly)",
        ],
        "warning": "Do not open next to anything that glows on its own. Ask the antique dealer why.",
        "price": to_pips(1, 4, 15),
        "badge": "Imported",
        "accent": "#2c2236",
        "effect": "darkness",
        "demo": "Throw a pinch",
    },
    {
        "slug": "skyroarer-rockets",
        "name": "Skyroarer Rockets",
        "category": "mayhem",
        "tagline": "Bigger. Brighter. Better at exams.",
        "description": (
            "The Starter Sparkbox sends up a handful of spinning dragons; the Grand Finale "
            "Crate fills an entire great hall. Try to stamp them out and they explode. Try to "
            "sweep them up and they multiply by ten. Our most famous product, as one examiner "
            "found out the hard way."
        ),
        "properties": [
            "Sweep one up and you get ten (we take no responsibility)",
            "Dragons, Catherine wheels and very rude sparklers",
            "Sets off a gratifying shriek from senior staff",
        ],
        "warning": "Do not light indoors. Do not light during an exam. Do it anyway.",
        "price": to_pips(5, 10, 0),
        "badge": "Legendary",
        "accent": "#e8562a",
        "effect": "whizbang",
        "demo": "Light the fuse",
    },
    {
        "slug": "songbird-creams",
        "name": "Songbird Creams",
        "category": "truancy-treats",
        "tagline": "Bite, transform, moult. Quite harmless.",
        "description": (
            "They look like ordinary custard creams, and that's the whole point. Offer one "
            "around and whoever eats it turns into a large yellow songbird for about a minute. "
            "They moult back to normal, a little ruffled. Feathers on the carpet are your problem."
        ),
        "properties": [
            "Turns the eater into a fully feathered songbird for a minute",
            "Indistinguishable from real custard creams",
            "Sold by the dozen: one for a victim, eleven for later",
        ],
        "warning": "Do not offer to cousins over half-term. We did. Dad still talks about it.",
        "price": to_pips(0, 7, 0),
        "badge": "Seven Shards",
        "accent": "#e8c547",
        "effect": "canary",
        "demo": "Offer one around",
    },
    {
        "slug": "bumble-fizzies",
        "name": "Bumble Fizzies",
        "category": "truancy-treats",
        "tagline": "Fizzy honey gummies. Mild levitation. Mind the ceiling.",
        "description": (
            "Sugar-dusted honey gummies shaped like little bees, with a sherbet fizz in the "
            "middle that lifts you a few inches off the floor while it lasts. Perfect for "
            "reaching the top shelf, skipping a puddle or making a teacher wonder why you "
            "suddenly seem taller. They hum in the box, so keep the lid on in quiet places."
        ),
        "properties": [
            "Lifts the eater three to six inches for about a minute",
            "Real honey, real fizz, entirely imaginary bees",
            "Comes in a hexagon box, or loose in a paper cone",
        ],
        "warning": "Do not eat a whole cone indoors. Rufus is still on the chandelier.",
        "price": to_pips(0, 9, 10),
        "badge": "New in",
        "accent": "#e8b13a",
        "effect": "bees",
        "demo": "Take off",
    },
    {
        "slug": "reverie-charms",
        "name": "Reverie Charms",
        "category": "creatures",
        "tagline": "Thirty minutes of top-quality escape.",
        "description": (
            "Lift the glass dome and you slip into a realistic half-hour daydream, just "
            "long enough for a typical school lesson and almost undetectable. Side effects "
            "include mild drooling and a vacant expression. Not sold to anyone under sixteen."
        ),
        "properties": [
            "Half an hour of vivid, entirely private adventure",
            "Comes back to reality on cue, with no forgetting spell needed",
            "Officially patented; unofficially much copied",
        ],
        "warning": "Not for under-sixteens. Do not ride a broomstick while dreaming.",
        "price": to_pips(3, 2, 0),
        "badge": "Patented",
        "accent": "#a774c9",
        "effect": "dream",
        "demo": "Drift off",
    },
    {
        "slug": "truants-tuckbox",
        "name": "Truant's Tuckbox",
        "category": "truancy-treats",
        "tagline": "The complete escape kit. Two ends, endless excuses.",
        "description": (
            "Our flagship: a box of two-ended sweets that make you ill on demand. Orange "
            "end to come down with something, purple end to get better once you're out of "
            "the classroom. Inside: Queasy Drops, Crimson Nose Nougat, Hot-Brow Fudge and "
            "Swooning Shortbreads. Developed during years of selfless research."
        ),
        "properties": [
            "Four sweets for four occasions; the details are yours",
            "Colour-coded, foolproof and teacher-tested",
            "Comes in a snap-lid box that hides its contents cleverly",
        ],
        "warning": "Not covered by any official warranty. Or any warranty at all.",
        "price": to_pips(2, 11, 0),
        "badge": "Flagship",
        "accent": "#d4612a",
        "effect": "snackbox",
        "demo": "Open the box",
    },
]

_BY_SLUG = {p["slug"]: p for p in PRODUCTS}
for _p in PRODUCTS:
    _p["coins"] = split_pips(_p["price"])


def get_product(slug: str):
    return _BY_SLUG.get(slug)


def category_name(slug: str) -> str:
    for c in CATEGORIES:
        if c["slug"] == slug:
            return c["name"]
    return ""


def related_products(product, count: int = 3):
    """Same-category products first, then the rest, without the product itself."""
    same = [p for p in PRODUCTS if p["category"] == product["category"] and p is not product]
    other = [p for p in PRODUCTS if p["category"] != product["category"]]
    return (same + other)[:count]
