import { ConfidentialClientApplication, AuthorizationCodeRequest, AuthorizationUrlRequest, CryptoProvider } from "@azure/msal-node";
import { Request, Response, NextFunction } from "express";
import { msalConfig, authConfig, apiConfig } from "./config";

// Create MSAL instance
const msalInstance = new ConfidentialClientApplication(msalConfig);
const cryptoProvider = new CryptoProvider();

// Session types
declare module "express-session" {
    interface SessionData {
        isAuthenticated: boolean;
        account: {
            homeAccountId: string;
            username: string;
            name?: string;
        };
        accessToken?: string;
        csrfToken?: string;
        pkceCodes?: {
            verifier: string;
            challenge: string;
            challengeMethod: string;
        };
    }
}

// Generate PKCE codes for secure authentication
async function generatePkceCodes(): Promise<{ verifier: string; challenge: string; challengeMethod: string }> {
    const { verifier, challenge } = await cryptoProvider.generatePkceCodes();
    return { verifier, challenge, challengeMethod: "S256" };
}

// Get authorization URL for login
export async function getAuthUrl(req: Request): Promise<string> {
    const pkceCodes = await generatePkceCodes();
    req.session.pkceCodes = pkceCodes;
    req.session.csrfToken = cryptoProvider.createNewGuid();

    const authCodeUrlParameters: AuthorizationUrlRequest = {
        scopes: authConfig.scopes,
        redirectUri: authConfig.redirectUri,
        codeChallenge: pkceCodes.challenge,
        codeChallengeMethod: pkceCodes.challengeMethod,
        state: req.session.csrfToken
    };

    return await msalInstance.getAuthCodeUrl(authCodeUrlParameters);
}

// Handle authentication callback
export async function handleCallback(req: Request): Promise<void> {
    const code = req.query.code as string;
    const state = req.query.state as string;

    // Validate CSRF token
    if (state !== req.session.csrfToken) {
        throw new Error("CSRF token validation failed");
    }

    if (!req.session.pkceCodes) {
        throw new Error("PKCE codes not found in session");
    }

    const tokenRequest: AuthorizationCodeRequest = {
        code,
        scopes: authConfig.scopes,
        redirectUri: authConfig.redirectUri,
        codeVerifier: req.session.pkceCodes.verifier
    };

    const response = await msalInstance.acquireTokenByCode(tokenRequest);

    req.session.isAuthenticated = true;
    req.session.account = {
        homeAccountId: response.account?.homeAccountId || "",
        username: response.account?.username || "",
        name: response.account?.name
    };
    req.session.accessToken = response.accessToken;

    // Clear PKCE codes and CSRF token
    delete req.session.pkceCodes;
    delete req.session.csrfToken;
}

// Get access token for API calls
export async function getAccessToken(req: Request): Promise<string | null> {
    if (!req.session.account) {
        return null;
    }

    try {
        const silentRequest = {
            account: {
                homeAccountId: req.session.account.homeAccountId,
                environment: "login.microsoftonline.com",
                tenantId: authConfig.tenantId,
                username: req.session.account.username,
                localAccountId: ""
            },
            scopes: apiConfig.scopes
        };

        const response = await msalInstance.acquireTokenSilent(silentRequest);
        return response.accessToken;
    } catch (error) {
        console.error("Error acquiring token silently:", error);
        return req.session.accessToken || null;
    }
}

// Logout
export function getLogoutUrl(): string {
    return `https://login.microsoftonline.com/${authConfig.tenantId}/oauth2/v2.0/logout?post_logout_redirect_uri=${encodeURIComponent(authConfig.postLogoutRedirectUri)}`;
}

// Authentication middleware
export function requireAuth(req: Request, res: Response, next: NextFunction): void {
    if (req.session.isAuthenticated) {
        next();
    } else {
        res.redirect("/login");
    }
}

// Check if authenticated (for API routes)
export function isAuthenticated(req: Request): boolean {
    return req.session.isAuthenticated === true;
}
