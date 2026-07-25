import pitchNight from "@/assets/pitch-night.jpg";
import futsalCourt from "@/assets/futsal-court.jpg";
import parkField from "@/assets/park-field.jpg";
import rooftopCourt from "@/assets/rooftop-court.jpg";

export type SkillLevel = "Casual" | "Intermediate" | "Baller" | "Open to All";

export interface PickupGame {
  id: string;
  title: string;
  venue: string;
  neighborhood: string;
  distanceMiles: number;
  dateLabel: string;
  timeLabel: string;
  startsIn?: string;
  skill: SkillLevel;
  format: string;
  joined: number;
  capacity: number;
  image?: string;
  host: string;
  pricePerPlayer: number;
  notes: string;
  lat: number;
  lng: number;
}

export const CURRENT_CITY = "Brooklyn, NY";

export const mockGames: PickupGame[] = [
  {
    id: "late-night-7v7",
    title: "Late Night 7v7 Sprints",
    venue: "McCarren Park Turf",
    neighborhood: "Williamsburg",
    distanceMiles: 0.8,
    dateLabel: "Today",
    timeLabel: "9:00 PM",
    startsIn: "Starts in 45m",
    skill: "Intermediate",
    format: "7v7",
    joined: 12,
    capacity: 14,
    image: pitchNight,
    host: "Marco D.",
    pricePerPlayer: 8,
    notes: "Bring dark + light shirts. Turf shoes recommended, no metal studs. We split teams on arrival.",
    lat: 40.7215,
    lng: -73.9518,
  },
  {
    id: "competitive-futsal",
    title: "Competitive Futsal",
    venue: "The Warehouse Indoor",
    neighborhood: "Long Island City",
    distanceMiles: 3.2,
    dateLabel: "Tomorrow",
    timeLabel: "8:00 AM",
    skill: "Baller",
    format: "5v5",
    joined: 6,
    capacity: 10,
    image: futsalCourt,
    host: "Ligia F.",
    pricePerPlayer: 12,
    notes: "Fast-paced futsal, flat-sole shoes only. Winners stay on. Come warmed up.",
    lat: 40.7447,
    lng: -73.9485,
  },
  {
    id: "sunday-morning-11s",
    title: "Sunday Morning 11s",
    venue: "Prospect Park Parade Ground",
    neighborhood: "Flatbush",
    distanceMiles: 1.4,
    dateLabel: "Sun",
    timeLabel: "10:00 AM",
    skill: "Casual",
    format: "11v11",
    joined: 22,
    capacity: 22,
    image: parkField,
    host: "Sam K.",
    pricePerPlayer: 5,
    notes: "Full-field friendly. All levels welcome, we rotate subs every 15 minutes.",
    lat: 40.6515,
    lng: -73.9701,
  },
  {
    id: "rooftop-cage-5s",
    title: "Rooftop Cage 5s",
    venue: "Skyline Pitch BK",
    neighborhood: "Downtown Brooklyn",
    distanceMiles: 2.1,
    dateLabel: "Fri",
    timeLabel: "7:30 PM",
    skill: "Intermediate",
    format: "5v5",
    joined: 7,
    capacity: 10,
    image: rooftopCourt,
    host: "Dre W.",
    pricePerPlayer: 15,
    notes: "Caged rooftop court with city views. Small-sided, quick touches. Ball provided.",
    lat: 40.6928,
    lng: -73.9857,
  },
  {
    id: "lunch-break-kickabout",
    title: "Lunch Break Kickabout",
    venue: "Bushwick Inlet Park",
    neighborhood: "Greenpoint",
    distanceMiles: 1.1,
    dateLabel: "Thu",
    timeLabel: "12:30 PM",
    skill: "Casual",
    format: "6v6",
    joined: 4,
    capacity: 12,
    host: "Priya N.",
    pricePerPlayer: 0,
    notes: "Free casual game. Show up, play, head back to work. Jumpers for goalposts energy.",
    lat: 40.7226,
    lng: -73.9614,
  },
  {
    id: "saturday-scrimmage",
    title: "Saturday Scrimmage & Drills",
    venue: "Red Hook Rec Fields",
    neighborhood: "Red Hook",
    distanceMiles: 4.6,
    dateLabel: "Sat",
    timeLabel: "9:00 AM",
    skill: "Baller",
    format: "8v8",
    joined: 11,
    capacity: 16,
    host: "Coach T.",
    pricePerPlayer: 10,
    notes: "First 30 min touch drills, then full scrimmage. Serious players only please.",
    lat: 40.6734,
    lng: -74.0083,
  },
];

export const skillColor: Record<SkillLevel, string> = {
  Casual: "text-muted-foreground",
  Intermediate: "text-primary",
  Baller: "text-foreground",
  "Open to All": "text-primary",
};

export interface Friend {
  id: string;
  name: string;
  handle: string;
  avatarSeed: string;
  following: boolean;
  followsYou: boolean;
  mutuals: number;
  rsvpedGameIds: string[];
  lastMessage?: string;
  lastMessageAt?: string;
  unread?: number;
}

export const mockFriends: Friend[] = [
  {
    id: "marco",
    name: "Marco Diaz",
    handle: "@marcod",
    avatarSeed: "Marco",
    following: true,
    followsYou: true,
    mutuals: 12,
    rsvpedGameIds: ["late-night-7v7", "rooftop-cage-5s"],
    lastMessage: "You coming tonight?",
    lastMessageAt: "12m",
    unread: 2,
  },
  {
    id: "ligia",
    name: "Ligia Ferreira",
    handle: "@ligiaf",
    avatarSeed: "Ligia",
    following: true,
    followsYou: true,
    mutuals: 8,
    rsvpedGameIds: ["competitive-futsal"],
    lastMessage: "Nice touch yesterday 🔥",
    lastMessageAt: "1h",
  },
  {
    id: "sam",
    name: "Sam Kwon",
    handle: "@samk",
    avatarSeed: "Sam",
    following: true,
    followsYou: false,
    mutuals: 3,
    rsvpedGameIds: ["sunday-morning-11s", "late-night-7v7"],
    lastMessage: "Rain check?",
    lastMessageAt: "3h",
  },
  {
    id: "dre",
    name: "Dre Williams",
    handle: "@drew",
    avatarSeed: "Dre",
    following: false,
    followsYou: true,
    mutuals: 5,
    rsvpedGameIds: ["rooftop-cage-5s"],
  },
  {
    id: "priya",
    name: "Priya Nair",
    handle: "@priyan",
    avatarSeed: "Priya",
    following: false,
    followsYou: true,
    mutuals: 2,
    rsvpedGameIds: ["lunch-break-kickabout"],
  },
  {
    id: "coach",
    name: "Coach T",
    handle: "@coacht",
    avatarSeed: "Coach",
    following: true,
    followsYou: true,
    mutuals: 21,
    rsvpedGameIds: ["saturday-scrimmage"],
    lastMessage: "Drills at 8:30 sharp",
    lastMessageAt: "1d",
  },
];

export function friendsForGame(gameId: string): Friend[] {
  return mockFriends.filter((f) => f.following && f.rsvpedGameIds.includes(gameId));
}
