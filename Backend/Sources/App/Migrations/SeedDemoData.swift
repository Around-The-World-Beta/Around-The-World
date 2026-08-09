import Fluent
import Vapor

/// Local / staging seed covering all nine Bay Area counties.
/// Enable with `SEED_DEMO=1` (default in `scripts/run-backend.sh`).
struct SeedDemoData: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let enabled = (Environment.get("SEED_DEMO") ?? "").lowercased()
        guard enabled == "1" || enabled == "true" || enabled == "yes" else {
            return
        }

        let existing = try await Game.query(on: database).count()
        if existing > 0 {
            return
        }

        let host = User(email: "coach@aroundtheworld.dev", displayName: "Coach T")
        try await host.save(on: database)
        guard let hostID = host.id else { return }

        try await Profile(
            userID: hostID,
            city: "San Francisco, CA",
            bio: "Bay Area pickup organizer — all nine counties.",
            favoritePosition: "Midfielder",
            skillLevel: "Baller",
            age: 29
        ).save(on: database)

        let player = User(email: "marco@aroundtheworld.dev", displayName: "Marco Diaz")
        try await player.save(on: database)
        try await Profile(
            userID: try player.requireID(),
            city: "Oakland, CA",
            bio: "East Bay regular",
            favoritePosition: "Forward",
            skillLevel: "Intermediate",
            age: 24
        ).save(on: database)

        let playerID = try player.requireID()

        // One open session per major city cluster across the nine counties.
        // `neighborhood` is "City, County" so Bay Area players can scan quickly.
        let specs: [(String, String, String, String, String, Int, Int, String, TimeInterval, Double, Double)] = [
            // San Francisco
            ("Mission Evening Scrimmage", "Franklin Square Park", "San Francisco, San Francisco", "Baller", "7v7", 14, 0, "Bring dark + light.", 20 * 3600, 37.7644, -122.4102),
            ("Sunset Weekend Kickabout", "West Sunset Playground", "San Francisco, San Francisco", "Beginner", "6v6", 12, 0, "Family-friendly, all ages 4+.", 30 * 3600, 37.7550, -122.4980),
            ("Embarcadero Lunch 5v5", "Sue Bierman Park", "San Francisco, San Francisco", "Intermediate", "5v5", 10, 500, "Quick lunch session.", 6 * 3600, 37.7956, -122.3970),
            // San Mateo
            ("Pacifica Coastal Scrimmage", "Fairmont Park Field", "Pacifica, San Mateo", "Intermediate", "7v7", 14, 0, "Windy — layers recommended.", 26 * 3600, 37.6138, -122.4869),
            ("Redwood City Night 7v7", "Stafford Park", "Redwood City, San Mateo", "Baller", "7v7", 14, 800, "Turf shoes only.", 18 * 3600, 37.4852, -122.2364),
            ("Daly City Community Pickup", "Marchbank Park", "Daly City, San Mateo", "Beginner", "6v6", 12, 0, "Open to everyone.", 40 * 3600, 37.6879, -122.4702),
            // Santa Clara
            ("Palo Alto Lunch 5v5", "Mitchell Park Field", "Palo Alto, Santa Clara", "Intermediate", "5v5", 10, 500, "First come first served.", 8 * 3600, 37.4020, -122.1130),
            ("San Jose Evening 8v8", "Lake Cunningham Regional Park", "San Jose, Santa Clara", "Baller", "8v8", 16, 1000, "Serious pace.", 22 * 3600, 37.3370, -121.7900),
            ("Mountain View Tech Pickup", "Rengstorff Park", "Mountain View, Santa Clara", "Open to All", "6v6", 12, 0, "Post-work social game.", 16 * 3600, 37.4025, -122.0965),
            ("Sunnyvale Turf Scrimmage", "Ortega Park", "Sunnyvale, Santa Clara", "Intermediate", "7v7", 14, 600, "Bring both shirt colors.", 28 * 3600, 37.3688, -122.0363),
            // Alameda
            ("Lake Merritt Morning Kickabout", "Lake Merritt Fields", "Oakland, Alameda", "Beginner", "6v6", 12, 0, "All ages welcome.", 48 * 3600, 37.8015, -122.2583),
            ("Berkeley Campus Pickup", "San Pablo Park", "Berkeley, Alameda", "Intermediate", "7v7", 14, 0, "Student + community mix.", 14 * 3600, 37.8545, -122.2830),
            ("Fremont Night Lights", "Central Park Soccer Fields", "Fremont, Alameda", "Baller", "8v8", 16, 900, "Under the lights.", 24 * 3600, 37.5502, -121.9720),
            ("Livermore Weekend Open", "Robertson Park", "Livermore, Alameda", "Open to All", "7v7", 14, 0, "Tri-Valley meetup.", 52 * 3600, 37.6820, -121.7680),
            // Contra Costa
            ("Walnut Creek Midweek 5v5", "Heather Farm Park", "Walnut Creek, Contra Costa", "Intermediate", "5v5", 10, 700, "After-work pace.", 12 * 3600, 37.9260, -122.0410),
            ("Concord Community Scrimmage", "Newhall Community Park", "Concord, Contra Costa", "Beginner", "6v6", 12, 0, "New players welcome.", 36 * 3600, 37.9780, -122.0310),
            ("Richmond Waterfront Pickup", "Point Isabel Regional Shoreline", "Richmond, Contra Costa", "Open to All", "7v7", 14, 0, "Sunset views.", 44 * 3600, 37.8985, -122.3240),
            // Marin
            ("Mill Valley Sunday Kickabout", "Old Mill Park Field", "Mill Valley, Marin", "Beginner", "6v6", 12, 0, "Bring the family.", 50 * 3600, 37.9060, -122.5450),
            ("San Rafael Evening 7v7", "Pickleweed Park", "San Rafael, Marin", "Intermediate", "7v7", 14, 500, "Marin regulars.", 19 * 3600, 37.9635, -122.5005),
            // Solano
            ("Vallejo Waterfront Scrimmage", "Wilson Park", "Vallejo, Solano", "Open to All", "7v7", 14, 0, "North Bay meetup.", 32 * 3600, 38.1000, -122.2560),
            ("Fairfield Weekend Open Play", "Allan Witt Park", "Fairfield, Solano", "Beginner", "6v6", 12, 0, "Casual pace.", 54 * 3600, 38.2490, -122.0400),
            // Napa
            ("Napa Valley Saturday Pickup", "Fuller Park", "Napa, Napa", "Intermediate", "7v7", 14, 0, "Wine country kickabout.", 46 * 3600, 38.2970, -122.2860),
            // Sonoma
            ("Santa Rosa Evening Scrimmage", "Howarth Park", "Santa Rosa, Sonoma", "Baller", "7v7", 14, 600, "Sonoma County ballers.", 21 * 3600, 38.4404, -122.7141),
            ("Petaluma Community 6v6", "Lucchesi Park", "Petaluma, Sonoma", "Beginner", "6v6", 12, 0, "South Sonoma welcome.", 38 * 3600, 38.2490, -122.6280),
        ]

        for (idx, s) in specs.enumerated() {
            let game = Game(
                hostID: hostID,
                title: s.0,
                venue: s.1,
                neighborhood: s.2,
                skill: s.3,
                format: s.4,
                capacity: s.5,
                priceCents: s.6,
                notes: s.7 + " · Bay Area beta.",
                startsAt: Date().addingTimeInterval(s.8 + Double(idx) * 120),
                latitude: s.9,
                longitude: s.10
            )
            try await game.save(on: database)
            if let gameID = game.id {
                try await Participant(gameID: gameID, userID: hostID, status: .joined).save(on: database)
                try await Participant(gameID: gameID, userID: playerID, status: .joined).save(on: database)
            }
        }
    }

    func revert(on database: any Database) async throws {}
}
