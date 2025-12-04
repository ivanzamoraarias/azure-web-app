import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";

export async function healthCheck(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log("Health check endpoint called");

    return {
        status: 200,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            status: "healthy",
            timestamp: new Date().toISOString(),
            version: "1.0.0"
        })
    };
}

app.http("healthCheck", {
    methods: ["GET"],
    authLevel: "anonymous",
    route: "health",
    handler: healthCheck
});
