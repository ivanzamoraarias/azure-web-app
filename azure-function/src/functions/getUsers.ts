import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { mockUsers } from "../mockData";

export async function getUsers(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`HTTP function processed request for url "${request.url}"`);

    // Get query parameters for filtering
    const role = request.query.get("role");
    const id = request.query.get("id");

    let users = [...mockUsers];

    // Filter by role if provided
    if (role) {
        users = users.filter(user => user.role.toLowerCase() === role.toLowerCase());
    }

    // Filter by id if provided
    if (id) {
        users = users.filter(user => user.id === id);
    }

    return {
        status: 200,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            success: true,
            data: users,
            count: users.length
        })
    };
}

app.http("getUsers", {
    methods: ["GET"],
    authLevel: "anonymous",
    route: "users",
    handler: getUsers
});
