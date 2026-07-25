import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import {
  getAuthState,
  type AuthState,
} from "./auth.functions";

interface AuthContextValue extends AuthState {
  refreshAuth: () => Promise<AuthState>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({
  initialState,
  children,
}: {
  initialState: AuthState;
  children: ReactNode;
}) {
  const [state, setState] = useState(initialState);

  const refreshAuth = useCallback(async () => {
    const next = await getAuthState();
    setState(next);
    return next;
  }, []);

  const value = useMemo(
    () => ({ ...state, refreshAuth }),
    [state, refreshAuth],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used inside AuthProvider.");
  }
  return context;
}

