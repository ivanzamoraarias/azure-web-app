import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { mockProducts } from "../mockData";

export async function getProducts(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
    context.log(`HTTP function processed request for url "${request.url}"`);

    // Get query parameters for filtering
    const category = request.query.get("category");
    const id = request.query.get("id");
    const minPrice = request.query.get("minPrice");
    const maxPrice = request.query.get("maxPrice");

    let products = [...mockProducts];

    // Filter by category if provided
    if (category) {
        products = products.filter(product => product.category.toLowerCase() === category.toLowerCase());
    }

    // Filter by id if provided
    if (id) {
        products = products.filter(product => product.id === id);
    }

    // Filter by price range if provided
    if (minPrice) {
        const min = parseFloat(minPrice);
        if (!isNaN(min)) {
            products = products.filter(product => product.price >= min);
        }
    }

    if (maxPrice) {
        const max = parseFloat(maxPrice);
        if (!isNaN(max)) {
            products = products.filter(product => product.price <= max);
        }
    }

    return {
        status: 200,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            success: true,
            data: products,
            count: products.length
        })
    };
}

app.http("getProducts", {
    methods: ["GET"],
    authLevel: "anonymous",
    route: "products",
    handler: getProducts
});
