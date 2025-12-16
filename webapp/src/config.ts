// MSAL Configuration for Entra ID authentication

export interface AuthConfig {
    clientId: string;
    tenantId: string;
    clientSecret: string;
    redirectUri: string;
    postLogoutRedirectUri: string;
    scopes: string[];
}

export const authConfig: AuthConfig = {
    clientId: process.env.AZURE_CLIENT_ID || "",
    tenantId: process.env.AZURE_TENANT_ID || "",
    clientSecret: process.env.AZURE_CLIENT_SECRET || "",
    redirectUri: process.env.REDIRECT_URI || "http://localhost:3000/auth/callback",
    postLogoutRedirectUri: process.env.POST_LOGOUT_REDIRECT_URI || "http://localhost:3000",
    scopes: ["openid", "profile", "email", "User.Read"]
};

export const msalConfig = {
    auth: {
        clientId: authConfig.clientId,
        authority: `https://login.microsoftonline.com/${authConfig.tenantId}`,
        clientSecret: authConfig.clientSecret
    },
    system: {
        loggerOptions: {
            loggerCallback(loglevel: number, message: string) {
                console.log(message);
            },
            piiLoggingEnabled: false,
            logLevel: 3 // Info
        }
    }
};

export const apiConfig = {
    baseUrl: process.env.API_BASE_URL || "http://localhost:7071/api",
    scopes: [`api://${authConfig.clientId}/.default`]
};
