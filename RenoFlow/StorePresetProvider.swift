import Foundation

struct StorePresetProvider {
    static func stores(for region: Region) -> [Store] {
        let regional: [Region: [Store]] = [
            .ca: [
                store("homedepot-ca", "Home Depot CA", "https://www.homedepot.ca", "https://www.homedepot.ca/search?q={query}"),
                store("rona", "RONA", "https://www.rona.ca", "https://www.rona.ca/en/search?text={query}"),
                store("canadiantire", "Canadian Tire", "https://www.canadiantire.ca", "https://www.canadiantire.ca/en/search-results.html?q={query}"),
                store("wayfair-ca", "Wayfair CA", "https://www.wayfair.ca", "https://www.wayfair.ca/keyword.php?keyword={query}"),
                store("walmart-ca", "Walmart CA", "https://www.walmart.ca", "https://www.walmart.ca/search?q={query}")
            ],
            .us: [
                store("homedepot-us", "Home Depot", "https://www.homedepot.com", "https://www.homedepot.com/s/{query}"),
                store("lowes-us", "Lowe's", "https://www.lowes.com", "https://www.lowes.com/search?searchTerm={query}"),
                store("menards", "Menards", "https://www.menards.com", "https://www.menards.com/main/search.html?search={query}"),
                store("wayfair-us", "Wayfair", "https://www.wayfair.com", "https://www.wayfair.com/keyword.php?keyword={query}"),
                store("walmart-us", "Walmart", "https://www.walmart.com", "https://www.walmart.com/search?q={query}")
            ],
            .gb: [
                store("b-and-q", "B&Q", "https://www.diy.com", "https://www.diy.com/search?term={query}"),
                store("wickes", "Wickes", "https://www.wickes.co.uk", "https://www.wickes.co.uk/search?text={query}"),
                store("screwfix", "Screwfix", "https://www.screwfix.com", "https://www.screwfix.com/search?search={query}"),
                store("argos", "Argos", "https://www.argos.co.uk", "https://www.argos.co.uk/search/{query}/"),
                store("john-lewis", "John Lewis", "https://www.johnlewis.com", "https://www.johnlewis.com/search?search-term={query}")
            ],
            .de: [
                store("obi-de", "OBI", "https://www.obi.de", "https://www.obi.de/search/{query}/"),
                store("bauhaus-de", "BAUHAUS", "https://www.bauhaus.info", "https://www.bauhaus.info/suche/produkte?text={query}"),
                store("hornbach-de", "HORNBACH", "https://www.hornbach.de", "https://www.hornbach.de/suche/?q={query}"),
                store("toom", "toom", "https://toom.de", "https://toom.de/suche/?search={query}"),
                store("wayfair-de", "Wayfair DE", "https://www.wayfair.de", "https://www.wayfair.de/keyword.php?keyword={query}")
            ],
            .fr: [
                store("leroymerlin-fr", "Leroy Merlin", "https://www.leroymerlin.fr", "https://www.leroymerlin.fr/recherche/?q={query}"),
                store("castorama-fr", "Castorama", "https://www.castorama.fr", "https://www.castorama.fr/search?term={query}"),
                store("bricodepot-fr", "Brico Depot", "https://www.bricodepot.fr", "https://www.bricodepot.fr/search?text={query}"),
                store("manomano-fr", "ManoMano", "https://www.manomano.fr", "https://www.manomano.fr/recherche/{query}"),
                store("but-fr", "BUT", "https://www.but.fr", "https://www.but.fr/recherche?text={query}")
            ],
            .au: [
                store("bunnings", "Bunnings", "https://www.bunnings.com.au", "https://www.bunnings.com.au/search/products?q={query}"),
                store("mitre10-au", "Mitre 10", "https://www.mitre10.com.au", "https://www.mitre10.com.au/search?text={query}"),
                store("ikea-au", "IKEA AU", "https://www.ikea.com/au/en", "https://www.ikea.com/au/en/search/?q={query}"),
                store("temple-and-webster", "Temple & Webster", "https://www.templeandwebster.com.au", "https://www.templeandwebster.com.au/search.html?keywords={query}"),
                store("kogan", "Kogan", "https://www.kogan.com", "https://www.kogan.com/au/shop/?q={query}")
            ],
            .nl: [
                store("gamma-nl", "GAMMA", "https://www.gamma.nl", "https://www.gamma.nl/assortiment/zoeken?text={query}"),
                store("praxis-nl", "Praxis", "https://www.praxis.nl", "https://www.praxis.nl/search?text={query}"),
                store("hornbach-nl", "HORNBACH NL", "https://www.hornbach.nl", "https://www.hornbach.nl/suche/?q={query}"),
                store("bol", "bol", "https://www.bol.com", "https://www.bol.com/nl/nl/s/?searchtext={query}"),
                store("fonq", "fonQ", "https://www.fonq.nl", "https://www.fonq.nl/zoeken/?q={query}")
            ],
            .pl: [
                store("castorama-pl", "Castorama PL", "https://www.castorama.pl", "https://www.castorama.pl/search?term={query}"),
                store("leroymerlin-pl", "Leroy Merlin PL", "https://www.leroymerlin.pl", "https://www.leroymerlin.pl/szukaj.html?q={query}"),
                store("obi-pl", "OBI PL", "https://www.obi.pl", "https://www.obi.pl/search/{query}/"),
                store("allegro", "Allegro", "https://allegro.pl", "https://allegro.pl/listing?string={query}"),
                store("komfort", "Komfort", "https://www.komfort.pl", "https://www.komfort.pl/szukaj?query={query}")
            ]
        ]
        return (regional[region] ?? []) + fallbackStores
    }

    static let fallbackStores = [
        store("amazon", "Amazon", "https://www.amazon.com", "https://www.amazon.com/s?k={query}"),
        store("ikea", "IKEA", "https://www.ikea.com", "https://www.ikea.com/search/?q={query}")
    ]

    private static func store(_ id: String, _ name: String, _ baseURL: String, _ searchURLTemplate: String?) -> Store {
        Store(id: id, name: name, baseURL: baseURL, searchURLTemplate: searchURLTemplate, isPreset: true)
    }
}

struct RoomSearchSuggestions {
    static func queries(for roomName: String) -> [String] {
        let key = roomName.lowercased()
        if key.contains("kitchen") { return ["kitchen sink", "kitchen cabinets", "kitchen appliances"] }
        if key.contains("bath") { return ["bathroom tiles", "shower", "bathroom sink"] }
        if key.contains("living") { return ["sofa", "tv stand", "coffee table"] }
        if key.contains("bed") { return ["bed frame", "wardrobe", "nightstand"] }
        if key.contains("laundry") { return ["laundry sink", "washer dryer", "storage cabinet"] }
        return ["paint", "flooring", "lighting"]
    }
}
