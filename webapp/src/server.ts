import express, { Request, Response } from "express";
import session from "express-session";
import path from "path";
import { getAuthUrl, handleCallback, getLogoutUrl, requireAuth, isAuthenticated, getAccessToken } from "./auth";
import { apiConfig } from "./config";

const app = express();
const PORT = process.env.PORT || 3000;

// Session configuration
app.use(session({
    secret: process.env.SESSION_SECRET || "development-secret-change-in-production",
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === "production",
        httpOnly: true,
        maxAge: 24 * 60 * 60 * 1000 // 24 hours
    }
}));

// Static files
app.use(express.static(path.join(__dirname, "../public")));

// JSON parsing
app.use(express.json());

// Login route
app.get("/login", async (req: Request, res: Response) => {
    try {
        const authUrl = await getAuthUrl(req);
        res.redirect(authUrl);
    } catch (error) {
        console.error("Login error:", error);
        res.status(500).send("Error initiating login");
    }
});

// Auth callback route
app.get("/auth/callback", async (req: Request, res: Response) => {
    try {
        await handleCallback(req);
        res.redirect("/");
    } catch (error) {
        console.error("Callback error:", error);
        res.status(500).send("Error during authentication callback");
    }
});

// Logout route
app.get("/logout", (req: Request, res: Response) => {
    req.session.destroy(() => {
        res.redirect(getLogoutUrl());
    });
});

// API proxy route - Get users
app.get("/api/users", requireAuth, async (req: Request, res: Response) => {
    try {
        const accessToken = await getAccessToken(req);
        const response = await fetch(`${apiConfig.baseUrl}/users`, {
            headers: {
                "Authorization": `Bearer ${accessToken}`,
                "Content-Type": "application/json"
            }
        });
        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error("Error fetching users:", error);
        res.status(500).json({ error: "Failed to fetch users" });
    }
});

// API proxy route - Get products
app.get("/api/products", requireAuth, async (req: Request, res: Response) => {
    try {
        const accessToken = await getAccessToken(req);
        const response = await fetch(`${apiConfig.baseUrl}/products`, {
            headers: {
                "Authorization": `Bearer ${accessToken}`,
                "Content-Type": "application/json"
            }
        });
        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error("Error fetching products:", error);
        res.status(500).json({ error: "Failed to fetch products" });
    }
});

// User info endpoint
app.get("/api/me", (req: Request, res: Response) => {
    if (isAuthenticated(req)) {
        res.json({
            authenticated: true,
            user: req.session.account
        });
    } else {
        res.json({
            authenticated: false,
            user: null
        });
    }
});

// Health check
app.get("/health", (req: Request, res: Response) => {
    res.json({
        status: "healthy",
        timestamp: new Date().toISOString()
    });
});

// Protected home page
app.get("/", requireAuth, (req: Request, res: Response) => {
    res.sendFile(path.join(__dirname, "../public/index.html"));
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

export default app;
