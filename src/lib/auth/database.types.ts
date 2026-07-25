export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type AppRole = "user" | "moderator" | "admin";

export interface Profile {
  id: string;
  display_name: string;
  city: string | null;
  bio: string | null;
  favorite_position: string | null;
  skill_level: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: {
          id: string;
          display_name: string;
          city?: string | null;
          bio?: string | null;
          favorite_position?: string | null;
          skill_level?: string | null;
          avatar_url?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          display_name?: string;
          city?: string | null;
          bio?: string | null;
          favorite_position?: string | null;
          skill_level?: string | null;
          avatar_url?: string | null;
          updated_at?: string;
        };
        Relationships: [];
      };
      user_roles: {
        Row: {
          user_id: string;
          role: AppRole;
          created_at: string;
        };
        Insert: {
          user_id: string;
          role?: AppRole;
          created_at?: string;
        };
        Update: {
          role?: AppRole;
        };
        Relationships: [];
      };
      audit_events: {
        Row: {
          id: number;
          actor_user_id: string | null;
          action: string;
          target_type: string;
          target_id: string | null;
          metadata: Json;
          created_at: string;
        };
        Insert: {
          id?: number;
          actor_user_id?: string | null;
          action: string;
          target_type: string;
          target_id?: string | null;
          metadata?: Json;
          created_at?: string;
        };
        Update: never;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: {
      app_role: AppRole;
    };
    CompositeTypes: Record<string, never>;
  };
}

